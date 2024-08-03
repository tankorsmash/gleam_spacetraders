import falcon
import falcon/core.{Json, Queries}
import gleam/dynamic
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
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
  Planet, GasGiant, Moon, OrbitalStation, JumpGate, AsteroidField, Asteroid,
  EngineeredAsteroid, AsteroidBase, Nebula, DebrisField, GravityWell,
  ArtificialGravityWell, FuelStation,
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

pub const all_raw_waypoint_traits: List(String) = [
  "UNCHARTED", "UNDER_CONSTRUCTION", "MARKETPLACE", "SHIPYARD", "OUTPOST",
  "SCATTERED_SETTLEMENTS", "SPRAWLING_CITIES", "MEGA_STRUCTURES", "PIRATE_BASE",
  "OVERCROWDED", "HIGH_TECH", "CORRUPT", "BUREAUCRATIC", "TRADING_HUB",
  "INDUSTRIAL", "BLACK_MARKET", "RESEARCH_FACILITY", "MILITARY_BASE",
  "SURVEILLANCE_OUTPOST", "EXPLORATION_OUTPOST", "MINERAL_DEPOSITS",
  "COMMON_METAL_DEPOSITS", "PRECIOUS_METAL_DEPOSITS", "RARE_METAL_DEPOSITS",
  "METHANE_POOLS", "ICE_CRYSTALS", "EXPLOSIVE_GASES", "STRONG_MAGNETOSPHERE",
  "VIBRANT_AURORAS", "SALT_FLATS", "CANYONS", "PERPETUAL_DAYLIGHT",
  "PERPETUAL_OVERCAST", "DRY_SEABEDS", "MAGMA_SEAS", "SUPERVOLCANOES",
  "ASH_CLOUDS", "VAST_RUINS", "MUTATED_FLORA", "TERRAFORMED",
  "EXTREME_TEMPERATURES", "EXTREME_PRESSURE", "DIVERSE_LIFE", "SCARCE_LIFE",
  "FOSSILS", "WEAK_GRAVITY", "STRONG_GRAVITY", "CRUSHING_GRAVITY",
  "TOXIC_ATMOSPHERE", "CORROSIVE_ATMOSPHERE", "BREATHABLE_ATMOSPHERE",
  "THIN_ATMOSPHERE", "JOVIAN", "ROCKY", "VOLCANIC", "FROZEN", "SWAMP", "BARREN",
  "TEMPERATE", "JUNGLE", "OCEAN", "RADIOACTIVE", "MICRO_GRAVITY_ANOMALIES",
  "DEBRIS_CLUSTER", "DEEP_CRATERS", "SHALLOW_CRATERS", "UNSTABLE_COMPOSITION",
  "HOLLOWED_INTERIOR", "STRIPPED",
]

pub type WaypointTrait {
  Uncharted
  UnderConstruction
  Marketplace
  Shipyard
  Outpost
  ScatteredSettlements
  SprawlingCities
  MegaStructures
  PirateBase
  Overcrowded
  HighTech
  Corrupt
  Bureaucratic
  TradingHub
  Industrial
  BlackMarket
  ResearchFacility
  MilitaryBase
  SurveillanceOutpost
  ExplorationOutpost
  MineralDeposits
  CommonMetalDeposits
  PreciousMetalDeposits
  RareMetalDeposits
  MethanePools
  IceCrystals
  ExplosiveGases
  StrongMagnetosphere
  VibrantAuroras
  SaltFlats
  Canyons
  PerpetualDaylight
  PerpetualOvercast
  DrySeabeds
  MagmaSeas
  Supervolcanoes
  AshClouds
  VastRuins
  MutatedFlora
  Terraformed
  ExtremeTemperatures
  ExtremePressure
  DiverseLife
  ScarceLife
  Fossils
  WeakGravity
  StrongGravity
  CrushingGravity
  ToxicAtmosphere
  CorrosiveAtmosphere
  BreathableAtmosphere
  ThinAtmosphere
  Jovian
  Rocky
  Volcanic
  Frozen
  Swamp
  Barren
  Temperate
  Jungle
  Ocean
  Radioactive
  MicroGravityAnomalies
  DebrisCluster
  DeepCraters
  ShallowCraters
  UnstableComposition
  HollowedInterior
  Stripped
}

pub fn decode_waypoint_trait() {
  fn(val) {
    use raw_waypoint_trait <- result.try(dynamic.string(val))

    // takes the raw string and returns the WaypointTrait that it is. it includes every single trait
    case raw_waypoint_trait {
      "UNCHARTED" -> Ok(Uncharted)
      "UNDER_CONSTRUCTION" -> Ok(UnderConstruction)
      "MARKETPLACE" -> Ok(Marketplace)
      "SHIPYARD" -> Ok(Shipyard)
      "OUTPOST" -> Ok(Outpost)
      "SCATTERED_SETTLEMENTS" -> Ok(ScatteredSettlements)
      "SPRAWLING_CITIES" -> Ok(SprawlingCities)
      "MEGA_STRUCTURES" -> Ok(MegaStructures)
      "PIRATE_BASE" -> Ok(PirateBase)
      "OVERCROWDED" -> Ok(Overcrowded)
      "HIGH_TECH" -> Ok(HighTech)
      "CORRUPT" -> Ok(Corrupt)
      "BUREAUCRATIC" -> Ok(Bureaucratic)
      "TRADING_HUB" -> Ok(TradingHub)
      "INDUSTRIAL" -> Ok(Industrial)
      "BLACK_MARKET" -> Ok(BlackMarket)
      "RESEARCH_FACILITY" -> Ok(ResearchFacility)
      "MILITARY_BASE" -> Ok(MilitaryBase)
      "SURVEILLANCE_OUTPOST" -> Ok(SurveillanceOutpost)
      "EXPLORATION_OUTPOST" -> Ok(ExplorationOutpost)
      "MINERAL_DEPOSITS" -> Ok(MineralDeposits)
      "COMMON_METAL_DEPOSITS" -> Ok(CommonMetalDeposits)
      "PRECIOUS_METAL_DEPOSITS" -> Ok(PreciousMetalDeposits)
      "RARE_METAL_DEPOSITS" -> Ok(RareMetalDeposits)
      "METHANE_POOLS" -> Ok(MethanePools)
      "ICE_CRYSTALS" -> Ok(IceCrystals)
      "EXPLOSIVE_GASES" -> Ok(ExplosiveGases)
      "STRONG_MAGNETOSPHERE" -> Ok(StrongMagnetosphere)
      "VIBRANT_AURORAS" -> Ok(VibrantAuroras)
      "SALT_FLATS" -> Ok(SaltFlats)
      "CANYONS" -> Ok(Canyons)
      "PERPETUAL_DAYLIGHT" -> Ok(PerpetualDaylight)
      "PERPETUAL_OVERCAST" -> Ok(PerpetualOvercast)
      "DRY_SEABEDS" -> Ok(DrySeabeds)
      "MAGMA_SEAS" -> Ok(MagmaSeas)
      "SUPERVOLCANOES" -> Ok(Supervolcanoes)
      "ASH_CLOUDS" -> Ok(AshClouds)
      "VAST_RUINS" -> Ok(VastRuins)
      "MUTATED_FLORA" -> Ok(MutatedFlora)
      "TERRAFORMED" -> Ok(Terraformed)
      "EXTREME_TEMPERATURES" -> Ok(ExtremeTemperatures)
      "EXTREME_PRESSURE" -> Ok(ExtremePressure)
      "DIVERSE_LIFE" -> Ok(DiverseLife)
      "SCARCE_LIFE" -> Ok(ScarceLife)
      "FOSSILS" -> Ok(Fossils)
      "WEAK_GRAVITY" -> Ok(WeakGravity)
      "STRONG_GRAVITY" -> Ok(StrongGravity)
      "CRUSHING_GRAVITY" -> Ok(CrushingGravity)
      "TOXIC_ATMOSPHERE" -> Ok(ToxicAtmosphere)
      "CORROSIVE_ATMOSPHERE" -> Ok(CorrosiveAtmosphere)
      "BREATHABLE_ATMOSPHERE" -> Ok(BreathableAtmosphere)
      "THIN_ATMOSPHERE" -> Ok(ThinAtmosphere)
      "JOVIAN" -> Ok(Jovian)
      "ROCKY" -> Ok(Rocky)
      "VOLCANIC" -> Ok(Volcanic)
      "FROZEN" -> Ok(Frozen)
      "SWAMP" -> Ok(Swamp)
      "BARREN" -> Ok(Barren)
      "TEMPERATE" -> Ok(Temperate)
      "JUNGLE" -> Ok(Jungle)
      "OCEAN" -> Ok(Ocean)
      "RADIOACTIVE" -> Ok(Radioactive)
      "MICRO_GRAVITY_ANOMALIES" -> Ok(MicroGravityAnomalies)
      "DEBRIS_CLUSTER" -> Ok(DebrisCluster)
      "DEEP_CRATERS" -> Ok(DeepCraters)
      "SHALLOW_CRATERS" -> Ok(ShallowCraters)
      "UNSTABLE_COMPOSITION" -> Ok(UnstableComposition)
      "HOLLOWED_INTERIOR" -> Ok(HollowedInterior)
      "STRIPPED" -> Ok(Stripped)
      _ ->
        Error([
          dynamic.DecodeError(
            expected: "UNCHARTED, UNDER_CONSTRUCTION etc",
            found: raw_waypoint_trait,
            path: ["idk"],
          ),
        ])
    }
  }
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
) -> st_response.ApiResult(List(Waypoint)) {
  let decoder = st_response.decode_data(dynamic.list(decode_waypoint()))

  let url = "systems/" <> system_symbol <> "/waypoints"

  client
  |> falcon.get(
    url,
    expecting: Json(
      decoder
      |> st_response.decode_api_response,
    ),
    options: [
      Queries(
        list.concat([
          [
            #(
              "traits",
              string.join(list.map(traits, fn(t) { t.symbol }), with: ","),
            ),
            #("limit", "20"),
          ],
          case waypoint_type {
            option.Some(t) -> [#("type", encode_waypoint_type_to_string(t))]
            option.None -> []
          },
        ]),
      ),
    ],
  )
}

pub fn get_waypoint(
  client: falcon.Client,
  system_symbol system_symbol: String,
  waypoint_symbol waypoint_symbol: String,
) -> st_response.ApiResult(Waypoint) {
  let decoder = st_response.decode_data(decode_waypoint())

  let url = "systems/" <> system_symbol <> "/waypoints/" <> waypoint_symbol

  client
  |> falcon.get(
    url,
    expecting: Json(st_response.decode_api_response(decoder)),
    options: [Queries([])],
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
