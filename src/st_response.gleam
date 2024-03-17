import gleam/io
import dotenv
import gleam/erlang/os
import gleam/string
import gleam/result
import gleam/option
import gleam/list
import falcon.{type Client, type FalconError, type FalconResponse}
import falcon/core.{Json, Raw, Url}
import gleam/dynamic
import gleeunit/should

pub type Meta {
  Meta(total: Int, page: Int, limit: Int)
}

pub type ApiResponse(data) {
  ApiResponse(data: data, meta: Meta)
}

pub type WebResult(data) =
  Result(FalconResponse(data), FalconError)

pub type WebResponse(data) =
  Result(FalconResponse(ApiResponse(data)), FalconError)

pub fn decode_meta() {
  dynamic.decode3(
    Meta,
    dynamic.field("total", dynamic.int),
    dynamic.field("page", dynamic.int),
    dynamic.field("limit", dynamic.int),
  )
}

pub fn decode_response(field_decoder) {
  dynamic.decode2(
    ApiResponse,
    dynamic.field("data", field_decoder),
    dynamic.field("meta", decode_meta()),
  )
}

pub fn decode_data(field_decoder) {
  dynamic.field("data", field_decoder)
}

pub fn extract_data(resp: ApiResponse(data)) -> data {
  resp.data
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

pub fn expect_200_body_result(resp: WebResult(value)) -> value {
  resp
  |> should.be_ok
  |> expect_status(200)
  |> core.extract_body
}

pub fn optional_field_with_default(
  named field: String,
  of decoder: dynamic.Decoder(t),
  or default: t,
) -> dynamic.Decoder(t) {
  let optional_field_fun = dynamic.optional_field(field, of: decoder)
  fn(d: dynamic.Dynamic) {
    optional_field_fun(d)
    |> result.map(with: fn(x) { option.unwrap(x, default) })
  }
}
