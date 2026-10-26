## v0.28.0 phone checks still needed

Install over the existing app without clearing data. Track each new side expedition from Camp/Quests. Follow the branch trail in and out, use joystick and D-Pad in both orientations, open the mechanism, dodge hazards and both guardian patterns, collect treasure, leave and revisit. Save/close/continue mid-expedition; verify run progress. Check paused defeat recovery and survival needs. Record FPS/heat/battery on the actual phone and native Windows input/audio separately.

# 0.27 custom controls device playtest

On Motorola Edge 2025, install over the existing app without clearing data. Verify
character/camp continuity. In Settings → Controls → Customize Layout:

- Drag every control, including top menu and contextual build/cast controls.
  Minimize Tools to reach the top row. Resize with the corner and 50–200% slider;
  check the visual/hitbox edges at every size and dark-dungeon skin/opacity.
- Test Save/Cancel, Undo/Redo, confirmed Reset, Preview → Return to Edit, overlaps,
  autofix, assignment swaps, hidden optional controls, all built-in presets and
  create/rename/overwrite/delete personal presets. Force-close/relaunch and verify
  both orientations and selected preset remain.
- Hold joystick or D-Pad while attacking, casting, dodging, building and opening
  inventory. Try D-Pad two-finger diagonals, opposing directions, sliding out/back,
  floating-stick exclusion around buttons, canceled touches, background/resume,
  controller hotplug and rotation while fingers are down.
- Check cutouts, system navigation/gesture edges, portrait and both landscape
  directions on phone/tablet. Record haptics and real gamepad mappings/hiding.
- Repeat moving/aiming/attacking/casting in a six-enemy outdoor battle and a castle
  room. Measure 30-minute FPS, RAM, heat/battery; distinguish renderer/GPU limits
  from responsiveness. Native Windows must retain keys, mouse, hotbar and gamepad.

These physical checks remain pending. Automated evidence is in VERIFICATION.md.

---

# 0.26.0 Four Kingdoms device playtest

Export the current character, install the matching-key APK over the existing app and keep app data. Confirm your class, level, inventory, camps, chest contents and story progress remain.

1. Camp → Castle expeditions: track all four castles on the map. Walk bridges and ramps in both directions. Follow the marker after distant travel and check facing on maps.
2. Enter each real gate. Find key/mechanism, inspect side rooms and guarded vaults. Go up and back down. Save/reload midway and confirm defeated guards/keys remain.
3. Bind a checkpoint, read the rune order, solve/reset the puzzle, use the secret shortcut, then die/reload to confirm checkpoint retention and stated gold loss.
4. Dodge warnings, defeat miniboss/boss phases and claim equipment, spell and forging material. Try a full bag before claiming, then make room. Assign/cast the exclusive spell and craft its unlocked recipe at a bench.
5. Return outside via entrance/final exit and revisit camps. Test portrait and both landscape rotations, held joystick plus attack/dash/cast, menus/scrolling, background/resume, audio and save export/import.
6. Start on Performance / Reduced crowds. Record frame time/FPS, memory, heat and battery for a 30-minute mixed session including blizzard, swamp fog, six-enemy combat and the four boss arenas. Try Balanced only if comfortable. Record exact location/settings of any slowdown.
7. On Windows, start the extracted EXE with its PCK, test keyboard/mouse, audio, save continuity, resize and low-power/OpenGL launchers.

These physical checks are pending; automated results are in VERIFICATION.md.

---

# Fieldcraft 0.24.0 — graphics checks

- Install over the prior app; retain character and settings. Reduced crowds should stay selected.
- Visit Broken Caravan, Silent Watch and Ashen Grove. Check that wagon/tent/burnt stump are recognizable and investigation still pays once.
- Gather wood, plants, ore, resin, crystals, glowcaps and reeds in each biome; confirm auto pickup, quantities and regrowth still work.
- Try Performance graphics, rotate portrait/landscape, and inspect nearby labels. New art should remain visible at every quality without added per-prop lights.
- Open a story runic cache once; check its artwork, mana/gold reward and closed/used state.
- Report any remaining ambiguity, overlap or sustained phone slowdown. Native phone rendering/FPS/heat/audio and Windows startup require hardware playtesting.

# Crowd Relief 0.23.1 — urgent phone checks

The player reported severe slowdown when many enemies accumulate. This is user evidence of a performance problem, not an FPS measurement.

1. Install over the previous game; keep existing data. Reduced crowds should already be ON in Pause.
2. Walk through the forest and snow for 10 minutes. Check joystick response, scrolling and fighting wolves/archers; note whether crowds still cause slowdown.
3. Test night and a busy fight. Ambient population should stay smaller; 30/60 FPS must not raise the crowd cap.
4. Try the Hollow Root and Ash and Oath. Required encounters remain, attacks still warn, menus pause, rewards stay correct.
5. If slowdown remains, report region/dungeon floor, approximate enemy count, active spells and whether the phone is hot. Native phone FPS/thermal/audio and Windows startup remain unmeasured here.

# Ash and Oath 0.23.0 — new player checks

- Install over the previous game; do not uninstall or clear data. Confirm your character, camp and graphics setting remain.
- Claim Chapter I, speak with Mara in Camp → Story journal, then track Ash and Oath.
- Complete Emberforge's sword + magic trial (or confirm a prior win counts). Claim its regional relic, read the inscription and start the ashen binding.
- Dodge the Keeper's warnings, defeat it and both embers. Check the phase below half health and readability on your phone.
- Pause, rotate, resume; retreat beyond the clearing or reload mid-fight. Confirm you can retry and no chapter completion was granted.
- Return to Mara; claim 350 gold, 6 essence and 2 points exactly once. Export/import the character and confirm Chapter II stays complete.
- Native Android update/install, Windows startup, real touch/audio and sustained performance remain hardware checks. Engine/package tests do not replace them.

# v0.22.0 — VYRNSPIRE rename and camp stores

Install Vyrnspire-Godot-v0.22.0.apk over the existing Runebound app without uninstalling/clearing data. Confirm the launcher/title show VYRNSPIRE and Continue loads the same character, chapter, camp and settings. Export a JSON and confirm its filename uses VYRNSPIRE; old JSON exports should still import.
Near a Storage chest open Camp → Choose supplies to store or take. Store five Wood while keeping Berries carried, take one back, then test maximum and stack limits. Reopen the app and check both carried/stored counts. Try a chest behind a wall/closed door, then open it and retry. Check native scrolling/controls in both orientations. On Windows launch Vyrnspire.exe and verify the old character remains; keep the existing historical user-data folder.

# v0.21.0 — camp provisioning

Install over the existing app and keep the same character. Camp → Craft → Parts: Choose quantity on Plank, select 5 and confirm. Check ten Wood were spent and five Planks added. Cancel another preview and check nothing is spent. Try Maximum and a shortage preset. Repeat with food beside a lit campfire; cooking should put food in Supplies without eating/healing/refilling needs. Eat a portion separately.
Check station access through an open/closed door, extinguish the fire and check cooking disables. Try the quantity controls and scrolling in both orientations. Save/reopen and confirm ingredients/output persist. Existing single Make, building placement/movement and regional discovery recipes should still work. User already reported the v0.20.1 character recovery works; retain that recovery menu for future stuck positions.

# v0.20.1 — recover the affected character

Keep the current app/data and install the patch over it. Continue the same character. Open Pause → Recover stuck character → Return to original camp · keep my character. Confirm you are paused back in Mossveil with the same gear, gold, levels, camp and quest state. Review survival supplies before resuming. The saved bed stays where you placed it.
Move in all four directions, then open World map. Around me should center your arrow; World overview should include your actual location and home. Travel across the snow boundary, pause/resume, rotate, then save/reopen and check movement again. If movement still fails, provide the recovery screen's Position coordinates and whether the joystick knob moves. The exact cause of the reported movement lock has not been confirmed from the user's actual save.

# v0.20.0 Dreadwood — graphics phone checks

Install over the existing app; keep its data. Confirm the same character and chapter state load. Compare skeletons, archers, wolves and The Hollow Heart with the last build. Check that silhouettes/eyes are visible on your phone and that warning circles, health bars, attacks, dropped items and touch controls remain readable.
Pause → Graphics offers Performance (default), Balanced and Rich. Test Performance first, then Balanced with low power on/off. Return to Performance if needed. Reopen the app and confirm your choice persists. Rotate while playing and while scrolling Graphics. Check rain/snow and a crowded fight. Report measured FPS, heat/battery behavior and whether the enemies look scary enough at your normal zoom. Native Windows startup/audio still need laptop testing.

# v0.19.0 Enemy Tactics — next phone checks

Install over the current app, keep its data, and confirm the same character and Chapter I state load.
Fight ranged enemies in a regular dungeon: they should hold range, back off when approached, and remain reachable in corners. Follow the gold line to identify a shooter. Walk out of a warning circle, dodge through one, then break sight behind a wall. Check that only standing in an unobstructed warning at impact takes damage.
Approach a mixed group: melee enemies should spread without walking through walls. Confirm wolves still flank and The Hollow Heart retains both phases. Pause during a warning and resume; it should continue from the paused point. Test portrait and landscape on the phone, then repeat a mixed encounter with battery saver enabled.
Report unexpected hits, stuck enemies, small-screen warning visibility and measured FPS/heat. Automated Linux runs do not establish these device outcomes.

# Final playtest checklist — 0.18.0

Record device, OS, prior app version, test date, outcome and any exact error. These are pending hardware checks, not completed tests.

## Motorola Edge 2025 / Android 16

1. Export a character backup from the installed v0.15.0 app. Install v0.18.0 over it without uninstalling. Continue and compare level, gear, gold, camp, discoveries and fishing records.
2. Hold movement, use a second finger for attacks/spells, release each finger independently, then rotate while moving. Test both landscape directions, portrait and orientation lock.
3. Swipe inventory cards, upgrade buttons, supplies, crafting and fishing pages. Swipes must scroll without spending anything; taps must act once.
4. Switch apps, turn the screen off and resume while moving or holding attack. Movement and attacks must stop; needs/world time must pause while away.
5. In Survival, watch rain wet clothing; test a roof, shelter, fire, extinguished fire and fire behind a closed wall. Check Classic does not drain needs.
6. Test a bed behind a wall, then a reachable bed near peaceful wildlife. Test shelter/disengage during enemy telegraphs and dodge before impact.
7. Learn and equip Meteor Fall / Blizzard. In both orientations, choose and drag a target, move with another finger, then CAST or CANCEL. Check Back, dodge, rotate, focus loss, wall-blocked ground and mana lost during preview. Confirm there is no accidental cast when releasing over CAST. Compare forward melee/miss animations and ordinary-enemy stagger against bosses. Buy/equip/cast every learned spell; run all regional trials, a five-floor Survival expedition, fishing/cooking, gardens, crafting, moving/dismantling buildings, storage and quest rewards.
8. Play 30–60 minutes with normal/battery-saver settings. Record frame time/FPS, heat, battery, memory, crashes and audio issues. Do not infer phone performance from Linux tests.
9. Export/import character JSON, close/relaunch, and compare progression. Keep the external backup throughout testing.

## Windows

Extract the entire ZIP. Check normal, low-power and OpenGL launchers; startup, audio, mouse aim, keyboard, fullscreen, menus, save/reload and Android JSON transfer. Repeat core RPG/Survival loops and a 60-minute session. Native Windows execution is distinct from testing the compiled PCK in the Linux engine.

## Commercial-release work

Complete hardware bug fixes and balance/pacing passes; expand main quest/dungeon content; review visual/audio consistency, accessibility and controller needs; review asset rights/credits and the original shared prototype signing identity before choosing a store/distribution signing plan. Do not replace the existing personal-update key without an explicit migration plan.

## New chapter playtest

Visit Mara, accept the missing-camps story, recover all three clues in any order, translate, and enter the story option at the ruins. Check journal bearings, optional caches, purple-rune warning timing, boss phase readability, final stairs, return to Mara and one-time rewards. Reload mid-investigation and mid-dungeon; verify progress. Test Hearthcall after cooldown and near enemies. Report actual completion time and difficulty; no target duration has been established.

User previously reported v0.17 installs and is playable, including controls. This is user-reported basic playability, not measured FPS, upgrade-save validation or testing of v0.18.

## 0.25.0 — Thornwatch hardware checks still needed

Install over the existing app; do not uninstall or clear data. Compare the same
character, inventory, built camp and stored supplies. Track Thornwatch through
Camp → Quests. Cross the bridge both ways, climb/descend the marked ramp and
enter/exit the keep. Exercise key/seal locks, optional vault, checkpoint death,
mid-run save/reload, guardian telegraphs and full-bag legendary retry. Test
portrait/landscape and real multitouch while moving, attacking and dodging.
Keep Reduced crowds and Performance graphics initially; report any frame drops,
heat or stuck positions during at least 30 minutes of play. Also test native
Windows EXE startup and old-save continuity on the laptop. None of these device
results is implied by the automated Linux engine checks.
