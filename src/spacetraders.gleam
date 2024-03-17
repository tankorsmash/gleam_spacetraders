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
// spacetraders
import st_response.{type ApiResponse, extract_data}
import contract.{type Contract, decode_contract_response}
import st_waypoint
import st_agent
import st_ship
import st_shipyard
// glint arg parse
import argv
import glint
import glint/flag

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

const view_name = "view"

fn view_flag() -> flag.FlagBuilder(String) {
  flag.string()
  |> flag.default("asdddd")
  |> flag.description("this is a desd")
}

fn view_agent() {
  create_client()
  |> st_agent.get_my_agent
  |> st_response.expect_200_body_result
  |> string.inspect
}

fn view_waypoints(system_symbol: String) {
  create_client()
  // |> st_waypoint.get_waypoints_for_system("X1-KS19", [
  |> st_waypoint.get_waypoints_for_system(system_symbol, [])
  // st_waypoint.Trait("SHIPYARD", "", ""),
  |> st_response.expect_200_body_result
  |> st_waypoint.show_traits_for_waypoints
}

pub fn inner_main(input: glint.CommandInput) {
  let assert Ok(view_val) = flag.get_string(from: input.flags, for: view_name)

  io.debug(view_val)
  let view_func =
    case view_val {
      "agent" -> view_agent()
      "waypoint" -> view_waypoints("X1-KS19")
      _ -> view_agent()
    }
    |> io.println
}

pub fn main() {
  dotenv.config()

  glint.new()
  |> glint.with_name("spacetraders")
  |> glint.with_pretty_help(glint.default_pretty_help())
  |> glint.add(
    at: [],
    do: glint.command(inner_main)
      |> glint.flag(view_name, view_flag())
      |> glint.description("this is the name i thin"),
  )
  |> glint.run(argv.load().arguments)
  // io.debug(argv.load().arguments)

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
