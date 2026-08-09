local Model = require("lib.model")

local base = "/home/illan/.local/share/pokemon-love2d/blue/data/generated/"
local function load(name)
  return assert(loadfile(base .. name .. ".lua"))()
end

local areas = Model.buildAreas({
  encounters = load("encounters"),
  townMap = load("field").townMap,
  pokemon = load("pokemon"),
  constants = load("constants"),
})

assert(#areas > 20, "the imported Blue cache must yield a populated Town Map guide")

local found = {}
for _, area in ipairs(areas) do
  for _, source in ipairs(area.sources) do
    if source.mapId == "MT_MOON_1F" or source.mapId == "MT_MOON_B1F" or source.mapId == "MT_MOON_B2F" then
      found[source.mapId] = source
    end
  end
end

assert(found.MT_MOON_1F and found.MT_MOON_B1F and found.MT_MOON_B2F,
  "all three imported Blue Mt. Moon floors must remain separate sources")
assert(found.MT_MOON_1F.label == "MT. MOON 1F", "first-floor label must be explicit")
assert(found.MT_MOON_B1F.label == "MT. MOON B1F", "basement label must be explicit")
assert(found.MT_MOON_1F.methods.land and #found.MT_MOON_1F.methods.land.species > 0,
  "the live 1F LAND table must be summarized")

print("BLUE CACHE: " .. #areas .. " areas; Mt. Moon has three separate encounter sources")
