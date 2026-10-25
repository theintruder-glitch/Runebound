# VYRNSPIRE 0.23.0 — Ash and Oath

An offline Godot 4.5.1 RPG for ARM64 Android, with the same gameplay on Windows x64. Android is the primary target. This continues the supplied **v0.15.0** source; it does not replace the game or its systems.

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

**Android:** install `Vyrnspire-Godot-v0.23.0.apk` over your existing **Runebound Godot / VYRNSPIRE** app. Keep the app installed and do not clear its data. Package `app.runebound.godot`, version code **31**, ARM64, minimum API 24, target API 35. The original prototype certificate is required for updates. Export important characters from Pause before final playtesting.

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
