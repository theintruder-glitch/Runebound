# World overhaul implementation map

Preserve Godot/GDScript, Android package and signing identity, legacy saves, classes, quests, survival and building. Source is incremental from the restored v0.25 checkpoint, with this session's backtracking and map improvements retained.

- scripts/realm_catalog.gd: stable region IDs, bounds, authored roads, entrance coordinates, bosses, relics, forging cores and spell rewards. Future region content can be added without rebuilding existing zones.
- scripts/kingdom_landscape.gd: original authored Emerald approach, river/bridge/cliff/ramp/waterfall, camp, new cache/grove and delegated regional drawing/collision.
- scripts/realm_landscapes.gd: snowy ravine and peaks, swamp channel/causeway, highland canyon/ramps, regional discoveries, culling and atmospheric effects.
- scripts/castle.gd: preserved Thornwatch dungeon and common floor/backtracking API.
- scripts/regional_castles.gd: three independently authored castle plans, real lock/pathfinding changes, rune puzzles/shortcuts, retained progress, checkpoints, hazards, bosses and rewards.
- scripts/realm_props.gd: one shared environment atlas.
- scripts/side_caves.gd: two enterable side expeditions with independent layouts, mechanisms, protected treasure, warnings, guardians and safe run recovery. Branch trails live in realm_catalog.gd; Camp/map tracking uses the same coordinates.
- tests/test_side_caves.gd: full-radius routes and room paths, save/reload, mechanisms, combat warning phases, treasure limits, repeat visits and exact exits in both orientations.
- tests/test_kingdoms.gd: full-radius travel both ways, locks, optional/main routes, exact returns, save migration, rewards, checkpoints, boss patterns and exclusive spells. Existing comprehensive tests remain.

Development order: first restored/validated Emerald and Thornwatch; then built distinct additional zones through shared systems; exercised source tests and mobile software renders; exported with original identity; verified packaged resources; documented remaining physical-device tests.

Remaining quality gates: real Motorola Edge 2025 upgrade and controls, measured Android frame times/RAM/heat/battery in sustained encounters, native Windows launch/audio/driver fallback, balance and artistic consistency. These are authored destination sections inside the broad original wilds; complete conversion of every procedural tile, future zones, deeper new cave interiors and final commercial art/encounter polish are not claimed complete.
