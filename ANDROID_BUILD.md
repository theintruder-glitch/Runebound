# Android build and milestone evidence

The game remains Godot/GDScript, package `app.runebound.godot`, ARM64, version code **19**, with the existing character/save migration code and all existing content. `project.godot`, `export_presets.cfg` and `scripts/data.gd` are unchanged.

## Reproducible build

Use Godot **4.5.1 stable** (`f62fdbde1`) and its matching Android debug template, Java **17**, Android platform **35**, build-tools **35.0.0**, platform-tools, and command-line tools **12.0**. Non-Gradle exports use the existing official template and do not require compiling an engine or installing an NDK.

Set `GODOT_BIN`, `JAVA_HOME`, `ANDROID_HOME` and, if needed, `XDG_DATA_HOME` to the location containing `godot/export_templates/4.5.1.stable/android_debug.apk`.

```bash
python3 tools/build_android.py --mode fresh-install-only
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
