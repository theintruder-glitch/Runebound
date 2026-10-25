# Four Kingdoms performance scope

Current 0.26 source keeps viewport-based tile retention and cached scenery. Only one castle floor (32 or 40 cells square) loads at once, with at most five authored foes. Default outdoor crowd cap remains six, optional Standard twelve. Additional outdoor castle textures are released when the active zone changes. The six-cell environment atlas is one shared roughly 6 MiB raw RGBA texture; a visible additional castle is roughly 6 MiB. Existing four-voice audio pool, eight-light pool, mobile 2/4-light limits and effect limits remain. Performance disables real lighting; low power and weather toggles remain.

Nine scenarios were measured by tools/benchmark_kingdoms.gd. Six-enemy outdoor means: frost 0.684 ms, mire 0.715 ms, highlands 0.826 ms. Outdoor p95 maximum 1.955 ms. Gatehouse/boss means 0.072–0.102 ms. These are headless desktop script CPU timings, not rendered frame times or Android results. Actual phone GPU, RAM, heat, battery and long-session measurements remain required. Software-rendered screenshots deliberately are not used to claim phone FPS.

---

# 0.24.0 Fieldcraft rendering bounds

Sixteen detailed field props share one 512 × 512 SVG imported texture, 1,048,576 bytes of base RGBA texels, with sixteen clipped AtlasTextures. Each resource draws one texture into the retained scenery canvas instead of rebuilding its primitive shapes; outdoor story sites move from per-frame World drawing to that same cached scenery. View bounds cull sites. Clue discovery refreshes the retained marker; generation/collision/pickup work is unchanged. No new lights, shaders, per-prop nodes, animation or physics bodies. This is a rendering-cost bound, not measured phone FPS. The prior six-enemy default and AI/targeting optimization remain unchanged.

# 0.23.1 crowd-load patch

User reports that accumulated enemies slow the entire screen. The previous wilds cap was 24 with low-power enabled and 38 otherwise, spawning roughly every 1.4–2.8 seconds before level/night scaling and allowing three-wolf packs. Target selection performed line-of-sight checks before rejecting enemies outside weapon range.

Reduced crowds now defaults ON: six total ambient actors including wildlife and pack additions, no ambient reinforcement attempts once three hostiles are within 320 units, and a 3–10 second bounded spawn-attempt interval. Standard caps at twelve, pressure threshold five, and a 2–10 second interval. Both frame-cap choices share those budgets. Named/trial/dungeon content is separate. Far idle ambient actors recycle at 900 units with no reward; changing the setting only recycles far idle actors, never active/status/objective enemies.

Ordinary wilds steering is sampled every 0.12–0.14 seconds, with displacement invalidation after 24 units of player movement. Physics movement/collision, status effects and attack timers retain full-rate updates; named/trial/dungeon decisions stay full-rate. Target queries now gate by distance/exclusions before line-of-sight. Rendering still culls offscreen actors through the existing draw bounds.

## Measured synthetic CPU result

Pinned Godot 4.5.1 on this Linux workspace, headless, seeded cave archers, 60 warmup ticks then 600 measured ticks per population. Same fixture before/after code change:

| Population | Before mean tick | After mean tick |
| --- | ---: | ---: |
| 6 enemies | 1,537.73 µs | 322.47 µs |
| 24 enemies | 5,490.27 µs | 948.94 µs |

This fixture exercises auto-targeting, cave line checks, steering and simulation. It excludes GPU rendering and actual phone input/heat; numbers are one-run CPU evidence, not Motorola FPS guarantees. Reproduce with `godot --headless --path . --script res://tests/benchmark_crowds.gd` inside an isolated XDG profile. The benchmark deliberately injects 24 enemies to stress legacy-size crowds even though new ambient spawns cannot reach that count.

## Prior performance notes

# 0.13 PC performance bounds

Graphics quality has Performance, Balanced and Rich settings. A fixed pool contains eight shadow-free PointLight2D nodes; Balanced enables up to four and Rich up to eight. Performance and the safe launcher disable those lights and ground-detail additions. Scenery draw commands are cached using the original camera/chest/build invalidation path. Terrain texture noise is generated when the seasonal palette changes, not every frame. Spell zones and temporary visual effects use existing bounded world simulation and redraw paths. The laptop frame cap is adjustable to 30 or 60 FPS.

These bounds and passing headless integration checks do not establish the player's Windows GPU performance. This environment could not open a native graphics display; no rendered screenshot or physical FPS result is claimed. Use Performance or Start-Low-Power.bat on a laptop where Balanced is slow.

# Reproducing the script benchmark

Run `godot --headless --path . --script res://tests/benchmark.gd`.

The benchmark creates 38 enemies, including off-screen enemies, requests 250 drawing frames and samples render-command construction after a warmup. It then times 600 simulation ticks. Frame caps are disabled during this measurement. It measures CPU-side GDScript work in a synthetic headless scene, not rendered GPU frames or physical phone performance. The version 0.3 baseline is available from the project's prior archive version. See VERIFICATION.md for the observed result and limits.

Run `godot --headless --path . --script res://tests/test_movement.gd` for movement, camera, cache, and mode checks. Tests write fixture saves into the engine's user-data directory; back up development saves before running them.

For landscape movement checks, append `-- landscape` to the movement command. The suite sets the logical viewport explicitly because physical headless window sizes are not reliable.

Run `godot --headless --path . --script res://tests/test_live_frames.gd` for the real-loop drawing regression; append `-- landscape` for the wider viewport. This catches disabled world processing, which the original coordinate-only suite missed. Historical synthetic benchmark results manually invoked drawing and must not be read as proof of live movement.

## 0.25.0 terrain and castle budget

The detailed castle exterior is one 1254×1254 transparent texture (about 6 MiB
base RGBA). Outdoor draw commands are cached and view culled. Animated water is
limited to the waterfall and eight visible river highlights. No new realtime
lights, shader passes, particle nodes or per-prop physics bodies were added.
Only the active castle level exists: 3–5 authored enemies and a 32×32 tile grid.
The outdoors keeps Reduced's six-enemy budget. See VERIFICATION.md and the
headless benchmark log for controlled CPU figures; those are not phone FPS.
