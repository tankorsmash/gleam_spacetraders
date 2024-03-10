import gleam/io
import dotenv
import gleam/erlang/os
import gleam/string
import gleam/list
import gleam/result
import falcon.{type Client, type FalconError, type FalconResponse}
import falcon/core.{Json, Raw, Url}
import gleam/dynamic
import gleeunit/should
import st_response

// {
// 	"symbol": "string",
// 	"registration": {
// 		"name": "string",
// 		"factionSymbol": "string",
// 		"role": "FABRICATOR"
// 	},
// 	"nav": {
// 		"systemSymbol": "string",
// 		"waypointSymbol": "string",
// 		"route": {
// 			"destination": {
// 				"symbol": "string",
// 				"type": "PLANET",
// 				"systemSymbol": "string",
// 				"x": 0,
// 				"y": 0
// 			},
// 			"origin": {
// 				"symbol": "string",
// 				"type": "PLANET",
// 				"systemSymbol": "string",
// 				"x": 0,
// 				"y": 0
// 			},
// 			"departureTime": "2019-08-24T14:15:22Z",
// 			"arrival": "2019-08-24T14:15:22Z"
// 		},
// 		"status": "IN_TRANSIT",
// 		"flightMode": "CRUISE"
// 	},
// 	"crew": {
// 		"current": 0,
// 		"required": 0,
// 		"capacity": 0,
// 		"rotation": "STRICT",
// 		"morale": 0,
// 		"wages": 0
// 	},
// 	"frame": {
// 		"symbol": "FRAME_PROBE",
// 		"name": "string",
// 		"description": "string",
// 		"condition": 0,
// 		"moduleSlots": 0,
// 		"mountingPoints": 0,
// 		"fuelCapacity": 0,
// 		"requirements": {
// 			"power": 0,
// 			"crew": 0,
// 			"slots": 0
// 		}
// 	},
// 	"reactor": {
// 		"symbol": "REACTOR_SOLAR_I",
// 		"name": "string",
// 		"description": "string",
// 		"condition": 0,
// 		"powerOutput": 1,
// 		"requirements": {
// 			"power": 0,
// 			"crew": 0,
// 			"slots": 0
// 		}
// 	},
// 	"engine": {
// 		"symbol": "ENGINE_IMPULSE_DRIVE_I",
// 		"name": "string",
// 		"description": "string",
// 		"condition": 0,
// 		"speed": 1,
// 		"requirements": {
// 			"power": 0,
// 			"crew": 0,
// 			"slots": 0
// 		}
// 	},
// 	"cooldown": {
// 		"shipSymbol": "string",
// 		"totalSeconds": 0,
// 		"remainingSeconds": 0,
// 		"expiration": "2019-08-24T14:15:22Z"
// 	},
// 	"modules": [
// 		{
// 			"symbol": "MODULE_MINERAL_PROCESSOR_I",
// 			"capacity": 0,
// 			"range": 0,
// 			"name": "string",
// 			"description": "string",
// 			"requirements": {
// 				"power": 0,
// 				"crew": 0,
// 				"slots": 0
// 			}
// 		}
// 	],
// 	"mounts": [
// 		{
// 			"symbol": "MOUNT_GAS_SIPHON_I",
// 			"name": "string",
// 			"description": "string",
// 			"strength": 0,
// 			"deposits": [
// 				"QUARTZ_SAND"
// 			],
// 			"requirements": {
// 				"power": 0,
// 				"crew": 0,
// 				"slots": 0
// 			}
// 		}
// 	],
// 	"cargo": {
// 		"capacity": 0,
// 		"units": 0,
// 		"inventory": [
// 			{
// 				"symbol": "PRECIOUS_STONES",
// 				"name": "string",
// 				"description": "string",
// 				"units": 1
// 			}
// 		]
// 	},
// 	"fuel": {
// 		"current": 0,
// 		"capacity": 0,
// 		"consumed": {
// 			"amount": 0,
// 			"timestamp": "2019-08-24T14:15:22Z"
// 		}
// 	}
// }

pub type Ship {
  Ship(
    symbol: String,
    registration: Registration,
    nav: Nav,
    crew: Crew,
    frame: Frame,
    reactor: Reactor,
    engine: Engine,
    cooldown: Cooldown,
    modules: List(Module),
    mounts: List(Mount),
    cargo: Cargo,
    fuel: Fuel,
  )
}

pub type Registration {
  Registration(name: String, faction_symbol: String, role: String)
}

pub type Nav {
  Nav(
    system_symbol: String,
    waypoint_symbol: String,
    route: Route,
    status: String,
    flight_mode: String,
  )
}

pub type Route {
  Route(
    destination: Destination,
    origin: Origin,
    departure_time: String,
    arrival: String,
  )
}

pub type Destination {
  Destination(
    symbol: String,
    type_: String,
    system_symbol: String,
    x: Int,
    y: Int,
  )
}

pub type Origin {
  Origin(symbol: String, type_: String, system_symbol: String, x: Int, y: Int)
}

pub type Crew {
  Crew(
    current: Int,
    required: Int,
    capacity: Int,
    rotation: String,
    morale: Int,
    wages: Int,
  )
}

pub type Frame {
  Frame(
    symbol: String,
    name: String,
    description: String,
    condition: Int,
    module_slots: Int,
    mounting_points: Int,
    fuel_capacity: Int,
    requirements: Requirements,
  )
}

pub type Requirements {
  Requirements(power: Int, crew: Int, slots: Int)
}

pub type Reactor {
  Reactor(
    symbol: String,
    name: String,
    description: String,
    condition: Int,
    power_output: Int,
    requirements: Requirements,
  )
}

pub type Engine {
  Engine(
    symbol: String,
    name: String,
    description: String,
    condition: Int,
    speed: Int,
    requirements: Requirements,
  )
}

pub type Cooldown {
  Cooldown(
    ship_symbol: String,
    total_seconds: Int,
    remaining_seconds: Int,
    expiration: String,
  )
}

pub type Module {
  Module(
    symbol: String,
    capacity: Int,
    range: Int,
    name: String,
    description: String,
    requirements: Requirements,
  )
}

pub type Mount {
  Mount(
    symbol: String,
    name: String,
    description: String,
    strength: Int,
    deposits: List(String),
    requirements: Requirements,
  )
}

pub type Cargo {
  Cargo(capacity: Int, units: Int, inventory: List(Inventory))
}

pub type Inventory {
  Inventory(symbol: String, name: String, description: String, units: Int)
}

pub type Fuel {
  Fuel(current: Int, capacity: Int, consumed: Consumed)
}

pub type Consumed {
  Consumed(amount: Int, timestamp: String)
}

pub fn decode_ship() {
  fn(value) {
    use #(s, r, n, c) <- result.try(dynamic.decode4(
      fn(s, r, n, c) { #(s, r, n, c) },
      dynamic.field("symbol", dynamic.string),
      dynamic.field("registration", decode_registration()),
      dynamic.field("nav", decode_nav()),
      dynamic.field("crew", decode_crew()),
    )(value))

    dynamic.decode8(
      fn(f, re, e, co, m, mo, ca, fu) {
        Ship(s, r, n, c, f, re, e, co, m, mo, ca, fu)
      },
      //   dynamic.field("symbol", dynamic.string),
      //   dynamic.field("registration", decode_registration),
      //   dynamic.field("nav", decode_nav),
      //   dynamic.field("crew", decode_crew),
      dynamic.field("frame", decode_frame()),
      dynamic.field("reactor", decode_reactor()),
      dynamic.field("engine", decode_engine()),
      dynamic.field("cooldown", decode_cooldown()),
      dynamic.field("modules", dynamic.list(decode_module())),
      dynamic.field("mounts", dynamic.list(decode_mount())),
      dynamic.field("cargo", decode_cargo()),
      dynamic.field("fuel", decode_fuel()),
    )(value)
  }
}

pub fn decode_registration() {
  dynamic.decode3(
    Registration,
    dynamic.field("name", dynamic.string),
    dynamic.field("factionSymbol", dynamic.string),
    dynamic.field("role", dynamic.string),
  )
}

pub fn decode_nav() {
  dynamic.decode5(
    Nav,
    dynamic.field("systemSymbol", dynamic.string),
    dynamic.field("waypointSymbol", dynamic.string),
    dynamic.field("route", decode_route()),
    dynamic.field("status", dynamic.string),
    dynamic.field("flightMode", dynamic.string),
  )
}

pub fn decode_route() {
  dynamic.decode4(
    Route,
    dynamic.field("destination", decode_destination()),
    dynamic.field("origin", decode_origin()),
    dynamic.field("departureTime", dynamic.string),
    dynamic.field("arrival", dynamic.string),
  )
}

pub fn decode_destination() {
  dynamic.decode5(
    Destination,
    dynamic.field("symbol", dynamic.string),
    dynamic.field("type", dynamic.string),
    dynamic.field("systemSymbol", dynamic.string),
    dynamic.field("x", dynamic.int),
    dynamic.field("y", dynamic.int),
  )
}

pub fn decode_origin() {
  dynamic.decode5(
    Origin,
    dynamic.field("symbol", dynamic.string),
    dynamic.field("type", dynamic.string),
    dynamic.field("systemSymbol", dynamic.string),
    dynamic.field("x", dynamic.int),
    dynamic.field("y", dynamic.int),
  )
}

pub fn decode_crew() {
  dynamic.decode6(
    Crew,
    dynamic.field("current", dynamic.int),
    dynamic.field("required", dynamic.int),
    dynamic.field("capacity", dynamic.int),
    dynamic.field("rotation", dynamic.string),
    dynamic.field("morale", dynamic.int),
    dynamic.field("wages", dynamic.int),
  )
}

pub fn decode_frame() {
  dynamic.decode8(
    Frame,
    dynamic.field("symbol", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("description", dynamic.string),
    dynamic.field("condition", dynamic.int),
    dynamic.field("moduleSlots", dynamic.int),
    dynamic.field("mountingPoints", dynamic.int),
    dynamic.field("fuelCapacity", dynamic.int),
    dynamic.field("requirements", decode_requirements()),
  )
}

pub fn decode_requirements() {
  dynamic.decode3(
    Requirements,
    dynamic.field("power", dynamic.int),
    dynamic.field("crew", dynamic.int),
    dynamic.field("slots", dynamic.int),
  )
}

pub fn decode_reactor() {
  dynamic.decode6(
    Reactor,
    dynamic.field("symbol", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("description", dynamic.string),
    dynamic.field("condition", dynamic.int),
    dynamic.field("powerOutput", dynamic.int),
    dynamic.field("requirements", decode_requirements()),
  )
}

pub fn decode_engine() {
  dynamic.decode6(
    Engine,
    dynamic.field("symbol", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("description", dynamic.string),
    dynamic.field("condition", dynamic.int),
    dynamic.field("speed", dynamic.int),
    dynamic.field("requirements", decode_requirements()),
  )
}

pub fn decode_cooldown() {
  dynamic.decode4(
    Cooldown,
    dynamic.field("shipSymbol", dynamic.string),
    dynamic.field("totalSeconds", dynamic.int),
    dynamic.field("remainingSeconds", dynamic.int),
    dynamic.field("expiration", dynamic.string),
  )
}

pub fn decode_module() {
  dynamic.decode6(
    Module,
    dynamic.field("symbol", dynamic.string),
    dynamic.field("capacity", dynamic.int),
    dynamic.field("range", dynamic.int),
    dynamic.field("name", dynamic.string),
    dynamic.field("description", dynamic.string),
    dynamic.field("requirements", decode_requirements()),
  )
}

pub fn decode_mount() {
  dynamic.decode6(
    Mount,
    dynamic.field("symbol", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("description", dynamic.string),
    dynamic.field("strength", dynamic.int),
    dynamic.field("deposits", dynamic.list(dynamic.string)),
    dynamic.field("requirements", decode_requirements()),
  )
}

pub fn decode_cargo() {
  dynamic.decode3(
    Cargo,
    dynamic.field("capacity", dynamic.int),
    dynamic.field("units", dynamic.int),
    dynamic.field("inventory", dynamic.list(decode_inventory())),
  )
}

pub fn decode_inventory() {
  dynamic.decode4(
    Inventory,
    dynamic.field("symbol", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("description", dynamic.string),
    dynamic.field("units", dynamic.int),
  )
}

pub fn decode_fuel() {
  dynamic.decode3(
    Fuel,
    dynamic.field("current", dynamic.int),
    dynamic.field("capacity", dynamic.int),
    dynamic.field("consumed", decode_consumed()),
  )
}

pub fn decode_consumed() {
  dynamic.decode2(
    Consumed,
    dynamic.field("amount", dynamic.int),
    dynamic.field("timestamp", dynamic.string),
  )
}

pub fn decode_ships() {
  dynamic.list(decode_ship())
}
