# Runebound — Android Edition (Godot v0.12.0)

**Runebound is an offline fantasy RPG developed for Android phones.** This repository's main build target is **Android**, not Windows. It contains editable Godot/GDScript game source, not an installable APK.

## Android game features

- Touchscreen joystick, attack, dodge, spells and class skills
- Portrait, landscape, and auto-rotate modes
- Four explorable regions: Mossveil Forest, Hollowdeep Caves, Whisperfen Swamp, and Frostfall Reach
- Eight character classes (including adventure-unlocked classes), directional combat, enemies, spells, loot and dungeons
- Auto pickup for nearby world resources, crafting, shelters, building, storage and campfires
- Weather and seasonal changes, crop gardens, quest board, and camp trader
- Local character saving; the game does not require a connection or an app store

**Not yet implemented in this recovered version:** a separate full hunger/thirst/sleep survival mode. These were discussed for a future update, not confirmed as shipped in v0.12.0.

## Edit on an Android phone

1. Install the official **Godot 4 Android editor** (Godot 4.5.x is appropriate for this source).
2. Clone or download this repository, then import the root `project.godot`.
3. Open the main scene and tap **Play** to test the project in the Android editor.
4. Edit files under `scripts/`, `scenes/`, and `assets/`. The current Android export preset lives in `export_presets.cfg`.

The project's Android configuration uses the Godot Compatibility renderer and ARM64 export. The project itself can be edited on a computer if desired, but there is **no Windows export preset** in this Android-focused repository.

## Build an APK

Requires Godot 4.5.x with its matching Android export templates, a compatible Android SDK and JDK 17. This repository includes an **Android** export preset:

```bash
mkdir -p builds
godot --headless --path . --export-release Android builds/Runebound-Android-v0.12.0.apk
```

The release export needs a correctly configured **private signing key**. The current package ID is `app.runebound.godot` and the current version code is `19`, inherited from the existing Android project. The export preset is for ARM64. Do not change the package ID or signing certificate if you intend to install an update over your existing Runebound app.

**Your existing Android signing key is not in this public repository.** Keep it private and backed up. A new or debug signing key generally cannot update an app installed with a different certificate. To protect existing character saves, **do not uninstall the app or clear its data** while testing upgrades.

A manually dispatched Android GitHub Actions workflow is present in `.github/workflows/android-debug.yml`; it requires the previously used debug signing identity in GitHub Secrets. It is not proof that an installable, update-compatible APK has been built.

## Current source status

- **Editable Android-oriented source:** v0.12.0, recovered and uploaded.
- **Latest confirmed APK from this repository:** none produced or validated in this GitHub conversion.
- **Proposed next version:** v0.13.0; newer editable source has not yet been incorporated.
- Android screen/touch compatibility and installed-APK upgrade behavior still require testing on the actual device.

The Android game uses `scripts/game.gd`, `scripts/hud.gd`, `scripts/joystick.gd`, `scripts/survival.gd`, and other GDScript files. A small desktop-support script remains because game code references it, but it is inactive on Android; removing it without refactoring would break the project.

Development check scripts are under `tests/`. Historical feature and test notes are in `VERIFICATION.md` and `PERFORMANCE.md`.

This is a development game, not a published store release.
