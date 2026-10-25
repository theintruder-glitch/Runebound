# Android-first completion roadmap

Current source: **0.26.0**, built incrementally from supplied **0.15.0**. The older GitHub 0.12.0 snapshot is superseded on the development branch.

## Four Kingdoms milestone

- [x] Four distinct castle exteriors and 12 floors / 71 named rooms across the four original regions.
- [x] Authored ice ravine, blackwater boardwalk, canyon crossing, raised approaches and layered landscape sections; legacy cavern/trials retained.
- [x] Keys, mechanisms, regional rune sequences, optional vault/shortcut, checkpoints, backtracking, minibosses and three-pattern regional bosses.
- [x] Exclusive relic equipment/spells, forging materials/recipes and eight new outdoor discovery sites.
- [x] Detailed environment atlas, regional ambience, gradual lighting, rain puddles, blizzards and mire fog; bounded draw/actor work.
- [x] Source and compiled-resource validation plus native software-rendered portrait/landscape review (see VERIFICATION.md).
- [ ] Physical Android upgrade, touch, long-session FPS/RAM/heat/battery and Windows driver/audio playtest.
- [ ] Art and balance refinement across the remaining procedural wilds; deeper cave interiors and expanded environmental storytelling.
- [ ] Volcanic, desert and corrupted-kingdom expansion content; catalog-based world configuration supports additive regions.

## Thornwatch landscape/castle milestone

- [x] Restore the saved checkpoint and original signing identity without adding secrets to Git.
- [x] First authored Emerald Wilds section: layered hills, collidable cliff, ramp, valley river, bridge, waterfall, lake and camp.
- [x] Website-inspired exterior and three connected castle levels with seventeen named rooms, key/seal locks, optional sentinel/vault, rune traps, checkpoint, miniboss and two-pattern final guardian.
- [x] One-time legendary weapon, persistent run progress, usable entrances/exits, real map marker/track action and castle HUD guidance.
- [x] Bounded active floor/actors, cached/cullable scenery and unchanged default six-enemy crowd budget.
- [ ] Physical-phone upgrade, navigation, touchscreen, long-session performance and encounter balance.
- [ ] Extend authored terrain throughout the remaining Emerald Wilds, refine the new Frostspire, Blackmire and Stormbreak landscape sections after phone feedback.
- [ ] Remaining world atmosphere, expansion zones and final cross-device optimization.

## Completed in earlier milestones

- [x] Install pinned Godot 4.5.1 engine/templates, JDK 17 and Android SDK/build tools; produce signed ARM64 APK and Windows x64 package locally.
- [x] Preserve application ID, original signing certificate, character save path and progression migration; raise Android version code to 34.
- [x] Isolate automated tests from developer saves and detect silent script errors, assertion failures, missing completion and timeouts.
- [x] Repair touch lifecycle/dead zone and save recovery; verify rotation/scrolling and existing combat/magic in engine checks.
- [x] Expand existing Survival mode with persisted wetness and cover/fire drying; fix heat/bed wall checks and stale enemy windups.
- [x] Prepare GitHub Actions tests and both build targets; inspect rendered mobile layouts.

## Combat milestone completed

- [x] Touch placement and CAST/CANCEL for learned ground spells, retaining multi-touch movement.
- [x] Shared forward melee, visible misses, directional weapon sweeps, spell glow and guarded ordinary-enemy stagger.
- [x] Add real touch-event tests and compiled Android/Windows regression coverage.

## Fieldcraft visual milestone

- [x] Recognizable covered-wagon wreck, ruined scout tent, charred grove and carved runic cache replace prototype markers.
- [x] Twelve distinct shaded gathering props, including log piles, plants, ore, resin, mushrooms, reeds and crystals.
- [x] One small shared editable atlas, cached outdoor drawing and original pickup/quest locations, yields and rewards retained.
- [ ] Player-check resource recognition, labels and phone performance in mixed biomes.

## Crowd Relief patch

- [x] Respond to user-reported crowd slowdown with default six-enemy ambient cap, bounded wolf packs and nearby-fight spawn pressure.
- [x] Slower bounded spawn cadence, far-idle cleanup, sampled ordinary steering and range-first target queries.
- [x] Preserve active/status/boss/trial/dungeon encounters and full-rate movement/attacks; persist separate crowd/frame-cap preferences.
- [ ] User-test the patch on Motorola Edge 2025; record remaining dungeon, spell or crowd slowdowns and long-session performance.

## Ash and Oath milestone

- [x] Playable second chapter links Mara, the existing Emberforge sword/magic trial, an inscription and a separate three-enemy binding encounter.
- [x] Veteran trial completion, one-time rewards, persistent journal, retries after retreat/defeat/reload and shared mobile/Windows UI.
- [x] Faster/wider Keeper phase, fixed story tracking helper and renamed Android CI artifact path.
- [ ] Player-test chapter pacing, encounter balance and narrative clarity on Android.

## VYRNSPIRE / Camp Stores milestone

- [x] Rename public title/launcher, Windows product/executable, exports, UI and icon to VYRNSPIRE.
- [x] Preserve historical package, release certificate and fixed legacy save/settings directory; exercise a real old-to-new Linux save-path probe.
- [x] Selective chest transfers (1/5/10/maximum), capacity bounds, saved contents, native menu in both orientations.
- [x] Preserve bulk transfers and prevent remote/stale/lookalike/wall-blocked chest operations.
- [ ] Verify actual Android rename/install-over-old and native Windows character continuity with the player.

## Camp Provisions milestone

- [x] Food/parts batches with exact quantities, full-cost preview, maximum/stack bounds and execution revalidation.
- [x] Preserve single-item gear/building actions and existing recipe/food progression.
- [x] Reachable lit-fire/workbench selection, all-recipe wall checks and building-move cost-bypass repair.
- [x] Native scrolling batch controls, both orientations and compiled-resource/save checks.
- [ ] Tune Survival resource availability and batch limits through player feedback.

## Position recovery patch

- [x] Replace fixed world-map arrow clamping with player/home-inclusive stable bounds and automatic local view for distant positions.
- [x] Add explicit paused camp recovery that keeps progression, supplies and saved bed location intact.
- [x] Repair blocked/extreme saved coordinates before chunk generation; keep valid snow positions.
- [x] Exercise real touch movement in both orientations, map movement and recovery/save reload.
- [x] User reports v0.20.1 recovery works; original movement-lock cause remains unconfirmed.

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
