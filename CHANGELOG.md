# Changelog

## 0.4.0 — 2026-08-11

- Adds a walking HUD: while you're on a map with wild encounters, a small top-right panel lists the LAND and WATER species with their exact level ranges, cached per map.
- The HUD only appears during overworld play — never over menus, battles, or the title screen.

## 0.3.0 — 2026-08-11

- Renames the START menu row to PKMN MAP, matching the game's own battle-menu abbreviation.
- Highlights the player's current location on the Kanto map with a blinking white marker, even where that spot has no wild encounters.

## 0.2.0 — 2026-08-09

- Opens ENCOUNTERS on the imported ROM's Kanto Town Map.
- Lets the D-pad move only between encounter-bearing markers and A open the exact source-map list.
- Marks every available encounter location and starts near the player's current map marker.
- Adds SELECT as a complete list fallback, preserving unmapped encounter sources.
- Adds package-safe map-screen, navigation, controls, and ROM-asset tests.

## 0.1.1 — 2026-08-09

- Fixes the ENCOUNTERS screen crash in installed ZIPs.
- Bundles runtime code into the mod entry file because installed mods do not extend Lua's module search path.
- Adds a package-context regression test that opens every Encounter Guide screen without development module paths.

## 0.1.0 — 2026-08-09

- First release.
- Adds START → ENCOUNTERS.
- Groups encounter sources by Town Map marker while keeping every route, floor, cave, and building explicit.
- Displays LAND and WATER tables separately, compact level ranges, and exact per-level per-step odds.
