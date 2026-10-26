# VYRNSPIRE 0.27 — Your controls

Open **Settings → Controls → Customize Layout** from the title screen or Pause.
The editor uses the actual paused world and the real gameplay controls. Continue
or create a character to enable live Preview.

- Drag a control freely. Tap it (or select it in the control list and tap
  Options) to adjust horizontal/vertical position, size from 50–200%, opacity
  from 20–100%, appearance, visibility, or supported action assignments.
- The selected control's bottom-right handle also resizes it. Minimize the
  toolbar with **–** to reach controls behind it; **Tools** brings it back.
- Choose Joystick or D-Pad in the editor. Only the selected movement style is
  drawn. Both drive the same movement, class speed, collision, animation and
  dodge code. Diagonals never increase maximum speed.
- Grid and Snap help placement. Red outlines mark overlapping controls.
  **Fix overlaps** searches for nearby clear positions. Very large arrangements
  may require smaller buttons or hidden optional controls. Save warns before
  accepting remaining overlaps. Contextual building and spell-confirm controls
  may share space because they are never active together.
- Undo and Redo retain the last 50 edits. Reset asks before restoring the current
  orientation's defaults. Cancel discards every unsaved layout/preset change.
- Preview makes the adjusted controls live. **Return to Edit** freezes gameplay
  again. Preview does not save the layout; gameplay actions affect the current
  character normally. Save commits the arrangement and returns to Controls.

## Movement and accessibility

Controls offers fixed/floating joystick selection, sensitivity (0.5–2), dead zone
(0–40%), D-Pad spacing (0–30%), optional haptics and gamepad hiding. A floating
stick starts where you touch the lower movement half of the screen, excluding
other buttons. Repositioning movement to the right changes that half to the
right. The D-Pad supports single-finger diagonals and two held direction keys.
Sliding off an action releases its hold; sliding off a held D-Pad stops movement
and sliding back resumes it. Release, canceled touches, hiding, pause, focus
loss, rotation and device switching clear virtual finger ownership.

Gameplay locks all positions. Essential movement, attack, dodge, interaction
and pause remain assigned and visible when relevant. Assignment changes swap
supported slots rather than duplicate an action or lose attack. Inventory,
camp, map, spells and optional auto attack remain reachable through menus.
Five skins provide fantasy, stone, gold, purple and blue treatments. Subtle
shadows and light borders keep controls readable in dark dungeons.

## Presets and rotation

Classic RPG, D-Pad Classic, Compact, Large Controls, Left-handed, Combat,
Exploration and Custom are included. Combat favors larger attack/dodge targets;
Exploration hides some optional combat buttons. Presets → Save copy creates up
to 12 named personal arrangements. Load, Overwrite, Rename and Delete operate
on personal presets; built-ins cannot be overwritten or deleted. Editor preset
changes persist only after Save. Selecting a preset from Controls applies and
saves it immediately.

Portrait and landscape have separate normalized layouts. Rotate while editing
to customize each; resizing a window never replaces stored positions. Copy
layout to other orientation is optional. Geometry is recalculated against
Godot's stretched viewport and Android's display-safe area, with a small edge
inset. Extremely large controls are clamped to available bounds. Custom layout
overlaps are highlighted for the player's review rather than silently moved.

## Preferences and other input devices

Only `user://controls.json` (with atomic temporary write and backup) stores these
preferences. It contains movement, options, per-control appearance/assignment,
selected preset, both orientations and custom presets. Malformed values are
clamped/repaired; a damaged main file falls back to its backup. Character,
inventory, camp, quest and survival save formats are unchanged.

The InputMap router owns shared action names and aggregates touch axes/holds
without releasing physical-device actions. Keyboard and gamepad bindings work
independently. The Windows hotbar, mouse aiming and display options remain.

Keyboard: WASD/arrows move; Space attack; Shift dodge; E interact/confirm;
1–3 spells; Q class skill; T auto; I inventory; M map; C camp; B spellbook;
V Survival; R rotate building; Escape cancels targeting/building or opens menu;
F11 fullscreen.

Gamepad: left stick/D-pad move; right stick aim; A attack; B dodge; X interact or
confirm a ground spell; Y class skill; shoulders/left trigger spells; Back opens
inventory; Start opens/cancels menus. Connected gamepads receive initial menu
focus, standard UI navigation/accept, and B to return. Controls can hide touchscreen buttons when
a pad is connected, retaining Pause. Disconnecting restores the saved layout.
The game's edge-follow camera has no separate touch-pan sensitivity setting.

## Verification limits

Engine event injection, compiled APK/PCK resource suites and native Linux/Mesa
renders check layout and behavior. Physical Motorola Edge 2025/Android 16 touch,
cutout/navigation reporting, haptics, gamepad hardware, sustained phone battles,
and native Windows driver behavior require device playtesting. These results do
not establish phone FPS, thermal performance or commercial readiness.
