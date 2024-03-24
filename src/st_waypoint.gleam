import gleam/string
import gleam/option.{type Option}
import gleam/result
import gleam/list
import gleam/io
import gleam/json
import falcon
import falcon/core.{Json, Queries}
import gleam/dynamic
import st_response

pub type WaypointType {
  Planet
  GasGiant
  Moon
  OrbitalStation
  JumpGate
  AsteroidField
  Asteroid
  EngineeredAsteroid
  AsteroidBase
  Nebula
  DebrisField
  GravityWell
  ArtificialGravityWell
  FuelStation
}

pub fn decode_waypoint_type() {
  fn(val) {
    use raw_waypoint_type <- result.try(dynamic.string(val))
    // use raw_ship_type <- result.try(dynamic.string(val))

    case raw_waypoint_type {
      "PLANET" -> Ok(Planet)
      "GAS_GIANT" -> Ok(GasGiant)
      "MOON" -> Ok(Moon)
      "ORBITAL_STATION" -> Ok(OrbitalStation)
      "JUMP_GATE" -> Ok(JumpGate)
      "ASTEROID_FIELD" -> Ok(AsteroidField)
      "ASTEROID" -> Ok(Asteroid)
      "ENGINEERED_ASTEROID" -> Ok(EngineeredAsteroid)
      "ASTEROID_BASE" -> Ok(AsteroidBase)
      "NEBULA" -> Ok(Nebula)
      "DEBRIS_FIELD" -> Ok(DebrisField)
      "GRAVITY_WELL" -> Ok(GravityWell)
      "ARTIFICIAL_GRAVITY_WELL" -> Ok(ArtificialGravityWell)
      "FUEL_STATION" -> Ok(FuelStation)
      _ ->
        Error([
          dynamic.DecodeError(
            expected: "PLANET, GAS_GIANT etc",
            found: raw_waypoint_type,
            path: ["idk"],
          ),
        ])
    }
  }
}

pub fn encode_waypoint_type_to_string(waypoint_type: WaypointType) -> String {
  case waypoint_type {
    Planet -> "PLANET"
    GasGiant -> "GAS_GIANT"
    Moon -> "MOON"
    OrbitalStation -> "ORBITAL_STATION"
    JumpGate -> "JUMP_GATE"
    AsteroidField -> "ASTEROID_FIELD"
    Asteroid -> "ASTEROID"
    EngineeredAsteroid -> "ENGINEERED_ASTEROID"
    AsteroidBase -> "ASTEROID_BASE"
    Nebula -> "NEBULA"
    DebrisField -> "DEBRIS_FIELD"
    GravityWell -> "GRAVITY_WELL"
    ArtificialGravityWell -> "ARTIFICIAL_GRAVITY_WELL"
    FuelStation -> "FUEL_STATION"
  }
}

pub fn encode_waypoint_type(waypoint_type: WaypointType) -> json.Json {
  encode_waypoint_type_to_string(waypoint_type)
  |> json.string
}

pub const all_waypoint_types = [
  Planet,
  GasGiant,
  Moon,
  OrbitalStation,
  JumpGate,
  AsteroidField,
  Asteroid,
  EngineeredAsteroid,
  AsteroidBase,
  Nebula,
  DebrisField,
  GravityWell,
  ArtificialGravityWell,
  FuelStation,
]

pub const all_raw_waypoint_types = [
  "PLANET", "GAS_GIANT", "MOON", "ORBITAL_STATION", "JUMP_GATE",
  "ASTEROID_FIELD", "ASTEROID", "ENGINEERED_ASTEROID", "ASTEROID_BASE", "NEBULA",
  "DEBRIS_FIELD", "GRAVITY_WELL", "ARTIFICIAL_GRAVITY_WELL", "FUEL_STATION",
]

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
  system_symbol system_symbol: String,
  waypoint_type waypoint_type: Option(WaypointType),
  traits traits: List(Trait),
) -> st_response.FalconResult(List(Waypoint)) {
  let decoder = st_response.decode_data(dynamic.list(decode_waypoint()))

  let url = "systems/" <> system_symbol <> "/waypoints"

  client
  |> falcon.get(
    url,
    expecting: Json(st_response.debug_decoder(decoder)),
    options: [
      Queries([
        #(
          "traits",
          string.join(list.map(traits, fn(t) { t.symbol }), with: ","),
        ),
        #("type", case waypoint_type {
          option.Some(t) -> encode_waypoint_type_to_string(t)
          option.None -> ""
        }),
        #("limit", "20"),
      ]),
    ],
  )
}

pub fn show_traits_for_waypoints(waypoints: List(Waypoint)) -> String {
  list.map(waypoints, fn(wp: Waypoint) {
    let traits = string.join(list.map(wp.traits, fn(t) { t.name }), with: ", ")
    let name = wp.symbol

    "- " <> name <> " (" <> traits <> ")"
  })
  |> string.join(with: "\n")
}
