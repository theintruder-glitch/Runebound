# RUNEBOUND 0.20.0 — Dreadwood

An offline Godot 4.5.1 RPG for ARM64 Android, with the same gameplay on Windows x64. Android is the primary target. This continues the supplied **v0.15.0** source; it does not replace the game or its systems.

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

**Android:** install `Runebound-Godot-v0.20.0.apk` over **Runebound Godot**. Keep the app installed and do not clear its data. Package `app.runebound.godot`, version code **27**, ARM64, minimum API 24, target API 35. The original prototype certificate is required for updates. Export important characters from Pause before final playtesting.

**Windows:** extract the Windows ZIP and run `Runebound.exe` beside `Runebound.pck`. Keep all extracted DLLs if present. The supplied low-power and OpenGL launchers remain available. The application name and `user://character.json` location remain unchanged, so existing local characters remain discoverable. Android and Windows exchange characters through the existing JSON import/export menus.

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
