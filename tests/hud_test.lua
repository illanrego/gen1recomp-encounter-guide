local Hud = require("lib.hud")

local function eq(actual, expected, message)
  assert(actual == expected,
    (message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function makeData()
  local forestSlots = {}
  for i = 1, 7 do forestSlots[#forestSlots + 1] = { species = "MON_" .. i, level = 3 } end
  return {
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
      ROUTE_23 = {
        grass = { rate = 128, slots = {
          { species = "A1", level = 3 }, { species = "A2", level = 3 },
          { species = "A3", level = 3 }, { species = "A4", level = 3 },
        } },
        water = { rate = 64, slots = {
          { species = "B1", level = 5 }, { species = "B2", level = 5 },
          { species = "B3", level = 5 },
        } },
      },
      VIRIDIAN_FOREST = { grass = { rate = 128, slots = forestSlots } },
      PALLET_TOWN = {},
    },
    field = { townMap = { locations = {} } },
    pokemon = {
      MANKEY = { name = "MANKEY" }, SPEAROW = { name = "SPEAROW" },
      POLIWAG = { name = "POLIWAG" }, PIDGEY = { name = "PIDGEY" },
      TENTACOOL = { name = "TENTACOOL" },
      A1 = { name = "A1" }, A2 = { name = "A2" }, A3 = { name = "A3" }, A4 = { name = "A4" },
      B1 = { name = "B1" }, B2 = { name = "B2" }, B3 = { name = "B3" },
    },
    constants = { encounterBuckets = { 128, 256 } },
    owned = { MANKEY = true },
  }
end

-- pure formatting: honest method labeling, exact level ranges, owned markers
local both = Hud.linesFor(makeData(), "ROUTE_22")
eq(both[1].text, "LAND", "maps with both methods label the land section")
eq(both[2].text, "MANKEY 3-5", "species lines show the exact level range")
eq(both[2].owned, true, "owned species are marked on the land section")
eq(both[3].text, "SPEAROW 3", "single-level species show one level")
eq(both[3].owned, false, "unowned species are not marked")
eq(both[4].text, "WATER", "maps with both methods label the water section")
eq(both[5].text, "POLIWAG 5", "water species follow their header")
eq(both[5].owned, false, "unowned water species are not marked")

local landOnly = Hud.linesFor(makeData(), "ROUTE_1")
eq(landOnly[1].text, "PIDGEY 2", "land-only maps skip the LAND header")
eq(landOnly[1].owned, false, "unowned species stay unmarked")

local waterOnly = Hud.linesFor(makeData(), "ROUTE_19")
eq(waterOnly[1].text, "WATER", "water-only maps must label the method")
eq(waterOnly[2].text, "TENTACOOL 5", "water-only species follow their header")

local overflow = Hud.linesFor(makeData(), "VIRIDIAN_FOREST")
eq(#overflow, 6, "the HUD box is capped at six lines")
eq(overflow[6].text, "+2 MORE", "hidden species are counted honestly")

local dangling = Hud.linesFor(makeData(), "ROUTE_23")
eq(#dangling, 6, "truncated mixed maps keep six lines")
eq(dangling[6].text, "+3 MORE", "a cut section counts its hidden species")
eq(dangling[5].text, "A4 3", "the last shown species is the final land species")
for _, record in ipairs(dangling) do
  assert(record.text ~= "WATER", "a section header with no visible species must never be shown")
end

-- method filtering: the AUTO tile mode shows only the matching table
local landOnlyFiltered = Hud.linesFor(makeData(), "ROUTE_22", nil, "land")
eq(#landOnlyFiltered, 2, "land filtering keeps only land species")
eq(landOnlyFiltered[1].text, "MANKEY 3-5", "land filtering drops the LAND header")
eq(landOnlyFiltered[1].owned, true, "land filtering keeps owned markers")
eq(landOnlyFiltered[2].text, "SPEAROW 3", "land filtering keeps every land species")
local waterFiltered = Hud.linesFor(makeData(), "ROUTE_22", nil, "water")
eq(#waterFiltered, 1, "water filtering keeps only water species")
eq(waterFiltered[1].text, "POLIWAG 5", "water filtering drops the WATER header")
eq(Hud.linesFor(makeData(), "ROUTE_1", nil, "water"), nil, "a land-only map filtered for water yields nothing")

eq(Hud.linesFor(makeData(), "PALLET_TOWN"), nil, "maps without encounters yield no HUD lines")
eq(Hud.linesFor(makeData(), "UNKNOWN_MAP"), nil, "unknown maps yield no HUD lines")
eq(Hud.linesFor(makeData(), nil), nil, "a nil map id yields no HUD lines")

-- state guard: the HUD only exists while the overworld is the top state
local function makeGame(mapId)
  local data = makeData()
  return {
    data = data,
    overworld = { map = { id = mapId }, player = { cellX = 5, cellY = 5 } },
    stack = { states = { { isOverworld = true, map = { id = mapId } } } },
    save = { options = {}, pokedex = { owned = data.owned } },
  }
end
local function makeModeGame(mapId, mode)
  local game = makeGame(mapId)
  game.save.options.encounterGuideHud = mode
  return game
end
eq(Hud.activeMapId(makeGame("ROUTE_22")), "ROUTE_22", "walking exposes the current map id")
local menuGame = makeGame("ROUTE_22")
menuGame.stack.states = { { isOverworld = true }, { isOpaque = true } }
eq(Hud.activeMapId(menuGame), nil, "a menu on top must hide the HUD")
local battleGame = makeGame("ROUTE_22")
battleGame.stack.states = { { isOverworld = true }, { isBattle = true } }
eq(Hud.activeMapId(battleGame), nil, "a battle on top must hide the HUD")
eq(Hud.activeMapId({}), nil, "no stack means no HUD")
eq(Hud.activeMapId({ stack = { states = {} } }), nil, "an empty stack means no HUD")

-- rendering: window-anchored top-right box, transform isolated, color restored
local rectangles, labels, transforms, colors, circles = {}, {}, {}, {}, {}
local graphics = {
  push = function(mode) transforms[#transforms + 1] = { "push", mode } end,
  pop = function(mode) transforms[#transforms + 1] = { "pop", mode } end,
  origin = function() transforms[#transforms + 1] = { "origin" } end,
  translate = function(x, y) transforms[#transforms + 1] = { "translate", x, y } end,
  scale = function(sx, sy) transforms[#transforms + 1] = { "scale", sx, sy } end,
  setColor = function(r, g, b, a) colors[#colors + 1] = { r, g, b, a } end,
  rectangle = function(mode, x, y, w, h) rectangles[#rectangles + 1] = { mode, x, y, w, h } end,
  circle = function(mode, x, y, radius) circles[#circles + 1] = { mode, x, y, radius } end,
}
local font = {
  draw = function(text, x, y) labels[#labels + 1] = { text = text, x = x, y = y } end,
  width = function(text) return #text * 8 end,
}
local mod = { ui = { Font = font } }
local viewport = { gameX = 8, gameY = 16, gameWidth = 160, gameHeight = 144 }
local function window() return 176, 176 end

local hud = Hud.new(mod, makeModeGame("ROUTE_1", "always"), {
  graphics = graphics, font = font, window = window,
})
hud:draw(viewport)
eq(transforms[1][1], "push", "the HUD must isolate its transform")
eq(transforms[1][2], "all", "the HUD must push the full graphics state")
eq(transforms[2][1], "origin", "the HUD must reset the transform like the touch overlay")
eq(#labels, 1, "one species line is drawn")
eq(labels[1].text, "PIDGEY 2", "the drawn line is the formatted species")
eq(labels[1].y, 4, "the first line sits below the box top padding")
local boxW = font.width("PIDGEY 2") + 4
eq(labels[1].x, 176 - boxW - 2 + 2, "text is drawn inside the top-right box")
local fill = rectangles[1]
eq(fill[1], "fill", "the HUD box is a filled panel")
eq(fill[2], 176 - boxW - 2, "the box hugs the window's top-right edge")
eq(fill[3], 2, "the box sits 2px from the top of the window")
local lastTransform = transforms[#transforms]
eq(lastTransform[1], "pop", "the HUD pops its transform after drawing")
eq(lastTransform[2], "all", "the HUD restores the full graphics state")
local lastColor = colors[#colors]
eq(lastColor[1], 1, "the HUD restores the default color (r)")
eq(lastColor[2], 1, "the HUD restores the default color (g)")
eq(lastColor[3], 1, "the HUD restores the default color (b)")

-- owned species draw the Pokédex ball after their name, like the ListMenu
local ownedHud = Hud.new(mod, makeModeGame("ROUTE_22", "always"), {
  graphics = graphics, font = font, window = window,
})
ownedHud:draw(viewport)
local mankeyLabel
for _, label in ipairs(labels) do
  if label.text == "MANKEY 3-5" then mankeyLabel = label end
end
assert(mankeyLabel, "the owned species line is drawn")
local ownedBoxW = 80 + 15 + 4 -- "MANKEY 3-5" + ball space + padding
local mankeyX = 176 - ownedBoxW - 2 + 2
eq(mankeyLabel.x, mankeyX, "owned lines share the box that reserves ball space")
local ball = circles[1]
eq(ball[1], "fill", "the owned ball is a filled circle")
eq(ball[2], mankeyX + 80 + 8 + 3, "the ball sits one blank glyph after the name")
eq(ball[3], mankeyLabel.y + 3, "the ball aligns with the text row")
eq(ball[4], 3.5, "the ball matches the ListMenu owned-ball size")

-- caching: one summary per map/mode key, recomputed only on change
local calls = 0
local cachedHud = Hud.new(mod, makeModeGame("ROUTE_1", "always"), {
  graphics = graphics, font = font, window = window,
  summarize = function(data, mapId)
    calls = calls + 1
    if mapId == "ROUTE_1" then
      return { land = { species = { { speciesId = "PIDGEY", name = "PIDGEY", minLevel = 2, maxLevel = 2 } } } }
    end
    return { land = { species = { { speciesId = "CATERPIE", name = "CATERPIE", minLevel = 3, maxLevel = 3 } } } }
  end,
})
cachedHud:draw(viewport)
cachedHud:draw(viewport)
eq(calls, 1, "the HUD caches the current map's summary")
cachedHud.game.overworld.map.id = "VIRIDIAN_FOREST"
cachedHud.game.stack.states[1].map.id = "VIRIDIAN_FOREST"
cachedHud:draw(viewport)
eq(calls, 2, "the HUD recomputes when the map changes")

-- modes: AUTO (tile-based), ALWAYS, OFF; the key cycles and persists
eq(Hud.new(mod, makeGame("ROUTE_1"), { graphics = graphics, font = font, window = window }):currentMode(),
  "auto", "the default mode is AUTO")
eq(Hud.new(mod, makeModeGame("ROUTE_1", "always"), { graphics = graphics, font = font, window = window }):currentMode(),
  "always", "ALWAYS is honored from save options")
eq(Hud.new(mod, makeModeGame("ROUTE_1", "off"), { graphics = graphics, font = font, window = window }):currentMode(),
  "off", "OFF is honored from save options")
eq(Hud.new(mod, makeModeGame("ROUTE_1", "bogus"), { graphics = graphics, font = font, window = window }):currentMode(),
  "auto", "unknown modes fall back to AUTO")

local before = #labels
local autoHud = Hud.new(mod, makeGame("ROUTE_1"), {
  graphics = graphics, font = font, window = window,
  tile = function() return "land" end,
})
autoHud:draw(viewport)
assert(#labels == before + 1 and labels[#labels].text == "PIDGEY 2",
  "AUTO mode shows the land table while standing on grass")

local waterAutoHud = Hud.new(mod, makeGame("ROUTE_22"), {
  graphics = graphics, font = font, window = window,
  tile = function() return "water" end,
})
waterAutoHud:draw(viewport)
local sawWater = false
for i = before + 1, #labels do
  if labels[i].text == "POLIWAG 5" then sawWater = true end
  assert(labels[i].text ~= "MANKEY 3-5", "AUTO water mode must not show the land table")
end
assert(sawWater, "AUTO mode shows the water table while on water")

local noneHud = Hud.new(mod, makeGame("ROUTE_1"), {
  graphics = graphics, font = font, window = window,
  tile = function() return nil end,
})
noneHud:draw(viewport)
eq(#labels, before + 2, "AUTO mode hides the box on non-encounter tiles")

local offHud = Hud.new(mod, makeModeGame("ROUTE_1", "off"), {
  graphics = graphics, font = font, window = window,
  tile = function() return "land" end,
})
offHud:draw(viewport)
eq(#labels, before + 2, "OFF mode never draws")

local alwaysHud = Hud.new(mod, makeModeGame("ROUTE_22", "always"), {
  graphics = graphics, font = font, window = window,
  tile = function() return nil end,
})
alwaysHud:draw(viewport)
local sawAlwaysLand, sawAlwaysWater = false, false
for i = before + 1, #labels do
  if labels[i].text == "MANKEY 3-5" then sawAlwaysLand = true end
  if labels[i].text == "POLIWAG 5" then sawAlwaysWater = true end
end
assert(sawAlwaysLand and sawAlwaysWater, "ALWAYS mode shows both tables regardless of tile")

-- 'h' toggles AUTO -> ALWAYS -> OFF -> AUTO with edge detection
local pressed = false
local modeGame = makeGame("ROUTE_1")
local keyHud = Hud.new(mod, modeGame, {
  graphics = graphics, font = font, window = window,
  keyDown = function(key) return key == "h" and pressed end,
})
eq(keyHud:currentMode(), "auto", "the key test starts in AUTO")
pressed = true
keyHud:draw(viewport)
eq(keyHud:currentMode(), "always", "h cycles AUTO -> ALWAYS")
eq(modeGame.save.options.encounterGuideHud, "always", "the key persists the mode to save.options")
keyHud:draw(viewport)
eq(keyHud:currentMode(), "always", "a held key must not repeat-cycle")
pressed = false
keyHud:draw(viewport)
pressed = true
keyHud:draw(viewport)
eq(keyHud:currentMode(), "off", "h cycles ALWAYS -> OFF")
pressed = false
keyHud:draw(viewport)
pressed = true
keyHud:draw(viewport)
eq(keyHud:currentMode(), "auto", "h cycles OFF -> AUTO")

-- empty and hidden states draw nothing
local emptyBefore = #labels
local emptyHud = Hud.new(mod, makeGame("PALLET_TOWN"), { graphics = graphics, font = font, window = window })
emptyHud:draw(viewport)
eq(#labels, emptyBefore, "maps without encounters draw no HUD")
local noWorldHud = Hud.new(mod, menuGame, { graphics = graphics, font = font, window = window })
noWorldHud:draw(viewport)
eq(#labels, emptyBefore, "a menu on top draws no HUD")

-- sizes: SMALL is the default base geometry; MEDIUM and LARGE scale it
local function makeSizeGame(mapId, size)
  local game = makeGame(mapId)
  game.save.options.encounterGuideSize = size
  game.save.options.encounterGuideHud = "always"
  return game
end
local function lastScaleCall()
  local last
  for _, t in ipairs(transforms) do
    if t[1] == "scale" then last = t end
  end
  return last
end

eq(Hud.new(mod, makeGame("ROUTE_1"), { graphics = graphics, font = font, window = window }):size(),
  "small", "the default HUD size is SMALL")
eq(Hud.new(mod, makeSizeGame("ROUTE_1", "bogus"), { graphics = graphics, font = font, window = window }):size(),
  "small", "unknown sizes fall back to SMALL")
eq(Hud.new(mod, makeSizeGame("ROUTE_1", "medium"), { graphics = graphics, font = font, window = window }):size(),
  "medium", "MEDIUM is honored from save options")
eq(Hud.new(mod, makeSizeGame("ROUTE_1", "large"), { graphics = graphics, font = font, window = window }):size(),
  "large", "LARGE is honored from save options")

local mediumHud = Hud.new(mod, makeSizeGame("ROUTE_1", "medium"), {
  graphics = graphics, font = font, window = window,
})
local mediumRectBase = #rectangles
mediumHud:draw(viewport)
local mediumScale = lastScaleCall()
eq(mediumScale[2], 1.5, "MEDIUM scales the box 1.5x horizontally")
eq(mediumScale[3], 1.5, "MEDIUM scales the box 1.5x vertically")
local mediumFill = rectangles[mediumRectBase + 1]
local baseBoxW = font.width("PIDGEY 2") + 4
eq(mediumFill[2], 176 / 1.5 - baseBoxW - 2, "MEDIUM anchors the box to the window's top-right")

local largeHud = Hud.new(mod, makeSizeGame("ROUTE_1", "large"), {
  graphics = graphics, font = font, window = window,
})
local largeRectBase = #rectangles
largeHud:draw(viewport)
local largeScale = lastScaleCall()
eq(largeScale[2], 2, "LARGE scales the box 2x horizontally")
eq(largeScale[3], 2, "LARGE scales the box 2x vertically")
local largeFill = rectangles[largeRectBase + 1]
eq(largeFill[2], 176 / 2 - baseBoxW - 2, "LARGE anchors the box to the window's top-right")
