local Model = require("lib.model")
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

return Screens
