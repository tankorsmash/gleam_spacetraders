import dotenv
import falcon.{type Client, type FalconError, type FalconResponse}
import falcon/core.{Json, Raw, Url}
import gleam/dynamic
import gleam/erlang/os
import gleam/io
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleeunit/should

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

pub fn decode_api_error() {
  dynamic.decode3(
    ApiError,
    dynamic.field("error", dynamic.field("code", dynamic.int)),
    dynamic.field("error", dynamic.field("message", dynamic.string)),
    dynamic.field("error", dynamic.optional_field("data", dynamic.dynamic)),
  )
}

pub fn decode_api_response(success_decoder) {
  dynamic.any([
    dynamic.decode1(Ok, success_decoder),
    dynamic.decode1(Error, decode_api_error()),
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

pub fn decode_data(field_decoder) {
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
    io.debug(val)
    decoder(val)
  }
}
