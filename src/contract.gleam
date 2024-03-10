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
import st_agent

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

pub fn decode_contract() {
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

pub fn decode_meta() {
  dynamic.decode3(
    st_response.Meta,
    dynamic.field("total", dynamic.int),
    dynamic.field("page", dynamic.int),
    dynamic.field("limit", dynamic.int),
  )
}

pub fn decode_contract_response() {
  dynamic.decode2(
    st_response.ApiResponse,
    dynamic.field("data", dynamic.list(decode_contract())),
    dynamic.field("meta", decode_meta()),
  )
}

pub fn get_my_contracts(client) -> st_response.WebResponse(List(Contract)) {
  client
  |> falcon.get(
    "/my/contracts",
    expecting: Json(decode_contract_response()),
    options: [],
  )
}

pub type AcceptContract {
  AcceptContract(st_agent.Agent, Contract)
}

pub fn accept_contract(
  client: Client,
  contract_id: String,
) -> st_response.WebResult(AcceptContract) {
  let decoder =
    st_response.decode_data(dynamic.decode2(
      AcceptContract,
      st_agent.decode_agent(),
      decode_contract(),
    ))

  client
  |> falcon.post(
    "/my/contracts/" <> contract_id <> "/accept",
    expecting: Json(decoder),
    options: [],
    body: "",
  )
}
