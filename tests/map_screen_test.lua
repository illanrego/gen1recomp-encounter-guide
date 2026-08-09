local MapScreen = require("lib.map_screen")

local loaded, draws, labels, rectangles = {}, {}, {}, {}
local graphics = {
  newImage = function(path)
    loaded[#loaded + 1] = path
    return { path = path, getDimensions = function() return 32, 32 end }
  end,
  newQuad = function(...) return { ... } end,
  setColor = function() end,
  rectangle = function(mode, x, y, width, height)
    rectangles[#rectangles + 1] = { mode = mode, x = x, y = y, width = width, height = height }
  end,
  draw = function(image, quad, x, y)
    draws[#draws + 1] = { image = image, quad = quad, x = x, y = y }
  end,
}
local font = {
  draw = function(text, x, y) labels[#labels + 1] = { text = text, x = x, y = y } end,
}
local game = {
  data = { field = { townMap = { background = {
    map = { 0, 1, 2, 3 },
    tiles = { path = "assets/generated/townmap/tiles.png" },
    cursor = { path = "assets/generated/townmap/cursor.png" },
  } } } },
}
local areas = {
  { name = "ROUTE 1", x = 3, y = 10, sources = { {} } },
  { name = "VIRIDIAN CITY", x = 3, y = 7, sources = { {} } },
  { name = "ROUTE 2", x = 5, y = 7, sources = { {} } },
}

local pushes = {}
local mod = {
  ui = {
    Font = font,
    push = function(_, id, ...)
      pushes[#pushes + 1] = { id = id, args = { ... } }
    end,
  },
}
local screen = MapScreen.new(mod, game, areas, { graphics = graphics, font = font })
screen:draw()

assert(loaded[1] == "assets/generated/townmap/tiles.png", "map screen must load the imported ROM's Town Map tiles")
assert(loaded[2] == "assets/generated/townmap/cursor.png", "map screen must load the imported ROM's Town Map cursor")
assert(#draws >= 4, "map screen must draw every tile in the imported Town Map background")
assert(labels[1] and labels[1].text == "ROUTE 1", "map banner must identify the selected encounter location")
local markerCount = 0
for _, rectangle in ipairs(rectangles) do
  if rectangle.mode == "fill" and rectangle.width == 4 and rectangle.height == 4 then markerCount = markerCount + 1 end
end
assert(markerCount == #areas, "map must visibly mark every encounter-bearing location")
assert(labels[2] and labels[2].text == "A:OPEN  SELECT:LIST", "map footer must explain its primary controls")

local pressed
local popped = false
game.input = { wasPressed = function(_, name) return pressed == name end }
game.stack = { pop = function() popped = true end }
pressed = "up"
screen:update(0)
assert(screen.selected == 2, "up must move to the nearest encounter location above")
pressed = "right"
screen:update(0)
assert(screen.selected == 3, "right must move to the nearest encounter location on the right")
pressed = "left"
screen:update(0)
assert(screen.selected == 2, "left must move back to the nearest encounter location")
pressed = "down"
screen:update(0)
assert(screen.selected == 1, "down must move to the nearest encounter location below")
pressed = "a"
screen:update(0)
assert(pushes[1] and pushes[1].id == "EncounterGuideArea", "A must open the selected location's exact sources")
assert(pushes[1].args[1] == areas[1], "A must preserve the selected grouped location")
pressed = "select"
screen:update(0)
assert(pushes[2] and pushes[2].id == "EncounterGuideAreas", "SELECT must open the complete location list fallback")
pressed = "b"
screen:update(0)
assert(popped, "B must return from the encounter map")

local currentLocationGame = {
  data = { field = { townMap = { locations = {
    VIRIDIAN_CITY = { name = "VIRIDIAN CITY", x = 3, y = 7 },
  } } } },
  overworld = { map = { id = "VIRIDIAN_CITY" } },
}
local currentLocationScreen = MapScreen.new(mod, currentLocationGame, areas, { graphics = graphics, font = font })
assert(currentLocationScreen.selected == 2, "map must initially focus the player's encounter-bearing location")
