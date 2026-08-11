local Model = require("lib.model")
local Hud = {}
Hud.__index = Hud

local MAX_LINES = 6
local MODES = { "auto", "always", "off" }
local SIZES = { small = 1, medium = 1.5, large = 2 }
local BALL_SPACE = 15 -- blank glyph (8) + gap (3) + half the ball (4)

local function isHeader(record)
  return record.text == "LAND" or record.text == "WATER"
end

local function levelRange(species)
  if species.minLevel == species.maxLevel then return tostring(species.minLevel) end
  return species.minLevel .. "-" .. species.maxLevel
end

local function speciesRecords(summary, owned)
  local records = {}
  for _, species in ipairs((summary or {}).species or {}) do
    records[#records + 1] = {
      text = species.name .. " " .. levelRange(species),
      owned = owned[species.speciesId] == true,
    }
  end
  return records
end

-- Pure formatting: honest LAND/WATER labels, exact level ranges, capped box.
-- method "land"|"water" filters to one table (the AUTO tile mode) and drops
-- the header; nil shows both with headers.
function Hud.linesFor(data, mapId, summarize, method)
  local summary = (summarize or Model.mapSummary)(data, mapId)
  if not summary then return nil end
  local owned = (data or {}).owned or {}
  local lines = {}
  if (method == nil or method == "land") and summary.land then
    if method == nil and summary.water then lines[#lines + 1] = { text = "LAND", owned = false } end
    for _, record in ipairs(speciesRecords(summary.land, owned)) do lines[#lines + 1] = record end
  end
  if (method == nil or method == "water") and summary.water then
    if method == nil then lines[#lines + 1] = { text = "WATER", owned = false } end
    for _, record in ipairs(speciesRecords(summary.water, owned)) do lines[#lines + 1] = record end
  end
  if #lines == 0 then return nil end
  if #lines > MAX_LINES then
    local kept = {}
    local index = 1
    while #kept < MAX_LINES - 1 and index <= #lines do
      local record = lines[index]
      if isHeader(record) and #kept + 3 > MAX_LINES then break end
      kept[#kept + 1] = record
      index = index + 1
    end
    local hidden = 0
    for j = index, #lines do
      if not isHeader(lines[j]) then hidden = hidden + 1 end
    end
    if hidden > 0 then kept[#kept + 1] = { text = "+" .. hidden .. " MORE", owned = false } end
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

-- Which encounter table the tile under the player offers, or nil.
-- Uses the live Map's own checks so it can never drift from the engine.
function Hud.tileAt(game, x, y)
  local overworld = game and game.overworld
  local map = overworld and overworld.map
  if not map or not map.isGrassCell or not map.isWaterCell then return nil end
  if map:isGrassCell(x, y) then return "land" end
  if map:isWaterCell(x, y) then return "water" end
  return nil
end

function Hud.new(mod, game, deps)
  deps = deps or {}
  local self = setmetatable({}, Hud)
  self.mod = mod
  self.game = game
  self.graphics = deps.graphics or love.graphics
  self.font = deps.font or mod.ui.Font
  self.window = deps.window or love.graphics.getDimensions
  self.tile = deps.tile
  self.keyDown = deps.keyDown
  self.summarize = deps.summarize
  self.cache = { key = nil, lines = nil }
  self.keyHeld = false
  return self
end

function Hud:currentMode()
  local options = (self.game and self.game.save and self.game.save.options) or {}
  local mode = options.encounterGuideHud
  for _, candidate in ipairs(MODES) do
    if mode == candidate then return mode end
  end
  return "auto"
end

function Hud:size()
  local options = (self.game and self.game.save and self.game.save.options) or {}
  local size = options.encounterGuideSize
  if SIZES[size] then return size end
  return "small"
end

function Hud:sizeFactor()
  return SIZES[self:size()] or 1
end

-- H cycles AUTO -> ALWAYS -> OFF with edge detection; the mode persists to
-- save.options so the options menu and the key stay in sync.
function Hud:handleToggle()
  local keyDown = self.keyDown or love.keyboard.isDown
  local held = keyDown ~= nil and keyDown("h") or false
  if held and not self.keyHeld then
    self.keyHeld = true
    local current = self:currentMode()
    local index = 1
    for i, candidate in ipairs(MODES) do
      if candidate == current then index = i break end
    end
    local nextMode = MODES[index % #MODES + 1]
    local options = (self.game.save or {}).options
    if options then options.encounterGuideHud = nextMode end
    self.cache.key = nil
  end
  if not held then self.keyHeld = false end
end

function Hud:tileAtPlayer()
  local overworld = (self.game or {}).overworld
  local player = overworld and overworld.player
  local x, y = player and player.cellX, player and player.cellY
  if not x or not y then return nil end
  return (self.tile or Hud.tileAt)(self.game, x, y)
end

function Hud:refresh()
  local mapId = Hud.activeMapId(self.game)
  if not mapId then
    self.cache.key, self.cache.lines = nil, nil
    return
  end
  local mode = self:currentMode()
  local method
  if mode == "off" then
    method = "none"
  elseif mode == "auto" then
    method = self:tileAtPlayer() or "none"
  end
  local key = tostring(mapId) .. ":" .. tostring(method or "both")
  if self.cache.key == key then return end
  local game = self.game
  local data = {
    encounters = (game.data or {}).encounters or {},
    townMap = ((game.data or {}).field or {}).townMap or {},
    pokemon = (game.data or {}).pokemon or {},
    constants = (game.data or {}).constants or {},
    owned = ((game.save or {}).pokedex or {}).owned or {},
  }
  self.cache.key = key
  if method == "none" then
    self.cache.lines = nil
    return
  end
  self.cache.lines = Hud.linesFor(data, mapId, self.summarize, method)
end

function Hud:draw(viewport)
  self:handleToggle()
  self:refresh()
  local lines = self.cache.lines
  if not lines or #lines == 0 then return end
  self:drawBox(lines)
end

-- Screen-space overlay: reset the transform like the engine's own touch
-- overlay (a render pipeline such as a voxel mod can leave its camera
-- transform active at render.hud time) and anchor to the window's top-right.
-- The SMALL geometry is the base unit; MEDIUM/LARGE scale the whole box.
function Hud:drawBox(lines)
  local graphics = self.graphics
  local font = self.font
  local maxWidth, anyOwned = 0, false
  for _, record in ipairs(lines) do
    local width = font.width(record.text)
    if width > maxWidth then maxWidth = width end
    if record.owned then anyOwned = true end
  end
  if anyOwned then maxWidth = maxWidth + BALL_SPACE end
  local boxWidth = maxWidth + 4
  local boxHeight = #lines * 8 + 4
  local windowWidth, windowHeight = self.window()
  local factor = self:sizeFactor()
  graphics.push("all")
  graphics.origin()
  graphics.scale(factor, factor)
  local originX = windowWidth / factor - boxWidth - 2
  local originY = 2
  graphics.setColor(1, 1, 1, 1)
  graphics.rectangle("fill", originX, originY, boxWidth, boxHeight)
  graphics.setColor(0, 0, 0, 1)
  graphics.rectangle("line", originX + 0.5, originY + 0.5, boxWidth - 1, boxHeight - 1)
  for index, record in ipairs(lines) do
    local x = originX + 2
    local y = originY + 2 + (index - 1) * 8
    font.draw(record.text, x, y)
    if record.owned then
      -- the same owned-ball marker the engine's ListMenu draws
      local bx = x + font.width(record.text) + 8 + 3
      local by = y + 3
      graphics.setColor(0, 0, 0, 1)
      graphics.circle("fill", bx, by, 3.5)
      graphics.setColor(1, 1, 1, 1)
      graphics.rectangle("fill", bx - 3.5, by - 0.5, 7, 1)
      graphics.circle("fill", bx, by, 1.2)
      graphics.setColor(0, 0, 0, 1)
    end
  end
  graphics.pop("all")
  graphics.setColor(1, 1, 1, 1)
end

return Hud
