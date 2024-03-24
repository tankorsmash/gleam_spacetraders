import gleam/io
import gleam/result
import falcon
import falcon/core.{Json}
import gleam/dynamic
import st_response
import st_ship

pub const purchase_ship = st_ship.purchase_ship

// {
//   "data": {
//     "symbol": "string",
//     "shipTypes": [
//       {
//         "type": "SHIP_PROBE"
//       }
//     ],
//     "transactions": [
//       {
//         "waypointSymbol": "string",
//         "shipSymbol": "string",
//         "shipType": "string",
//         "price": 0,
//         "agentSymbol": "string",
//         "timestamp": "2019-08-24T14:15:22Z"
//       }
//     ],
//     "ships": [
//       {
//         "type": "SHIP_PROBE",
//         "name": "string",
//         "description": "string",
//         "supply": "SCARCE",
//         "activity": "WEAK",
//         "purchasePrice": 0,
//         "frame": {
//           "symbol": "FRAME_PROBE",
//           "name": "string",
//           "description": "string",
//           "condition": 0,
//           "integrity": 0,
//           "moduleSlots": 0,
//           "mountingPoints": 0,
//           "fuelCapacity": 0,
//           "requirements": {
//             "power": 0,
//             "crew": 0,
//             "slots": 0
//           }
//         },
//         "reactor": {
//           "symbol": "REACTOR_SOLAR_I",
//           "name": "string",
//           "description": "string",
//           "condition": 0,
//           "integrity": 0,
//           "powerOutput": 1,
//           "requirements": {
//             "power": 0,
//             "crew": 0,
//             "slots": 0
//           }
//         },
//         "engine": {
//           "symbol": "ENGINE_IMPULSE_DRIVE_I",
//           "name": "string",
//           "description": "string",
//           "condition": 0,
//           "integrity": 0,
//           "speed": 1,
//           "requirements": {
//             "power": 0,
//             "crew": 0,
//             "slots": 0
//           }
//         },
//         "modules": [
//           {
//             "symbol": "MODULE_MINERAL_PROCESSOR_I",
//             "capacity": 0,
//             "range": 0,
//             "name": "string",
//             "description": "string",
//             "requirements": {
//               "power": 0,
//               "crew": 0,
//               "slots": 0
//             }
//           }
//         ],
//         "mounts": [
//           {
//             "symbol": "MOUNT_GAS_SIPHON_I",
//             "name": "string",
//             "description": "string",
//             "strength": 0,
//             "deposits": [
//               "QUARTZ_SAND"
//             ],
//             "requirements": {
//               "power": 0,
//               "crew": 0,
//               "slots": 0
//             }
//           }
//         ],
//         "crew": {
//           "required": 0,
//           "capacity": 0
//         }
//       }
//     ],
//     "modificationsFee": 0
//   }
// }

pub type ShipType {
  ShipType(type_: String)
}

pub type Transaction {
  Transaction(
    waypoint_symbol: String,
    ship_symbol: String,
    ship_type: String,
    price: Int,
    agent_symbol: String,
    timestamp: String,
  )
}

pub type Shipyard {
  Shipyard(
    symbol: String,
    ship_types: List(ShipType),
    transactions: List(Transaction),
    ships: List(ShipyardShip),
    modifications_fee: Int,
  )
}

pub type ShipyardCrew {
  ShipyardCrew(required: Int, capacity: Int)
}

pub fn decode_shipyard_crew() {
  dynamic.decode2(
    ShipyardCrew,
    dynamic.field("required", dynamic.int),
    dynamic.field("capacity", dynamic.int),
  )
}

pub type ShipyardShip {
  ShipyardShip(
    type_: String,
    name: String,
    description: String,
    supply: String,
    activity: String,
    purchase_price: Int,
    frame: st_ship.Frame,
    reactor: st_ship.Reactor,
    engine: st_ship.Engine,
    modules: List(st_ship.Module),
    mounts: List(st_ship.Mount),
    crew: ShipyardCrew,
  )
}

pub fn decode_shipyard_ship() {
  fn(val) {
    let triple_decoder =
      dynamic.decode3(
        fn(t, n, d) { #(t, n, d) },
        dynamic.field("type", dynamic.string),
        dynamic.field("name", dynamic.string),
        dynamic.field("description", dynamic.string),
      )
    use #(type_, name, description) <- result.try(triple_decoder(val))

    use res <- result.map(dynamic.decode9(
      fn(d, a, p, f, r, e, mo, moun, crew) {
        ShipyardShip(type_, name, description, d, a, p, f, r, e, mo, moun, crew)
      },
      dynamic.field("supply", dynamic.string),
      dynamic.field("activity", dynamic.string),
      dynamic.field("purchasePrice", dynamic.int),
      dynamic.field("frame", st_ship.decode_frame()),
      dynamic.field("reactor", st_ship.decode_reactor()),
      dynamic.field("engine", st_ship.decode_engine()),
      dynamic.field("modules", dynamic.list(st_ship.decode_module())),
      dynamic.field("mounts", dynamic.list(st_ship.decode_mount())),
      dynamic.field("crew", decode_shipyard_crew()),
    )(val))

    res
  }
}

pub fn decode_ship_type() {
  dynamic.decode1(ShipType, dynamic.field("type", dynamic.string))
}

pub fn decode_transaction() {
  dynamic.decode6(
    Transaction,
    dynamic.field("waypointSymbol", dynamic.string),
    dynamic.field("shipSymbol", dynamic.string),
    dynamic.field("shipType", dynamic.string),
    dynamic.field("price", dynamic.int),
    dynamic.field("agentSymbol", dynamic.string),
    dynamic.field("timestamp", dynamic.string),
  )
}

pub fn decode_shipyard() {
  dynamic.decode5(
    Shipyard,
    dynamic.field("symbol", dynamic.string),
    dynamic.field("shipTypes", dynamic.list(decode_ship_type())),
    st_response.optional_field_with_default(
      "transactions",
      dynamic.list(decode_transaction()),
      [],
    ),
    st_response.optional_field_with_default(
      "ships",
      dynamic.list(decode_shipyard_ship()),
      [],
    ),
    dynamic.field("modificationsFee", dynamic.int),
  )
}

pub fn view_available_ships(
  client: falcon.Client,
  system_symbol: String,
  waypoint_symbol: String,
) -> st_response.FalconResult(Shipyard) {
  client
  |> falcon.get(
    "/systems/"
      <> system_symbol
      <> "/waypoints/"
      <> waypoint_symbol
      <> "/shipyard",
    Json(fn(val) { dynamic.field("data", decode_shipyard())(val) }),
    // Json(st_response.decode_response(dynamic.dynamic)),
    // Raw(dynamic.dynamic),
    [],
  )
}
