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
import st_response.{type ApiResponse, extract_data}
import contract.{type Contract, decode_contract_response}
import st_waypoint
import st_agent
import st_ship

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

const contract_id: String = "clthywl03m46cs60cl8ezck89f"

pub fn main() {
  dotenv.config()
  let client =
    create_client()
    |> st_waypoint.get_waypoints_for_system("X1-KS19", [])
    |> io.debug
}
