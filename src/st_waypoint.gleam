import gleam/io
import dotenv
import gleam/erlang/os
import gleam/string
import gleam/option.{type Option}
import gleam/result
import gleam/list
import falcon.{type Client, type FalconError, type FalconResponse}
import falcon/core.{Json, Raw, Url}
import gleam/dynamic
import gleeunit/should
import st_response

// {
// 	"symbol": "string",
// 	"type": "PLANET",
// 	"systemSymbol": "string",
// 	"x": 0,
// 	"y": 0,
// 	"orbitals": [
// 		{
// 			"symbol": "string"
// 		}
// 	],
// 	"orbits": "string",
// 	"faction": {
// 		"symbol": "COSMIC"
// 	},
// 	"traits": [
// 		{
// 			"symbol": "UNCHARTED",
// 			"name": "string",
// 			"description": "string"
// 		}
// 	],
// 	"modifiers": [
// 		{
// 			"symbol": "STRIPPED",
// 			"name": "string",
// 			"description": "string"
// 		}
// 	],
// 	"chart": {
// 		"waypointSymbol": "string",
// 		"submittedBy": "string",
// 		"submittedOn": "2019-08-24T14:15:22Z"
// 	},
// 	"isUnderConstruction": true
// }

pub type Waypoint {
  Waypoint(
    symbol: String,
    type_: String,
    system_symbol: String,
    x: Int,
    y: Int,
    orbitals: List(Orbital),
    orbits: Option(String),
    faction: Faction,
    traits: List(Trait),
    modifiers: List(Modifier),
    chart: Chart,
    is_under_construction: Bool,
  )
}

pub type Orbital {
  Orbital(symbol: String)
}

pub type Faction {
  Faction(symbol: String)
}

pub type Trait {
  Trait(symbol: String, name: String, description: String)
}

pub type Modifier {
  Modifier(symbol: String, name: String, description: String)
}

pub type Chart {
  Chart(
    waypoint_symbol: Option(String),
    submitted_by: String,
    submitted_on: String,
  )
}

pub fn decode_waypoint() {
  fn(value) {
    let sym = dynamic.field("symbol", dynamic.string)
    let type_ = dynamic.field("type", dynamic.string)
    let syssym = dynamic.field("systemSymbol", dynamic.string)
    let x = dynamic.field("x", dynamic.int)
    let y = dynamic.field("y", dynamic.int)
    let orbs = dynamic.field("orbitals", dynamic.list(decode_orbital()))
    let orbits = dynamic.optional_field("orbits", dynamic.string)
    let faction =
      dynamic.field("faction", dynamic.decode1(Faction, decode_faction()))
    let traits = dynamic.field("traits", dynamic.list(decode_trait()))
    let mods = dynamic.field("modifiers", dynamic.list(decode_modifier()))
    let chart = dynamic.field("chart", decode_chart())
    let is_under_construction =
      dynamic.field("isUnderConstruction", dynamic.bool)

    use actual_sym <- result.try(sym(value))
    use actual_type <- result.try(type_(value))
    use actual_syssym <- result.try(syssym(value))
    use actual_x <- result.try(x(value))
    use actual_y <- result.try(y(value))
    use actual_orbs <- result.try(orbs(value))
    use actual_orbits <- result.try(orbits(value))
    use actual_faction <- result.try(faction(value))
    use actual_traits <- result.try(traits(value))
    use actual_mods <- result.try(mods(value))
    use actual_chart <- result.try(chart(value))
    use actual_is_under_construction <- result.try(is_under_construction(value))

    Ok(Waypoint(
      symbol: actual_sym,
      type_: actual_type,
      system_symbol: actual_syssym,
      x: actual_x,
      y: actual_y,
      orbitals: actual_orbs,
      orbits: actual_orbits,
      faction: actual_faction,
      traits: actual_traits,
      modifiers: actual_mods,
      chart: actual_chart,
      is_under_construction: actual_is_under_construction,
    ))
  }
  // dynamic.decode9(
  //   Waypoint,
  //   dynamic.field("symbol", dynamic.string),
  //   dynamic.field("type", dynamic.string),
  //   dynamic.field("systemSymbol", dynamic.string),
  //   dynamic.field("x", dynamic.int),
  //   dynamic.field("y", dynamic.int),
  //   dynamic.field("orbitals", dynamic.list(decode_orbital)),
  //   dynamic.field("orbits", dynamic.string),
  //   dynamic.field("faction", dynamic.decode1(Faction, decode_faction())),
  //   dynamic.field("traits", dynamic.list(decode_trait())),
  // )
  // dynamic.field("modifiers", dynamic.list(decode_modifier())),
  // dynamic.field("chart", decode_chart()),
  // dynamic.field("isUnderConstruction", dynamic.bool),
}

pub fn decode_trait() {
  dynamic.decode3(
    Trait,
    dynamic.field("symbol", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("description", dynamic.string),
  )
}

pub fn decode_orbital() {
  dynamic.decode1(Orbital, dynamic.field("symbol", dynamic.string))
}

pub fn decode_faction() {
  dynamic.field("symbol", dynamic.string)
}

pub fn decode_trade() {
  dynamic.decode3(
    Trait,
    dynamic.field("symbol", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("description", dynamic.string),
  )
}

pub fn decode_modifier() {
  dynamic.decode3(
    Modifier,
    dynamic.field("symbol", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("description", dynamic.string),
  )
}

pub fn decode_chart() {
  dynamic.decode3(
    Chart,
    dynamic.optional_field("waypointSymbol", dynamic.string),
    dynamic.field("submittedBy", dynamic.string),
    dynamic.field("submittedOn", dynamic.string),
  )
}

pub fn get_waypoints_for_system(
  client: falcon.Client,
  system_name: String,
  traits: List(Trait),
) {
  let decoder = st_response.decode_data(dynamic.list(decode_waypoint()))
  client
  |> falcon.get(
    "systems/" <> system_name <> "/waypoints",
    expecting: Json(decoder),
    // expecting: Raw(dynamic.dynamic),
    options: [],
  )
}
