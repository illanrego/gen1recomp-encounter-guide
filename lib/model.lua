local Names = require("lib.names")
local Model = {}

local function hasSlots(group)
  return type(group) == "table"
    and type(group.slots) == "table"
    and #group.slots > 0
    and (group.rate or 0) > 0
end

local function floorKey(mapId)
  local floor = mapId:match("_(%d+)F$")
  if floor then return tonumber(floor) end
  local basement = mapId:match("_B(%d+)F$")
  if basement then return 100 + tonumber(basement) end
  return 50
end

function Model.summarizeMethod(method, pokemon, buckets)
  local rate = method.rate or 0
  local total = (buckets and buckets[#buckets]) or 256
  if total <= 0 then total = 256 end
  local bySpecies, species = {}, {}

  for index, slot in ipairs(method.slots or {}) do
    local previous = (buckets and buckets[index - 1]) or ((index - 1) * total / #(method.slots or {}))
    local cumulative = (buckets and buckets[index]) or (index * total / #(method.slots or {}))
    local conditionalOdds = math.max(0, cumulative - previous) / total
    local speciesId, level = slot.species, slot.level
    if speciesId and level then
      local row = bySpecies[speciesId]
      if not row then
        local info = (pokemon or {})[speciesId] or {}
        row = {
          speciesId = speciesId,
          name = info.name or speciesId,
          minLevel = level,
          maxLevel = level,
          levels = {},
          levelsByValue = {},
        }
        bySpecies[speciesId] = row
        species[#species + 1] = row
      end
      row.minLevel = math.min(row.minLevel, level)
      row.maxLevel = math.max(row.maxLevel, level)
      local levelRow = row.levelsByValue[level]
      if not levelRow then
        levelRow = { level = level, slotCount = 0, conditionalOdds = 0, perStepOdds = 0 }
        row.levelsByValue[level] = levelRow
        row.levels[#row.levels + 1] = levelRow
      end
      levelRow.slotCount = levelRow.slotCount + 1
      levelRow.conditionalOdds = levelRow.conditionalOdds + conditionalOdds
      levelRow.perStepOdds = levelRow.conditionalOdds * rate / 256
    end
  end

  for _, row in ipairs(species) do
    row.levelsByValue = nil
    table.sort(row.levels, function(a, b) return a.level < b.level end)
  end
  table.sort(species, function(a, b)
    if a.name ~= b.name then return a.name < b.name end
    return a.speciesId < b.speciesId
  end)
  return { rate = rate, species = species }
end

function Model.buildAreas(data)
  local areasByKey, areas = {}, {}
  local encounters = data.encounters or {}
  local locations = ((data.townMap or {}).locations) or {}

  for mapId, definition in pairs(encounters) do
    if hasSlots(definition.grass) or hasSlots(definition.water) then
      local location = locations[mapId]
      local areaName = location and location.name or "OTHER AREAS"
      local key = location
        and table.concat({ location.x or -1, location.y or -1, areaName }, ":")
        or "OTHER:" .. mapId
      local area = areasByKey[key]
      if not area then
        area = { name = areaName, x = location and location.x, y = location and location.y, sources = {} }
        areasByKey[key] = area
        areas[#areas + 1] = area
      end
      local methods = {}
      if hasSlots(definition.grass) then
        methods.land = Model.summarizeMethod(definition.grass, data.pokemon,
          definition.grass.buckets or (data.constants or {}).encounterBuckets)
      end
      if hasSlots(definition.water) then
        methods.water = Model.summarizeMethod(definition.water, data.pokemon,
          definition.water.buckets or (data.constants or {}).encounterBuckets)
      end
      area.sources[#area.sources + 1] = {
        mapId = mapId,
        label = Names.map(mapId),
        encounters = definition,
        methods = methods,
      }
    end
  end

  for _, area in ipairs(areas) do
    table.sort(area.sources, function(a, b)
      local aFloor, bFloor = floorKey(a.mapId), floorKey(b.mapId)
      if aFloor ~= bFloor then return aFloor < bFloor end
      return a.mapId < b.mapId
    end)
  end
  table.sort(areas, function(a, b)
    if a.y and b.y and a.y ~= b.y then return a.y < b.y end
    if a.x and b.x and a.x ~= b.x then return a.x < b.x end
    return a.name < b.name
  end)

  return areas
end

return Model
