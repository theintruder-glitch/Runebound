# Android-first completion roadmap

Current source: **0.20.1**, built incrementally from supplied **0.15.0**. The older GitHub 0.12.0 snapshot is superseded on the development branch.

## Completed in this milestone

- [x] Install pinned Godot 4.5.1 engine/templates, JDK 17 and Android SDK/build tools; produce signed ARM64 APK and Windows x64 package locally.
- [x] Preserve application ID, original signing certificate, character save path and progression migration; raise Android version code to 28.
- [x] Isolate automated tests from developer saves and detect silent script errors, assertion failures, missing completion and timeouts.
- [x] Repair touch lifecycle/dead zone and save recovery; verify rotation/scrolling and existing combat/magic in engine checks.
- [x] Expand existing Survival mode with persisted wetness and cover/fire drying; fix heat/bed wall checks and stale enemy windups.
- [x] Prepare GitHub Actions tests and both build targets; inspect rendered mobile layouts.

## Combat milestone completed

- [x] Touch placement and CAST/CANCEL for learned ground spells, retaining multi-touch movement.
- [x] Shared forward melee, visible misses, directional weapon sweeps, spell glow and guarded ordinary-enemy stagger.
- [x] Add real touch-event tests and compiled Android/Windows regression coverage.

## Position recovery patch

- [x] Replace fixed world-map arrow clamping with player/home-inclusive stable bounds and automatic local view for distant positions.
- [x] Add explicit paused camp recovery that keeps progression, supplies and saved bed location intact.
- [x] Repair blocked/extreme saved coordinates before chunk generation; keep valid snow positions.
- [x] Exercise real touch movement in both orientations, map movement and recovery/save reload.
- [ ] Confirm the affected user's save is movable after the patch/recovery; original movement-lock cause remains unconfirmed.

## Dreadwood art milestone

- [x] Thirteen distinct shaded creature designs, including two unique story bosses; keep original art assets.
- [x] New tree/rock/chest atlas, calmer ground texture, stone joints and cached dungeon details.
- [x] Shared mobile/Windows quality menu, persisted Android selection and bounded lights.
- [x] Exported-resource checks and rendered portrait/landscape art review.
- [ ] Check scary/readable enemy silhouettes, mixed encounters and sustained phone heat/FPS with the player.

## Enemy tactics milestone

- [x] Shared ranged spacing in dungeon/wilds, blocked-retreat checks and pathfinder fallback.
- [x] Local neighbor steering for ordinary attackers, deterministic overlap separation and capped speed.
- [x] Source-linked ranged warnings, cover/reach cancellation and paused attack guards.
- [ ] Tune encounter pressure and readability from actual phone playtests.

## Story milestone

- [x] Mara dialogue, three investigation camps, persistent journal and bearings.
- [x] Separate three-floor expedition, warning runes, optional caches and two-phase named boss.
- [x] One-time chapter rewards, safe Hearthcall and a lead toward the existing caves adventure.
- [ ] Measure and tune chapter length, encounter difficulty and rewards through player testing.

## Next: hardware playtest and fixes

- [ ] Install over v0.15.0 on Motorola Edge 2025 / Android 16 and compare saved progress.
- [ ] Exercise real multi-touch, both landscape directions, scrolling, focus/resume and file import/export dialogs.
- [ ] Measure FPS/frame times, RAM, heat and battery during 30–60 minute sessions; tune limits from actual measurements.
- [ ] Run Windows executable on the laptop; verify driver fallback, audio and save location.
- [x] Observe successful GitHub Actions source/Windows validation for v0.16.0 (run 40093299724).
- [ ] Configure original Android release-signing secrets for remote APK builds.

## Then: RPG/content completion

- [ ] Combat feel and balance pass: attack animation timing, hit feedback, spell placement on touch, enemy pack/ranged behavior and class progression.
- [ ] Longer main quest arc, dungeon encounters/rewards, exploration goals and pacing; retain Classic endless dungeon as an option.
- [ ] Building/crafting usability and Survival resource balance, including wetness pacing and access to water/food/rest.
- [ ] Consistent art/audio, accessibility, onboarding and a broader final-playtest cycle.
- [ ] Commercial packaging, rights/credits review and an explicit distribution/signing plan compatible with the existing prototype population.

A passing engine suite is not physical-device validation or commercial-release readiness. Record real hardware results in PLAYTEST.md before closing those items.
