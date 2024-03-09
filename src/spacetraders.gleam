import gleam/io
import dotenv
// import gleam_stdlib
import gleam/erlang/os
import gleam/string
import gleam/list
import gleam/bool
import falcon.{type Client, type FalconError, type FalconResponse}
import falcon/core.{Json, Raw, Url}
import gleam/dynamic
import gleeunit/should
import st_response.{type ApiResponse}
import contract.{type Contract, decode_contract_response}
import st_waypoint

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

// // @external(erlang, "./openai/space_traders_api/api/agents.ex", "get_agent")
// @external(erlang, "Elixir.SpaceTradersAPI.Api.Agents", "get_agent")
// pub fn get_agent(a: String, b: String) -> Result(String, String)

// @external(erlang, "Elixir.SpaceTradersAPI.Connection", "new")
// pub fn new_elixir_client() -> String

pub fn expect_status(status: Int) {
  fn(resp: FalconResponse(anything)) {
    should.be_true(resp.status == status)
    resp
  }
}

fn extract_data(resp: ApiResponse(data)) -> data {
  resp.data
}

pub fn expect_200_body(resp: st_response.WebResult(value)) -> value {
  resp
  |> should.be_ok
  |> expect_status(200)
  |> core.extract_body
}

const contract_id: String = "clthywl03m46cs60cl8ezck89"

pub fn main() {
  dotenv.config()
  let client = create_client()
  client
  // |> contract.get_my_contracts
  // |> expect_200_body
  // |> extract_data
  // |> list.map(with: fn(contract: Contract) {
  //   io.debug(
  //     "Has contract been accepted ?: " <> bool.to_string(contract.accepted),
  //   )
  //   contract
  // })
  // |> io.debug
  // ----
  // |> contract.accept_contract(contract_id)
  // |> expect_200_body
  // |> io.debug

  |> st_waypoint.get_waypoints_for_system("X1-NB8", [
    // st_waypoint.Trait("MARKETPLACE", "", ""),
    st_waypoint.Trait("CORRUPT", "", ""),
  ])
  |> io.debug
}
