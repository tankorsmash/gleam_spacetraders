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
//   "symbol": "string",
//   "exports": [
//     {
//       "symbol": "PRECIOUS_STONES",
//       "name": "string",
//       "description": "string"
//     }
//   ],
//   "imports": [
//     {
//       "symbol": "PRECIOUS_STONES",
//       "name": "string",
//       "description": "string"
//     }
//   ],
//   "exchange": [
//     {
//       "symbol": "PRECIOUS_STONES",
//       "name": "string",
//       "description": "string"
//     }
//   ],
//   "transactions": [
//     {
//       "waypointSymbol": "string",
//       "shipSymbol": "string",
//       "tradeSymbol": "string",
//       "type": "PURCHASE",
//       "units": 0,
//       "pricePerUnit": 0,
//       "totalPrice": 0,
//       "timestamp": "2019-08-24T14:15:22Z"
//     }
//   ],
//   "tradeGoods": [
//     {
//       "symbol": "PRECIOUS_STONES",
//       "type": "EXPORT",
//       "tradeVolume": 1,
//       "supply": "SCARCE",
//       "activity": "WEAK",
//       "purchasePrice": 0,
//       "sellPrice": 0
//     }
//   ]
// }

pub type MarketExport {
  MarketExport(symbol: String, name: String, description: String)
}

pub type MarketImport {
  MarketImport(symbol: String, name: String, description: String)
}

pub type MarketExchange {
  MarketExchange(symbol: String, name: String, description: String)
}

pub type MarketTransaction {
  MarketTransaction(
    waypoint_symbol: String,
    ship_symbol: String,
    trade_symbol: String,
    type_: String,
    units: Int,
    price_per_unit: Int,
    total_price: Int,
    timestamp: String,
  )
}

pub type MarketTradeGood {
  MarketTradeGood(
    symbol: String,
    type_: String,
    trade_volume: Int,
    supply: String,
    activity: Option(String),
    purchase_price: Int,
    sell_price: Int,
  )
}

pub type Market {
  Market(
    symbol: String,
    exports: List(MarketExport),
    imports: List(MarketImport),
    exchange: List(MarketExchange),
    transactions: List(MarketTransaction),
    trade_goods: List(MarketTradeGood),
  )
}

pub fn decode_market_export() {
  dynamic.decode3(
    MarketExport,
    dynamic.field("symbol", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("description", dynamic.string),
  )
}

pub fn decode_market_import() {
  dynamic.decode3(
    MarketImport,
    dynamic.field("symbol", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("description", dynamic.string),
  )
}

pub fn decode_market_exchange() {
  dynamic.decode3(
    MarketExchange,
    dynamic.field("symbol", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("description", dynamic.string),
  )
}

pub fn decode_market_transaction() {
  dynamic.decode8(
    MarketTransaction,
    dynamic.field("waypointSymbol", dynamic.string),
    dynamic.field("shipSymbol", dynamic.string),
    dynamic.field("tradeSymbol", dynamic.string),
    dynamic.field("type", dynamic.string),
    dynamic.field("units", dynamic.int),
    dynamic.field("pricePerUnit", dynamic.int),
    dynamic.field("totalPrice", dynamic.int),
    dynamic.field("timestamp", dynamic.string),
  )
}

pub fn decode_market_trade_good() {
  dynamic.decode7(
    MarketTradeGood,
    dynamic.field("symbol", dynamic.string),
    dynamic.field("type", dynamic.string),
    dynamic.field("tradeVolume", dynamic.int),
    dynamic.field("supply", dynamic.string),
    dynamic.optional_field("activity", dynamic.string),
    dynamic.field("purchasePrice", dynamic.int),
    dynamic.field("sellPrice", dynamic.int),
  )
}

pub fn decode_market() {
  dynamic.decode6(
    Market,
    dynamic.field("symbol", dynamic.string),
    dynamic.field("exports", dynamic.list(decode_market_export())),
    dynamic.field("imports", dynamic.list(decode_market_import())),
    dynamic.field("exchange", dynamic.list(decode_market_exchange())),
    dynamic.field("transactions", dynamic.list(decode_market_transaction())),
    dynamic.field("tradeGoods", dynamic.list(decode_market_trade_good())),
  )
}

pub fn view_market(
  client: falcon.Client,
  system_symbol: String,
  waypoint_symbol: String,
) -> st_response.FalconResult(Market) {
  let decoder = st_response.decode_data(decode_market())
  let url =
    "systems/" <> system_symbol <> "/waypoints/" <> waypoint_symbol <> "/market"
  client
  |> falcon.get(
    url,
    // expecting: Json(fn(val) { decoder(io.debug(val)) }),
    expecting: Json(decoder),
    options: [],
  )
}
