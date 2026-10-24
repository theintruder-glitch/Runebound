# 0.17.0 Focused Combat verification — 2026-10-24

Continues v0.16.0 and the supplied v0.15.0 Godot source. Android remains primary. No application ID, save path, signing identity or character schema change.

- **Source:** 25 isolated suite runs, **1,628 checks**, pass in Godot 4.5.1.stable.official.f62fdbde1, including **71 new touch/combat checks**. No script errors or failed assertions in passing test logs.
- **Android compiled resources:** all 25 runs / **1,628 checks** pass against actual resources extracted from the signed APK. The export helper additionally runs six focused compiled-resource suites / **541 checks**, protects the APK checksum while tests run, and verifies its signature again afterward.
- **Windows compiled PCK:** six suites / **333 checks** pass: release boot, fishing, Survival kit, prior stability, new touch/combat in forced mobile mode, and desktop spellbook. This executes the exported PCK using the matching Linux engine, not the native Windows executable.
- **APK export:** actual ARM64 APK; app.runebound.godot; version code **24**; 0.17.0-focused-combat; minimum API 24; target API 35. ZIP integrity, native ELF 16 KB alignment, ZIP 16 KB alignment, actual v2/v3 signer-block presence and apksigner verification pass.
- **Signing comparison:** the new APK's certificate matches the supplied signed v0.15.0 APK: SHA-256 79a1ef0f60f3b4c6e65bd42cc422b28c7e969dd5ae54b0ddc77242f9287bab37. No new key was generated. Physical install-over-existing-app was not tested.
- **Earlier artifact discrepancy:** the v0.16.0 APK copy presently in this workspace has no APK Signing Block and fails verification, conflicting with the earlier recorded success. Treat that APK as superseded; use the freshly verified v0.17.0 package. Independent signing-block checks and checksum protection now guard final output. A deliberately unsigned ZIP with the correct game contents is rejected by the verifier.
- **Rendered phone QA:** inspected portrait and landscape target placement, valid green circles / blocked red circles, disabled CAST, controls clear of the joystick, and the forward melee hit pose, using native Godot drawing and Linux/Mesa software rendering. The capture fixture uses dummy audio; its shutdown reports audio playback objects retained by the engine, so no hardware-audio or leak-free runtime claim is made from these captures.
- **Prior CI evidence:** v0.16.0 GitHub Actions run 40093299724 passed source tests and Windows export. Current-commit CI status is separate from these local results.

## New behavior checked

Separate movement/aim/confirm fingers; preview without spending; touch-to-world coordinates and drag ownership; release without casting; CAST exactly once at the chosen point; delayed real Meteor damage/burn; free cancellation; release over CAST without accidental confirmation; blocked targets and range limits; Back, dodge, focus, menu and layout cancellation; needs/time/movement remaining live while aiming; unavailable mana during preview; instant healing; canceled Android touches; forward-only melee; ordinary-enemy windup interruption and guard; boss/named/burn resistance to stun locking; short hit/cast recovery; visible missed attacks, weapon cooldowns, paused attack rejection and wildlife protection; unchanged character roundtrip.

The older gameplay test now resumes play before its bow attack; paused attacks are correctly rejected. Legacy spells also tolerate a missing cooldown entry after a cooldown reset.

## Remaining validation

Real Motorola Edge 2025 / Android 16 installation, physical multi-touch feel, heat/battery/RAM/FPS, hardware audio, native Windows startup and graphics-driver behavior, long-session balance and remaining quest/dungeon content still need playtesting. No commercial-release completion claim is made. See PLAYTEST.md and ROADMAP_ANDROID.md.

## Historical verification (retained; current artifact observations above take precedence)

# 0.16.0 Shelter & Steel verification — 2026-10-24

Continues the supplied v0.15.0 Godot project. The GitHub base was v0.12.0; the branch incorporates existing 0.13–0.15 systems as well as this stabilization milestone.

- **Source:** all 24 isolated suite runs pass, **1557 checks**, with Godot 4.5.1.stable.official.f62fdbde1. Includes both movement/live-frame orientations, native touch scrolling, rotation, existing combat/magic, progression, fishing, farming, quests, trading, Survival/kit and **39 new stability checks**.
- **Signed APK resources:** all 24 suites pass again, **1557 checks**, using the exact compiled resources extracted from the final signed APK, external test scripts and isolated profiles. Tests do not load source scripts in place of the exported gameplay.
- **Windows compiled PCK:** release, fishing, kit and new stability suites pass, **217 checks**. This executes the actual exported data pack with the matching Linux engine; it does not execute the Windows PE binary.
- **Android export:** real ARM64 release APK produced with JDK 17, official matching templates, Android 35 and Build-Tools 35.0.1. Package app.runebound.godot; code 23; name 0.16.0-shelter-and-steel; minimum API 24; target API 35. ZIP CRC, v2/v3 signature, ARM64-only native libraries, ELF 16 KB LOAD alignment and zipalign -P 16 checks pass. Tests, migration files and keystores are absent from the APK.
- **Signing:** original certificate SHA-256 79a1ef0f60f3b4c6e65bd42cc422b28c7e969dd5ae54b0ddc77242f9287bab37. No replacement signing key was generated. App name, package ID and user://character.json path remain unchanged. Save recovery/migration tests preserve progression and good backups; physical install-over-existing-app remains pending.
- **Windows export:** actual x64 EXE/PCK and full output ZIP produced from the matching official template. Output pack passes the checks above.
- **Visual QA:** real rendered Linux/Mesa captures inspected at phone portrait and landscape aspect ratios: live controls, inventory and Survival supplies. The screenshots use the mobile interface and show readable, bounded controls/menus. Software-rendered Linux screenshots do not establish phone FPS, touchscreen feel or native Windows behavior. Audio used the dummy driver; hardware audio was not evaluated.
- **Build checks:** shell syntax and Python compilation pass. Test runner handles historical completion formats and requires successful completion, no script/assertion errors and a valid exit. It isolates saves/configuration per suite. Build helpers validate actual artifacts and include compiled-resource regression checks.

## New checks

Thumb jitter/dead zone; independent finger ownership; mouse/touch contention; hiding/focus-loss release; legacy wetness default; malformed wetness rejection; corrupt/structurally invalid save recovery without clobbering the last good backup; failed-write reporting; actual calendar rain, cover drying, wet cold exposure, fire drying, paused weather needs and bounds; wall-blocked warmth/bed access; stale/dead/disengaged/sheltered attack handling; peaceful-wildlife bed rest; stale bed rejection; shared save roundtrip.

## Limits and next verification

No physical Android install/upgrade, native Windows executable launch, phone RAM/FPS/thermal/battery measurement, hardware audio or long-session balance test occurred here. GitHub Actions configuration is prepared; remote CI success must be observed separately. The spellbook suite requires --desktop because it tests mouse placement; the runner now supplies that mode. This milestone is ready for device playtesting, not a claim of commercial completion. See PLAYTEST.md and ROADMAP_ANDROID.md.

## Historical verification (earlier versions; retained as supplied)

# 0.15.0 Wild Waters verification

82 dedicated fishing integration checks pass against the source, the compiled Windows pack and the exact game resources extracted from the signed Android APK. They exercise old-save migration, malformed records, actual rod menu callbacks and costs, real world casting, immediately saved bait, duplicate/early/late reeling, native game-tick bites, one-catch rewards, movement/dodge/attack/spell/pause/dungeon interruptions, hostile proximity, full stacks, all regional species, rare Starfin, exact one-time collection reward, save/JSON transfer, cooking costs and food/water effects, reachable fires, reserved construction space, tracking priority, menu bounds in phone portrait/landscape and desktop, and native drawing callbacks.

Ten additional native touch checks pass against source and shipped Android game resources. They dispatch screen-touch plus Android-style emulated mouse events directly over the enabled Craft fishing rod button. Swipes scroll or respect list bounds without crafting; taps consume each ingredient once. Portrait and landscape are covered. These checks use a separate isolated fixture to avoid inheriting the unrelated garden test's scroll state.

Regression suites pass with isolated profiles: 266 gameplay/save, 35 camp survival/building, 25 auto pickup, 73 Survival mode, 76 Survival kit, 107 farming, 109 desktop, 45 spellbook and 87 native menu scrolling checks. The menu suite includes the fishing journal. The shipped Windows pack also passes 20 general release checks. Passing logs contain no script errors or failed checks. The release fishing prompt test accepts the desktop E prefix as well as the mobile wording.

Android release export and ZIP integrity checks pass. apksigner verifies v2/v3 signatures using the existing certificate SHA-256 79a1ef0f60f3b4c6e65bd42cc422b28c7e969dd5ae54b0ddc77242f9287bab37. Manifest: app.runebound.godot, code 22 / 0.15.0-wild-waters, minimum API 24, target API 35, ARM64. The native template was recovered from the previous APK after removing its old game resources and signing metadata, then exported and signed anew. Windows export uses the matching Godot 4.5.1 x64 runtime and current version metadata. Both shipped packs execute the new fishing logic in the engine.

Limits: Android installation and native Windows executable startup, rendered appearance, physical touch feel, audio and device FPS have not been tested on hardware here. The new artwork is code-drawn in the existing style. Engine checks do not establish physical-device performance or long-term fishing balance. No rendered screenshot QA is claimed.

## Historical verification

# 0.14.0 Trailcraft verification

76 dedicated kit checks pass against the source and again against both the compiled Windows pack and the exact resources extracted from the signed Android APK. They cover old-save defaults, invalid ownership/cooldown rejection, six-charge save validation, exact crafting costs, reachable workbench requirements, duplicate prevention, no free water, real spring refill and drink consumption, winter/summer exposure and live Survival ticks, cloak toggling, unchanged gear, bedroll costs and limits, hostile/wildlife checks, dungeons/building/defeat guards, persistence, active-time cooldown, normal bed regression, menu/button bounds and phone-gauge separation from class controls.

Regression suites pass: 266 gameplay/save checks, 35 camp survival/building, 25 auto pickup, 107 farming, 109 desktop, 73 Survival mode, 45 spellbook and 83 touch-menu scrolling checks. The scrolling suite includes the kit menu in portrait and landscape. The compiled Windows pack also passes its 20 general release checks. Passing logs contain no script errors or failed checks. Tests use isolated local profiles. Initial concurrent runs of three suites ended without check output, so those suites were rerun sequentially to obtain their actual passing results.

Android export succeeds. ZIP integrity, compiled kit/game/data/UI scripts and native ARM64 library are checked. apksigner verifies v2/v3 signatures with the unchanged certificate SHA-256 79a1ef0f60f3b4c6e65bd42cc422b28c7e969dd5ae54b0ddc77242f9287bab37. Manifest: app.runebound.godot, code 21 / 0.14.0-trailcraft, minimum API 24, target API 35. The clean native template was recovered from the previous signed APK with old game assets and signing metadata removed, then exported and signed anew.

Windows x64 export succeeds; its exact compiled pack is exercised above. The native Windows executable and Android APK were not run on physical devices. Headless engine checks do not establish rendered appearance, audio, touch feel, Windows graphics-driver support or achieved device FPS. An X display could not open a listening socket here, so no rendered screenshot QA is claimed. The portable editable project has empty custom-template fields; source excludes build output and test profiles.

## Historical verification

# 0.13.0 Wilds & Wonders verification

73 Survival mode checks pass: migration of old characters to Classic; malformed needs rejection; real active-play food/water/rest drain; pause behavior; spring proximity and E interaction; flask capacity and charge consumption; raw and cooked food consumption; tea; cold, winter, summer heat, snow, fire fuel and roof effects; real deprivation damage without passive recovery cancelling it; exhaustion movement penalty; safe bed rest and its supply costs; garden harvest objective; chapter goal reward and repeat protection; mode switching without refill; five-floor Survival completion and Classic floor-six regression; defeat recovery; responsive gauge and menu widths; JSON roundtrip.

45 spellbook checks pass: legacy starter loadout; invalid ranks and slot rejection; merchant proximity, level, price and rank caps; slot swaps; preview without mana consumption; cancel with right click or Escape; confirmation spending once; delayed meteor damage and burn; placement wall blocking; cooldown; chain jumps; directional ice lance swept collision and slow; repeated blizzard pulses and expiry; Sunburst heal/damage; Ward's reduction in real enemy strikes and lack of deprivation immunity; pause and scene cleanup; native menu widths; hotbar labels and saved assignments. Quality controls and fixed light-pool behavior are checked.

All 20 integration suite runs pass with isolated local profiles: auto pickup, desktop, safe desktop boot, gameplay/save, menu scrolling, rotation, movement in both orientations, live frames in both orientations, camp survival/building, opening forest, region/class expansion, presentation, contracts, weather, trader, farming, Survival mode and spellbook. There are no script errors in passing logs. The final hotbar, artwork and Survival fatal-damage adjustment were rechecked with the desktop, Survival mode and spellbook suites.

Windows x64 release export succeeds. Its actual compiled Runebound.pck passes 20 release checks, including native keyboard/aimed input, auto pickup, menu pause, save export, enabling Survival and actual gauge drain, buying/equipping Meteor, preview/confirmation/expiry, Survival supplies, lighting-pool presence and native draw callbacks. PE architecture and 0.13.0.0 product metadata are verified.

Limits: the Windows PE executable was not run on Windows in this environment. The compiled pack was loaded with Linux Godot using its exported laptop feature. A native rendered graphics display could not be opened here; no screenshot, Windows GPU FPS, audio, actual fullscreen behavior, file-picker or physical device validation is claimed. Balance of the five-day chapter and spell economy still needs playtesting. No new Android APK is included.

## Historical verification

# 0.12.0 Laptop Edition verification

109 desktop checks passed with real native input events and engine callbacks. Coverage includes desktop detection; 1280x720 logical view; hidden touch joystick; native mouse hotbar; physical WASD input, release and normalized diagonals; world-space pointer aim; held attacks, cooldown repeats and release over UI; keyboard attacks; hotbar taps without duplicate world actions; preserving aim while hovering GUI; aimed arrows and Firebolt without a locked target; mana costs; shifted physical skill keys; forward sword arcs and miss animations; shelter restrictions; keyboard/right-mouse dodges and fixed dodge direction; R/E/Escape construction controls; camp/map/equipment shortcuts; automatic combat toggle; paused calendars; focus-loss handling; hotbar and menu bounds at 1366x768, 1920x1080 and 960x540; settings, F11 and view changes; saved aim/view preferences; 30/60 FPS caps; native Save-dialog configuration; filesystem export, validated shared JSON and real import callbacks with partial crops; failed-write reporting; and native world/reticle drawing. One additional safe-mode boot check confirms Close view, windowed preference, 30 FPS and disabled weather particles.

The exported Windows Runebound.pck was loaded separately with the same Godot 4.5.1 Linux engine, without a source-project path or desktop override. Twelve release-pack checks passed: shipped laptop feature, bytecode boot, current metadata, farming/trader inclusion, real keyboard movement, aimed combat, hidden mobile controls, paused camp menu, JSON export/validation, automatic resource pickup and native draw callbacks. This validates the exported data pack; it does not constitute executing the Windows PE binary on Windows.

Automatic resource pickup from 0.11.1 is retained. Its 25 dedicated checks passed, including capacity protection, paused/build/dungeon guards, seasonal yields and the actual Pause toggle. The merged builds use Android version code 19 so they update over 0.11.1 code 18.

Phone regression suites passed: 266 gameplay/save, 79 native touch-menu scrolling, 39 rotation/layout, 35 survival, 48 opening/shrine, 94 regions/abilities, 33 presentation/map, 72 contracts, 61 weather, 99 trader and 107 farming checks. Movement passed 55 checks and live frames passed 23 checks in each orientation. Passing runs had no script errors. Phone joystick and spell coordinates are retained; desktop-specific behavior is gated off on Android.

Windows release export succeeded using the official Godot 4.5.1 Windows x86_64 release template. It was fetched from the official export-template archive using byte ranges and validated against the archive directory's CRC and uncompressed size. Template SHA-256: 78ccc576e8f8bffd7ef6ad6f36ebd72a41e609a1052225a55b3407c96ea84065. The generated executable is a PE x86-64 image with current product resources. Its game pack is separate. ANGLE/OpenGL driver paths are present; external imports are Windows system DLLs. The Windows build is an unsigned prototype. Native Windows startup, actual GPU support, fullscreen transitions, audio and laptop FPS have not been tested on a Windows machine here.

Android release export succeeded. apksigner verifies v2/v3 signatures with the unchanged certificate SHA-256 79a1ef0f60f3b4c6e65bd42cc422b28c7e969dd5ae54b0ddc77242f9287bab37. Manifest: app.runebound.godot, version code 19 / 0.12.0-laptop-edition, minimum API 24, target API 35, ARM64. The matching phone update adds the file-export button needed for character transfer. Native Windows/Android file-picker UI has not been exercised on physical devices; configured dialog modes and the selected-path read/write/import callbacks were tested headlessly.

The release has local saves and explicit JSON transfer, without automatic device synchronization. View and display preferences are separate from character progression. Desktop manual combat changes aim and hit direction but retains normal damage, enchantments, cooldowns, collision and shelter rules; automatic combat retains assisted targeting. Wider views increase draw work, and achieved FPS/long-term balance still need device playtesting. No store publication, accounts, payments or analytics were added.

## Previous release evidence

# Auto pickup 0.11.1 verification

25 dedicated Godot engine checks passed, including actual game-tick collection, walking into range, seasonal yields, tutorial progression, immediate disk saves, duplicate prevention, manual fallback, pause/build/defeat/dungeon guards, door blocking and opening, capacity preservation, skipping full stacks, cooldowns, persistent settings and the actual Pause toggle.

Regression suites passed: 266 gameplay/save checks, 35 survival checks, 107 farming checks and 79 native touch-menu scrolling checks. No script errors or failed checks were emitted. Tests used separate local profiles.

ARM64 Android release export succeeded. apksigner verifies v2/v3 signatures using the same certificate as the downloaded 0.11.0 APK. Package app.runebound.godot; version code 18 / 0.11.1-auto-pickup. Physical phone installation and playtesting were not performed here.

# 0.11.0 Camp Farming verification

107 farming checks passed: old-camp compatibility and empty-plot defaults; actual ghost placement and exact material costs; twelve-plot bound and moving at the cap; walkable plots and overlap rules; outdoor construction; actual stored-plot identity; nearby and line-of-sight guards; safe world prompts that preserve wild gathering beside plots; menu entry; carried ingredients and discovery gates; seed consumption; preventing duplicate planting, early harvest and stale actions; real game-tick growth; exact spring/winter and season/year transitions; paused native physics; partial and ripe disk saves; no offline catch-up; moving and rotating without losing crops; continued growth while exploring caves and dungeons; clearing refunds and full-stack protection; all three fixed harvest yields; ready-crop persistence; one-shot reward and emptied-plot disk persistence; existing cooking and trader integration; planting/clearing/harvesting UI; both menu orientations and horizontal bounds; native scenery draw callbacks for crop stages; protected dismantling and half-material refunds; malformed crop and excessive-plot save rejection.

79 native touch-menu checks passed across portrait and landscape. They dispatch touch plus Android-style emulated mouse events to the viewport, covering swipes and single taps over Plant, Clear and Harvest, as well as inventory cards, descriptions, upgrades, character points, and existing camp, class, realm, quest, trader and guide pages. Swiping spends no ingredients, gold or points and does not collect a crop. Page changes cancel old scroll momentum. Short lists correctly stop at their bounds.

Regression suites passed: 266 gameplay/save, 35 survival, 48 opening/shrine, 94 region/ability, 33 presentation/map, 72 contracts, 61 weather, 99 trader and 39 layout/rotation checks. Movement passed 55 checks and live native frames passed 23 checks in each orientation. The final garden interaction-range adjustment was checked again with farming, touch menus, gameplay/save, movement and rotation. Passing runs had no script errors.

Gardens are bounded to twelve within the existing sixty-four-structure camp limit. Growth uses the saved active-play calendar with a constant-time seasonal integral, adds no enemy actors or per-plot timer nodes, and invalidates retained scenery only when a crop changes visual stage. These implementation bounds are not phone FPS measurements. Crop durations, yields and their effect on the trading economy still need gameplay feedback.

Android release export succeeded. apksigner verifies v2/v3 signatures with the unchanged certificate SHA-256 79a1ef0f60f3b4c6e65bd42cc422b28c7e969dd5ae54b0ddc77242f9287bab37. Manifest: app.runebound.godot, version code 17 / 0.11.0-camp-farming, minimum API 24, target API 35, ARM64. APK ZIP integrity and the new compiled farming, game, HUD, scenery, survival, data and UI-art scripts were verified. The editable project's custom-template setting remains portable.

This APK has not been installed on a physical phone here. Actual screen appearance, touch comfort, audio, GPU performance and long-term balance still require phone playtesting. No store publication or monetization occurred.

## Previous release evidence

# 0.10.0 Camp Trader verification

99 trader checks passed: old-save defaults; all 13 offers; remote and unknown purchase guards; world interaction and paused UI; advertised bundle quantity, exact price and finite stock; no menu/level reroll; unaffordable and sold-out purchases; real Rare enchanted equipment; stock persistence through save and character reload; paused restock timers and new-day level snapshots; 10%/15% quest discounts; discounted purchase/resale inequalities across all supplies and equipment at levels 1 and 1000; equipped-item protection; exact spare-item sale payout and receipt state; stale-ID rejection; saved upgraded and enchanted items; persistent buyback across days; remote/unaffordable/full-bag buyback; recovery fee and one-shot exact restoration; last-eight receipt bounds; stack overflow and invalid sale quantities; underground trading rejection and exit guidance; persistent trader tracking; Buy/Sell/Buyback menu widths in both orientations; map marker touch selection and tracking; construction clearance; native drawing callbacks; malformed trader state and fractional receipt rejection.

59 native menu-scroll checks passed, including the trader page, portrait and landscape, taps versus swipes, resource protection and previous-page momentum. Existing suites passed: 266 gameplay/save, 35 survival, 48 opening/shrine, 94 region/ability, 33 presentation/map, 72 contracts, 61 weather and 39 layout/rotation checks. The 55-check movement and 23-check live-frame suites each passed in portrait and landscape. The final compact shop header passed the 99 trader checks and 59 scrolling checks; the final map-caption placement passed the 99 trader checks and 33 presentation checks. Passing runs had no script errors.

Mara is retained scenery and a bounded, event-driven trading manager. Buyback holds at most eight equipment dictionaries, stock has thirteen known entries and no NPC movement/AI loop is added. These are implementation bounds, not measurements of phone GPU time or FPS. Prices and long-term reward balance still need gameplay feedback.

Android release export succeeded. apksigner verifies v2/v3 signatures with the unchanged certificate SHA-256 79a1ef0f60f3b4c6e65bd42cc422b28c7e969dd5ae54b0ddc77242f9287bab37. Manifest: app.runebound.godot, version code 16 / 0.10.0-camp-trader, minimum API 24, target API 35, ARM64. APK integrity passed; compiled trader, HUD, map, contracts, weather, game and card scripts are present. Source export-template settings remain portable.

This APK has not been installed on a physical phone here. Actual touch comfort, visual appearance, audio and GPU performance still require phone playtesting. No store publication or monetization occurred.

## Previous release evidence

# 0.9.1 Touch Scroll verification

The reported problem was reproduced on the unmodified 0.9.0 source: a swipe beginning on an inventory card did not move the list. The same test passed after allowing menu buttons, selectable cards and decorative panels to pass pointer events to the enclosing native ScrollContainer. Combat touch controls retain their own event handling. No character-save format change was made.

55 native menu-scroll checks passed across portrait (1080x2400) and landscape (2400x1080). The test enables the engine's touchscreen path and dispatches touch events plus the corresponding emulated mouse events through the viewport, rather than calling button callbacks or changing the scroll value to simulate a gesture. Programmatic scroll positioning is used only to reveal the starting control before a gesture. Assertions cover card swipes in both directions, item-detail panel swipes, swipes over upgrade and stat buttons without spending resources, single normal taps that select or upgrade once, camp/classes/realm/quest/guide content and bounds, cancellation of previous-page momentum, and isolation from character controls. Menus whose content fits entirely correctly stay at zero scroll.

Regression checks passed: 266 gameplay/save, 35 survival, 48 opening/shrine, 94 region/ability, 33 presentation/map, 72 contracts, 61 weather, and 39 rotation/layout checks. The 55-check movement and 23-check live-frame suites passed in both portrait and landscape. No script errors occurred in the passing runs.

Android export succeeded. apksigner verifies v2/v3 signatures and the unchanged certificate SHA-256 79a1ef0f60f3b4c6e65bd42cc422b28c7e969dd5ae54b0ddc77242f9287bab37. Manifest: app.runebound.godot, version code 15 / 0.9.1-touch-scroll, minimum API 24, target API 35, ARM64. ZIP integrity passed. Both compiled HUD and card scripts differ from the prior APK; contract, weather, map and main-game scripts remain bundled. The native export base was recovered from the previous verified APK with its old game assets and signing metadata removed, then exported and signed afresh. Source export-template settings remain portable.

No physical phone was available for this test. Actual device touch comfort, screen appearance and GPU smoothness still require phone playtesting. No store publication occurred.

## Previous release evidence

# 0.9.0 Frontier Jobs verification

72 contract checks passed. Coverage includes six posted jobs, no automatic acceptance, old-save migration, board proximity and interaction, UI acceptance and compact Active/Posted views, duplicate and active-cap guards, delivery readiness after spending or storage transfer, exact material consumption, remote claim rejection, reward previews and payouts, one-shot claims, paused and repeatable cooldowns, actual enemy defeat events and duplicate-death protection, enemy variant matching and neutral exclusions, saved bounty progress, abandonment, new survey visits and duplicate-visit protection, objective tracking and turn-in bearings, actual distinct floor clears and floor-reload protection, underground board guidance, full-bag milestone preservation, guaranteed Rare and Epic enchanted rewards, saved claim state, map/job tracking replacement, portrait/landscape menu width and tracking actions, malformed save rejection, and construction clearance around the board.

Regression suites passed: 61 weather checks, 266 gameplay/save checks, 35 survival checks, 48 opening/shrine checks, 94 regional/ability checks, 33 presentation checks and 39 layout/rotation checks. The 55-check movement suite and 23-check live-frame suite both passed in portrait and landscape. After compacting the quest menu, the 72 contract checks and 33 presentation checks passed again on the final source. Tests use native headless Godot frame callbacks and dispatched touch events; no script errors occurred.

The board uses retained static scenery, accepts at most three active jobs, and checks survey proximity at half-second intervals. It adds no moving actors, particles or enemy spawns. This is a bounded implementation claim, not a new phone performance benchmark.

Android release export succeeded. apksigner verifies v2/v3 signatures with the existing certificate SHA-256 79a1ef0f60f3b4c6e65bd42cc422b28c7e969dd5ae54b0ddc77242f9287bab37. Manifest: app.runebound.godot, version code 14 / 0.9.0-frontier-jobs, ARM64, minimum API 24, target API 35. APK ZIP integrity passed and compiled contracts, weather, world-map and game scripts are present. Editable project export settings use a portable empty custom-template path.

This APK has not been installed on a physical phone here. Screen appearance, touch comfort, audio, GPU smoothness, background behavior and longer-term reward balance still need device playtesting. No store publication or monetization was performed.

## Previous release evidence

# 0.8.0 Turning Seasons verification

61 weather checks passed: full season boundaries and annual wrap, deterministic regional weather, underground exclusions, old-save defaults and malformed time rejection, four palette transitions, seasonal resource bonuses, exact roof cover, shelter/fire combinations and fuel exhaustion, cozy health and mana recovery, tea crafting/consumption/duration/nonstacking, saved calendar and buff expiry, paused time/fuel, unchanged winter movement speed, combat exclusion of recovery bonuses, particle caps, real native rain/snow/fog/underground draw callbacks, effects disabling, and Camp Journal integration.

Existing suites passed: 266 gameplay/save checks, 35 survival checks, 48 opening/shrine checks, 94 region/class checks, 33 presentation/menu/map checks, and 39 layout/rotation checks. Both portrait and landscape passed 55 movement checks and 23 live-frame checks each. The live-frame suite dispatches real touch events through the viewport and verifies ongoing physics and drawing. No script errors occurred. The new tea icon and weather integration were covered by a final rerun of the presentation and weather suites.

A headless 38-enemy benchmark at a 900x900 logical viewport measured draw-command construction mean 219 microseconds (p95 370), tick mean 301 microseconds, and one retained scenery rebuild across the stationary draw benchmark. These are scripting measurements in this environment, not GPU time, phone FPS, or a guarantee of device smoothness. Weather drawing is capped at 18 precipitation particles in low power or 42 normally; effects can be disabled independently.

Signed ARM64 release APK verified: app.runebound.godot, version code 13 / 0.8.0-seasons, minimum API 24, target API 35. Android apksigner verifies v2/v3 signatures with the unchanged prototype certificate SHA-256 79a1ef0f60f3b4c6e65bd42cc422b28c7e969dd5ae54b0ddc77242f9287bab37. APK ZIP integrity passed; compiled weather, world-map, UI-art and game scripts are present. The editable project restores portable export-template settings.

This build has not been installed on a physical phone here. Screen appearance, sound, touch comfort, GPU performance and extended gameplay balance still need phone playtesting. No store publication or monetization was performed.

## Previous release evidence

# 0.7.0 Wayfinder verification

33 presentation checks passed: selectable equipment icons, equipped markers, item details and equip action, weapon filtering, crafting-card output, supply counts and food actions, horizontal layout bounds, full map visibility in portrait and landscape, map-marker touch selection, tracking and return to play, local-map bounds, saved home/ruins tracking, spell effects, real draw callbacks, bounded effects, expiry, and scene cleanup.

The existing 266 gameplay/save checks, 94 regional/skill expansion checks, 39 mobile layout and rotation checks, and 23 live-frame movement checks passed during integration. Rendering commands and control geometry were exercised headlessly. A native screenshot review was unavailable in this environment; actual screen appearance, touch comfort, GPU performance, and audio still need phone playtesting. No store publication or monetization was performed.

Signed ARM64 APK verified: app.runebound.godot, version code 12 / 0.7.0-wayfinder, existing prototype certificate, valid Android v2/v3 signatures. New map and visual-menu scripts are present in the APK.

## Historical checks

# 0.6.0 Four Realms verification

94 expansion checks passed. They cover four regional identities and resource sets, first-discovery rewards, cave wall collision and safe recovery of older saves, regional crafting and armor output, reed rope, wolf pack alerts and different approach directions, fleeing nonaggressive wildlife and hunting supplies, archer spacing, all three adventure trials, combo/dash/bow requirements, class unlocks, regional relic claims and duplication protection, all eight exclusive skills with mana/cooldown effects, live drawing of new creatures in each region, first-dungeon rewards, persistent exploration, and legacy-save defaults.

The existing 266 gameplay/save checks, 35 survival checks, 48 forest milestone checks, 39 mobile layout/rotation/input checks (including the skill button), 55 movement/camera/cache checks, and 23 live-frame movement checks also passed during integration.

A synthetic headless benchmark with 38 enemies at a 900x900 logical viewport measured mean draw-command construction of 238 microseconds and mean tick work of 430 microseconds, with one stationary scenery rebuild. These are scripting measurements, not GPU frame time or phone FPS. They do not establish physical-device performance.

This build uses existing save identities and adds validated exploration defaults. In-progress regional fights restart after leaving/relaunching; finished discoveries, trial unlocks, and pending/claimed rewards persist. Audio playback is skipped under the headless display driver; original sound assets are loaded but not auditioned on phone here. Physical graphics, touch comfort, sound, long sessions, and gameplay balance still require device playtesting. No store publication or monetization was performed.

Signed ARM64 release verified: app.runebound.godot, version code 11 / 0.6.0-four-realms. Android v2/v3 signatures use the existing prototype certificate. Compiled exploration/ability scripts and new audio are present in the APK.

## Historical verification

# 0.5.1 thumb layout verification

39 orientation/layout/input checks passed at four portrait and landscape window sizes. They verify the landscape joystick inset, portrait spell bottom alignment, extra space above combat controls, nonoverlapping touch targets, movement input after rotation, and construction controls. This update changes layout only. Physical-phone comfort still needs device confirmation.

Signed ARM64 APK version code 10 / 0.5.1-thumb-layout uses the existing package and certificate. Android v2/v3 signatures verified.

## Prior checks

# 0.5.0 Heart of Mossveil verification

- 48 forest milestone checks passed: opening objective progression, construction preview/cancel/confirmation, rotation, movement and projectile blocking, relocating structures, door passage and safe closure, bed recovery and defeat return, storage conservation and persistence, dismantling refunds, attack telegraphs, avoiding damage by movement and dash, boss encounter/phase changes, class unlock, full-bag reward handling, one-time reward claiming, saved progression, canopy placement, old-save defaults, menu opening, and audio asset availability.
- 266 existing gameplay/save checks passed. The 35 survival checks passed during integration. 23 real-engine live-frame movement checks and 33 orientation/layout/input checks passed, including construction controls in portrait and landscape.
- Audio is original synthesis, included as WAV files. Headless runs deliberately skip playback; asset loading is checked, but device audio has not been auditioned here.
- This is a playable development milestone. Physical-phone graphics, audio, performance, long-session stability, and balance require playtesting. No commercial-readiness certification, public store release, or monetization was performed.

Signed ARM64 release: app.runebound.godot, version code 9 / 0.5.0-mossveil. Android v2/v3 signatures verified with the existing prototype certificate. The APK includes the forest, survival, audio scripts, and imported music.

## Historical checks

# Godot 0.4.1 rotation and controls verification

29 rotation checks passed at 1080x2400, 2400x1080, 1280x720, and 720x1280 window sizes. Checks exercise viewport scaling, orientation changes, nonoverlapping bottom controls, on-screen placement, larger touch targets, touch cancellation and re-entry after rotation, and preservation of character state. The 23 live-frame checks also passed, confirming continuous drawn movement remains active. Android physical rotation still requires device playtesting.

APK version code 8 / 0.4.1-rotation passed v2/v3 signature verification with the existing certificate.

## Prior checks

# Godot 0.4.0 camp and crafting verification

- 35 survival checks passed: gathering and depletion, timed resource regrowth, plank and rope recipes, construction costs and spacing, cooking range and fuel requirements, refueling, menu pause, food healing and consumption, shelter protection and recovery, outgoing attack restriction, workbench gating, weapon crafting, enemy detection and retreat, saved materials/structures, legacy-save migration, malformed-structure rejection, and opening the Camp menu.
- The existing 266 gameplay/save checks, 55 movement/camera checks, and 23 real-loop drawing checks passed on this update.
- Version code 7 / version name 0.4.0-campcraft uses the existing app.runebound.godot package and prototype signing key. Materials and buildings are added to the existing JSON character save, with defaults for older saves. The exported ARM64 APK passed Android v2/v3 signature verification with the same certificate as the prior update; package/version were checked with aapt.
- Headless engine tests passed; this APK has not been playtested on a physical phone here. Mobile visual layout, balance, and long sessions still need device playtesting.

## Prior verification

# Godot 0.3.3 live movement verification

## Confirmed defect and correction

On the 0.3.2 source, the World node reported `is_processing() == false` and its animation clock advanced by exactly zero across ten engine frames. The game physics callback was enabled. The World script had been attached after the node entered the scene tree; manually calling `_ready()` initialized graphics but did not enable its `_process()` callback. Character coordinates moved while drawing remained stale until another action requested a redraw.

The script is now attached directly in `main.tscn`. Godot initializes it and enables frame processing normally. The same check now reports processing enabled and a changing animation clock. The camera's large area jumps have also been replaced by continuous scrolling of only the distance walked beyond the visible boundary.

## Checks for 0.3.3

- All 266 gameplay/save regression checks passed.
- All 55 movement, camera, cache, and save checks passed at both 480x900 and 1688x900 logical viewports. Crossing a boundary by one pixel now moves the camera by only one pixel.
- All 23 live-frame checks passed in both orientations. These dispatch touch press/drag/release events and allow actual engine physics and drawing callbacks to run. They do not call `tick()`, `_process()`, `_draw()`, or `queue_redraw()` manually. Draw callbacks receive advancing hero positions on successive frames in all four directions. Animation advances, releasing touch stops movement, pausing stops animation, and camera motion never exceeds character motion in a frame.
- APK release: package app.runebound.godot, version code 6, version name 0.3.3-live-movement. The existing prototype signing key and JSON save format are retained. Android apksigner verified v2/v3 signatures; the certificate SHA-256 matches the prior APK. Manifest inspection confirmed the package and version.

These headless tests exercise frame callbacks and drawing commands, not a physical phone GPU or touchscreen. Physical-device gameplay remains untested here. Earlier coordinate-only checks missed the disabled world callback; they did not establish live rendered movement.

## Historical verification records

### Godot 0.3 verification

Completed using the official Godot 4.5.1 Linux editor/runtime and matching Android export templates:

- The actual Godot project imports, parses, and runs headlessly.
- 267 regression checks passed with the legacy export fixture, including 120 seeded dungeon connectivity checks and weighted loot sampling. The standalone source suite runs 266 checks without the optional fixture.
- Tests cover old character migration, malformed imports, day/night boundaries, night spawn ratio, class unlocks, upgrade and enchant actions, equipped-item salvage protection, bow projectile collisions, spell cooldown and mana handling, dungeon collision, locked stairs, saved enemy defeats, unique floor rewards, fifth-floor bosses, expedition restoration, full bags, defeat loss, atomic saving, and backup recovery.
- Independent movement and spell touch indexes are exercised through Godot InputEventScreenTouch objects.
- Native frames rendered with Godot's OpenGL Compatibility renderer using Mesa software rendering. Title, wilds, dungeons, gear, realm, class menu, and landscape views were inspected. The virtual environment has no physical audio device; its renderer and audio device messages are environmental and no sound assets are included.
- A signed ARM64 Android release APK was exported using Godot's Android export system. Android apksigner verifies v2 and v3 signatures.
- Manifest inspected: `app.runebound.godot`, version code 3, minimum Android API 24, target API 35.
- The original app's Save Transfer Android update compiled successfully with the existing package/signing key. Its bundled game script contains the export action, which routes the character JSON to Android's document-create picker.
- The Save Transfer export payload is compatible with the Godot migration schema. Imported old dungeon expeditions return safely to the wilds.

The APKs have not been installed on a physical phone in this environment. Real device performance, physical multitouch, Android document picker save/import, background lifecycle behavior, and extended gameplay balance still require phone playtesting. Headless and rendered desktop tests do not establish those outcomes.


## Historical 0.3.1 movement and performance update

The user clarified that the character stayed centered while the map scrolled. This was the follow-camera behavior; it is not, by itself, evidence of lag. The update adds camera drag margins, stronger walking animation, and a visible movement indicator.

- The original standalone 266-check suite passed again on the updated source.
- Eleven new checks passed for world-space movement, visible screen-space movement before camera follow, animation start/stop, scenery cache reuse, 30/60 FPS limits, progression preservation, incremental terrain retention, bounded terrain size, and save compatibility.
- A 38-enemy synthetic benchmark was run in the same Godot 4.5.1 headless environment at a 900x900 logical viewport. Render-command construction mean fell from 863 microseconds to 110 microseconds (240 measured samples after warmup). Tick-loop mean fell from 117 to 76 microseconds (600 ticks). This measures scripting and command generation, not GPU time or phone frame rate. It is one desktop-environment run, not a hardware performance guarantee.
- Scenery rebuilt once across the stationary 250-frame benchmark; previously its geometry was rebuilt every drawing frame.
- A signed update uses the existing package and signing key with version code 4. The existing JSON character format is retained.

Actual phone smoothness, device GPU behavior, and camera preference still need confirmation on the user's phone. The prior visual review describes the 0.3 version; it is not a claim that this 0.3.1 APK has been exercised on physical hardware.


## 0.3.2 fixed-view movement update

This version removes camera following and drag margins. Touch input moves the hero across a stationary view. The camera changes area only when the hero crosses a playable boundary. Static scenery, terrain generation, and actor culling use the camera position so that the opposite side of the screen remains populated when the hero is off center.

- The standalone 266-check regression suite passed.
- The 51-check movement suite passed at logical viewports 480x900 (portrait) and 1688x900 (landscape). InputEventScreenTouch and InputEventScreenDrag were dispatched through the viewport, rather than assigning a direction directly. All four directions moved the hero more than 125 logical pixels while the camera and world landmarks stayed stationary. Touch release stopped movement. All four area transitions kept the hero within the playable view and left the camera fixed afterward. Terrain and scenery covered each new view. Save compatibility and 30/60 FPS settings passed.
- The signed ARM64 APK exported successfully. Android apksigner verified v2/v3 signatures and the same certificate SHA-256 as the prior APK. Manifest inspection confirmed app.runebound.godot, version code 5 / version name 0.3.2-area-camera.
- These are headless engine checks. The 0.3.2 APK has not been installed or playtested on a physical phone here. The historical rendering review and performance benchmark above do not establish phone performance for this build.
