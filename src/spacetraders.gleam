import gleam/io
import dotenv
// import gleam_stdlib
import gleam/erlang/os
import gleam/string
import gleam/list
import gleam/option
import gleam/result
import gleam/int
import gleam/json
import gleam/dynamic
import falcon.{type Client}
import falcon/core.{Url}
// spacetraders
import st_response
import st_waypoint
import st_agent
import st_ship
import st_shipyard
import st_market
// glint arg parse
import argv
import glint
import glint/flag
import glint/flag/constraint
import birl
import birl/duration

pub fn create_client() -> Client {
  let assert Ok(token) = os.get_env("SPACETRADERS_TOKEN")
  let client =
    falcon.new(
      base_url: Url("https://api.spacetraders.io/v2/"),
      headers: [
        #("Authorization", "Bearer " <> token),
        #("Content-Type", "application/json"),
      ],
      timeout: falcon.default_timeout,
    )
  client
}

// const contract_id: String = "clthywl03m46cs60cl8ezck89f"

const system_flag_name = "system"

fn system_flag() -> flag.FlagBuilder(String) {
  flag.string()
  |> flag.default("X1-KS19")
  |> flag.description("system symbol")
}

const ship_symbol_name = "ship"

fn ship_symbol_flag() -> flag.FlagBuilder(String) {
  flag.string()
  |> flag.default("TANKOR_SMASH-1")
  |> flag.description("ship symbol")
}

const ship_type_name = "ship_type"

fn ship_type_flag() -> flag.FlagBuilder(String) {
  flag.string()
  // |> flag.default("TANKOR_SMASH-1")
  |> flag.description("ship type, ie SHIP_MINING_DRONE")
  |> flag.constraint(constraint.one_of(st_ship.all_raw_ship_types))
}

const waypoint_flag_name = "waypoint"

fn waypoint_flag() -> flag.FlagBuilder(String) {
  flag.string()
  |> flag.default("X1-KS19-C41")
  |> flag.description("waypoint symbol")
}

const waypoint_type_flag_name = "waypoint_type"

fn waypoint_type_flag() -> flag.FlagBuilder(String) {
  flag.string()
  |> flag.description("waypoint type")
  |> flag.constraint(constraint.one_of(st_waypoint.all_raw_waypoint_types))
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
  let raw_waypoint_type = flag.get_string(input.flags, waypoint_type_flag_name)

  let waypoint_type: option.Option(st_waypoint.WaypointType) = case
    raw_waypoint_type
  {
    Ok(raw_waypoint_type) -> {
      dynamic.from(raw_waypoint_type)
      |> st_response.debug_decoder(st_waypoint.decode_waypoint_type()(_))
      |> option.from_result()
    }
    Error(_) -> option.None
  }

  let resp =
    create_client()
    |> st_waypoint.get_waypoints_for_system(
      system_symbol,
      waypoint_type: waypoint_type,
      traits: traits,
    )
    |> st_response.expect_body_result
  case resp {
    Ok(waypoints) -> {
      st_waypoint.show_traits_for_waypoints(waypoints)
    }
    Error(api_error) -> {
      api_error.message <> "\n" <> string.inspect(api_error.data)
    }
  }
}

fn view_shipyard(input: glint.CommandInput) -> String {
  io.println("viewing shipyard")
  let assert Ok(system_symbol) =
    flag.get_string(from: input.flags, for: system_flag_name)
  let assert Ok(waypoint_symbol) =
    flag.get_string(from: input.flags, for: waypoint_flag_name)
  io.println("system: " <> system_symbol <> " waypoint: " <> waypoint_symbol)

  let resp =
    create_client()
    |> st_shipyard.view_available_ships(system_symbol, waypoint_symbol)

  let _ = case resp {
    Ok(_) -> {
      Nil
    }
    Error(core.JsonDecodingError(json.UnexpectedFormat(errors))) -> {
      st_response.string_format_decode_errors(errors)
      |> io.println
    }
    Error(unknown_error) -> {
      io.debug(unknown_error)

      Nil
    }
  }

  let shipyard =
    resp
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
    |> list.map(fn(ship) {
      "- Type: "
      <> ship.type_
      <> " Symbol: "
      <> ship.frame.symbol
      <> case list.length(ship.modules) {
        0 -> {
          ""
        }
        _ ->
          "\n  Mods: "
          <> string.join(
            list.map(ship.modules, fn(module) { module.symbol }),
            ", ",
          )
      }
    })
  types <> "\nModification fee: " <> mod_fee <> "\n" <> string.join(ships, "\n")
}

fn view_market(input: glint.CommandInput) -> String {
  io.println("viewing market")
  let assert Ok(system_symbol) =
    flag.get_string(from: input.flags, for: system_flag_name)
  let assert Ok(waypoint_symbol) =
    flag.get_string(from: input.flags, for: waypoint_flag_name)
  io.println("system: " <> system_symbol <> " waypoint: " <> waypoint_symbol)

  let resp =
    create_client()
    |> st_market.view_market(system_symbol, waypoint_symbol)

  let _ = case resp {
    Ok(_) -> {
      Nil
    }
    Error(core.JsonDecodingError(json.UnexpectedFormat(errors))) -> {
      st_response.string_format_decode_errors(errors)
      |> io.println
    }
    Error(unknown_error) -> {
      io.debug(unknown_error)

      Nil
    }
  }

  let market =
    resp
    |> st_response.expect_200_body_result

  let exports = market.exports
  let imports = market.imports
  let exchange = market.exchange
  let _transactions = market.transactions
  let trade_goods = market.trade_goods

  let export_string =
    exports
    |> list.map(fn(export: st_market.MarketExport) {
      export.symbol <> " " <> export.name
    })
    |> string.join(", ")

  let import_string =
    imports
    |> list.map(fn(import_: st_market.MarketImport) {
      import_.symbol <> " " <> import_.name
    })
    |> string.join(", ")

  let exchange_string =
    exchange
    |> list.map(fn(exchange: st_market.MarketExchange) {
      exchange.symbol <> " " <> exchange.name
    })
    |> string.join(", ")
  let trade_goods_string =
    trade_goods
    |> list.map(fn(trade_good: st_market.MarketTradeGood) {
      "  - "
      <> trade_good.symbol
      <> " ["
      <> trade_good.type_
      <> "] vol:"
      <> int.to_string(trade_good.trade_volume)
      <> ", "
      <> trade_good.supply
      <> " supply,"
      <> " +"
      <> int.to_string(trade_good.purchase_price)
      <> "/-"
      <> int.to_string(trade_good.sell_price)
    })
    |> string.join("\n")

  "Imports:\n "
  <> import_string
  <> "\nExports:\n "
  <> export_string
  <> "\nExchange:\n "
  <> exchange_string
  <> "\nTrade Goods $(buying/selling price):\n"
  <> trade_goods_string
}

fn view_my_ships(_input: glint.CommandInput) -> String {
  io.println("viewing my ships")

  let ship_formatter = fn(ship: st_ship.Ship) {
    let module_names = list.map(ship.modules, fn(m: st_ship.Module) { m.name })
    let fuel_string =
      "Fuel: "
      <> int.to_string(ship.fuel.current)
      <> "/"
      <> int.to_string(ship.fuel.capacity)
      <> " (Consumed: "
      <> int.to_string(ship.fuel.consumed.amount)
      <> ")"
    let symbol = ship.symbol
    symbol
    <> " ("
    <> ship.frame.name
    <> ")"
    <> " -- @"
    <> ship.nav.waypoint_symbol
    <> ", "
    <> ship.nav.status
    <> " -- "
    <> fuel_string
    <> "\n Inv: "
    <> int.to_string(list.length(ship.cargo.inventory))
    <> "\n Mods: "
    <> string.join(module_names, ", ")
    <> case ship.nav.status {
      "DOCKED" | "IN_ORBIT" -> ""
      _ -> "\n Nav: " <> pretty_nav(ship.nav)
    }
    <> "\n"
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

fn pretty_nav(nav: st_ship.Nav) -> String {
  let route = nav.route
  let destination = route.destination
  let origin = route.origin

  let flight_mode = nav.flight_mode
  let status = nav.status

  let now = birl.now()
  let assert Ok(arrival) = birl.parse(route.arrival)
  case status {
    "IN_ORBIT" | "DOCKED" -> "Status: " <> status <> " - " <> flight_mode
    _ -> {
      let qwe =
        birl.difference(arrival, now)
        |> duration.decompose
        |> string.inspect
      "Status: "
      <> status
      <> " - "
      <> flight_mode
      <> " - D:"
      <> destination.symbol
      <> " O:"
      <> origin.symbol
      <> "\nETA: "
      <> route.arrival
      <> "in "
      <> qwe
    }
  }
}

pub fn set_ship_to_orbit(input: glint.CommandInput) -> String {
  io.println("setting ship to orbit")
  let assert Ok(ship_symbol) =
    flag.get_string(from: input.flags, for: ship_symbol_name)
  io.println("ship: " <> ship_symbol)
  let nav =
    create_client()
    |> st_ship.set_ship_to_orbit(ship_symbol)
    |> st_response.expect_200_body_result
  pretty_nav(nav)
  // nav
  // |> string.inspect
}

pub fn refuel_ship(input: glint.CommandInput) -> String {
  io.println("refuelling...")
  let assert Ok(ship_symbol) =
    flag.get_string(from: input.flags, for: ship_symbol_name)

  io.println("refuelling ship: " <> ship_symbol)

  let resp =
    create_client()
    |> st_ship.refuel_ship(ship_symbol)

  // let assert Ok(refuel_response) = resp

  case resp {
    Ok(refuel_response) -> {
      case refuel_response.body {
        // |> st_response.expect_200_body_result,
        st_ship.RefuelSuccess(_agent, _fuel, _transaction) ->
          "Refuelled, probably. Agent and fuel and transcation TODO"
        st_ship.RefuelFailure(message) -> {
          "Failure: " <> message
        }
      }
    }
    Error(error) -> {
      io.debug(error)
      "unknown error"
    }
  }
}

pub fn purchase_ship(input: glint.CommandInput) -> String {
  io.println("purchasingg...")
  let assert Ok(raw_ship_type) =
    flag.get_string(from: input.flags, for: ship_type_name)

  let assert Ok(ship_type) =
    st_ship.decode_ship_type()(dynamic.from(raw_ship_type))

  let assert Ok(waypoint_symbol) =
    flag.get_string(from: input.flags, for: waypoint_flag_name)

  io.println("purchasing ship type: " <> string.inspect(ship_type))

  let resp =
    create_client()
    |> st_ship.purchase_ship(waypoint_symbol, ship_type)

  // let assert Ok(purchase_response) = resp

  case resp {
    Ok(purchase_response) -> {
      let _response = io.debug(purchase_response)
      ""
    }
    Error(error) -> {
      io.debug(error)
      "unknown error"
    }
  }
}

pub fn set_ship_to_navigate(input: glint.CommandInput) -> String {
  io.println("setting ship to orbit")
  let assert Ok(ship_symbol) =
    flag.get_string(from: input.flags, for: ship_symbol_name)

  let assert Ok(waypoint_symbol) =
    flag.get_string(from: input.flags, for: waypoint_flag_name)
  io.println(
    "navigating ship: " <> ship_symbol <> " to waypoint: " <> waypoint_symbol,
  )

  let resp =
    create_client()
    |> st_ship.navigate_ship_to_waypoint(ship_symbol, waypoint_symbol)

  case
    resp
    |> st_response.expect_body_result
  {
    st_ship.NavigateSuccess(nav, fuel, events) -> {
      let nav_string = pretty_nav(nav)
      let fuel_string =
        "Fuel: "
        <> int.to_string(fuel.current)
        <> "/"
        <> int.to_string(fuel.capacity)

      let event_string =
        events
        |> list.map(fn(event) { event.name <> " " <> event.description })
        |> string.join(", ")
      nav_string <> " " <> fuel_string <> " Events: " <> event_string
    }
    st_ship.NavigateFailure(error) -> {
      "Navigation failed: " <> error.message
    }
  }
}

pub fn set_ship_to_dock(input: glint.CommandInput) -> String {
  io.println("setting ship to dock")
  let assert Ok(ship_symbol) =
    flag.get_string(from: input.flags, for: ship_symbol_name)
  io.println("ship: " <> ship_symbol)
  let nav =
    create_client()
    |> st_ship.set_ship_to_dock(ship_symbol)
    |> st_response.expect_200_body_result

  pretty_nav(nav)
  // nav
  // |> string.inspect
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
      at: ["orbit_ship"],
      do: glint.command(set_ship_to_orbit)
        |> glint.flag(ship_symbol_name, ship_symbol_flag())
        |> glint.description("set ship to orbit"),
    )
    |> glint.add(
      at: ["navigate_ship"],
      do: glint.command(set_ship_to_navigate)
        |> glint.flag(ship_symbol_name, ship_symbol_flag())
        |> glint.flag(waypoint_flag_name, waypoint_flag())
        |> glint.description("navigate ship to waypoint"),
    )
    |> glint.add(
      at: ["dock_ship"],
      do: glint.command(set_ship_to_dock)
        |> glint.flag(ship_symbol_name, ship_symbol_flag())
        |> glint.description("set ship to dock"),
    )
    |> glint.add(
      at: ["refuel_ship"],
      do: glint.command(refuel_ship)
        |> glint.flag(ship_symbol_name, ship_symbol_flag())
        |> glint.description("refuel docked ship"),
    )
    |> glint.add(
      at: ["purchase_ship"],
      do: glint.command(purchase_ship)
        |> glint.flag(waypoint_flag_name, waypoint_flag())
        |> glint.flag(ship_type_name, ship_type_flag())
        |> glint.description("purchase ship"),
    )
    |> glint.add(
      at: ["waypoints"],
      do: glint.command(view_waypoints)
        |> glint.flag(system_flag_name, system_flag())
        |> glint.flag(traits_flag_name, traits_flag())
        |> glint.flag(waypoint_type_flag_name, waypoint_type_flag())
        |> glint.description("view waypoints for a given system"),
    )
    |> glint.add(
      at: ["shipyard"],
      do: glint.command(view_shipyard)
        |> glint.flag(system_flag_name, system_flag())
        |> glint.flag(waypoint_flag_name, waypoint_flag())
        |> glint.description("view shipyard for a given waypoint"),
    )
    |> glint.add(
      at: ["market"],
      do: glint.command(view_market)
        |> glint.flag(system_flag_name, system_flag())
        |> glint.flag(waypoint_flag_name, waypoint_flag())
        |> glint.description("view market for a given waypoint"),
    )
    |> glint.run_and_handle(argv.load().arguments, with: fn(x: String) {
      io.println("the returned value is:\n" <> x)
    })
}
