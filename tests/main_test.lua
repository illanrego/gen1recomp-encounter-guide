local entry = assert(loadfile(os.getenv("ENCOUNTER_GUIDE_ROOT") .. "/main.lua"))

local registeredScreens, wrappedHooks = {}, {}
local mod = {
  content = { screens = { register = function(_, id, definition)
    registeredScreens[id] = definition
  end } },
  hooks = { wrap = function(_, hook, callback)
    wrappedHooks[hook] = callback
  end },
  ui = {
    insertBefore = function(items, label, item)
      for index, row in ipairs(items) do
        if row.label == label then table.insert(items, index, item); return items end
      end
      table.insert(items, item)
      return items
    end,
    push = function(game, id) game.pushedScreen = id end,
  },
}

entry()(mod)
assert(registeredScreens.EncounterGuideMap, "main must register the Kanto encounter map screen")
assert(registeredScreens.EncounterGuideAreas, "main must preserve the list fallback screen")
assert(registeredScreens.EncounterGuideArea, "main must register the selected-area screen")
assert(registeredScreens.EncounterGuideSource, "main must register the source/method screen")
assert(registeredScreens.EncounterGuideMethod, "main must register the method species-list screen")
assert(registeredScreens.EncounterGuideSpecies, "main must register the exact species screen")
assert(wrappedHooks["ui.start_menu.items"], "main must extend the START menu through its public hook")

local game = {}
local output = wrappedHooks["ui.start_menu.items"](function(_, items) return items end, game, {
  { label = "ITEM" }, { label = "SAVE" },
})
assert(output[2].label == "PKMN MAP", "PKMN MAP must appear before SAVE")
assert(output[3].label == "SAVE", "the existing SAVE entry must be preserved")
output[2].onSelect()
assert(game.pushedScreen == "EncounterGuideMap", "PKMN MAP must open the Kanto encounter map")

assert(wrappedHooks["render.hud"], "main must wrap the render.hud hook for the walking HUD")
local nextCalled = false
local hudGame = {
  data = {
    encounters = { ROUTE_1 = { grass = { rate = 128, slots = { { species = "PIDGEY", level = 2 } } } } },
    field = { townMap = { locations = {} } },
    pokemon = { PIDGEY = { name = "PIDGEY" } },
    constants = { encounterBuckets = { 128, 256 } },
  },
  overworld = { map = { id = "ROUTE_1" } },
  stack = { states = { { isOverworld = true, map = { id = "ROUTE_1" } }, { isOpaque = true } } },
  save = { options = {} },
}
wrappedHooks["render.hud"](function() nextCalled = true end, hudGame,
  { gameX = 0, gameY = 0, gameWidth = 160, gameHeight = 144 })
assert(nextCalled, "the render.hud wrap must preserve the hook chain")
assert(hudGame.data.encounters.ROUTE_1.grass.slots[1].level == 2, "the render.hud wrap must not mutate game data")

assert(wrappedHooks["ui.options.rows"], "main must extend the options menu for the HUD mode")
local rowsOut = wrappedHooks["ui.options.rows"](function(_, rows) return rows end, hudGame, {
  { id = "tilt", label = "TILT" },
})
local hudRow
for _, row in ipairs(rowsOut) do
  if row.id == "encounterGuideHud" then hudRow = row end
end
assert(hudRow, "the options menu gains an Encounter Guide HUD row")
assert(hudRow.label == "ENC. GUIDE HUD", "the HUD row carries a readable label")
assert(hudRow.value(hudGame) == "AUTO", "the HUD row shows the current mode")
assert(hudRow.step(hudGame, 1) == true, "stepping right must apply")
assert(hudRow.value(hudGame) == "ALWAYS", "stepping right cycles AUTO -> ALWAYS")
assert(hudRow.step(hudGame, 1) == true and hudRow.value(hudGame) == "OFF", "stepping right cycles ALWAYS -> OFF")
assert(hudRow.step(hudGame, -1) == true and hudRow.value(hudGame) == "ALWAYS", "stepping left cycles OFF -> ALWAYS")
