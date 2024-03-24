import gleam/io
import dotenv
import gleam/erlang/os
import gleam/string
import gleam/result
import gleam/option
import gleam/json
import gleam/list
import falcon.{type Client, type FalconError, type FalconResponse}
import falcon/core.{Json, Raw, Url}
import gleam/dynamic
import gleeunit/should

pub type Meta {
  Meta(total: Int, page: Int, limit: Int)
}

pub type PagedResponse(data) {
  PagedResponse(data: data, meta: Meta)
}

pub type FalconResult(data) =
  Result(FalconResponse(data), FalconError)

pub type WebResponse(data) =
  Result(FalconResponse(PagedResponse(data)), FalconError)

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
    PagedResponse,
    dynamic.field("data", field_decoder),
    dynamic.field("meta", decode_meta()),
  )
}

pub fn decode_data(field_decoder) {
  dynamic.field("data", field_decoder)
}

pub fn extract_data(resp: PagedResponse(data)) -> data {
  resp.data
}

pub fn extract_meta(resp: PagedResponse(data)) -> Meta {
  resp.meta
}

pub fn force_body_response_data(resp: WebResponse(data)) -> data {
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

pub fn expect_200_body(resp: WebResponse(value)) -> value {
  resp
  |> should.be_ok
  |> expect_status(200)
  |> core.extract_body
  |> extract_data
}

pub fn expect_200_body_result(resp: FalconResult(value)) -> value {
  resp
  |> should.be_ok
  |> expect_status(200)
  |> core.extract_body
}

pub fn expect_200_meta(resp: WebResponse(value)) -> Meta {
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
