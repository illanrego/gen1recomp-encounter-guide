local model = require("lib.model")

local function eq(actual, expected, message)
  assert(actual == expected,
    (message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local areas = model.buildAreas({
  encounters = {
    MT_MOON_1F = { grass = { rate = 10, slots = { { species = "ZUBAT", level = 8 } } } },
    MT_MOON_B1F = { grass = { rate = 10, slots = { { species = "GEODUDE", level = 10 } } } },
  },
  townMap = {
    locations = {
      MT_MOON_1F = { name = "MT.MOON", x = 6, y = 2 },
      MT_MOON_B1F = { name = "MT.MOON", x = 6, y = 2 },
    },
  },
  pokemon = {
    ZUBAT = { name = "ZUBAT" },
    GEODUDE = { name = "GEODUDE" },
  },
  constants = { encounterBuckets = { 128, 256 } },
})

eq(#areas, 1, "one Town Map marker should create one parent area")
eq(areas[1].name, "MT.MOON", "the parent marker keeps its Town Map name")
eq(#areas[1].sources, 2, "each underlying map/floor must remain a separate source")
eq(areas[1].sources[1].mapId, "MT_MOON_1F", "the first source is retained")
eq(areas[1].sources[2].mapId, "MT_MOON_B1F", "the basement source is retained")
eq(areas[1].sources[1].label, "MT. MOON 1F", "each source gets an explicit player-facing heading")
eq(areas[1].sources[1].methods.land.species[1].name, "ZUBAT", "land encounters stay inside their source map")

local summary = model.summarizeMethod({
  rate = 64,
  slots = {
    { species = "ZUBAT", level = 8 },
    { species = "ZUBAT", level = 10 },
    { species = "ZUBAT", level = 10 },
    { species = "GEODUDE", level = 10 },
  },
}, { ZUBAT = { name = "ZUBAT" }, GEODUDE = { name = "GEODUDE" } },
{ 64, 128, 192, 256 })

eq(summary.rate, 64, "the source encounter rate is retained")
eq(#summary.species, 2, "slots are grouped by species")
eq(summary.species[2].name, "ZUBAT", "species rows sort by readable name")
eq(summary.species[2].minLevel, 8, "a species range keeps its actual lowest level")
eq(summary.species[2].maxLevel, 10, "a species range keeps its actual highest level")
eq(#summary.species[2].levels, 2, "duplicate species/level slots merge into one exact row")
eq(summary.species[2].levels[2].slotCount, 2, "duplicate level slots retain their combined weight")
eq(summary.species[2].levels[2].conditionalOdds, 0.5, "combined level probability is exact")
eq(summary.species[2].levels[2].perStepOdds, 0.125, "combined chance per step uses the map rate")

local overridden = model.buildAreas({
  encounters = {
    ROUTE_1 = { grass = {
      rate = 128,
      buckets = { 64, 256 },
      slots = { { species = "PIDGEY", level = 2 }, { species = "RATTATA", level = 3 } },
    } },
  },
  townMap = { locations = { ROUTE_1 = { name = "ROUTE 1", x = 2, y = 10 } } },
  pokemon = { PIDGEY = { name = "PIDGEY" }, RATTATA = { name = "RATTATA" } },
  constants = { encounterBuckets = { 128, 256 } },
})
eq(overridden[1].sources[1].methods.land.species[1].levels[1].conditionalOdds, 0.25,
  "map-specific encounter buckets override the global defaults")

-- mapSummary: the per-map acquisition summary behind the walking HUD
local hudData = {
  encounters = {
    ROUTE_22 = {
      grass = { rate = 128, slots = {
        { species = "MANKEY", level = 3 }, { species = "MANKEY", level = 5 },
        { species = "SPEAROW", level = 3 },
      } },
      water = { rate = 64, slots = { { species = "POLIWAG", level = 5 } } },
    },
    ROUTE_1 = { grass = { rate = 128, slots = { { species = "PIDGEY", level = 2 } } } },
    ROUTE_19 = { water = { rate = 64, slots = { { species = "TENTACOOL", level = 5 } } } },
    PALLET_TOWN = {},
    EMPTY_ROUTE = { grass = { rate = 0, slots = {} } },
  },
  townMap = { locations = {} },
  pokemon = {
    MANKEY = { name = "MANKEY" }, SPEAROW = { name = "SPEAROW" },
    POLIWAG = { name = "POLIWAG" }, PIDGEY = { name = "PIDGEY" },
    TENTACOOL = { name = "TENTACOOL" },
  },
  constants = { encounterBuckets = { 128, 256 } },
}
local hudSummary = model.mapSummary(hudData, "ROUTE_22")
eq(hudSummary.land.species[1].name, "MANKEY", "mapSummary exposes the land acquisition summary")
eq(hudSummary.land.species[1].minLevel, 3, "mapSummary preserves the land level range minimum")
eq(hudSummary.land.species[1].maxLevel, 5, "mapSummary preserves the land level range maximum")
eq(hudSummary.water.species[1].name, "POLIWAG", "mapSummary exposes the water acquisition summary")
local waterOnly = model.mapSummary(hudData, "ROUTE_19")
eq(waterOnly.water.species[1].name, "TENTACOOL", "water-only maps keep a water summary")
eq(waterOnly.land, nil, "water-only maps have no land summary")
eq(model.mapSummary(hudData, "PALLET_TOWN"), nil, "maps without slots yield no summary")
eq(model.mapSummary(hudData, "EMPTY_ROUTE"), nil, "zero-rate empty slots yield no summary")
eq(model.mapSummary(hudData, "SOME_UNKNOWN_MAP"), nil, "unknown maps yield no summary")
eq(model.mapSummary(hudData, nil), nil, "a nil map id yields no summary")
