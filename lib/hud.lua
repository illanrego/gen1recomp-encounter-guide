local Model = require("lib.model")
local Hud = {}
Hud.__index = Hud

local MAX_LINES = 6

local function isHeader(line)
  return line == "LAND" or line == "WATER"
end

local function levelRange(species)
  if species.minLevel == species.maxLevel then return tostring(species.minLevel) end
  return species.minLevel .. "-" .. species.maxLevel
end

local function speciesLines(summary)
  local lines = {}
  for _, species in ipairs((summary or {}).species or {}) do
    lines[#lines + 1] = species.name .. " " .. levelRange(species)
  end
  return lines
end

-- Pure formatting: honest LAND/WATER labels, exact level ranges, capped box.
function Hud.linesFor(data, mapId, summarize)
  local summary = (summarize or Model.mapSummary)(data, mapId)
  if not summary then return nil end
  local lines = {}
  if summary.land and summary.water then
    lines[#lines + 1] = "LAND"
    for _, line in ipairs(speciesLines(summary.land)) do lines[#lines + 1] = line end
    lines[#lines + 1] = "WATER"
    for _, line in ipairs(speciesLines(summary.water)) do lines[#lines + 1] = line end
  elseif summary.water then
    lines[#lines + 1] = "WATER"
    for _, line in ipairs(speciesLines(summary.water)) do lines[#lines + 1] = line end
  else
    for _, line in ipairs(speciesLines(summary.land)) do lines[#lines + 1] = line end
  end
  if #lines > MAX_LINES then
    local kept = {}
    local index = 1
    while #kept < MAX_LINES - 1 and index <= #lines do
      local line = lines[index]
      if isHeader(line) and #kept + 3 > MAX_LINES then break end
      kept[#kept + 1] = line
      index = index + 1
    end
    local hidden = 0
    for j = index, #lines do
      if not isHeader(lines[j]) then hidden = hidden + 1 end
    end
    if hidden > 0 then kept[#kept + 1] = "+" .. hidden .. " MORE" end
    lines = kept
  end
  return lines
end

-- The HUD exists only while the overworld is the top state: walking and
-- dialogue yes; menus, battles, and the title screen no.
function Hud.activeMapId(game)
  local stack = game and game.stack
  local states = stack and stack.states
  local top = states and states[#states]
  if not (top and top.isOverworld) then return nil end
  local overworld = game and game.overworld
  return overworld and overworld.map and overworld.map.id
end

function Hud.new(mod, game, deps)
  deps = deps or {}
  local self = setmetatable({}, Hud)
  self.mod = mod
  self.game = game
  self.graphics = deps.graphics or love.graphics
  self.font = deps.font or mod.ui.Font
  self.window = deps.window or love.graphics.getDimensions
  self.summarize = deps.summarize
  self.cache = { mapId = nil, lines = nil }
  return self
end

function Hud:refresh()
  local mapId = Hud.activeMapId(self.game)
  if not mapId then
    self.cache.mapId, self.cache.lines = nil, nil
    return
  end
  if self.cache.mapId == mapId then return end
  local game = self.game
  local data = {
    encounters = (game.data or {}).encounters or {},
    townMap = ((game.data or {}).field or {}).townMap or {},
    pokemon = (game.data or {}).pokemon or {},
    constants = (game.data or {}).constants or {},
  }
  self.cache.mapId = mapId
  self.cache.lines = Hud.linesFor(data, mapId, self.summarize)
end

function Hud:draw(viewport)
  self:refresh()
  local lines = self.cache.lines
  if not lines or #lines == 0 then return end
  local ok, err = pcall(function()
    self:drawBox(lines)
  end)
  if not ok then
    -- the engine's hook runner also catches this; never crash the frame
  end
end

-- Screen-space overlay: reset the transform like the engine's own touch
-- overlay (a render pipeline such as a voxel mod can leave its camera
-- transform active at render.hud time) and anchor to the window's top-right.
function Hud:drawBox(lines)
  local graphics = self.graphics
  local font = self.font
  local maxWidth = 0
  for _, line in ipairs(lines) do
    local width = font.width(line)
    if width > maxWidth then maxWidth = width end
  end
  local boxWidth = maxWidth + 4
  local boxHeight = #lines * 8 + 4
  local windowWidth, windowHeight = self.window()
  graphics.push("all")
  graphics.origin()
  graphics.setColor(1, 1, 1, 1)
  graphics.rectangle("fill", windowWidth - boxWidth - 2, 2, boxWidth, boxHeight)
  graphics.setColor(0, 0, 0, 1)
  graphics.rectangle("line", windowWidth - boxWidth - 2 + 0.5, 2.5, boxWidth - 1, boxHeight - 1)
  for index, line in ipairs(lines) do
    font.draw(line, windowWidth - boxWidth - 2 + 2, 2 + 2 + (index - 1) * 8)
  end
  graphics.pop("all")
  graphics.setColor(1, 1, 1, 1)
end

return Hud
