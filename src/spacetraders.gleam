import gleam/io
import dotenv
// import gleam_stdlib
import gleam/erlang/os
import gleam/string
import gleam/list
import gleam/int
import gleam/bool
import falcon.{type Client, type FalconError, type FalconResponse}
import falcon/core.{Json, Raw, Url}
import gleam/dynamic
import gleeunit/should
// spacetraders
import st_response.{type PagedResponse, extract_data}
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

const traits_flag_name = "traits"

fn traits_flag() -> flag.FlagBuilder(List(String)) {
  flag.string_list()
  |> flag.default([])
  |> flag.description("trait symbols")
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

  let assert Ok(raw_trait_names) =
    flag.get_strings(input.flags, traits_flag_name)
  let traits: List(st_waypoint.Trait) =
    raw_trait_names
    |> list.map(fn(trait_symbol) {
      st_waypoint.Trait(string.uppercase(trait_symbol), "", "")
    })

  create_client()
  // |> st_waypoint.get_waypoints_for_system("X1-KS19", [
  |> st_waypoint.get_waypoints_for_system(system_symbol, traits)
  // st_waypoint.Trait("SHIPYARD", "", ""),
  |> st_response.expect_200_body_result
  |> st_waypoint.show_traits_for_waypoints
}

fn view_shipyard(input: glint.CommandInput) -> String {
  io.println("viewing shipyard")
  let assert Ok(system_symbol) =
    flag.get_string(from: input.flags, for: system_flag_name)
  let assert Ok(waypoint_symbol) =
    flag.get_string(from: input.flags, for: waypoint_flag_name)
  io.println("system: " <> system_symbol <> " waypoint: " <> waypoint_symbol)
  let shipyard =
    create_client()
    |> st_shipyard.view_available_ships(system_symbol, waypoint_symbol)
    |> st_response.expect_200_body_result

  let types =
    shipyard.ship_types
    |> list.map(fn(x) { x.type_ })
    |> string.join(", ")

  let mod_fee =
    shipyard.modifications_fee
    |> int.to_string

  let ships =
    shipyard.ships
    |> list.map(fn(ship) { ship.frame.symbol })
  types <> "\nModification fee: " <> mod_fee <> "\n" <> string.join(ships, ", ")
}

fn view_my_ships(_input: glint.CommandInput) -> String {
  io.println("viewing my ships")

  let ship_formatter = fn(ship: st_ship.Ship) {
    let module_names = list.map(ship.modules, fn(m: st_ship.Module) { m.name })
    let symbol = ship.symbol
    symbol
    <> " - ("
    <> ship.frame.name
    <> ") Inv: "
    <> int.to_string(list.length(ship.cargo.inventory))
    <> " - "
    <> string.join(module_names, ", ")
  }
  create_client()
  |> st_ship.get_my_ships
  |> st_response.expect_200_body
  |> fn(ships: List(st_ship.Ship)) {
    ships
    |> list.map(ship_formatter)
    |> string.join("\n")
  }
}

pub fn main() {
  dotenv.config()

  let _ =
    glint.new()
    |> glint.with_name("spacetraders")
    |> glint.with_pretty_help(glint.default_pretty_help())
    |> glint.add(
      at: ["agent"],
      do: glint.command(view_agent)
        |> glint.description("view your agent"),
    )
    |> glint.add(
      at: ["my_ships"],
      do: glint.command(view_my_ships)
        |> glint.description("view my ships"),
    )
    |> glint.add(
      at: ["waypoints"],
      do: glint.command(view_waypoints)
        |> glint.flag(system_flag_name, system_flag())
        |> glint.flag(traits_flag_name, traits_flag())
        |> glint.description("view waypoints for a given system"),
    )
    |> glint.add(
      at: ["shipyard"],
      do: glint.command(view_shipyard)
        |> glint.flag(system_flag_name, system_flag())
        |> glint.flag(waypoint_flag_name, waypoint_flag())
        |> glint.description("view shipyard for a given waypoint"),
    )
    |> glint.run_and_handle(argv.load().arguments, with: fn(x: String) {
      io.println("the returned value is:\n" <> x)
    })
}
