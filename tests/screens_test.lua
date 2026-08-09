local Screens = require("lib.screens")

local pushes = {}
local mod = {
  ui = {
    ListMenu = { new = function(game, title, items, options)
      return { game = game, title = title, items = items, onChoose = options.onChoose, options = options }
    end },
    push = function(game, id, ...)
      pushes[#pushes + 1] = { id = id, args = { ... } }
    end,
  },
}

local game = {
  data = {
    encounters = {
      MT_MOON_1F = { grass = { rate = 10, slots = { { species = "ZUBAT", level = 8 }, { species = "ZUBAT", level = 10 } } } },
      MT_MOON_B1F = { grass = { rate = 10, slots = { { species = "GEODUDE", level = 10 } } } },
    },
    field = { townMap = { locations = {
      MT_MOON_1F = { name = "MT.MOON", x = 6, y = 2 },
      MT_MOON_B1F = { name = "MT.MOON", x = 6, y = 2 },
    } } },
    pokemon = { ZUBAT = { name = "ZUBAT" }, GEODUDE = { name = "GEODUDE" } },
    constants = { encounterBuckets = { 128, 256 } },
  },
}

local areasMenu = Screens.newAreas(mod, game)
assert(areasMenu.title == "ENCOUNTERS", "area browser needs an encounter-guide title")
assert(#areasMenu.items == 1 and areasMenu.items[1].label == "MT.MOON", "browser groups one Town Map marker")
areasMenu.onChoose(areasMenu.items[1])
assert(pushes[#pushes].id == "EncounterGuideArea", "area selection opens the source list")

local area = pushes[#pushes].args[1]
local areaMenu = Screens.newArea(mod, game, area)
assert(areaMenu.items[1].label == "-- MT. MOON 1F", "first floor remains visibly distinct")
assert(areaMenu.items[2].label == "-- MT. MOON B1F", "basement remains visibly distinct")
areaMenu.onChoose(areaMenu.items[1])
assert(pushes[#pushes].id == "EncounterGuideSource", "source selection opens encounter methods")

local source = pushes[#pushes].args[1]
local sourceMenu = Screens.newSource(mod, game, source)
assert(sourceMenu.items[1].label == "LAND", "the game grass table is presented as LAND")
sourceMenu.onChoose(sourceMenu.items[1])
assert(pushes[#pushes].id == "EncounterGuideMethod", "method selection opens its species list")

local methodName = pushes[#pushes].args[2]
assert(methodName == "land", "the method list retains the chosen method")
local methodMenu = Screens.newMethod(mod, game, source, methodName)
assert(methodMenu.items[1].label == "ZUBAT" and methodMenu.items[1].right == "Lv. 8-10",
  "method list keeps the truthful compact level range")
methodMenu.onChoose(methodMenu.items[1])
assert(pushes[#pushes].id == "EncounterGuideSpecies", "species selection opens exact odds")

local species = pushes[#pushes].args[3]
assert(species.name == "ZUBAT" and species.minLevel == 8 and species.maxLevel == 10,
  "species list carries the truthful level range")

local speciesMenu = Screens.newSpecies(mod, game, source, methodName, species)
assert(speciesMenu.title == "ZUBAT", "detail page identifies the selected species")
assert(speciesMenu.items[1].label == "Lv. 8" and speciesMenu.items[1].right == "1.95%",
  "detail page displays the exact per-step chance")
