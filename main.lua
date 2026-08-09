-- Self-contained release entry: installed mods do not extend Lua package.path.

local Names = {}

local overrides = {
  MT_MOON = "MT. MOON",
  DIGLETTS_CAVE = "DIGLETT's CAVE",
  POKEMON_TOWER = "POKéMON TOWER",
  POKEMON_MANSION = "POKéMON MANSION",
  POKEMON_LEAGUE = "POKéMON LEAGUE",
}

function Names.map(mapId)
  local base, suffix = mapId:match("^(.-)(_B?%d+F)$")
  if base then
    return (overrides[base] or base:gsub("_", " ")) .. suffix:gsub("_", " ")
  end
  return overrides[mapId] or mapId:gsub("_", " ")
end

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

local Screens = {}

local function guideData(game)
  local data = (game and game.data) or {}
  return {
    encounters = data.encounters or {},
    townMap = (data.field or {}).townMap or {},
    pokemon = data.pokemon or {},
    constants = data.constants or {},
  }
end

local function levelRange(species)
  if species.minLevel == species.maxLevel then return "Lv. " .. species.minLevel end
  return "Lv. " .. species.minLevel .. "-" .. species.maxLevel
end

local function percent(value)
  return string.format("%.2f%%", (value or 0) * 100)
end

function Screens.newAreas(mod, game)
  local areas = Model.buildAreas(guideData(game))
  local items = {}
  for _, area in ipairs(areas) do
    items[#items + 1] = {
      label = area.name,
      right = #area.sources .. " MAPS",
      value = area,
    }
  end
  return mod.ui.ListMenu.new(game, "ENCOUNTERS", items, {
    pageJump = true,
    onChoose = function(item)
      mod.ui.push(game, "EncounterGuideArea", item.value)
    end,
  })
end

function Screens.newArea(mod, game, area)
  local items = {}
  for _, source in ipairs((area or {}).sources or {}) do
    local methods = {}
    if source.methods.land then methods[#methods + 1] = "LAND" end
    if source.methods.water then methods[#methods + 1] = "WATER" end
    items[#items + 1] = {
      label = "-- " .. source.label,
      right = table.concat(methods, "/"),
      value = source,
    }
  end
  return mod.ui.ListMenu.new(game, (area or {}).name or "AREA", items, {
    pageJump = true,
    onChoose = function(item)
      mod.ui.push(game, "EncounterGuideSource", item.value)
    end,
  })
end

function Screens.newSource(mod, game, source)
  local items = {}
  for _, row in ipairs({ { key = "land", label = "LAND" }, { key = "water", label = "WATER" } }) do
    local summary = source and source.methods and source.methods[row.key]
    if summary then
      items[#items + 1] = {
        label = row.label,
        right = summary.rate .. "/256",
        value = row.key,
      }
    end
  end
  return mod.ui.ListMenu.new(game, (source and source.label) or "SOURCE", items, {
    onChoose = function(item)
      mod.ui.push(game, "EncounterGuideMethod", source, item.value)
    end,
  })
end

function Screens.newMethod(mod, game, source, methodName)
  local summary = source and source.methods and source.methods[methodName] or { species = {} }
  local items = {}
  for _, species in ipairs(summary.species or {}) do
    items[#items + 1] = {
      label = species.name,
      right = levelRange(species),
      value = species,
    }
  end
  local title = ((source and source.label) or "SOURCE") .. " " .. (methodName == "water" and "WATER" or "LAND")
  return mod.ui.ListMenu.new(game, title, items, {
    pageJump = true,
    onChoose = function(item)
      mod.ui.push(game, "EncounterGuideSpecies", source, methodName, item.value)
    end,
  })
end

function Screens.newSpecies(mod, game, source, methodName, species)
  local items = {}
  for _, level in ipairs((species or {}).levels or {}) do
    items[#items + 1] = {
      label = "Lv. " .. level.level,
      right = percent(level.perStepOdds),
      value = level,
    }
  end
  return mod.ui.ListMenu.new(game, (species and species.name) or "POKéMON", items, {
    footer = ((source and source.label) or "SOURCE") .. " " .. (methodName == "water" and "WATER" or "LAND"),
  })
end

local SCREENS = {
  areas = "EncounterGuideAreas",
  area = "EncounterGuideArea",
  source = "EncounterGuideSource",
  method = "EncounterGuideMethod",
  species = "EncounterGuideSpecies",
}

return function(mod)
  mod.content.screens:register(SCREENS.areas, {
    new = function(game)
      return Screens.newAreas(mod, game)
    end,
  })
  mod.content.screens:register(SCREENS.area, {
    new = function(game, area)
      return Screens.newArea(mod, game, area)
    end,
  })
  mod.content.screens:register(SCREENS.source, {
    new = function(game, source)
      return Screens.newSource(mod, game, source)
    end,
  })
  mod.content.screens:register(SCREENS.method, {
    new = function(game, source, methodName)
      return Screens.newMethod(mod, game, source, methodName)
    end,
  })
  mod.content.screens:register(SCREENS.species, {
    new = function(game, source, methodName, species)
      return Screens.newSpecies(mod, game, source, methodName, species)
    end,
  })

  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out = next(game, items)
    if type(out) ~= "table" then return out end
    return mod.ui.insertBefore(out, "SAVE", {
      label = "ENCOUNTERS",
      onSelect = function() mod.ui.push(game, SCREENS.areas) end,
    })
  end)
end
