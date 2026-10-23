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
