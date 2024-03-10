import gleam/io
import dotenv
import gleam/erlang/os
import gleam/string
import gleam/list
import falcon.{type Client, type FalconError, type FalconResponse}
import falcon/core.{Json, Raw, Url}
import gleam/dynamic
import gleeunit/should
import st_response

// {
//   "accountId": "string",
//   "symbol": "string",
//   "headquarters": "string",
//   "credits": 0,
//   "startingFaction": "string",
//   "shipCount": 0
// }

pub type Agent {
  Agent(
    account_id: String,
    symbol: String,
    headquarters: String,
    credits: Int,
    starting_faction: String,
    ship_count: Int,
  )
}

pub fn decode_agent() {
  dynamic.decode6(
    Agent,
    dynamic.field("accountId", dynamic.string),
    dynamic.field("symbol", dynamic.string),
    dynamic.field("headquarters", dynamic.string),
    dynamic.field("credits", dynamic.int),
    dynamic.field("startingFaction", dynamic.string),
    dynamic.field("shipCount", dynamic.int),
  )
}

pub fn get_my_agent(client) {
  client
  |> falcon.get("/my/agent", Json(st_response.decode_data(decode_agent())), [])
  |> should.be_ok
  |> core.extract_body
  // |> st_response.extract_data
}
