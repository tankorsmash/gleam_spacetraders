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
