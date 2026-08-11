local MapScreen = {}
MapScreen.__index = MapScreen
MapScreen.isOpaque = true

local function loadBackground(graphics, game)
  local townMap = (((game or {}).data or {}).field or {}).townMap or {}
  local definition = townMap.background
  if not (definition and definition.map and definition.tiles and definition.tiles.path) then return nil end

  local ok, image = pcall(graphics.newImage, definition.tiles.path)
  if not ok then return nil end
  local width, height = image:getDimensions()
  local quads = {}
  for index = 0, (width / 8) * (height / 8) - 1 do
    quads[index] = graphics.newQuad(
      (index % (width / 8)) * 8,
      math.floor(index / (width / 8)) * 8,
      8, 8, width, height
    )
  end

  local cursor
  if definition.cursor and definition.cursor.path then
    local cursorOk, cursorImage = pcall(graphics.newImage, definition.cursor.path)
    if cursorOk then cursor = cursorImage end
  end
  return { image = image, quads = quads, map = definition.map, cursor = cursor }
end

function MapScreen.playerPosition(game, currentMapId)
  if not currentMapId then return nil end
  local townMap = (((game or {}).data or {}).field or {}).townMap or {}
  local location = (townMap.locations or {})[currentMapId]
  if location and location.x ~= nil and location.y ~= nil then
    return { x = location.x, y = location.y }
  end
  return nil
end

function MapScreen.new(mod, game, areas, deps)
  deps = deps or {}
  local self = setmetatable({}, MapScreen)
  self.mod = mod
  self.game = game
  self.graphics = deps.graphics or love.graphics
  self.font = deps.font or mod.ui.Font
  self.locations = {}
  for _, area in ipairs(areas or {}) do
    if area.x ~= nil and area.y ~= nil then self.locations[#self.locations + 1] = area end
  end
  self.selected = 1
  local currentMapId = game.overworld and game.overworld.map and game.overworld.map.id
  local townMap = (((game or {}).data or {}).field or {}).townMap or {}
  local current = currentMapId and (townMap.locations or {})[currentMapId]
  if current then
    for index, location in ipairs(self.locations) do
      if location.x == current.x and location.y == current.y then
        self.selected = index
        break
      end
    end
  end
  self.player = MapScreen.playerPosition(game, currentMapId)
  self.blink = 0
  self.background = loadBackground(self.graphics, game)
  return self
end

function MapScreen:move(dx, dy)
  local current = self.locations[self.selected]
  if not current then return end
  local best, bestScore
  for index, location in ipairs(self.locations) do
    if index ~= self.selected then
      local deltaX, deltaY = location.x - current.x, location.y - current.y
      local forward = deltaX * dx + deltaY * dy
      if forward > 0 then
        local sideways = math.abs(deltaX * dy) + math.abs(deltaY * dx)
        local score = forward + sideways * 3
        if not best or score < bestScore then
          best, bestScore = index, score
        end
      end
    end
  end
  if best then self.selected = best end
end

function MapScreen:update(dt)
  self.blink = (self.blink + 1) % 32
  local input = self.game.input
  if input:wasPressed("b") then
    self.game.stack:pop()
    return
  elseif input:wasPressed("select") then
    self.mod.ui.push(self.game, "EncounterGuideAreas")
    return
  elseif input:wasPressed("up") then self:move(0, -1)
  elseif input:wasPressed("down") then self:move(0, 1)
  elseif input:wasPressed("left") then self:move(-1, 0)
  elseif input:wasPressed("right") then self:move(1, 0)
  elseif input:wasPressed("a") then
    local location = self.locations[self.selected]
    if location then self.mod.ui.push(self.game, "EncounterGuideArea", location) end
  end
end

function MapScreen:draw()
  local graphics = self.graphics
  graphics.setColor(1, 1, 1, 1)
  graphics.rectangle("fill", 0, 0, 160, 144)

  if self.background then
    for index, tile in ipairs(self.background.map) do
      local column = (index - 1) % 20
      local row = math.floor((index - 1) / 20)
      graphics.draw(self.background.image, self.background.quads[tile], column * 8, row * 8)
    end
  end

  local location = self.locations[self.selected]
  graphics.setColor(0, 0, 0, 1)
  for _, marker in ipairs(self.locations) do
    local markerX, markerY = marker.x * 8 + 16, marker.y * 8 + 8
    graphics.rectangle("fill", markerX + 2, markerY + 2, 4, 4)
  end

  if self.player and self.blink < 16 then
    local playerX, playerY = self.player.x * 8 + 16, self.player.y * 8 + 8
    graphics.setColor(0, 0, 0, 1)
    graphics.rectangle("fill", playerX + 1, playerY + 1, 6, 6)
    graphics.setColor(1, 1, 1, 1)
    graphics.rectangle("fill", playerX + 2, playerY + 2, 4, 4)
  end

  if location then
    local x, y = location.x * 8 + 16, location.y * 8 + 8
    if self.background and self.background.cursor then
      graphics.draw(self.background.cursor, x - 4, y - 4)
    else
      graphics.setColor(0, 0, 0, 1)
      graphics.rectangle("line", x + 0.5, y + 0.5, 7, 7)
    end
    graphics.setColor(1, 1, 1, 1)
    graphics.rectangle("fill", 0, 0, 160, 8)
    graphics.setColor(0, 0, 0, 1)
    self.font.draw(location.name, 8, 0)
  end
  graphics.setColor(1, 1, 1, 1)
  graphics.rectangle("fill", 0, 136, 160, 8)
  graphics.setColor(0, 0, 0, 1)
  self.font.draw("A:OPEN  SELECT:LIST", 4, 136)
  graphics.setColor(1, 1, 1, 1)
end

return MapScreen
