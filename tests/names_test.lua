local names = require("lib.names")

local function eq(actual, expected, message)
  assert(actual == expected,
    (message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

eq(names.map("MT_MOON_1F"), "MT. MOON 1F", "Mt. Moon floor labels should use the game name")
eq(names.map("MT_MOON_B2F"), "MT. MOON B2F", "Mt. Moon basement labels should remain explicit")
eq(names.map("CERULEAN_CAVE_B1F"), "CERULEAN CAVE B1F", "generic dungeon floors remain readable")
eq(names.map("ROUTE_3"), "ROUTE 3", "route IDs should become human-readable")
eq(names.map("DIGLETTS_CAVE"), "DIGLETT's CAVE", "known punctuation should be restored")
