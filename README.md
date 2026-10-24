# RUNEBOUND 0.16.0 — Shelter & Steel

An offline Godot 4.5.1 RPG for ARM64 Android, with the same gameplay on Windows x64. Android is the primary target. This continues the supplied **v0.15.0** source; it does not replace the game or its systems.

## This milestone

- Responsive joystick dead zone, finger ownership, and reliable release when controls hide, the app loses focus, or play pauses.
- Recovery saves keep their last valid backup instead of replacing it with a corrupt primary.
- Survival wetness: rain and snow soak clothing; wet clothing worsens cold exposure; cover dries clothing and reachable fires dry it faster. Older characters start dry. Classic has no needs drain.
- Walls block campfire warmth and bed interaction. Peaceful wildlife does not block bed rest. Removed beds cannot be used through stale menu selections.
- Enemy attacks cancel when enemies disengage or you reach shelter. Existing dodge, class abilities, telegraphs, weapon animations and learned spells remain.
- Pinned engine/templates, JDK 17 and Android SDK export helpers; isolated regression runner; Android and Windows build workflows.

Existing content includes eight classes, four regions, quests and regional trials, five-floor Survival expeditions, Classic endless dungeons, building, gardens, crafting, trading, equipment, spell purchases and hotbar assignments, fishing, cooking, weather, hunger, thirst, sleep, warmth, waterskins, cloaks and bedrolls.

## Play and preserve saves

**Android:** install `Runebound-Godot-v0.16.0.apk` over **Runebound Godot**. Keep the app installed and do not clear its data. Package `app.runebound.godot`, version code **23**, ARM64, minimum API 24, target API 35. The original prototype certificate is required for updates. Export important characters from Pause before final playtesting.

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

The runner selects each suite's required desktop flags, covers both movement orientations, checks exit codes and script/assertion errors, and requires a completion marker. Every suite gets a disposable XDG save/config directory, protecting developer characters. `--suite test_stability` selects the new checks. Tests do not establish physical-phone FPS or touch feel.

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
