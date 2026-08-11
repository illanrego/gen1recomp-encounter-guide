local root = assert(os.getenv("ENCOUNTER_GUIDE_ROOT"))
local definitions, wrappedHooks = {}, {}
local mod = {
  content = { screens = { register = function(_, id, definition)
    definitions[id] = definition
  end } },
  hooks = { wrap = function(_, hook, callback)
    wrappedHooks[hook] = callback
  end },
  ui = {
    ListMenu = { new = function(game, title, items, options)
      return { game = game, title = title, items = items, options = options }
    end },
    insertBefore = function(items) return items end,
    push = function() end,
  },
}

local entry = assert(loadfile(root .. "/main.lua"))()
entry(mod)

local game = {
  data = {
    encounters = {
      MT_MOON_1F = { grass = { rate = 10, slots = {
        { species = "ZUBAT", level = 8 },
        { species = "ZUBAT", level = 10 },
      } } },
    },
    field = { townMap = { locations = {
      MT_MOON_1F = { name = "MT.MOON", x = 6, y = 2 },
    } } },
    pokemon = { ZUBAT = { name = "ZUBAT" } },
    constants = { encounterBuckets = { 128, 256 } },
  },
}

package.loaded["lib.screens"] = nil
package.loaded["lib.map_screen"] = nil
local originalPath = package.path
package.path = "/nonexistent/?.lua;/nonexistent/?/init.lua"
local mapOk, mapResult = pcall(definitions.EncounterGuideMap.new, game)
assert(mapOk, "installed map factory must be self-contained: " .. tostring(mapResult))
assert(mapResult.locations and mapResult.locations[1] and mapResult.locations[1].name == "MT.MOON",
  "installed map factory must build encounter-bearing Town Map locations")
local ok, result = pcall(definitions.EncounterGuideAreas.new, game)
if ok then
  local area = result.items[1].value
  ok, result = pcall(definitions.EncounterGuideArea.new, game, area)
end
if ok then
  local source = result.items[1].value
  ok, result = pcall(definitions.EncounterGuideSource.new, game, source)
  if ok then
    local methodName = result.items[1].value
    ok, result = pcall(definitions.EncounterGuideMethod.new, game, source, methodName)
    if ok then
      local species = result.items[1].value
      ok, result = pcall(definitions.EncounterGuideSpecies.new, game, source, methodName, species)
    end
  end
end
package.path = originalPath

assert(ok, "installed screen factories must not depend on the project package.path: " .. tostring(result))
assert(result and result.title == "ZUBAT", "the package-safe factories must reach the exact species screen")

-- the walking HUD must also load and run in the installed context; a menu
-- state on top keeps the draw path from touching love.graphics in the runner
local hudNext = false
local hudOk, hudErr = pcall(wrappedHooks["render.hud"], function() hudNext = true end, {
  data = { encounters = {}, field = { townMap = { locations = {} } }, pokemon = {}, constants = {} },
  overworld = { map = { id = "ROUTE_1" } },
  stack = { states = { { isOverworld = true }, { isOpaque = true } } },
}, { gameX = 0, gameY = 0, gameWidth = 160, gameHeight = 144 })
assert(hudOk, "installed render.hud wrap must be self-contained: " .. tostring(hudErr))
assert(hudNext, "installed render.hud wrap must call through the hook chain")
