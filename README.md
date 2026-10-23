# Runebound 0.12.0 — Laptop Edition

An offline native Godot/GDScript Android RPG prototype. Four explorable regions now have distinct terrain, resources, enemies, recipes, and landmark discoveries. All eight classes have exclusive active abilities, and hidden classes can be unlocked through adventures. Camp construction, attack warnings, dodging, original audio, and saved character progression are retained. This is a development build, not a certified store-ready release.

## Auto pickup — 0.11.1

Walk within 65 world units of a wild resource to collect it automatically. Auto pickup starts ON and can be switched under Pause > Auto pickup; the preference is remembered on this device. It uses the existing gathering sound, notification, seasonal bonuses, tutorial progress, resource respawn and immediate saves. Checks run at most five times per second with the existing half-second gather cooldown.

Walls and closed doors block collection. Full or nearly full material stacks leave the entire resource waiting; other nearby materials can still be collected. Menus, defeat, dungeon expeditions and active building placement suspend collection. Manual GATHER continues to work when auto pickup is OFF. Enemy gold, XP, hides, meat and equipment rewards already enter the inventory automatically. Chests, gardens and camp interactions still require their normal buttons.

## Install and play

Install Runebound-Godot-v0.12.0.apk over the existing **Runebound Godot** app. Do not uninstall or clear app data if you want to retain your character. The package and signing certificate are unchanged. Pause identifies this update as **0.12.0 · Laptop Edition**.

The APK supports ARM64 Android 7.0+ devices with OpenGL ES 3.0. It runs independently of an editor or Termux. Turn the phone sideways, or choose Pause > Landscape view. Portrait and Auto-rotate are also available. Low power selects 30 FPS or 60 FPS. Pause > Sound and music controls all audio and remembers your choice.

## Play on a Windows laptop (0.12.0)

Download **Runebound-Windows-v0.12.0.zip**, choose **Extract all**, then open **Runebound.exe** in the extracted folder. Keep Runebound.pck beside it. No Godot editor, Python, Termux or emulator is needed. This is a Windows 10/11, 64-bit x86 build; it is not a Chromebook or macOS build.

Laptop mode replaces the touch joystick with keyboard movement and a compact mouse-friendly hotbar. The initial window is sized for a typical laptop desktop. Resize it or press F11 for fullscreen. Pause > Laptop settings and controls lets you choose Close, Balanced or Wide world views, 30/60 FPS, weather effects and mouse aim. Close makes the character larger; Wide shows more terrain. Preferences persist separately from character progression. A fresh laptop setup defaults to a 60 FPS cap; the frame cap is not a guarantee of achieved FPS.

| Action | Laptop control |
| --- | --- |
| Move | WASD or arrow keys; diagonals are normalized |
| Aim | Mouse over the world; GUI buttons preserve the last world direction |
| Attack | Hold left mouse button or Space |
| Dodge | Shift or right mouse button; held movement sets dodge direction |
| Interact / place | E; clicking the world also places the active building ghost |
| Rotate / cancel building | R / Escape |
| Fire / Frost / Heal | 1 / 2 / 3 |
| Class skill | Q |
| Automatic combat | T |
| Camp / equipment / map | C / I / M |
| Pause / fullscreen | Escape / F11 |

With mouse aim enabled, manual sword attacks use a forward arc, bows/staves shoot toward the pointer, and Firebolt can be aimed without locking onto an enemy. Attacks can miss. Existing damage, cooldown, enchantment, collision and shelter rules still apply. Automatic combat retains assisted targeting of alerted enemies; disable mouse aim for the original assisted manual targeting. Class skills keep their existing targeting rules. Menus and focus loss pause play and release held attacks.

The Windows build uses the Compatibility renderer through ANGLE / Direct3D 11, with native OpenGL fallback. **Start-Low-Power.bat** starts with the Close view, 30 FPS, weather particles off and a window instead of fullscreen. **Start-OpenGL.bat** tries native OpenGL if the default graphics path has trouble. GPU support and real laptop performance still depend on the installed graphics driver. The executable is an unsigned development build; Windows may identify its publisher as unknown. See the official [Godot 4.5 requirements](https://docs.godotengine.org/en/4.5/about/system_requirements.html) and [Compatibility driver options](https://docs.godotengine.org/en/4.5/classes/class_projectsettings.html#class-projectsettings-property-rendering-gl-compatibility-driver-windows).

### Bring a phone character to the laptop

1. Install the matching 0.12.0 APK over the phone app without uninstalling.
2. In the phone game, open Pause > Export character save and save the JSON in Downloads.
3. Move that JSON to the laptop using USB or your usual file transfer.
4. On the laptop title screen, choose Import a character save and select it.

The export includes levels, gear, gold, camp, gardens, quests and discoveries. Both editions use the same validated character format. Each device then keeps its own local save; future progress does not sync automatically. To move back, export from the laptop and import on the phone. Import replaces the current character on the receiving device, so export that character first if you want to keep it. The existing clipboard backup remains available if the phone's file picker cannot save to a selected location.

## Camp farming (0.11.0)

Open **Camp > Garden plots** and choose **Place a Garden**, or find Garden under **Camp > Build**. Each plot costs 4 Wood, 2 Stone and 2 Fiber. Position and rotate its ghost, then confirm PLACE. Gardens use outdoor ground, leave paths walkable and count toward the existing 64-structure camp limit. You may build up to 12 gardens. Caves and dungeons cannot receive new plots.

Walk up to the soil and tap **TEND GARDEN**. You can also open Garden plots from Camp anywhere to review your crops and their bearings; planting, clearing and harvesting require being within 110 units with a clear path to the actual plot. The world prompt only takes over within 48 units, keeping nearby wild resources gatherable. Use carried ingredients for planting; withdraw stored materials first.

| Crop | Planting cost | Harvest | Summer / Autumn growth time |
| --- | --- | --- | --- |
| Berries | 2 Berries | 6 Berries | 3 minutes |
| Herbs | 2 Herbs | 5 Herbs | 3 minutes 30 seconds |
| Glowcap | 2 Glowcap | 5 Glowcap | 4 minutes; discover the Veil Altar first |

Spring growth is 25% faster, winter growth is 25% slower. The menu shows progress and estimated remaining seconds at the current season's rate; the rate changes when a new season begins. Seasonal gathering bonuses apply to wild resource nodes, while gardens use the fixed yields above. Outdoor crops continue growing as you explore other regions or dungeons. Menus and time away pause growth, with no offline catch-up. Growth and planted crops are saved with the character.

Soil changes from seedlings to larger plants, then ripe crops with a READY label. Ready crops do not spoil. Tap **Harvest** nearby to collect ingredients and reuse the empty plot. A full carried stack leaves the harvest waiting. Gathered ingredients work in all existing cooking, storage, delivery and trading systems.

Move or rotate a planted garden through the existing construction controls without losing the crop. Harvest or clear it before dismantling. **Clear crop** returns only the two planting ingredients and resets growth; dismantling an empty garden returns half its building materials. There is no watering chore or cold damage to crops in this version. Native swipe scrolling works over Plant, Clear and Harvest buttons without activating them.

## Mara's camp market (0.10.0)

Mara has a permanent trading stall northeast of the original starting camp at (448, -256). Open **Camp > Trader Mara > Track Mara**, or select her marker on the World map. Approach within 110 units and tap **TRADE WITH MARA**. You may browse from anywhere, but purchases, sales and buyback require visiting her in the wilds. Trading menus pause the world.

The shop has **Buy**, **Sell** and **Buyback** pages, with **Supplies** and **Gear** filters where appropriate. Native swipe scrolling works over the cards and buttons, and worn equipment is protected from sale.

| Stock | Offer |
| --- | --- |
| Supplies | Wood, Stone, Fiber, Herbs and Iron bundles |
| Meals | Roasted berries, Herbal stew and Warm tea |
| Rare equipment | Guaranteed enchanted sword, bow and staff; a Travel Coat |
| Epic equipment | A guaranteed enchanted relic weapon; its weapon kind rotates by game day |

Stock is finite and refreshes when the saved play clock enters a new 10-minute game day. Menus and time away pause that clock. Gear level is fixed for that day's stock when checked, rather than rerolling on every visit; it updates on a new day, up to level 1000. Gear previews show rarity, power, enchantment and a raw power comparison against the equipped item in that slot. This comparison is not a DPS estimate.

Sell spare equipment individually or carried supplies in quantities of 1, 10 or all. Stored materials must be withdrawn first. A sale preview quotes the gold paid. Equipped items cannot be sold; choose different equipment in Gear first. Purchases reject insufficient gold, sold-out offers, full equipment bags or overflowing material stacks without charging or losing stock.

The last **8 equipment pieces sold** remain in Buyback across saves and game days. Recovery restores the exact item ID, level, power, upgrades and enchantment. It costs the sale payout plus 10%, rounded up, with at least 1 extra gold. Buying back removes that receipt, and a full bag or insufficient gold leaves it pending. Selling a ninth piece removes the oldest receipt. Supplies are not kept in Buyback.

Completing **6 quest-board jobs** earns 10% off shop purchases. **18 jobs** earns 15% off. Buyback fees do not receive this discount. Existing quest completion counts apply immediately. Prices, stock counts and receipts are saved locally; there are no real-money purchases or network requirements.

Mara and her stall use the existing retained drawing style and add no moving enemies or AI update loop. New construction keeps the center of the stall approachable. Existing equipment, classes, camp structures, seasons, quests, control placement and character progression carry over.

## Touch menu scrolling (0.9.1)

Swipe up or down directly over inventory cards, item descriptions, upgrade buttons, crafting panels, or other list content. The list follows your finger and uses Godot's native inertia after release. You do not need to grab the scrollbar or find an empty patch of background.

Menu buttons and decorative panels now pass pointer events to their enclosing ScrollContainer. Selectable gear cards do the same; noninteractive supply cards retain their ignore behavior. The native scroll-start notification cancels the pending button press when movement crosses the 12-logical-pixel gesture threshold. A tap still selects an item or performs a single upgrade; a swipe over Upgrade or Add point does not spend gold or points. The page header and tabs remain outside the scrolling list.

No character, gear, camp, quest, season or control-layout migration is introduced. Install this patch over the existing app without uninstalling.

## Quest board and repeatable jobs (0.9.0)

A wooden quest board stands northwest of the starting camp at (-128, -48). Walk close and tap **QUEST BOARD**, or open **Camp > Quest board and active jobs**. You can review and track jobs anywhere; accepting and turning in require being within 120 units of the board in the wilds. **Track quest board** gives a live bearing back to it. The compact menu has separate **Posted** and **Active** pages.

| Job | Objective |
| --- | --- |
| A roof over Mossveil | Deliver 18 carried Wood and 8 Stone |
| Food for the trail | Deliver 3 carried Roasted berries |
| Wolves on the road | Defeat 6 wolves or frost wolves after accepting |
| Break the ambush | Defeat 4 archers or ice archers after accepting |
| Beyond the green border | Revisit Emberforge, Veil Altar, and Winter Oath after accepting |
| Light in the deep | Clear 2 new dungeon floors after accepting |

Accept up to three jobs at once. Deliveries consume supplies only at turn-in; withdraw stored materials first. Existing carried supplies can be delivered. Bounties count only new matching defeats, and neutral wildlife never counts. Survey jobs require new visits within 90 units of each landmark, even when already discovered. Reloading or revisiting a rewarded dungeon floor does not duplicate progress.

Each job previews its gold, XP and essence reward; gold and XP scale with the level at acceptance. Turning in also grants 10 renown. Every third completion adds a guaranteed Rare enchanted weapon of your currently equipped weapon kind. Every ninth completion gives Epic instead. The weapon level is the accepted job's level (capped at 1000). If the 40-item bag is full on a milestone, the entire turn-in remains pending and supplies are kept until you make room. Normal non-milestone jobs can still pay currency with a full bag.

Completed jobs repost after 10 minutes of active play. Menus and time away pause the timer. Abandoning a job keeps your materials and forfeits that job's progress without a reward. Accepted jobs, progress, cooldowns, tracked job and completion count persist in the character save. Defeat does not cancel a job. Tracking a job replaces the map objective; choosing a map target or opening guide replaces job tracking. Inside a dungeon, board tracking directs you to the entrance stairs rather than giving a misleading wilderness bearing.

The board adds no moving actors or spawns. Its drawing is retained with static scenery; survey proximity checks run twice per second. Existing controls, seasons, building, classes, map and equipment menus remain available. New construction keeps the board approachable.

## Weather and seasons (0.8.0)

Spring, Summer, Autumn and Winter now follow the saved play clock. A day is 10 minutes of active play, each season lasts two days, and a full year lasts 80 minutes. Existing play time determines the current season. Pausing or closing the app freezes the calendar, fire fuel and food buffs; there is no offline catch-up.

Rain, clear skies, fog and snow vary by region in two-minute blocks. Frostfall stays snow-covered year-round; snow showers can pause. Caves and dungeons have no outdoor precipitation. Forest terrain and trees change appearance with the season; autumn adds drifting leaves and winter brings snow beyond Frostfall. The HUD shows season and weather. **Camp > Journal** gives the current day and gathering bonus.

| Season | Extra material per harvest |
| --- | --- |
| Spring | +1 Herbs or Fiber |
| Summer | +1 Berries or Resin |
| Autumn | +1 Wood or Glowcap |
| Winter | +1 Frost shard or Pine resin |

Stand under a Roof (its 64-unit footprint) or inside a Shelter (60-unit radius) to keep rain and snow off you. A lit Campfire within 100 units gives +1 mana/second outside combat. Combine fire with cover for +1 health and +2 mana/second, in addition to normal regeneration. A depleted fire stops granting the bonus. Shelter safety and its existing health recovery remain intact. Cold and rain do not damage you or slow movement.

Cook **Warm tea** at a lit fire for 2 Herbs and 1 Berries. Drink it from **Camp > Supplies** to restore 15 health and 15 mana, plus +1 mana/second outside combat for three active-play minutes. Another cup refreshes the timer; tea and fire recovery do not stack. The remaining buff time is saved with your character.

**Pause > Weather effects** disables particles and fog, while retaining the calendar and gameplay benefits. Low-power precipitation is capped at 18 particles, normal at 42. Scenery and terrain palettes rebuild only when needed. Thumb positions, equipment cards, map tracking, classes and camp management from 0.7.0 are retained.

## Touch layout

In landscape, the joystick moves 160 logical units inward from its previous position. In portrait, Fire, Frost, and Heal sit on the bottom row with 20 logical units of bottom clearance. Attack, Auto, and Dash use a shorter row above them, leaving 42 more logical units of the previous spell area clear. The exclusive class skill button sits above the joystick; Q activates it on a keyboard.

## Presentation and menus (0.7.0)

Gear now uses rarity-colored item cards. Filter by Weapons, Armor, or Trinkets, then select a card to see its full name, enchantment, power comparison, and equipment actions. A gold dot marks equipped items. The comparison shows raw item power versus the current item in that slot; it is not an estimated damage-per-second calculation.

Camp has Build, Craft, Supplies, and Journal pages. Make planks and rope from **Craft > Parts**, equipment from **Craft > Gear**, and meals from **Craft > Food**. Eat carried food from Supplies. Building placement, nearby structure management, storage, and refueling remain available.

Open **World map** from Camp or Pause, or press M. The overview shows the four regions, landmarks, ruins, your return point, camp structures, and your position. Tap a marker and choose **Track selected** to update the objective and return to play. Home and ruins tracking persist with your character. **Around me** switches to a local map; **World overview** restores the broad view. The map is a navigation overview, not a tile-by-tile fog-of-war system.

Combat adds distinct fire impacts, frost expansion, healing marks, lightning links, class runes, and dash afterimages. Enemy warning rings fill as impact approaches. Effects expire and are capped at 24 in low-power mode or 48 in normal mode. Camera behavior and thumb-control positions are retained.

## Opening journey and discoveries

1. Follow the objective beneath the health bars. Approach a labeled tree and GATHER wood.
2. Gather stone, open Camp, and place a campfire. Gather berries and cook while near the lit fire.
3. Make planks and rope, then build a shelter.
4. Follow the bearing to **Mossveil Ruins**, southeast of the start at (520, 320). Approach its stone doorway and enter the dungeon. Clearing your first floor awards 50 gold and 2 essence once. Find the green entrance stairs to return, or use Realm > Leave dungeon.
5. Seek the **Elder Shrine** northeast at (760, -520). Defeat the Root Warden, avoiding its red attack warnings. Victory unlocks Arcane Archer and a unique Epic enchanted weapon claimed at the shrine.

Camp > Journal includes a regional journal with discovery status, bearings, and challenge instructions. Track any landmark to replace the current objective with its direction and distance. **Resume opening guide** returns to the starter objectives. Regional landmarks each award 30 gold and 2 essence on first discovery and unlock their recipes. Progress and pending relic rewards persist.

| Region | Direction and landmark | Resources, enemies, recipes, and challenge |
| --- | --- | --- |
| Mossveil Forest | Central region; Elder Shrine northeast | Resin, wolves in packs, archers, deer; Ember-enchanted Resin blade. Defeat the Root Warden for Arcane Archer. |
| Hollowdeep Caves | East beyond x=1400; Emberforge at (2050, 0) | Rock walls, connected mine passages, Iron, Crystal, crystal wisps and skeletons; Storm-enchanted Crystal staff. Strike the Forge Sentinel with both a sword and magic before defeating it to unlock Spellblade. |
| Whisperfen Swamp | West beyond x=-1400; Veil Altar at (-2050, 0) | Dark marsh pools, Reeds, Glowcap, bog toads and wisps; Reed rope, Bog remedy, Trail stew. Defeat three Veil Shades and use DASH during the trial to unlock Reaper. |
| Frostfall Reach | North beyond y=-1400; Winter Oath at (0, -2050) | Snow terrain, conifers, snowfall, Frost shards, Pine resin, frost wolves and ice archers; Frost-enchanted bow. Land a bow hit and use DASH before defeating the Winter Sentinel to unlock Arcane Archer. |

Successful regional trials grant 70 gold, 4 essence, and a unique Epic relic claimed at their landmark. Failed requirements allow a retry. Full equipment bags leave rewards pending. Trial fights restart if abandoned or the app is closed; completed trials and claimed rewards remain saved. The shrine and trial clearings cannot be obstructed with buildings.

Caves are part of the continuous world and include solid walls with connected openings and a broad main corridor. Previously saved characters inside a newly introduced cave wall are moved to a nearby open position on load.

## Exclusive class skills

The dedicated skill button above the joystick shows its mana cost and cooldown. Skills respect walls and shelter restrictions. Switch classes from Gear > Paths; old achievement-based unlock requirements remain available alongside adventure unlocks.

| Class | Skill | Effect |
| --- | --- | --- |
| Warrior | Cleave | Wide melee damage and knockback. |
| Mage | Meteor | Burning magic blast around a target. |
| Ranger | Volley | Three arrows toward a target. |
| Rogue | Vanish | Four seconds of concealment and faster movement; attacking breaks concealment. |
| Cleric | Sanctuary | Six-second healing circle with pulses that damage enemies. |
| Spellblade | Runeburst | Combined melee and magic strikes. |
| Arcane Archer | Star Volley | Five arrows with chain lightning. |
| Reaper | Soul Harvest | Area damage and health recovery. |

Class silhouettes use different hats, hoods, armor details, auras, and insignia. Walking limbs and held weapons respond to facing and movement. Bows recoil, sword attacks sweep visibly, and staffs show a glowing tip. Equipped weapon type, enchantment color, helmet, and shield remain visible.

## Combat

Joystick or WASD/arrows moves; ATTACK or Space attacks. Auto attacks engage alerted enemies in the wilds. Wilds enemies have limited detection ranges and return home when you escape. Wisps and archers keep their distance. Wolves spawn in packs, alert nearby pack members, and approach from different sides. Deer flee and never start attacks; automatic combat leaves them alone. Hunting deer supplies Raw meat and Hide for cooking and leather armor. Enemy attacks show red circles before damage; leaving a circle avoids it, and dash grants brief protection. Your attacks show a directional slash and play action sounds. Walls and closed gates block movement and attack sight lines.

Gathering, cooking, building, magic, impacts, and wolves have distinct original synthesized sounds, with a looping music track and a mute setting.

Fire, Frost, and Heal use mana. All previous classes, hidden class requirements, weapons, enchantments, upgrades, loot, day/night, renown, settlement buildings, and dungeon progression are retained. Arcane Archer can now also be unlocked by defeating the Root Warden.

## Build your camp

Collect Wood, Stone, Fiber, Berries, Herbs, and Iron from marked resources. Nodes return after three minutes of active play. Camp shows recipe costs and missing requirements.

Choosing **Place** enters construction mode without spending materials. Walk to position the snapped ghost in front of your character. ROTATE changes orientation; PLACE confirms; CANCEL spends nothing. Invalid locations appear red. Keep the shrine clearing and return point open.

- **Shelter:** a safe recovery circle; outgoing attacks and damaging spells are disabled while inside.
- **Campfire:** cooking station, initially fueled for 90 seconds. Each wood adds 90 seconds, up to the displayed capacity.
- **Workbench:** craft level-scaled Rare bows and iron swords for Gear.
- **Wall / Door:** solid building pieces. Closed doors block passage and attacks. Walk nearby and use OPEN/CLOSE DOOR. A door cannot close through your character.
- **Bed:** stand nearby, open Camp, and rest to restore health/mana and set your return point after defeat. Rest requires nearby enemies to be clear. Moving a bed clears the return point until you rest again.
- **Storage:** deposit or withdraw carried materials from Camp. Contents persist. Empty a chest before dismantling it.
- **Roof:** a translucent decorative canopy that can overlap furnishings. It has no weather or shelter protection mechanic.

Open Camp near a structure to move it or dismantle it. Moving preserves its contents and costs no new materials. Dismantling refunds half the recipe (rounded down, minimum one of each ingredient). The current limit is 64 structures. Materials do not use equipment-bag slots.

Cooking produces roasted berries (35 health), herbal stew (70 health and 25 mana), roasted meat (50 health), Bog remedy (35 health and 50 mana), or Trail stew (85 health and 15 mana). Eat them from Camp > Supplies. Menus pause gameplay, fuel consumption, and resource timers. There is no hunger, offline fuel burning, or multiplayer.

## Saves and older versions

Progress saves locally to character.json with a backup. New journey, construction, and return-point fields are added when older Godot saves load. Existing character progression and structures are preserved. Saving never packages test profiles into the APK.

For the original non-Godot v0.2 app, install the optional migration/Runebound-v0.2.1-Save-Transfer.apk over that original app, then Pause > Export character for Godot. Import the resulting JSON from the Godot title screen. The apps have separate private save locations. Imported old dungeon expeditions return to the wilds. The optional migration Android source is included in migration/legacy-android.

## Editable project

Extract Runebound-Godot-v0.7.0-Project.zip and import Runebound-Godot/project.godot in Godot 4.5.1 (standard GDScript edition). The project uses the Compatibility renderer and no external plugins. On Android, use the Godot Android editor to import and run the project.

Key source files:

- scripts/game.gd: movement, combat, camera, and building interaction.
- scripts/desktop.gd: laptop detection, mouse aiming, directional combat, window and view preferences.
- scripts/farming.gd: gardens, crop growth, planting, harvesting and clearing.
- scripts/weather.gd: seasons, weather and camp comfort.
- scripts/contracts.gd / trader.gd: repeatable jobs, shop stock, sales and buyback.
- scripts/survival.gd: resources, recipes, construction, storage, beds, and enemy behavior.
- scripts/forest.gd: opening objectives, first-dungeon reward, Elder Shrine, Root Warden, and unique rewards.
- scripts/exploration.gd: regions, caves, landmark discoveries, enemy selection, and adventure trials.
- scripts/abilities.gd: exclusive class skills and cooldowns.
- scripts/hud.gd: responsive touch controls, filtered menus, map selection, and equipment details.
- scripts/ui_art.gd / ui_card.gd / ui_icon.gd: reusable native item and material icons.
- scripts/world_map.gd: region overview, map markers, and local navigation view.
- scripts/world.gd / scenery.gd: native drawing, actors, telegraphs, structures, and shrine.
- scripts/game_audio.gd / assets/audio: original synthesized music and action sounds.
- scripts/data.gd: progression, validation, migration, and saves.

## Windows export

Install matching Godot 4.5.1 export templates. The Windows preset adds the laptop feature tag, exports a 64-bit executable plus Runebound.pck and includes the native desktop controls. Create builds/Windows first, then run:

```bash
godot --headless --path . --export-release Windows builds/Windows/Runebound.exe
```

Keep the EXE and PCK together. Windows metadata and the icon are set during export; no external resource editor is required. A public release would need its own signing arrangement. The downloadable laptop ZIP also includes the player guide, licenses and optional low-power/OpenGL launchers.

## Android export

Install matching Godot 4.5.1 export templates and configure Java 17 plus an Android SDK in Editor Settings > Export > Android. The portable Android preset exports ARM64 without Gradle. Create the builds directory, then export with:

```bash
GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$PWD/signing/REPLACE_WITH_YOUR_PRIVATE_VALUE.jks" \
GODOT_ANDROID_KEYSTORE_RELEASE_USER=runebound \
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=REPLACE_WITH_YOUR_PRIVATE_VALUE \
godot --headless --path . --export-release Android builds/Runebound-Godot-v0.12.0.apk
```

The package is app.runebound.godot, version code 19, version name 0.12.0-laptop-edition. The deliberately shared personal prototype signing key is included to allow updates to this prototype. Use a private release signing arrangement before public store distribution. This update does not publish a store listing or add payments, advertising, analytics, accounts, or cloud saves.

## Verification

Run tests with `godot --headless --path . --script res://tests/test_forest.gd`; other suites are in tests/. They create local fixture saves, so use a separate test profile or back up development saves. See VERIFICATION.md for the exact checks and limits. Desktop checks use `--script res://tests/test_desktop.gd -- --desktop`; safe-mode checks add `--safe-mode` with test_desktop_boot.gd. The exported Windows PCK can be checked with the same-version Linux engine and the absolute path to tests/test_release_pack.gd. Engine tests do not replace physical Windows/phone playtesting or player feedback about balance, sound, appearance, and long sessions.
