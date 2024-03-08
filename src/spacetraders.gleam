import gleam/io
import dotenv
import gleam/erlang/os
import gleam/string
import gleam/list
import falcon.{type Client, type FalconError, type FalconResponse}
import falcon/core.{Json, Raw, Url}
import gleam/dynamic
import gleeunit/should

// {
//   "data": [
//     {
//       "id": "clthywl03m46cs60cl8ezck89",
//       "factionSymbol": "COSMIC",
//       "type": "PROCUREMENT",
//       "terms": {
//         "deadline": "2024-03-15T01:18:05.870Z",
//         "payment": {
//           "onAccepted": 1107,
//           "onFulfilled": 7848
//         },
//         "deliver": [
//           {
//             "tradeSymbol": "COPPER_ORE",
//             "destinationSymbol": "X1-NB8-H50",
//             "unitsRequired": 43,
//             "unitsFulfilled": 0
//           }
//         ]
//       },
//       "accepted": false,
//       "fulfilled": false,
//       "expiration": "2024-03-09T01:18:05.870Z",
//       "deadlineToAccept": "2024-03-09T01:18:05.870Z"
//     }
//   ],
//   "meta": {
//     "total": 1,
//     "page": 1,
//     "limit": 10
//   }
// }

pub type Deliver {
  Deliver(
    trade_symbol: String,
    destination_symbol: String,
    units_required: Int,
    units_fulfilled: Int,
  )
}

pub type Payment {
  Payment(on_accepted: Int, on_fulfilled: Int)
}

pub type Terms {
  Terms(deadline: String, payment: Payment, deliver: List(Deliver))
}

pub type Contract {
  Contract(
    id: String,
    faction_symbol: String,
    type_: String,
    terms: Terms,
    accepted: Bool,
    fulfilled: Bool,
    expiration: String,
    deadline_to_accept: String,
  )
}

pub type Meta {
  Meta(total: Int, page: Int, limit: Int)
}

pub type Response(data) {
  Response(data: data, meta: Meta)
}

fn decode_contract() {
  dynamic.decode8(
    Contract,
    dynamic.field("id", dynamic.string),
    dynamic.field("factionSymbol", dynamic.string),
    dynamic.field("type", dynamic.string),
    dynamic.field(
      "terms",
      dynamic.decode3(
        Terms,
        dynamic.field("deadline", dynamic.string),
        dynamic.field(
          "payment",
          dynamic.decode2(
            Payment,
            dynamic.field("onAccepted", dynamic.int),
            dynamic.field("onFulfilled", dynamic.int),
          ),
        ),
        dynamic.field(
          "deliver",
          dynamic.list(dynamic.decode4(
            Deliver,
            dynamic.field("tradeSymbol", dynamic.string),
            dynamic.field("destinationSymbol", dynamic.string),
            dynamic.field("unitsRequired", dynamic.int),
            dynamic.field("unitsFulfilled", dynamic.int),
          )),
        ),
      ),
    ),
    dynamic.field("accepted", dynamic.bool),
    dynamic.field("fulfilled", dynamic.bool),
    dynamic.field("expiration", dynamic.string),
    dynamic.field("deadlineToAccept", dynamic.string),
  )
}

fn decode_meta() {
  dynamic.decode3(
    Meta,
    dynamic.field("total", dynamic.int),
    dynamic.field("page", dynamic.int),
    dynamic.field("limit", dynamic.int),
  )
}

fn decode_contract_response() {
  dynamic.decode2(
    Response,
    dynamic.field("data", dynamic.list(decode_contract())),
    dynamic.field("meta", decode_meta()),
  )
}

fn get_contracts(
  client,
) -> Result(FalconResponse(Response(List(Contract))), FalconError) {
  client
  // |> falcon.get("/my/contracts", expecting: Raw(fn(a) { Ok(a) }), options: [])
  |> falcon.get(
    "/my/contracts",
    expecting: Json(decode_contract_response()),
    options: [],
  )
  |> io.debug
}

fn create_client() -> Client {
  let assert Ok(token) = os.get_env("SPACETRADERS_TOKEN")
  let client =
    falcon.new(
      base_url: Url("https://api.spacetraders.io/v2/"),
      headers: [#("Authorization", "Bearer " <> token)],
      timeout: falcon.default_timeout,
    )
  client
}

pub fn main() {
  dotenv.config()

  let client = create_client()
  let assert Ok(contract_resp) = get_contracts(client)
  let contracts: List(Contract) = contract_resp.body.data
  io.println(
    "Hello from spacetraders!: "
    <> string.join(list.map(contracts, fn(c) { c.type_ }), "-"),
  )
}
