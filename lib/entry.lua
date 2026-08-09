local SCREENS = {
  map = "EncounterGuideMap",
  areas = "EncounterGuideAreas",
  area = "EncounterGuideArea",
  source = "EncounterGuideSource",
  method = "EncounterGuideMethod",
  species = "EncounterGuideSpecies",
}

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
      label = "ENCOUNTERS",
      onSelect = function() mod.ui.push(game, SCREENS.map) end,
    })
  end)
end
