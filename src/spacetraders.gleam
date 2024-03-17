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
import st_shipyard

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

const contract_id: String = "clthywl03m46cs60cl8ezck89f"

pub fn main() {
  dotenv.config()

  create_client()
  // |> st_agent.get_my_agent
  |> st_shipyard.view_available_ships("X1-KS19", "X1-KS19-C41")
  |> st_response.expect_200_body_result
  // ---
  // |> st_waypoint.get_waypoints_for_system("X1-KS19", [
  //   st_waypoint.Trait("SHIPYARD", "", ""),
  // ])
  // |> st_response.expect_200_body_result
  // |> st_waypoint.show_traits_for_waypoints
  // ------ ships and their modules
  // |> st_ship.get_my_ships
  // |> st_response.expect_200_body
  // |> fn(ships: List(st_ship.Ship)) {
  //   ships
  //   |> list.map(fn(ship: st_ship.Ship) {
  //     let module_names =
  //       list.map(ship.modules, fn(m: st_ship.Module) { m.name })
  //     let symbol = ship.symbol
  //     symbol <> string.join(module_names, ", ")
  //   })
  // }
  |> io.debug
  // |> io.println
}
