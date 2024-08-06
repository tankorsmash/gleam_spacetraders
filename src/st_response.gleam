import dot_env/env
import efetch
import falcon.{type FalconError, type FalconResponse}
import falcon/core
import gleam/dynamic
import gleam/float
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleeunit/should
import pprint

pub type FalconResult(data) =
  Result(FalconResponse(data), FalconError)

pub type Meta {
  Meta(total: Int, page: Int, limit: Int)
}

pub type PagedApiData(data) {
  PagedApiData(data: data, meta: Meta)
}

pub type PagedApiResponse(data) =
  FalconResult(PagedApiData(data))

pub type ApiError(data) {
  ApiError(status: Int, message: String, data: option.Option(data))
}

/// the Ok result will be either the decoder we want, or the generic ApiError type
pub type ApiResult(data) =
  FalconResult(Result(data, ApiError(dynamic.Dynamic)))

pub fn decode_api_error(dynamic: dynamic.Dynamic) {
  dynamic
  |> dynamic.decode3(
    ApiError,
    dynamic.field("error", dynamic.field("code", dynamic.int)),
    dynamic.field("error", dynamic.field("message", dynamic.string)),
    dynamic.field("error", dynamic.optional_field("data", dynamic.dynamic)),
  )
}

pub fn decode_api_response(success_decoder) {
  dynamic.any([
    dynamic.decode1(Ok, success_decoder),
    dynamic.decode1(Error, decode_api_error),
  ])
}

pub fn decode_meta() {
  dynamic.decode3(
    Meta,
    dynamic.field("total", dynamic.int),
    dynamic.field("page", dynamic.int),
    dynamic.field("limit", dynamic.int),
  )
}

pub fn decode_paged_response(field_decoder) {
  dynamic.decode2(
    PagedApiData,
    dynamic.field("data", field_decoder),
    dynamic.field("meta", decode_meta()),
  )
}

pub fn decode_data(field_decoder: dynamic.Decoder(a)) {
  dynamic.field("data", field_decoder)
}

pub fn extract_data(resp: PagedApiData(data)) -> data {
  resp.data
}

pub fn extract_meta(resp: PagedApiData(data)) -> Meta {
  resp.meta
}

pub fn force_body_response_data(resp: PagedApiResponse(data)) -> data {
  resp
  |> should.be_ok
  |> core.extract_body
  |> extract_data
}

pub fn expect_status(status: Int) {
  fn(resp: FalconResponse(anything)) {
    should.be_true(resp.status == status)
    resp
  }
}

pub fn expect_200_body(resp: PagedApiResponse(value)) -> value {
  resp
  |> should.be_ok
  |> expect_status(200)
  |> core.extract_body
  |> extract_data
}

pub fn expect_body(resp: PagedApiResponse(value)) -> value {
  resp
  |> should.be_ok
  // |> expect_status(200)
  |> core.extract_body
  |> extract_data
}

pub fn expect_body_result(resp: FalconResult(value)) -> value {
  resp
  |> should.be_ok
  // |> expect_status(200)
  |> core.extract_body
}
/// gets the body from a response, after making sure it's a 200
pub fn expect_200_body_result(resp: FalconResult(value)) -> value {
  resp
  |> should.be_ok
  |> expect_status(200)
  |> core.extract_body
}

pub fn expect_200_meta(resp: PagedApiResponse(value)) -> Meta {
  resp
  |> should.be_ok
  |> expect_status(200)
  |> core.extract_body
  |> extract_meta
}

pub fn optional_field_with_default(
  named field: String,
  of decoder: dynamic.Decoder(t),
  or default: t,
) -> dynamic.Decoder(t) {
  fn(d: dynamic.Dynamic) {
    d
    |> dynamic.optional_field(field, of: decoder)
    |> result.map(with: option.unwrap(_, default))
  }
}

pub fn string_format_decode_errors(errors: List(dynamic.DecodeError)) -> String {
  errors
  |> list.map(fn(e) {
    e
    |> string.inspect
  })
  |> string.join("\n")
}

pub fn debug_decoder(decoder) {
  fn(val) {
    pprint.debug(val)
    decoder(val)
  }
}

pub fn pprint_decoder(decoder) {
  fn(val) {
    pprint.debug(val)
    decoder(val)
  }
}

pub type ClientEx

pub fn create_request(path: String) -> request.Request(String) {
  // let assert Ok(token) = os.get_env("SPACETRADERS_TOKEN")
  let assert Ok(token) = env.get("SPACETRADERS_TOKEN")

  let body = ""

  let request =
    request.Request(
      method: http.Get,
      headers: [
        #("Authorization", "Bearer " <> token),
        #("Content-Type", "application/json"),
      ],
      body: body,
      scheme: http.Http,
      host: "api.spacetraders.io",
      port: option.Some(80),
      path: "/v2/" <> path,
      query: option.None,
    )

  request
}

pub fn create_my_agent_request() -> request.Request(String) {
  let path = "my/agent"
  create_request(path)
}

pub fn create_my_ships_request() -> request.Request(String) {
  let path = "my/ships"
  create_request(path)
}

pub type RateLimit {
  RateLimit(
    rate_limit_type: String,
    limit_burst: Int,
    limit_per_second: Int,
    remaining: Int,
    reset: String,
  )
}

pub fn parse_headers_for_rate_limit(
  headers: List(#(String, String)),
) -> Result(RateLimit, json.DecodeError) {
  headers
  |> list.map(fn(header) {
    let name = header.0
    let raw_value = header.1
    let is_float = float.parse(raw_value)
    let is_int = int.parse(raw_value)

    case is_float, is_int {
      Ok(f), _ -> #(name, f |> json.float)
      _, Ok(i) -> #(name, i |> json.int)
      _, _ -> #(name, raw_value |> json.string)
    }
  })
  |> json.object
  |> json.to_string
  |> fn(raw_json) {
    json.decode(
      from: raw_json,
      using: dynamic.decode5(
        RateLimit,
        dynamic.field("x-ratelimit-type", dynamic.string),
        dynamic.field("x-ratelimit-limit-burst", dynamic.int),
        dynamic.field("x-ratelimit-limit-per-second", dynamic.int),
        dynamic.field("x-ratelimit-remaining", dynamic.int),
        dynamic.field("x-ratelimit-reset", dynamic.string),
      ),
    )
  }
}

pub fn test_efetch(req: request.Request(String), decoder) {
  // let req = create_my_agent_request()
  // use result_response <- efetch.send(req)
  let result_response = efetch.send(req)

  result_response
  |> fn(r: Result(response.Response(String), efetch.HttpError)) {
    case r {
      Ok(response) -> {
        let _result_rate_limit =
          response.headers
          |> parse_headers_for_rate_limit

        response
        // |> pprint.debug
        |> fn(r: response.Response(String)) { r.body }
        |> json.decode(decoder)
        |> fn(decode_result) {
          decode_result
          |> pprint.styled
          |> io.println
          // case decode_result {
          //   Ok(Ok(data)) -> {
          //     data
          //     |> pprint.with_config(pprint.Config(
          //       pprint.Styled,
          //       pprint.BitArraysAsString,
          //       pprint.Labels,
          //     ))
          //   }
          //   Ok(Error(_)) -> {
          //     "Error decoding"
          //   }
          //   Error(err) -> {
          //     err
          //     |> pprint.format
          //   }
          // }
        }
        |> pprint.format
      }
      Error(err) -> {
        err
        |> pprint.format
      }
    }
  }
}
