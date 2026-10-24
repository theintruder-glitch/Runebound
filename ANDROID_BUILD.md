# Android build and milestone evidence

The game remains Godot/GDScript, package `app.runebound.godot`, ARM64, version code **19**, with the existing character/save migration code and all existing content. `project.godot` and `export_presets.cfg` are unchanged. The Survival milestone adds validated optional fields to the existing save migration; the save path, atomic write/backup handling, progression and inventory remain intact.

## Reproducible build

Use Godot **4.5.1 stable** (`f62fdbde1`) and its matching Android debug template, Java **17**, Android platform **35**, build-tools **35.0.0**, platform-tools, and command-line tools **12.0**. Non-Gradle exports use the existing official template and do not require compiling an engine or installing an NDK.

Set `GODOT_BIN`, `JAVA_HOME`, `ANDROID_HOME` and, if needed, `XDG_DATA_HOME` to the location containing `godot/export_templates/4.5.1.stable/android_debug.apk`.

```bash
python3 tools/build_android.py --mode check
```

The script isolates editor settings, caches, test profiles and signing files in temporary directories. Tests never use the normal local save profile. Each test suite gets its own disposable profile. The script rejects engine errors and nonzero exits, verifies that source project/export settings have not changed, and independently checks ZIP integrity, compiled game resources, package/version, ARM64 libraries, API 24/35, offline permissions, signature certificate and 16 KB ZIP alignment. An APK is uploaded by CI only after these checks pass. Tooling is excluded from game imports using `tools/.gdignore`.

Run regression checks separately with:

```bash
python3 tools/android_checks.py
```

## Signing and existing characters

The historical original signing certificate documented in `VERIFICATION.md` is:

```text
79a1ef0f60f3b4c6e65bd42cc422b28c7e969dd5ae54b0ddc77242f9287bab37
```

The private key is unavailable in this workspace. Default test builds create a disposable key in an isolated temporary directory; they do not change the original signing identity. Their filenames and included installation instructions say **FRESH INSTALL ONLY**. They cannot replace the installed original game. Use a separate test phone or Android profile with no installed Runebound. Do not uninstall Runebound, clear its data, or use a downgrade/data-reset workaround.

To build using the original certificate, manually dispatch the workflow with `signing_mode=original`. Configure `ANDROID_DEBUG_KEYSTORE_BASE64`, `ANDROID_DEBUG_KEY_ALIAS` and `ANDROID_DEBUG_KEY_PASSWORD` in repository secrets. The key must hold the historical certificate above, even if it was originally used for release exports. The build fails before export if any value is missing or the certificate differs. Pull-request builds never receive these secrets. Certificate equality is necessary but does not prove device upgrade compatibility; Android package/version acceptance and saved-character retention must still be tested safely.

No private key, password, signing credential file or generated APK is committed to source.

## Actual checks, 2026-10-24

- Baseline: all 16 Android regression runs passed (1,114 assertions).
- Touch milestone: all 18 Android regression runs passed (1,150 assertions), including 18 new native input checks in **each** orientation. Existing gameplay/save, survival/camp, forest, regions/abilities, presentation, contracts, weather, trader, farming, auto pickup, menu scroll, rotation, movement and live-frame suites passed without script errors.
- The baseline APK exported successfully (exit 0). Android tools verified package `app.runebound.godot`, version code 19 / `0.12.0-android`, minimum API 24, target API 35, only ARM64, launchable activity, no requested permissions, v2/v3 signatures, ZIP integrity and 16 KB ZIP alignment.
- **GitHub Actions passed:** [run 40049962398](https://github.com/theintruder-glitch/Runebound/actions/runs/40049962398), commit `b6c750c4fee18847b95f4b09b3e4f9d0ec9e5a9c`. Tool installation/checksums, project import, all Android suites, signed APK export, verification and both artifact uploads succeeded. [Download the fresh-install-only APK bundle](https://github.com/theintruder-glitch/Runebound/actions/runs/40049962398/artifacts/12543390088) (available until 2026-11-07). It includes installation instructions, manifest/signature reports and verification JSON. [Test/build diagnostics](https://github.com/theintruder-glitch/Runebound/actions/runs/40049962398/artifacts/12542439692) include every suite's assertion log and summary.
- CI APK SHA-256: `2c673d6e924b15d6705238eea96d9485a1866c5e22c1554d103e1d12e5416711`. CI disposable certificate SHA-256: `7eb390af77da8fb9b2d4cf87da4ea8202f1891be308ff01957b9bbbeccadd514`. These identify this test artifact, **not** the original signing identity. Each fresh-install-only build uses its own disposable key.
- The managed local sandbox forbids TCP listeners. Godot's editor language/debug services and ADB emitted `ERR_CANT_CREATE` / `Operation not permitted` diagnostics. The strict all-in-one script correctly rejected those errors. An independently verified APK is distinct from a clean CI run or a device installation; inspect the PR checks for actual CI status.
- No physical Android phone or emulator is attached. Installation, Android 16 startup, GPU performance, audio, battery/thermal behavior and installation over a previous build have **not** been tested.

## Touch combat milestone

The joystick now has an 8% center dead zone to suppress thumb drift, retains continuous full-range response, and preserves touch ownership when other fingers are active. Canceled touches and hidden controls release held actions. Touch action buttons brighten immediately on press and restore their appearance on release, pause or rotation. Simultaneous movement, held attack and a third-finger Firebolt cast are covered with real viewport input events, including Android's emulated mouse event and a one-cast mana check. Existing spell costs, cooldowns and damage are unchanged. No save schema change is needed.

## Motorola Edge 2025 / Android 16 checklist (not yet performed)

1. On the original installation, use the existing JSON character export and keep a separate backup. Record the installed package/version and certificate without uninstalling or clearing data.
2. For a disposable-key build, use a separate device/profile without Runebound. For an original-key build, first compare its certificate with the installed APK; only then attempt an ordinary install/update that preserves data. Stop if Android rejects it.
3. Launch offline; create a separate test character. Check menus, terrain, enemies, audio and startup errors.
4. Hold the joystick continuously; use attack, dodge, all spells and class skills with other fingers. Check center drift, canceled touches and rapid input.
5. Rotate portrait/landscape while holding controls. Check safe areas, nonoverlapping targets, building tools and reacquiring touch ownership.
6. Swipe inventory, crafting, trader and farming lists over buttons; confirm swipes never spend items/gold and taps activate once.
7. Background/resume during combat; verify pause and released controls. Save, relaunch and load; confirm level, inventory, quests, gardens, weather and camp persist.
8. Test low-power and normal modes while exploring and fighting. Record sustained frame rate, RAM, heat and battery use on the phone.

## Next milestones

1. Obtain physical-phone results and original-certificate upgrade evidence; finish the remaining Priority 0/1 checks.
2. Profile combat/effects on the phone, then improve dodge/hit cues and spell readability within the existing low-power effect limits.
3. Add opt-in Survival mode separately from Adventure, with old-save defaults, hunger/thirst/fatigue/exposure, fair remedies and save/load regression tests before shipping.
4. Expand spell upgrades/hotbar choices, encounters, quests and progression in later tested milestones. These expansions are not implemented by this change.

## Combat readability milestone — 2026-10-24

Spell, class-skill and dodge labels retain their names while recovering. Touch buttons show a compact recovery bar, and mana-limited spells keep their cost visible. Spell casts and dodges update the HUD immediately; cooldown buttons stay unavailable until the action actually recovers. Dodge adds a short directional chevron cue within the existing 24/48-effect budgets. Costs, damage, recovery durations, save format and Android identity are unchanged.

Local validation passed **1,184 assertions across 18 Android runs**, including 35 mobile-control checks per orientation. The new checks exercise real touch casts/dodges, cooldown tap rejection, recovery progress, mana versus cooldown state, world draw callbacks and the low-power effect cap. CI results for this milestone are attached to PR #1; the earlier artifact above predates these graphics changes. Physical-phone appearance, sustained performance and Android 16 installation remain untested. Next: phone readability feedback and save-safe opt-in Survival mechanics.

## Opt-in Survival milestone — 2026-10-24

Pause → Game mode offers Adventure, Survival Normal and Survival Gentle for the current character. Existing saves and new characters start in Adventure. Modes share the existing character/camp/story and save slot. Switching freezes/resumes the same meters; it never refills them. Gentle halves depletion. Normal rates per active second are food −0.04, water −0.06 and fatigue +0.02. All meters remain between 0 and 100. Critical needs reduce ordinary walking by at most 30% (Gentle 10%); they never cause damage and do not alter dodge speed.

Food/tea use the existing inventory and recipes. Survival adds a three-use travel flask (40 water per use), free hydration/refills near the starting camp, and safe fatigue recovery at camp, a shelter or bed. Close hostiles prevent rest. Existing bed rest also recovers fatigue. Exposure responds to winter, snow regions and rain; cover, fueled fires and tea reverse it. No offline depletion, new timers/nodes or heavy rendering are introduced. Gameplay HUD shows the meters while Survival is active; actions use the existing scrolling menu.

New migration fields are gameMode and needs (food, water, fatigue, exposure, flask, difficulty). Missing fields get safe defaults. Invalid or nonfinite values are rejected so the existing backup-read fallback can recover the previous valid save. Mode changes and flask/rest/refill actions restore their prior state if saving fails. New tests cover old/partial saves, invalid fields, actual simulation/movement, conditions/remedies, difficulty, persistence, corrupt-save recovery, failed-write rollback and native swipes over hydration controls in both orientations.

Manual checks still needed: Android 16 installation, meter readability, touch comfort and long-session balance on Motorola Edge 2025. Original-certificate upgrades remain untested. Local validation passed 1,348 assertions across 20 Android runs, including 79 Survival checks per orientation and 85 native menu-scroll checks. CI artifacts for this milestone are recorded in PR #1. Earlier APK links in this file predate Survival. Next: more water sources/crafted travel tools and phone playtesting; then spell upgrade/hotbar expansion.

## Wilderness and presentation milestone

Survival has explicit title-screen guidance, a SURVIVAL / ADVENTURE entry in Pause, and a direct Camp entry. Pause also offers Explore calmly: unprovoked ordinary wilderness monsters do not chase or attack; attacking them provokes defense. Enabling it cancels existing ordinary wilderness windups/aggro. Bosses, named encounters and dungeons keep their combat rules. The preference persists in encounters.cfg independently of character saves. Ordinary wounded enemies retreat nearby and cannot launch a strike during retreat.

Scenery gains deterministic biome-colored terraces, rock faces, shadows and ruin columns, retained in the existing scenery cache. Camp origin, region objectives, ruins and saved structures get clearance. These are visual landforms: this milestone does not add physical cliffs, height traversal or new collision rules to saved locations. Original sprites remain with added horns, fangs, eye accents and spirit tendrils; neutral deer are unchanged. Primitive detail remains available in low-power mode without new particles or nodes.

Automated checks exercise calm simulation, provocation, retreat, boss/dungeon exclusions, preference persistence, Survival discoverability, deterministic bounded scenery, saved-camp clearance and real draw callbacks in both orientations. Local regressions passed 1,390 assertions across 22 Android runs. Current CI run/artifact evidence is recorded in PR #1. Physical-device appearance, frame rate and player comfort are untested. Next: phone art feedback and interactive terrain/encounter landmarks, then further spell/content progression. Existing signing and save restrictions still apply.

## Persistent update signing policy

The earlier fresh-install-only commands and artifacts above are historical. PR builds now run checks without producing an APK. Manual builds require `original` or `updates` signing with a retained private key, pinned public certificate and increasing version code; there is no generated-key fallback. GitHub uses 1000 + run_number. The version override is restored on failure. Five signing/version policy tests pass locally; Python compilation and workflow YAML parsing passed. No update-compatible APK or device update is claimed until the secure key is configured and its match to the installed app is established. See UPDATE_SETUP.md. The GitHub connection here cannot set Actions secrets.
