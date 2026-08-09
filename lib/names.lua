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

return Names
