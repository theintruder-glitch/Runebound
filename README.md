# Runebound — Android Edition (Godot v0.12.0)

**Runebound is an offline fantasy RPG developed for Android phones.** This repository's main build target is **Android**, not Windows. It contains editable Godot/GDScript game source, not an installable APK.

## Android game features

- Touchscreen joystick, attack, dodge, spells and class skills
- Portrait, landscape, and auto-rotate modes
- Four explorable regions: Mossveil Forest, Hollowdeep Caves, Whisperfen Swamp, and Frostfall Reach
- Eight character classes (including adventure-unlocked classes), directional combat, enemies, spells, loot and dungeons
- Auto pickup for nearby world resources, crafting, shelters, building, storage and campfires
- Weather and seasonal changes, crop gardens, quest board, and camp trader
- Raised terrace and ruin scenery, sharper monster details, and optional calm wilderness exploration
- Local character saving; the game does not require a connection or an app store

**Opt-in Survival:** open Pause → SURVIVAL / ADVENTURE (also available from Camp) to enable Normal or Gentle on the current character. Food, water, fatigue and cold exposure use active play time only. Existing saves default to Adventure. Use cooked food/tea, the travel flask, camp refills, safe rest, shelter and warmth to recover. Needs affect walking speed with a bounded penalty and never cause damage. Adventure freezes the meters without resetting them. This first milestone uses the existing camp/story and save slot; it is not a separate character slot or endless challenge.

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

The Android GitHub Actions workflow runs on pull requests and manual dispatch. It pins Godot **4.5.1**, Java **17**, SDK/build-tools **35**, imports the project, runs the Android regression suites with isolated saves, and verifies APK identity, signature, integrity and alignment before uploading an artifact. See [ANDROID_BUILD.md](ANDROID_BUILD.md) for local commands and signing restrictions.

The default artifact is **FRESH INSTALL ONLY**, signed with a disposable test key, for a separate test device/profile without Runebound. **Never uninstall your existing game or clear its data to install this artifact.** Manual `original` mode requires the existing private key through GitHub Secrets and rejects any certificate other than the historical Runebound certificate. Physical-device upgrades remain untested.

## Current source status

- **Editable Android-oriented source:** v0.12.0, recovered and uploaded.
- **Latest local verification:** an ARM64 Android test APK has been exported and independently verified; see [ANDROID_BUILD.md](ANDROID_BUILD.md) for current evidence and limitations. It is not signed with the original certificate.
- **Proposed next version:** v0.13.0; newer editable source has not yet been incorporated.
- Android screen/touch compatibility and installed-APK upgrade behavior still require testing on the actual device.

The Android game uses `scripts/game.gd`, `scripts/hud.gd`, `scripts/joystick.gd`, `scripts/survival.gd`, and other GDScript files. A small desktop-support script remains because game code references it, but it is inactive on Android; removing it without refactoring would break the project.

Development check scripts are under `tests/`. Historical feature and test notes are in `VERIFICATION.md` and `PERFORMANCE.md`.

This is a development game, not a published store release.

**Less chasing:** Pause → Explore calmly lets ordinary wilderness monsters leave you alone until attacked. Bosses and dungeons stay dangerous. Wounded ordinary enemies can retreat. New terrace/ruin art adds visual depth without introducing collisions into existing camps or changing saved routes.
