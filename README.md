# VYRNSPIRE 0.31.0 — Boss Signs

An offline Godot 4.5.1 RPG for ARM64 Android, with Windows x64 support. Continues the existing game, classes, characters, Survival, building, crafting, quests, garden, fishing and trading. Package `app.runebound.godot`, legacy save directory and original signing certificate remain fixed. Android version code **41**.

Menu actions now retain your scroll position when refreshing the same screen, including repeated stat upgrades, settings and crafting. Switching pages starts at the top.

## Boss signs

Boss health bars now include their name, remaining health percentage and phase. Trial, forge and beacon encounters identify their group and the number of enemies remaining. Actual faster phases on story, castle, cave and beacon keepers display Phase II below half health. Ordinary guardians do not falsely advertise faster attacks. A single brief effect signals a faster phase; it cannot repeat on every hit.

Heavy attack warnings reinforce the existing circular damage boundary with eight visible edge marks and a center cross. Named attacks keep their existing labels; other heavy strikes receive a clear label. These are presentation changes: attack timing, collision, damage, movement, enemy counts and rewards remain unchanged. Menus hide the caption and pause combat normally. No new textures, dynamic lights or enemies are required.

## Dungeon atlas

Inside any dungeon, open **Pause → World map** (or press M on Windows) to see the current floor. Visible tiles are recorded as you walk. Unknown areas stay dark; discovered castle/cave rooms and unclaimed keys, mechanisms, checkpoints or treasure become selectable destinations. Choose a marker or **Route** button to preview a gold path. **Entrance** remains available to help an older in-progress save find its way out. Other routes require discovered corridors. The arrow shows your actual dungeon position and facing; the map does not walk, teleport or interact for you.

**World map** switches back to the outdoor map, where your marker still represents the entrance. **Current dungeon floor** returns to the atlas. **Resume exploration** returns to play. The small dungeon minimap also uses explored tiles, keeping hidden rooms undisclosed.

Map memory stays in the existing expedition save. It survives continuing the game, checkpoints and castle backtracking; leaving ends that run's map. Old characters and in-progress expeditions gain the atlas automatically. Invalid optional survey data is repaired without rejecting the character. Classic endless runs retain at most eight floor surveys. No new permanent character/settings files, textures or enemies are required.

## Waykeeper beacons

Open **Camp → Waykeeper beacons · exploration journal** (also in Quests). Track the Rootlight Beacon near the Emerald river road, Last Ember Beacon above the frost ravine, Drowned Lantern on Blackmire's causeway, or Skywatch Orrery on Stormbreak's southern approach. The world map marks all four.

Read each central oath, then interact with Leaf, Moon and Star stones in its recorded order. The sequence differs by region. Wrong input resets that beacon's sequence; partial and solved sequences survive saves. Tracking points toward the next required stone. Return to the center to awaken three watchers. Keepers alternate a locked ground mark and a wider slam, then speed up below half health. Menus pause the encounter. Retreat farther than 380 units, defeat or reload ends an unfinished fight; solved runes remain, allowing a retry. An active beacon prevents another dungeon/trial encounter from stacking on top.

After defeating all three, return to claim a named **Epic ring or charm, 250 gold, 5 essence and 2 regional forging cores**. Make room in Gear and the core stack first; a blocked claim grants nothing and remains available. Completed encounters and rewards are once per character. Restoring all four grants **2 additional stat points**, once. Rings/charms use existing equipment slots and are not automatically equipped. Old character saves start these optional discoveries uncompleted.

Watchers spawn only after activation. The existing six/twelve-enemy crowd budget includes their three slots. Only distant idle ambient actors may be recycled for space; nearby fights, burning actors and named enemies remain protected. If necessary, clear nearby threats before starting. Rootlight's rooted shrine, Frostspire's brazier, Blackmire's chained lantern and Stormbreak's orrery are cached, culled native scenery with no extra textures or real lights. All four castles, both side expeditions, original progression, survival/building and custom controls remain available.

## Hidden side expeditions

Glacier Hollow and Oathstone Mine now have enterable interiors, five named chambers each, different branching layouts and marked trails from the regional roads. Open **Camp → Quests → Explore Glacier Hollow / Oathstone Mine**, or select their markers on the world map. Walk to the cave mouth and tap ENTER. Previously searched outdoor caches still allow entry.

Read the entrance journal. Glacier Hollow has faceted ice, rounded grotto chambers, a thaw brazier and an icebound guardian; Oathstone Mine has timber supports, rails, abandoned carts, a counterweight lever and the Oathstone Foreman. Each mechanism opens a real sealed side passage. Hazard circles warn before striking; dash or step away. Guardians use two warned attacks and speed up below half health. An optional vault watchman guards each treasure.

Each expedition treasure grants **180 gold, 4 essence and 5 regional materials**, once per character. Make room for the materials if the stack is full. Ordinary enemy/floor rewards remain repeatable. Only the active floor and four authored enemies load. Entrance stairs always leave; cleared gold stairs also return to the exact outdoor entry position. Defeat applies the normal 15% gold loss and returns to the paused cave entrance, retaining open passages, defeated foes and claimed treasure. Save/reload retains run progress. These are two single-floor side expeditions; all four three-floor castles and the original dungeons remain.

## Customize your controls

Open **Settings → Controls → Customize Layout**. Drag actual controls anywhere,
resize them from 50–200%, adjust opacity/appearance, swap supported assignments,
and choose joystick or eight-way D-Pad. Fixed/floating stick, sensitivity, dead
zone, grid/snapping, overlap highlighting/fixing, undo/redo, reset confirmation,
live Preview, left-handed/large/compact/combat/exploration presets and 12 named
personal presets are available. Minimize the toolbar with **–** to reach buttons
behind it. Save commits both orientations; Cancel discards the draft.

Portrait and landscape use separate normalized layouts within the usable screen
area. Preferences survive restarts in a separate controls settings file. Movement
and combat share the InputMap router with keyboard/gamepad support. Touch release
never releases a physical key or gamepad axis. See [CONTROLS.md](CONTROLS.md) for
all options, bindings and preview behavior. Character saves and original signing
identity remain unchanged. Physical phone/haptic/gamepad tests remain pending.

## Play the four castle expeditions

Open **Camp → Castle expeditions · four kingdoms**, select an Explore action and follow its bearing. All four castles also have selectable markers and roads on the world map. Walk to the actual gate and tap ENTER. The original regional shrines, hidden classes, Mossveil dungeons and both story chapters remain available.

| Region | Castle | Terrain and approach | Boss | Legendary equipment | Relic spell |
| --- | --- | --- | --- | --- | --- |
| Emerald Wilds | Thornwatch Keep | River valley, Old King's Bridge, hillside ramp, waterfall, Moonroot Grove | Thornbound Colossus | Thornwatch Oath | Briarheart |
| Frostbound Peaks | Frostspire Citadel | Jagged snowy peaks, ice ravine bridge, frozen lake, stepped ascent | Frost King | Winter Sovereign staff | Winter Crown |
| Drowned Mire | Blackmire Fortress | Blackwater channel, wooden boardwalk, ruined raised causeway, Witchroot Grove | Drowned Abomination | Blackmire Carapace armor | Mirebound Ward |
| Shattered Highlands | Stormbreak Bastion | Canyon bridge, stone cliffs, mountain road and siege camp; original Hollowdeep caverns retained | Storm Warden | Stormbreak Oath | Storm Warden's Lance |

There are **12 castle floors and 71 named rooms** in total. Each castle has a different plan, three floors, armory key, regional gate mechanism, optional guarded vault, miniboss, warned traps, checkpoint and final arena. The three new castles also have different Sun/Star/Moon rune sequences. Read the archive, align the runes in the stated order and open the secret vault and connecting shortcut. Wrong input resets the sequence. Partial progress survives saves.

Entrance stairs on floor one lead outside; upper entrance stairs backtrack to the previous floor. Final gold stairs also return outside. Keys, defeated guards, opened treasure and solved puzzles persist while backtracking or reloading a run. Leaving the castle ends that run; entering again starts a new run. Legendary equipment and its exclusive spell can be claimed once per character. A full bag lets you make room and return. Assign relic spells through the existing Spells menu; the game does not overwrite your hotbar.

Bosses have distinct silhouettes and warned attack patterns, with a faster phase below half health. Dash or leave the warning circle to avoid a strike. Each new castle's second floor offers a checkpoint that retains run progress after the normal 15% defeat gold loss. Optional rooms do not block the main staircase objective.

Castles supply Thorn sigils, Rime seals, Mire chains and Stormcores for four unlocked workbench recipes. Regional caches also provide frost shards, glowcaps or crystals. Hidden caches and inscriptions along the forest approach provide one-time exploration rewards and directions.

## Landscape, atmosphere and loading

The original 2D renderer now presents authored destination sections with layered hills, jagged textured peaks, cliff faces, raised trails, ravines, bridges and flowing water. All existing world coordinates and camps are retained. These are hand-authored sections within the existing broad wilds, not a conversion to 3D or a claim that every distant procedural tile has been sculpted.

New isolated castle images and a shared six-cell environment atlas provide detailed stone, snow, trees, roots and mossy boulders. Thornwatch art is preserved. The live website returned a sign-in wall here, so exact comparison against its current artwork remains unverified. Original synthesized wind/marsh ambience changes by region; day/night lighting transitions gradually, blizzards drift across snow regions, rain shows puddles and moving fog drifts through the mire. Existing temperature, wetness, hunger, thirst and sleep remain active.

Only one dungeon floor and at most five authored enemies load at once. Default ambient crowds remain six (Standard twelve). Terrain stays near the camera; distant scenery is culled, static scenery retains its draw commands and castle textures are released on region changes. One extra shared environment atlas is about 6 MiB raw RGBA; a visible additional castle is about 6 MiB. Existing low-power/quality controls remain. Graphics → Performance keeps real lights off; Balanced/Rich add bounded soft lighting and cloud shadows. Weather effects can be disabled.

## Install and test

Install `Vyrnspire-Godot-v0.31.0.apk` over the existing VYRNSPIRE / Runebound app. Keep the app installed and its data intact. Export a character backup from Pause first. The release must match the original certificate; no replacement key is included in source.

Windows: extract the entire Windows ZIP and run `Vyrnspire.exe` beside its PCK. The low-power and OpenGL launchers remain. Android and Windows exchange characters through the existing JSON menus.

Automated source, compiled-resource and software-rendered visual checks are recorded in `VERIFICATION.md`. They do not measure Motorola frame rate, heat, battery, physical touch or native Windows driver behavior. This is a playable four-castle development release requiring device playtesting and further art/balance refinement, not a finished commercial game.

## Fieldcraft — recognizable supplies and story sites

The Broken Caravan is now a damaged covered wagon with a wooden chassis, torn canvas, visible wheels, a detached rim and spilled cargo. Silent Watch has a ruined scout tent, journal and shield; Ashen Grove has a charred stump and living sprout. The Hollow Root's runic cache has its own carved chest artwork.

All twelve regional gathering kinds now use distinct shaded artwork: cut logs/woodpiles, stone clusters, iron-veined rock, fiber, berry bushes, flowering herbs, resin stumps, cave crystals, glowcap clusters, cattail reeds, frost crystals and pine-resin bark. The opening guide says woodpile to match its new appearance. Existing gathering positions, IDs, yields, respawn timers and auto-pickup remain; sites keep their clue locations, story text, one-time progress and rewards. Props remain walk-through as before.

Sixteen original editable designs share a single **512 × 512 transparent atlas** (1 MiB base RGBA). `assets/field_props.svg` and `tools/build_gathering_assets.py` are included; the generator reproduces the SVG without external art/dependencies. Resources and outdoor story sites use cached scenery texture commands with view culling; finding a clue refreshes its marker. No new per-prop nodes, dynamic lights, shaders, collision or ongoing animation. All graphics qualities use the new art, and the six-enemy crowd patch remains included.

## Crowd Relief

Reduced crowds now defaults ON for existing and new installations, independently of the 30/60 FPS option. Ordinary roaming population is capped at **6** including wildlife and wolf-pack additions (previously 24/38). Standard, available under **Pause → Enemy crowds**, caps roaming at **12**. No class, item, biome or quest content is removed.

Reduced mode stops ambient reinforcements when three hostiles are within 320 units, and clamps spawn attempts to at least three seconds even at night/high levels. Failed spawn attempts also wait before retrying. Standard uses a five-hostile threshold and at least two seconds. Ordinary idle enemies beyond 900 units are recycled without loot or kill credit; active fights, burning foes and named/objective enemies are retained. Switching the setting only recycles distant idle ambient enemies.

Ordinary wilds steering is sampled about every 0.12–0.14 seconds and refreshes immediately after meaningful player displacement. Movement, collision, status effects, telegraphs and damage still run each physics frame. Named bosses, regional trials and dungeon AI retain full-rate updates. Targeting rejects out-of-range enemies before checking expensive line-of-sight paths. The crowd preference survives changes to the separate frame-cap option.

Existing story/trial/dungeon encounter counts are preserved. Crowd settings control ambient wilds spawning, not required dungeon objectives. If a particular dungeon still lags on the phone, record its floor and encounter for the next measured optimization.

## Chapter II — Ash and Oath

After claiming Chapter I's reward, open **Camp → Story journal · Chapters I–II** and speak with Mara to start Ash and Oath. Track the chapter to follow the eastern road to **Emberforge**. Discover the landmark and complete its existing sword + magic trial; earlier trial wins count, and its Spellblade unlock/relic remain unchanged.

Read the forge inscription, then choose **Break ashen binding** at the forge or in the journal while nearby. Defeat the **Ashbound Keeper and two Bound Embers**. Warning circles lock before striking; the Keeper's second phase shortens its warning and widens its strike. Menus pause the fight. Leaving the clearing, defeat or reload abandons the encounter, keeping the inscription and allowing a retry. This encounter is separate from the regional trial and regular dungeons.

Return to Mara for a one-time **350 gold, 6 essence and 2 stat points**, plus a lead toward the existing Whisperfen adventure. A full gear bag does not block this currency reward. Story progress survives JSON import/export; older characters receive an unstarted second chapter. Track the journal from either screen orientation. The former Emberforge tracking action now calls a real validated tracking helper. The Android CI artifact glob now matches the Vyrnspire APK name.

## VYRNSPIRE and camp storage

The game is now **VYRNSPIRE**, formerly Runebound. The title/window, Android launcher label, Windows product/executable, export filenames and save-transfer labels use the new brand, with a new V rune icon. Install the APK over the old game. Package `app.runebound.godot` and the original signing key deliberately remain unchanged. Public branding is separate from this technical update identity.

Existing character/settings/backup paths stay fixed. Linux uses `godot/app_userdata/Runebound Godot` beneath its app-data directory; Windows keeps `%APPDATA%\Godot\app_userdata\Runebound Godot`. Android retains the original private package data location and equivalent legacy user-directory identity. The project uses explicit custom-user-directory settings, including platform-specific capitalization, so changing its display name does not create an empty new desktop save folder. The automated rename probe writes a legacy character/backup/settings fixture, launches VYRNSPIRE, and verifies the exact same directory and contents. Old JSON exports remain importable; new exports are named VYRNSPIRE-Character.json. Do not delete the historical data folder.

Stand near a built **Storage** chest, open **Camp → Choose supplies to store or take**, and select a material. Transfer 1, 5, 10 or the maximum that fits. Food and other supplies stay where you leave them. Existing bulk actions remain, with stack-capacity and reachable-chest checks. Removed, remote, lookalike or wall-blocked chests cannot be used. Crafting still uses carried ingredients; take items from storage before crafting.

## Camp Provisions

Open **Camp → Craft → Food or Parts → Choose quantity** on a recipe. Use plus/minus for an exact quantity, the 1/5/10 presets, or Maximum (up to 99). The preview shows full ingredient costs, carried quantities, shortages and remaining output capacity. Confirm spends the complete cost once and produces the complete batch; unaffordable or stale requests spend nothing. Leaving the preview spends nothing. The existing single-item Make actions remain.

Cooking requires a reachable lit campfire; gear requires a reachable workbench. Walls/closed doors now block all station recipes, not only fish. A closer blocked or extinguished station no longer hides a second usable station. Moving a building cannot bypass ingredient costs for other recipes. Buildings/gear remain one-at-a-time. Batches use carried ingredients only; storage is not automatically emptied. Cooking makes food, rather than eating it or refilling needs. Existing food, discoveries, tutorial milestones and save formats remain.

The user reported that v0.20.1's recovery worked. Camp recovery/map fixes and Dreadwood graphics remain included.

## Stuck character and map fix

Install this patch over the existing app and continue the same character. If movement is stuck, open **Pause → Recover stuck character → Return to original camp · keep my character**. This explicitly returns to original Mossveil camp rather than a bed in snow. Gear, levels, quests, camp, gold, saved bed location, health/mana and survival gauges are retained. A wilds trial is abandoned. Recovery stays paused so you can review supplies before choosing Resume journey. It cannot discard an active dungeon.

The endless wilds had outgrown the map's fixed central rectangle: distant positions were clamped to a corner. Maps now open centered around distant characters; World overview expands in stable blocks to include the actual player and home, and Around me centers on you. The arrow rotates with your facing. Inside a dungeon it marks the wilds entrance rather than dungeon-local coordinates. Viewing the map never moves your character.

Blocked saved positions are checked before nearby terrain/resources are generated. Extreme finite coordinates that cannot represent ordinary movement are recovered to playable ground without wiping the character. Valid distant snow saves stay in snow; this is not a blanket region reset. The cause of the user's particular movement lock is not confirmed without their save or device reproduction; touch movement in snow and the recovery path are covered by new tests.

## Dreadwood graphics

Thirteen new creature designs replace the old shared block shapes: gaunt skeletons, hooded archers, horned guardians, fanged wolves, toothy oozes, ragged spirits and distinct thorned Root Warden/Hollow Heart bosses. Glowing eyes, breathing/hover motion, existing attack lunges and recoil make their intent readable. Boss art is larger; hitboxes and damage rules stay the same. Deer keep their peaceful wildlife appearance.

Trees, rocks and metal-bound chests use a new shaded environment atlas. Ground noise is softer; dungeon floors/walls have baked stone joints and cached cracks/bone fragments. Existing weather, seasons, buildings, terrain and original assets remain.

On either platform open **Pause → Graphics**. Performance includes all the new art and keeps real lights off; it remains the phone default. Balanced adds soft lighting; Rich adds ground detail/atmosphere. The setting now persists on Android. Battery saver caps lights at two; mobile without battery saver caps them at four. Safe mode forces Performance. The two new atlases occupy under 1.7 MiB of raw RGBA texture data before engine overhead. No realtime shadows or new shaders are required.

Vector art remains editable in `assets/enemies.svg` and `assets/environment.svg`; regenerate it with `python3 tools/build_visual_assets.py`. See `assets/ART-DREADWOOD.md` for layout. Measured Motorola performance and subjective scare/readability still need phone playtesting.

## Enemy tactics

Ranged enemies now keep a firing distance in dungeons as well as the wilds. They back away from a close hero when the floor allows it and stand their ground when cornered. Clear a room by using cover, closing the gap and dodging the locked warning circle. A gold dashed line identifies which ranged enemy is preparing the shot; it does not track your new position.

Approaching ordinary enemies spread slightly around nearby allies while retaining collision, the dungeon pathfinder and wolf flanking. Named bosses keep their existing approach and phase behavior. Pending attacks cancel if cover breaks line of sight or the target disengages beyond reach. Menus freeze attack timers. The steering cache is transient; no character/save schema changes are required.

## Chapter I — The Hollow Root

Speak with Mara northeast of the original camp: **Camp → Chapter I** or **Mara’s market → Speak with Mara**. Investigate Silent Watch, the Broken Caravan and Ashen Grove, then bring their clues back for translation. Bearings and recovered dialogue appear in the scrolling chapter journal; Track chapter updates the HUD without deleting other quests.

At Mossveil Ruins, choose the separate **three-floor story expedition**: Buried Gate, Rootworks and Heart Chamber. Purple ground runes give a one-second warning before pulsing. Dodge or move away. Optional runic caches give gold/mana once per floor/run. Defeat the Hollow Heart and all remaining enemies; its warning circles widen and its windup shortens below half health. The final gold stairs return to the wilds.

Return to Mara for **250 gold, 5 essence, 2 stat points and Hearthcall**. Hearthcall returns to your bed’s saved return point or the starting camp, only outside dungeons/trials and away from hostiles. It recharges over 120 seconds of active play; it does not heal, refill needs or skip time. The next lead points toward the existing Emberforge adventure.

The original tutorial, Elder Shrine/Root Warden, repeatable jobs, Classic endless dungeon and five-floor Survival expeditions remain available. Older characters gain an unstarted chapter while keeping their progress. New construction leaves clue camps approachable; existing structures remain saved.

v0.17 combat/touch targeting and v0.16 wetness/save fixes are retained. This is a first playable story chapter; pacing and difficulty still need player feedback. No hour-long duration or commercial readiness is claimed.

Existing content includes eight classes, four regions, quests and regional trials, five-floor Survival expeditions, Classic endless dungeons, building, gardens, crafting, trading, equipment, spell purchases and hotbar assignments, fishing, cooking, weather, hunger, thirst, sleep, warmth, waterskins, cloaks and bedrolls.

## Play and preserve saves

**Android:** install `Vyrnspire-Godot-v0.31.0.apk` over your existing **Runebound Godot / VYRNSPIRE** app. Keep the app installed and do not clear its data. Package `app.runebound.godot`, version code **41**, ARM64, minimum API 24, target API 35. The original prototype certificate is required for updates. Export important characters from Pause before final playtesting.

**Windows:** extract the Windows ZIP and run `Vyrnspire.exe` beside `Vyrnspire.pck`. Keep all extracted DLLs if present. The supplied low-power and OpenGL launchers remain available. The public name is VYRNSPIRE; the explicitly pinned legacy user directory and `user://character.json` location keep existing local characters discoverable. Android and Windows exchange characters through the existing JSON import/export menus.

The original non-Godot v0.2 Android app has a separate package and private save directory; it still needs its existing save-transfer procedure. Do not uninstall it to move a character.

## Editable source and tests

Import `project.godot` into **Godot 4.5.1 standard GDScript**. Compatibility renderer; no external game plugins. Main systems remain under `scripts/`; `scenes/main.tscn` is the entry scene.

```bash
bash BUILD-ANDROID-CODEX.sh --engine-only
export GODOT_BIN="$HOME/.local/bin/runebound-godot-4.5.1"
"$GODOT_BIN" --headless --path . --import
python3 tools/run_tests.py
```

The runner selects each suite's required desktop flags, covers both movement orientations, checks exit codes and script/assertion errors, and requires a completion marker. Every suite gets a disposable XDG save/config directory, protecting developer characters. `--suite test_enemy_tactics` selects the new steering/attack checks; `--suite test_touch_combat` selects touch/combat checks; `test_stability` retains the prior save/Survival checks. Tests do not establish physical-phone FPS or touch feel.

## Build

Linux x86_64 helpers download official pinned Godot 4.5.1 assets and Android command-line tools with SHA-256 verification. Java 17 must be installed. `--engine-only` also enables Windows builds without an Android SDK or signing key.

For Android, supply the **original** keystore through `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, its alias through `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, and password through `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`. Keys and passwords are not included in this source or committed to GitHub. Recover the original identity from your privately retained v0.15.0 source; do not generate a substitute.

```bash
bash BUILD-ANDROID-CODEX.sh --accept-sdk-licenses
bash BUILD-WINDOWS-CODEX.sh
```

The license flag accepts the SDK terms. The prebuilt APK path installs platform tools, Android 35 and Build-Tools 35.0.1; no Gradle/NDK compilation is required. The Android helper imports assets, runs regression suites, exports release ARM64, checks ZIP integrity, original certificate, actual manifest/version/ABI, ELF load alignment and ZIP alignment for 16 KB devices. `--skip-test` is for an already-tested checkout; asset import and package validation still run. Windows exports and tests its actual compiled PCK before packaging all output files.

GitHub Actions `.github/workflows/build.yml` runs source tests and Windows exports on pushes and PRs. Android release export is manually dispatched with `build_android=true`, using repository secrets `ANDROID_RELEASE_KEYSTORE_BASE64`, `ANDROID_RELEASE_KEY_ALIAS`, and `ANDROID_RELEASE_KEY_PASSWORD`. It fails if the original identity is absent or different. Remote CI runs must be checked separately; local validation is recorded in `VERIFICATION.md`.

## Release status

This is a development milestone for final playtesting, not a finished commercial release. See `VERIFICATION.md`, `PLAYTEST.md`, and `ROADMAP_ANDROID.md` for evidence, limits and remaining work. Native Android installation, native Windows startup, hardware audio, long sessions, balance and Motorola Edge 2025 performance still require actual-device tests.
