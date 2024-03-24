import gleam/io
import gleam/option.{type Option}
import gleam/result
import gleam/json
import falcon
import falcon/core.{Json}
import gleam/dynamic
import st_response
import st_agent
import st_market

// import st_market

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
    expiration: Option(String),
  )
}

pub type Module {
  Module(
    symbol: String,
    capacity: Option(Int),
    range: Option(Int),
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
    strength: Option(Int),
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

// {
//   "symbol": "REACTOR_OVERLOAD",
//   "component": "FRAME",
//   "name": "string",
//   "description": "string"
// }

pub type ShipConditionEvent {
  ShipConditionEvent(
    symbol: String,
    component: String,
    name: String,
    description: String,
  )
}

pub fn decode_ship_condition_event() {
  dynamic.decode4(
    ShipConditionEvent,
    dynamic.field("symbol", dynamic.string),
    dynamic.field("component", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("description", dynamic.string),
  )
}

pub fn optional_field_with_default(field_name, decoder, def) {
  fn(value) {
    value
    |> dynamic.optional_field(field_name, of: decoder)
    |> result.try(fn(_errs) { Ok(def) })
  }
}

pub fn decode_requirements() {
  //   |> 
  //   |> Ok
  //   |> result.map(fn(a) { a })
  //   |> result.unwrap(option.Some(0))
  //   use d <- decoder
  //   result.map(decoder(value), fn(_) { 0 })
  // fn(value) {
  //   result.map(
  //     dynamic.optional_field(named: field_name, of: dynamic.int)(value),
  //     fn(_) { 0 },
  //   )
  // }
  dynamic.decode3(
    Requirements,
    // dynamic.field("power", dynamic.int),
    // dynamic.field("crew", dynamic.int),
    // {
    //   dynamic.field(named: "slots", of: {
    //     fn(value) { result.try_recover(dynamic.int(value), 
    //     fn(a) { Ok(0) }) }
    //     //   use i <- result.unwrap(dynamic.int(value))
    //     //   Ok(i)
    //   })
    // },
    // ----
    // {
    //   fn(value) {
    //     result.map(
    //       dynamic.optional_field(named: "slots", of: dynamic.int)(value),
    //       fn(_) { 0 },
    //     )
    //   }
    // },
    optional_field_with_default("power", dynamic.int, 0),
    optional_field_with_default("crew", dynamic.int, 0),
    optional_field_with_default("slots", dynamic.int, 0),
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
    dynamic.optional_field("expiration", dynamic.string),
  )
}

pub fn decode_module() {
  dynamic.decode6(
    Module,
    dynamic.field("symbol", dynamic.string),
    dynamic.optional_field("capacity", dynamic.int),
    dynamic.optional_field("range", dynamic.int),
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
    dynamic.optional_field("strength", dynamic.int),
    optional_field_with_default("deposits", dynamic.list(dynamic.string), []),
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

pub fn get_my_ships(client: falcon.Client) {
  client
  |> falcon.get(
    "/my/ships/",
    Json(st_response.decode_paged_response(decode_ships())),
    // Json(st_response.decode_response(dynamic.dynamic)),
    // Raw(dynamic.dynamic),
    [],
  )
  // |> should.be_ok
  // |> core.extract_body
  // |> st_response.extract_data
  //   |> decode_ships()
  // |> io.debug
}

pub fn set_ship_to_orbit(client: falcon.Client, ship_symbol: String) {
  client
  |> falcon.post(
    "/my/ships/" <> ship_symbol <> "/orbit",
    Json(dynamic.field("data", dynamic.field("nav", decode_nav()))),
    options: [],
    body: "",
  )
}

pub fn set_ship_to_dock(client: falcon.Client, ship_symbol: String) {
  client
  |> falcon.post(
    "/my/ships/" <> ship_symbol <> "/dock",
    Json(dynamic.field("data", dynamic.field("nav", decode_nav()))),
    options: [],
    body: "",
  )
}

pub type NavigateResponse {
  NavigateSuccess(nav: Nav, fuel: Fuel, events: List(ShipConditionEvent))
  NavigateFailure(message: String)
}

pub fn navigate_ship_to_waypoint(
  client: falcon.Client,
  ship_symbol: String,
  waypoint_symbol: String,
) -> st_response.FalconResult(NavigateResponse) {
  let body =
    json.object([#("waypointSymbol", json.string(waypoint_symbol))])
    |> json.to_string
  let success_decoder = fn(val) {
    dynamic.field(
      "data",
      dynamic.decode3(
        NavigateSuccess,
        dynamic.field("nav", decode_nav()),
        dynamic.field("fuel", decode_fuel()),
        dynamic.field("events", dynamic.list(decode_ship_condition_event())),
      ),
    )(io.debug(val))
  }

  let failure_decoder = fn(val) {
    dynamic.decode1(NavigateFailure, dynamic.field("message", dynamic.string))(
      val,
    )
  }

  let decoder = dynamic.any([success_decoder, failure_decoder])

  client
  |> falcon.post(
    "/my/ships/" <> ship_symbol <> "/navigate",
    Json(decoder),
    options: [],
    body: body,
  )
}

pub type RefuelResponse {
  RefuelSuccess(
    agent: st_agent.Agent,
    fuel: Fuel,
    transaction: Option(st_market.MarketTransaction),
  )

  RefuelFailure(message: String)
}

pub fn refuel_ship(
  client: falcon.Client,
  ship_symbol: String,
) -> st_response.FalconResult(RefuelResponse) {
  let success_decoder =
    dynamic.decode3(
      RefuelSuccess,
      dynamic.field("agent", st_agent.decode_agent()),
      dynamic.field("fuel", decode_fuel()),
      dynamic.optional_field(
        "transation",
        st_market.decode_market_transaction(),
      ),
    )
  let _failure_decoder =
    dynamic.decode1(RefuelFailure, dynamic.field("message", dynamic.string))
  // let decoder = fn(val) {
  //   // io.debug(dict.keys(dynamic.unsafe_coerce(val)))
  //   // io.debug(dict.get(dynamic.unsafe_coerce(val), "data"))
  //   // io.debug(val)

  //   dynamic.any([
  //     dynamic.field("data", success_decoder),
  //     dynamic.field("error", failure_decoder),
  //   ])(val)
  // }

  client
  |> falcon.post(
    "/my/ships/" <> ship_symbol <> "/refuel",
    // Json(decoder),
    Json(dynamic.field("data", success_decoder)),
    options: [],
    body: "",
  )
}

pub fn get_ship_waypoint(ship: Ship) -> String {
  ship.nav.waypoint_symbol
}

// "transaction": {
//   "waypointSymbol": "string",
//   "shipSymbol": "string",
//   "shipType": "string",
//   "price": 0,
//   "agentSymbol": "string",
//   "timestamp": "2019-08-24T14:15:22Z"
// }

pub type ShipTransaction {
  ShipTransaction(
    waypoint_symbol: String,
    ship_symbol: String,
    ship_type: ShipType,
    price: Int,
    agent_symbol: String,
    timestamp: String,
  )
}

pub fn decode_ship_transaction() {
  dynamic.decode6(
    ShipTransaction,
    dynamic.field("waypointSymbol", dynamic.string),
    dynamic.field("shipSymbol", dynamic.string),
    dynamic.field("shipType", decode_ship_type()),
    dynamic.field("price", dynamic.int),
    dynamic.field("agentSymbol", dynamic.string),
    dynamic.field("timestamp", dynamic.string),
  )
}

pub type ShipType {
  ShipProbe
  ShipMiningDrone
  ShipSiphonDrone
  ShipInterceptor
  ShipLightHauler
  ShipCommandFrigate
  ShipExplorer
  ShipHeavyFreighter
  ShipLightShuttle
  ShipOreHound
  ShipRefiningFreighter
  ShipSurveyor
}

pub fn decode_ship_type() {
  fn(val) {
    use raw_ship_type <- result.try(dynamic.string(val))

    case raw_ship_type {
      "SHIP_PROBE" -> Ok(ShipProbe)
      "SHIP_MINING_DRONE" -> Ok(ShipMiningDrone)
      "SHIP_SIPHON_DRONE" -> Ok(ShipSiphonDrone)
      "SHIP_INTERCEPTOR" -> Ok(ShipInterceptor)
      "SHIP_LIGHT_HAULER" -> Ok(ShipLightHauler)
      "SHIP_COMMAND_FRIGATE" -> Ok(ShipCommandFrigate)
      "SHIP_EXPLORER" -> Ok(ShipExplorer)
      "SHIP_HEAVY_FREIGHTER" -> Ok(ShipHeavyFreighter)
      "SHIP_LIGHT_SHUTTLE" -> Ok(ShipLightShuttle)
      "SHIP_ORE_HOUND" -> Ok(ShipOreHound)
      "SHIP_REFINING_FREIGHTER" -> Ok(ShipRefiningFreighter)
      "SHIP_SURVEYOR" -> Ok(ShipSurveyor)
      _ ->
        Error([
          dynamic.DecodeError(
            expected: "SHIP_PROBE etc",
            found: raw_ship_type,
            path: ["idk"],
          ),
        ])
    }
  }
}

pub fn encode_ship_type(ship_type: ShipType) {
  case ship_type {
    ShipProbe -> "SHIP_PROBE"
    ShipMiningDrone -> "SHIP_MINING_DRONE"
    ShipSiphonDrone -> "SHIP_SIPHON_DRONE"
    ShipInterceptor -> "SHIP_INTERCEPTOR"
    ShipLightHauler -> "SHIP_LIGHT_HAULER"
    ShipCommandFrigate -> "SHIP_COMMAND_FRIGATE"
    ShipExplorer -> "SHIP_EXPLORER"
    ShipHeavyFreighter -> "SHIP_HEAVY_FREIGHTER"
    ShipLightShuttle -> "SHIP_LIGHT_SHUTTLE"
    ShipOreHound -> "SHIP_ORE_HOUND"
    ShipRefiningFreighter -> "SHIP_REFINING_FREIGHTER"
    ShipSurveyor -> "SHIP_SURVEYOR"
  }
  |> json.string
}

pub const all_raw_ship_types = [
  "SHIP_PROBE", "SHIP_MINING_DRONE", "SHIP_SIPHON_DRONE", "SHIP_INTERCEPTOR",
  "SHIP_LIGHT_HAULER", "SHIP_COMMAND_FRIGATE", "SHIP_EXPLORER",
  "SHIP_HEAVY_FREIGHTER", "SHIP_LIGHT_SHUTTLE", "SHIP_ORE_HOUND",
  "SHIP_REFINING_FREIGHTER", "SHIP_SURVEYOR",
]

// type PurchaseShipError

pub fn purchase_ship(
  client: falcon.Client,
  waypoint_symbol: String,
  ship_type: ShipType,
) -> st_response.FalconResult(#(st_agent.Agent, Ship, ShipTransaction)) {
  let body =
    json.object([
      #("waypointSymbol", json.string(waypoint_symbol)),
      #("shipType", encode_ship_type(ship_type)),
    ])
    |> json.to_string

  let valid_decoder = fn() {
    dynamic.field(
      "data",
      dynamic.decode3(
        fn(agent, ship, transaction) { #(agent, ship, transaction) },
        dynamic.field("agent", st_agent.decode_agent()),
        dynamic.field("ship", decode_ship()),
        dynamic.field("transation", decode_ship_transaction()),
      ),
    )
  }

  // let invalid_ship_type_decoder = fn() {
  //   dynamic.field("error", dynamic.string)
  // }
  client
  |> falcon.post("/my/ships/", Json(valid_decoder()), options: [], body: body)
}
