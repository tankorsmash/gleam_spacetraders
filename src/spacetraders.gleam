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
  |> flag.default("main")
  |> flag.description("this is a desd")
}

const system_flag_name = "system"

fn system_flag() -> flag.FlagBuilder(String) {
  flag.string()
  |> flag.default("X1-KS19")
  |> flag.description("system symbol")
}

const waypoint_flag_name = "waypoint"

fn waypoint_flag() -> flag.FlagBuilder(String) {
  flag.string()
  |> flag.default("X1-KS19-C41")
  |> flag.description("waypoint symbol")
}

fn view_agent(_input: glint.CommandInput) -> String {
  io.println("viewing agent")
  create_client()
  |> st_agent.get_my_agent
  |> st_response.expect_200_body_result
  |> string.inspect
}

fn view_waypoints(input: glint.CommandInput) -> String {
  io.println("viewing waypints")
  let assert Ok(system_symbol) =
    flag.get_string(from: input.flags, for: system_flag_name)
  create_client()
  // |> st_waypoint.get_waypoints_for_system("X1-KS19", [
  |> st_waypoint.get_waypoints_for_system(system_symbol, [])
  // st_waypoint.Trait("SHIPYARD", "", ""),
  |> st_response.expect_200_body_result
  |> st_waypoint.show_traits_for_waypoints
}

pub fn main() {
  dotenv.config()

  let returned_value =
    glint.new()
    |> glint.with_name("spacetraders")
    |> glint.with_pretty_help(glint.default_pretty_help())
    |> glint.add(
      at: ["agent"],
      do: glint.command(view_agent)
        |> glint.description("view your agent"),
    )
    |> glint.add(
      at: ["waypoints"],
      do: glint.command(view_waypoints)
        |> glint.flag(system_flag_name, system_flag())
        // |> glint.flag(waypoint_flag_name, waypoint_flag())
        |> glint.description("view waypoints for a given system"),
    )
    |> glint.run_and_handle(argv.load().arguments, with: fn(x: String) {
      io.println("the returned value is:\n" <> x)
    })
  // io.debug(argv.load().arguments)

  // create_client()
  // // |> st_agent.get_my_agent
  // |> st_shipyard.view_available_ships("X1-KS19", "X1-KS19-C41")
  // |> st_response.expect_200_body_result
  // // ---
  // // |> st_waypoint.get_waypoints_for_system("X1-KS19", [
  // //   st_waypoint.Trait("SHIPYARD", "", ""),
  // // ])
  // // |> st_response.expect_200_body_result
  // // |> st_waypoint.show_traits_for_waypoints
  // // ------ ships and their modules
  // // |> st_ship.get_my_ships
  // // |> st_response.expect_200_body
  // // |> fn(ships: List(st_ship.Ship)) {
  // //   ships
  // //   |> list.map(fn(ship: st_ship.Ship) {
  // //     let module_names =
  // //       list.map(ship.modules, fn(m: st_ship.Module) { m.name })
  // //     let symbol = ship.symbol
  // //     symbol <> string.join(module_names, ", ")
  // //   })
  // // }
  // |> io.debug
  // // |> io.println
}
