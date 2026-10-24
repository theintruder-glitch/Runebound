# Runebound — Android completion roadmap for Codex

**Baseline**: editable Godot v0.12.0 sources in this repository. Android-focused export preset uses ARM64, app ID `app.runebound.godot`, version code 19. No new Android APK has been built or verified by this handoff.

**2026-10-24 progress:** the baseline and touch-control milestone now have passing Android regression runs and an independently verified local test APK. See [ANDROID_BUILD.md](ANDROID_BUILD.md) for exact evidence, signing restrictions, CI status limitations and the physical-phone checklist. This does not establish original-key upgrade compatibility or physical-device validation.

## Priority 0: Make the current Android game buildable and testable
- [x] Verify exact Godot 4.5.x version required; install the matching editor and export templates, Android SDK/build-tools, and Java 17 in a supported build environment. Pinned to 4.5.1 / SDK 35 / build-tools 35.0.0 / Java 17.
- [x] Run Godot project import and existing automated tests; repair actual failures without dropping features. 1,150 assertions across 18 Android runs pass; local sandbox editor-service errors are recorded separately.
- [x] Audit `.github/workflows/android-debug.yml` and make it successfully publish **verified Android test APKs** on GitHub Actions. [Run 40049962398](https://github.com/theintruder-glitch/Runebound/actions/runs/40049962398) passed import, Android suites, export, verification and upload at commit `b6c750c`. This is a fresh-install-only test APK; original-key upgrade compatibility is unverified.
- [x] Verify APK manifest: ARM64, `app.runebound.godot`, appropriate Android compatibility, versionCode, package identity, and signature. Disposable certificate only; API 24/35, version 19, v2/v3 signature and 16 KB ZIP alignment checked.
- [x] Prepare a physical-phone test checklist for Motorola Edge 2025 / Android 16. See ANDROID_BUILD.md. Execution of installation, boot, joystick/combat, rotation, scrolling, resume and save/load checks is still pending.
- [ ] Preserve existing data during updates: require the exact old signing certificate for install-over-previous-build testing; if unavailable, use a fresh-install-only test flow and explain the limitation.

## Priority 1: Finish the Android experience
- [ ] Fix joystick lag, drift and rotation-position errors; controls must respond continuously.
  - Automated milestone: center dead zone, ownership, cancellation and hidden-control release implemented; native movement, rotation and 36 new combat-input assertions pass. Phone comfort/performance testing remains pending.
- [ ] Improve touch control placement, spell buttons, screen scaling and accessible menu scrolling in both orientations.
- [ ] Polish responsive combat animations, hit feedback, dodge cues and audio; profile CPU/GPU and RAM on a real phone.
  - Combat readability milestone: named cooldowns, recovery bars, immediate spell/dodge HUD feedback and directional dodge cues. 1,184 assertions pass across 18 Android runs; physical-phone graphics and profiling remain pending.
- [ ] Harden save migration, autosaves and reload/recovery with regression tests.

## Priority 2: Expanded survival mode (first opt-in milestone implemented)
- [x] Offer **Adventure** (existing core gameplay) and opt-in **Survival** rules, selected in Pause → Game mode on the current character. Existing saves default to Adventure; no separate save slot is introduced.
- [x] Survival meters: food, water, fatigue and cold exposure. Rain, winter, snow biome, underground cover, roofs, shelters, fire and tea affect exposure.
- [ ] Expand survival remedies and useful crafted tools. Initial remedies reuse cooked food, tea, crafted shelters/beds/fires and add a three-use travel flask with starting-camp refills. Needs never damage health; walking penalties cap at 30% (10% on Gentle). Crafted flask upgrades and more water sources remain future work.
- [x] Persist additive meters, flask charges and Normal/Gentle difficulty. Validate malformed data, use existing backup recovery and roll back failed mode/flask saves.
- [x] Build automated checks around recovery, depletion, shelter, seasons/biomes, save/load and mode switching, plus native menu swipes. Physical-device validation and balance remain pending.

## Priority 3: RPG expansion and content
- [ ] Expand spell upgrade/buy/unlock paths, spell hotbar customization, gear and enchantment variety.
- [ ] Make combat skills, enemies, treasure and region exploration more varied and legible on a phone.
  - Wilderness milestone: optional calm exploration, wounded-enemy retreat and clearer monster silhouettes; deterministic terrace/ruin scenery adds visual depth while preserving old camps/routes. Physical height traversal and phone art/performance validation remain pending.
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
