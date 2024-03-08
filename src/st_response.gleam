import gleam/io
import dotenv
import gleam/erlang/os
import gleam/string
import gleam/list
import falcon.{type Client, type FalconError, type FalconResponse}
import falcon/core.{Json, Raw, Url}
import gleam/dynamic
import gleeunit/should

pub type Meta {
  Meta(total: Int, page: Int, limit: Int)
}

pub type Response(data) {
  Response(data: data, meta: Meta)
}

pub type WebResult(data) =
  Result(FalconResponse(data), FalconError)

pub type WebResponse(data) =
  Result(FalconResponse(Response(data)), FalconError)

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
    Response,
    dynamic.field("data", field_decoder),
    dynamic.field("meta", decode_meta()),
  )
}

pub fn decode_data(field_decoder) {
    dynamic.field("data", field_decoder)
}