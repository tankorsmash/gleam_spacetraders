import gleam/io
import dotenv
import gleam/erlang/os
import gleam/string
import gleam/list
import falcon.{type Client, type FalconError, type FalconResponse}
import falcon/core.{Json, Raw, Url}
import gleam/dynamic
import gleeunit/should
import st_response.{type Response}
import contract.{type Contract, decode_contract_response}

fn get_contracts(
  client,
) -> Result(FalconResponse(Response(List(Contract))), FalconError) {
  client
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
