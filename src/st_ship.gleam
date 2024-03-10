import gleam/io
import dotenv
import gleam/erlang/os
import gleam/string
import gleam/list
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
