local SCREENS = {
  map = "EncounterGuideMap",
  areas = "EncounterGuideAreas",
  area = "EncounterGuideArea",
  source = "EncounterGuideSource",
  method = "EncounterGuideMethod",
  species = "EncounterGuideSpecies",
}
local entryHud

return function(mod)
  mod.content.screens:register(SCREENS.map, {
    new = function(game)
      local areas = Model.buildAreas(guideData(game))
      local screen = MapScreen.new(mod, game, areas)
      if #screen.locations == 0 then return Screens.newAreas(mod, game) end
      return screen
    end,
  })
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
      label = "PKMN MAP",
      onSelect = function() mod.ui.push(game, SCREENS.map) end,
    })
  end)

  mod.hooks:wrap("render.hud", function(next, game, viewport)
    if next then next(game, viewport) end
    if not entryHud then entryHud = Hud.new(mod, game, {}) end
    entryHud:draw(viewport)
  end)

  local HUD_MODES = { "auto", "always", "off" }
  local HUD_SIZES = { "small", "medium", "large" }
  local function optionLabel(option, candidates, fallback)
    for _, candidate in ipairs(candidates) do
      if option == candidate then return candidate:upper() end
    end
    return fallback
  end
  local function cycleOption(options, key, candidates, dir)
    local current = options[key]
    local index = 1
    for i, candidate in ipairs(candidates) do
      if candidate == current then index = i break end
    end
    options[key] = candidates[((index - 1 + dir) % #candidates) + 1]
    return true
  end
  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    local out = next(game, rows)
    if type(out) ~= "table" then return out end
    out[#out + 1] = {
      id = "encounterGuideHud",
      label = "ENC. GUIDE HUD",
      value = function(g)
        return optionLabel(((g.save or {}).options or {}).encounterGuideHud, HUD_MODES, "AUTO")
      end,
      step = function(g, dir)
        local options = (g.save or {}).options
        if not options then return false end
        return cycleOption(options, "encounterGuideHud", HUD_MODES, dir)
      end,
    }
    out[#out + 1] = {
      id = "encounterGuideSize",
      label = "ENC. GUIDE SIZE",
      value = function(g)
        return optionLabel(((g.save or {}).options or {}).encounterGuideSize, HUD_SIZES, "SMALL")
      end,
      step = function(g, dir)
        local options = (g.save or {}).options
        if not options then return false end
        return cycleOption(options, "encounterGuideSize", HUD_SIZES, dir)
      end,
    }
    return out
  end)
end
