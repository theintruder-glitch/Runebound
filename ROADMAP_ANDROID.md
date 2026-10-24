# Runebound — Android completion roadmap for Codex

**Baseline**: editable Godot v0.12.0 sources in this repository. Android-focused export preset uses ARM64, app ID `app.runebound.godot`, version code 19. No new Android APK has been built or verified by this handoff.

## Priority 0: Make the current Android game buildable and testable
- [ ] Verify exact Godot 4.5.x version required; install the matching editor and export templates, Android SDK/build-tools, and Java 17 in a supported build environment.
- [ ] Run Godot project import and existing automated tests; repair actual failures without dropping features.
- [ ] Audit `.github/workflows/android-debug.yml` and make it successfully publish **verified Android test APKs** on GitHub Actions. Do not claim an update-compatible APK unless signed by the original certificate.
- [ ] Verify APK manifest: ARM64, `app.runebound.godot`, appropriate Android compatibility, versionCode, package identity, and signature.
- [ ] Prepare a physical-phone test checklist for Motorola Edge 2025 / Android 16. Validate installation, boot, joystick and combat, rotation, scrolling, resume, saving and loading.
- [ ] Preserve existing data during updates: require the exact old signing certificate for install-over-previous-build testing; if unavailable, use a fresh-install-only test flow and explain the limitation.

## Priority 1: Finish the Android experience
- [ ] Fix joystick lag, drift and rotation-position errors; controls must respond continuously.
- [ ] Improve touch control placement, spell buttons, screen scaling and accessible menu scrolling in both orientations.
- [ ] Polish responsive combat animations, hit feedback, dodge cues and audio; profile CPU/GPU and RAM on a real phone.
- [ ] Harden save migration, autosaves and reload/recovery with regression tests.

## Priority 2: Expanded survival mode (planned, not shipped)
- [ ] Offer **Adventure** (existing core gameplay) and separate **Survival** game modes.
- [ ] Survival meters: hunger, thirst, fatigue/sleep, temperature/exposure; weather and biome conditions matter.
- [ ] Add fair remedies: food, water, shelter, bedding, fires and useful crafted tools; avoid unplayable punishment loops.
- [ ] Persist new meters and difficulty options without corrupting old Adventure saves.
- [ ] Build automated checks around regeneration, depletion, shelter, seasons, save/load and mode switching.

## Priority 3: RPG expansion and content
- [ ] Expand spell upgrade/buy/unlock paths, spell hotbar customization, gear and enchantment variety.
- [ ] Make combat skills, enemies, treasure and region exploration more varied and legible on a phone.
- [ ] Improve world objectives, quests, progression pacing, crafting and camp personalization.
- [ ] Improve art consistency and readable visual effects while keeping an adjustable low-power mode.
- [ ] Consider a separate endless/survival challenge mode, distinct from the main storyline, with clear player choice.

## Definition of done for a milestone
1. Changes committed and reviewable.
2. Existing relevant tests pass; new feature tests included.
3. An Android APK is successfully built and checked **if build tools and signing requirements are actually available**.
4. Phone-specific manual validation recorded or explicitly noted as untested.
5. Save compatibility and signing restrictions documented.
6. The next unfinished milestone is named.

## First Codex task
Read `AGENTS.md` and this roadmap. First prove the existing Android project imports, runs its tests and exports a verifiable APK in CI. Fix the build pipeline instead of only writing instructions. Preserve all existing features and the Android app ID. Do not introduce a new signing certificate as if it were an update to installed users. Report the exact verified APK artifact or the precise remaining blocker, and create a pull request.
