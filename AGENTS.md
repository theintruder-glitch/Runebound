# Codex instructions — Runebound Android

## Mission
Continue and finish the native **Android** edition of Runebound. This repository contains the editable **Godot 4.5 GDScript** game project. The current source is **v0.20.1**, continued from the supplied **v0.15.0** baseline. Make incremental, reviewable improvements without losing any existing game content.

Read `README.md`, `PHONE-START.txt`, `VERIFICATION.md`, `export_presets.cfg`, and `ROADMAP_ANDROID.md` before editing. Use VERIFICATION.md to distinguish local checks from pending hardware and CI validation.

## Nonnegotiable requirements
- **Android-first**: target ARM64 Android devices, including Motorola Edge 2025 on Android 16. Do not switch this project to a PC or browser game.
- Keep Godot/GDScript; do not rewrite in another engine or create a web-only clone.
- Preserve existing classes, loot, progression, biomes, enemies, quests, camp/crafting/building, inventory, mobile controls, auto pickup, garden, trading, seasons and weather.
- Retain the application ID `app.runebound.godot`. Preserve existing save-file handling, migration, and upgrade paths. Never uninstall the app or wipe live save data during testing.
- Do not modify Android signing identity or secrets as a side effect. **Never commit a keystore, tokens, or passwords.** A new debug certificate is not update-compatible with the existing signed app. Use the original signing key through a secure secret mechanism only when available and authorized; if missing, clearly mark test builds as fresh-install-only, not upgrade-compatible.
- Preserve original assets and credits; do not claim builds, tests, APK signatures, or device results that did not actually happen.
- Make UI functional in both portrait and landscape, with full touch/swipe scrolling and live joystick response; avoid tiny tap targets.
- Prefer lightweight graphics with adjustable quality/performance for mobile hardware rather than heavy desktop-only rendering.

## Task workflow
1. Inspect the existing project and identify broken imports/tests/build blockers without silently deleting features.
2. Establish a reliable Godot 4.5 + Android SDK/JDK/export-template build in CI; run import, automated suites, and Android debug export as appropriate. The current GitHub Actions workflow may need repair. Upload a verified artifact only when a real build completes.
3. Prioritize a functioning Android APK and safe update path, then tackle `ROADMAP_ANDROID.md` in testable milestones.
4. For every change: run relevant checks, document what actually passed, and list physical-device tests still needed.
5. Commit changes in Git and open a pull request for review. Do not force-push over existing work.

## Existing architecture
- `project.godot`, `export_presets.cfg` and `scenes/main.tscn` are the Godot root/scene/export entrypoints.
- `scripts/game.gd`: core game; `scripts/hud.gd`, `scripts/joystick.gd`, `scripts/touch_action.gd`: mobile UI/input.
- `scripts/survival.gd`, `scripts/farming.gd`, `scripts/weather.gd`: resources, construction, gardens and seasons.
- `scripts/abilities.gd`, `scripts/exploration.gd`, `scripts/forest.gd`, `scripts/world.gd`: RPG logic/world.
- `tests/`: historical Godot scripted tests; validate whether they run in current environment.
- `scripts/desktop.gd` is referenced by the game; it may remain as an inactive compatibility helper on Android. Do not remove referenced scripts just because of their name.

## Reporting style
Provide concise task results: files changed, tests/builds that really passed, APK artifact link if built, blockers, and the next actionable task. When a build fails, show the specific error and a proposed repair—not a generic missing-SDK statement.
