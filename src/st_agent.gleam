import falcon.{type Client}
import falcon/core.{Json}
import gleam/dynamic
import gleam/json
import gleam/option
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

pub fn decode_agent(dynamic: dynamic.Dynamic) {
  dynamic.decode6(
    Agent,
    dynamic.field("accountId", dynamic.string),
    dynamic.field("symbol", dynamic.string),
    dynamic.field("headquarters", dynamic.string),
    dynamic.field("credits", dynamic.int),
    dynamic.field("startingFaction", dynamic.string),
    dynamic.field("shipCount", dynamic.int),
  )(dynamic)
}

pub fn get_my_agent(client) {
  client
  |> falcon.get("/my/agent", Json(st_response.decode_data(decode_agent)), [])
}

pub fn register_agent(
  client: Client,
  agent_symbol: String,
  faction_symbol: String,
  email: option.Option(String),
) {
  let body =
    json.object([
      #("symbol", json.string(agent_symbol)),
      #("faction", json.string(faction_symbol)),
      #("email", email |> option.map(json.string) |> option.unwrap(json.null())),
    ])

  client
  |> falcon.post(
    "register",
    json.to_string(body),
    // Json(st_response.decode_api_response(decode_agent())), // can't use decode_agent because id lose the api token
    Json(st_response.decode_api_response(dynamic.dynamic)),
    [],
  )
}
