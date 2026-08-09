local entry = assert(loadfile(os.getenv("ENCOUNTER_GUIDE_ROOT") .. "/main.lua"))

local registeredScreens, wrappedHook = {}, nil
local mod = {
  content = { screens = { register = function(_, id, definition)
    registeredScreens[id] = definition
  end } },
  hooks = { wrap = function(_, hook, callback)
    wrappedHook = { hook = hook, callback = callback }
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
assert(wrappedHook and wrappedHook.hook == "ui.start_menu.items", "main must extend the START menu through its public hook")

local game = {}
local output = wrappedHook.callback(function(_, items) return items end, game, {
  { label = "ITEM" }, { label = "SAVE" },
})
assert(output[2].label == "ENCOUNTERS", "ENCOUNTERS must appear before SAVE")
assert(output[3].label == "SAVE", "the existing SAVE entry must be preserved")
output[2].onSelect()
assert(game.pushedScreen == "EncounterGuideMap", "ENCOUNTERS must open the Kanto encounter map")
