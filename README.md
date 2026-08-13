# 🗺️ Encounter Guide

> **Superseded:** Encounter Guide now lives inside **[Will's Mod](https://github.com/illanrego/wills-mod)**, the combined catch-'em-all toolkit with the map-first guide plus owned-ball battle HUD. Please install and follow releases there.

**A map-first wild-encounter guide for Gen1Recomp.** Walk the real Kanto Town Map, hop between encounter-bearing locations, and drill down to exact routes, floors, and buildings — with truthful level ranges and per-step odds derived from *your* imported ROM.

![API 2](https://img.shields.io/badge/mod%20API-2-8b5cf6) ![Profile: Content](https://img.shields.io/badge/profile-content-10b981) ![Read-only](https://img.shields.io/badge/read--only-✓-f59e0b) ![Tests](https://img.shields.io/badge/tests-8%20files%20passing-22c55e) ![Platform](https://img.shields.io/badge/platform-desktop%20%2B%20Android-3b82f6)

---

## The problem it solves

Plain encounter lists answer *“what appears here?”* — but never *“where is here?”* Without the map, a list of routes and floors is a phone book you can't navigate. This guide makes Kanto itself the menu:

> **START → PKMN MAP** drops you on the imported ROM's own Town Map. D-pad between glowing markers, press **A**, and you're inside that location's exact encounter tables — `-- MT. MOON 1F`, `-- MT. MOON B1F`, `-- MT. MOON B2F` as separate, never-merged sources.

## Features

- 🗺️ **The real Kanto map** — artwork and coordinates come from your locally imported ROM. Nothing is bundled or redrawn.
- 🎯 **Map-first navigation** — only locations with wild encounters are selectable; the cursor snaps between them.
- 📍 **Exact source identity** — floors, caves, gates, buildings, and Pokémon Centers are never blended. `-- ROUTE 4 POKÉMON CENTER` stays honest about being an interior.
- 📍 **You are here** — a blinking white marker shows your current location on Kanto, even where that spot has no wild encounters.
- 👀 **Walking HUD** — while exploring, a top-right panel lists the current area's LAND and WATER species with their exact level ranges; it hides itself in menus and battles.
- 🎚️ **HUD modes** — AUTO (only while standing on grass or water, showing just that table), ALWAYS, or OFF, from the Options menu or the **H** key.
- 📐 **HUD sizes** — SMALL, MEDIUM, or LARGE from the Options menu (ENC. GUIDE SIZE).
- ⚪ **Owned markers** — caught Pokémon carry the Pokédex ball, on the walking HUD and in every PKMN MAP species list.
- 🌿 **LAND and 🌊 WATER/SURF as separate views** — no deceptive merged tables.
- 📏 **Compact level ranges, full odds on demand** — `ZUBAT Lv. 8-10` up top, then every exact level with its chance per movement step.
- 🔍 **SELECT opens the complete list** — catches every encounter source, including any that lack Town Map coordinates.
- 📻 **Pure ROM-derived data** — works with Red, Blue, or Yellow; zero hard-coded species tables; no copyrighted content shipped.

## How it works

```text
your imported ROM
      │  (Gen1Recomp extraction)
      ▼
generated data  ──►  model.lua          ──►  screens (list + detail)
(encounters,      │   groups sources,        │
 field/townMap,   │   never merges maps,     ▼
 pokemon,         │   sums duplicate slots,  ListMenu UI (A open / B back)
 constants)       └── calculates odds        MapScreen (D-pad cursor)
```

The mod is read-only: it never touches saves, encounter mechanics, or link state.

## Install

1. Open **MODS** in Gen1Recomp (`F10` on desktop).
2. **Import mod .zip** and select `encounter_guide-0.6.0.zip`.
3. Enable **Encounter Guide**.

Works on desktop and Android. Requires an imported Pokémon Red, Blue, or Yellow ROM.

> 💡 Mods are loaded from the installed copy. After editing source, rebuild (`python3 tools/bundle.py`), repack, and re-import — tests alone don't update a running game.

## Usage

| Input | Action |
|-------|--------|
| **D-pad** | Move between encounter-bearing locations on Kanto |
| **A** | Open the selected location's exact source maps |
| **A** (in lists) | Drill down: source → LAND/WATER → species → levels |
| **SELECT** | Jump to the complete location list (incl. unmapped sources) |
| **B** | Back one level |
| **H** | Cycle the walking HUD: AUTO → ALWAYS → OFF |

```text
START → PKMN MAP
  → KANTO MAP                (D-pad, A to select)
    → MT. MOON               (grouped Town Map marker)
      → -- MT. MOON 1F       (exact source, always separate)
        → LAND · WATER       (never merged)
          → ZUBAT  Lv. 8-10  (truthful compact range)
            → Lv. 8  · 1.95% (exact per-step odds)
```

## Project layout

```text
.
├── main.lua               # self-contained release entry (generated)
├── lib/
│   ├── entry.lua          # screen registration + START menu hook  (source of truth)
│   ├── model.lua          # source grouping, methods, levels, buckets, odds
│   ├── names.lua          # player-facing map/source labels
│   ├── screens.lua        # ListMenu-based area/source/method/species screens
│   ├── map_screen.lua     # Town Map viewer: ROM tiles, cursor, markers, controls
│   └── hud.lua            # walking HUD: per-area species panel via render.hud
├── tools/bundle.py        # deterministic bundler: lib/ → main.lua
├── tests/                 # LÖVE test suite (8 files, fixtures + live Blue cache)
├── manifest.json          # mod metadata (id: encounter_guide)
├── mod.card               # launcher-facing description
└── dist/                  # importable release ZIPs
```

## Development

Requires any LÖVE 11+ runtime (the Gen1Recomp AppImage bundles one) plus the official [`modkit.py`](https://github.com/bryanthaboi/gen1recomp) tooling.

```sh
# run the test suite (fixtures + your imported Blue cache)
ENCOUNTER_GUIDE_ROOT="$PWD" love tests/runner

# regenerate main.lua after editing lib/
python3 tools/bundle.py

# official mod validation, ROM-content lint, and packaging
modkit validate --base fixture --strict .
modkit lint .
modkit pack -o dist/encounter_guide-0.6.0.zip .
```

Every release gate runs before tagging: **8/8 test files green** → strict loader validation → no-ROM-content lint → clean archive → live in-game smoke test.

## Scope

- **Covered:** walking/LAND and Surf/WATER encounter tables.
- **Deferred (truthfully labeled later):** fishing, static encounters, gifts, trades, prizes, and Game Corner — each deserves its own honest acquisition method before it appears in the guide.

## Roadmap

- [x] v0.1.0 — exact-source area browser, LAND/WATER separation, odds
- [x] v0.1.1 — package-safe single-file entry (fixes installed-ZIP crash)
- [x] v0.2.0 — map-first Kanto navigation on ROM-generated artwork
- [x] v0.3.0 — PKMN MAP menu entry + blinking player-position marker
- [x] v0.4.0 — walking HUD with per-area species and level ranges
- [x] v0.4.1 — HUD visible under render pipelines (voxel mods)
- [x] v0.5.0 — HUD modes (AUTO/ALWAYS/OFF + H key + options menu) and owned-ball markers
- [x] v0.6.0 — HUD size option (SMALL/MEDIUM/LARGE)
- [ ] Red/Yellow data pass on real caches
- [ ] Fishing as its own method

## Credits

- **[Gen1Recomp](https://github.com/bryanthaboi/gen1recomp)** — the decompiled-Gen-1 runtime, public mod API, and UI toolkit this mod is built on.
- **pret/pokered** — the original disassembly reference behind the data extraction.
- Built for Illan, who wanted to know what's in the tall grass *before* stepping in it.
