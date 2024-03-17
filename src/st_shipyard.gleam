import gleam/io
import dotenv
import gleam/erlang/os
import gleam/string
import gleam/option.{type Option}
import gleam/list
import gleam/result
import gleam/function
import falcon.{type Client, type FalconError, type FalconResponse}
import falcon/core.{Json, Raw, Url}
import gleam/dynamic
import gleeunit/should
import st_response
import st_ship

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
    ships: List(st_ship.Ship),
    modifications_fee: Int,
  )
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
      dynamic.list(st_ship.decode_ship()),
      [],
    ),
    dynamic.field("modificationsFee", dynamic.int),
  )
}

pub fn view_available_ships(
  client: falcon.Client,
  system_symbol: String,
  waypoint_symbol: String,
) -> st_response.WebResult(Shipyard) {
  client
  |> falcon.get(
    "/systems/"
      <> system_symbol
      <> "/waypoints/"
      <> waypoint_symbol
      <> "/shipyard",
    Json(fn(val) {
      io.debug(val)
      dynamic.field("data", decode_shipyard())(val)
    }),
    // Json(st_response.decode_response(dynamic.dynamic)),
    // Raw(dynamic.dynamic),
    [],
  )
}
