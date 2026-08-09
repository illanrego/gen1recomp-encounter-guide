# Changelog

## 0.1.1 — 2026-08-09

- Fixes the ENCOUNTERS screen crash in installed ZIPs.
- Bundles runtime code into the mod entry file because installed mods do not extend Lua's module search path.
- Adds a package-context regression test that opens every Encounter Guide screen without development module paths.

## 0.1.0 — 2026-08-09

- First release.
- Adds START → ENCOUNTERS.
- Groups encounter sources by Town Map marker while keeping every route, floor, cave, and building explicit.
- Displays LAND and WATER tables separately, compact level ranges, and exact per-level per-step odds.
