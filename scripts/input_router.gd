extends Node

# Virtual sources are aggregated separately so releasing a touchscreen finger
# can never release a keyboard/gamepad action held by another device.
var game
var held:Dictionary={}
var virtual_actions:Dictionary={}
var trigger_down:Dictionary={}
const KEYS={"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_up":[KEY_W,KEY_UP],"move_down":[KEY_S,KEY_DOWN],"attack":[KEY_SPACE],"dodge":[KEY_SHIFT],"skill":[KEY_Q],"spell_1":[KEY_1],"spell_2":[KEY_2],"spell_3":[KEY_3],"interact":[KEY_E],"inventory":[KEY_I],"camp":[KEY_C],"map":[KEY_M],"pause":[KEY_ESCAPE],"auto":[KEY_T],"build_rotate":[KEY_R],"spellbook":[KEY_B],"needs":[KEY_V],"fullscreen":[KEY_F11]}
const JOY={"attack":JOY_BUTTON_A,"dodge":JOY_BUTTON_B,"interact":JOY_BUTTON_X,"skill":JOY_BUTTON_Y,"spell_1":JOY_BUTTON_LEFT_SHOULDER,"spell_2":JOY_BUTTON_RIGHT_SHOULDER,"pause":JOY_BUTTON_START,"inventory":JOY_BUTTON_BACK,"move_left":JOY_BUTTON_DPAD_LEFT,"move_right":JOY_BUTTON_DPAD_RIGHT,"move_up":JOY_BUTTON_DPAD_UP,"move_down":JOY_BUTTON_DPAD_DOWN}

const UI_JOY={"ui_accept":JOY_BUTTON_A,"ui_cancel":JOY_BUTTON_B,"ui_left":JOY_BUTTON_DPAD_LEFT,"ui_right":JOY_BUTTON_DPAD_RIGHT,"ui_up":JOY_BUTTON_DPAD_UP,"ui_down":JOY_BUTTON_DPAD_DOWN}

func _ready() -> void:
	for action in KEYS:
		ensure_action(action)
		for code in KEYS[action]:
			var key=InputEventKey.new();key.physical_keycode=code
			if not InputMap.action_has_event(action,key): InputMap.action_add_event(action,key)
	for action in ["build_cancel","cast_confirm","cast_cancel","auto","look_left","look_right","look_up","look_down"]: ensure_action(action)
	for action in JOY:
		var button=InputEventJoypadButton.new();button.device=-1;button.button_index=JOY[action]
		if not InputMap.action_has_event(action,button): InputMap.action_add_event(action,button)
	# Declare pad UI bindings explicitly; headless/exported projects may only
	# supply keyboard defaults, and menu access must not depend on touch.
	for action in UI_JOY:
		ensure_action(action)
		var button=InputEventJoypadButton.new();button.device=-1
		button.button_index=UI_JOY[action]
		if not InputMap.action_has_event(action,button): InputMap.action_add_event(action,button)
	for binding in [["move_left",JOY_AXIS_LEFT_X,-1],["move_right",JOY_AXIS_LEFT_X,1],["move_up",JOY_AXIS_LEFT_Y,-1],["move_down",JOY_AXIS_LEFT_Y,1],["look_left",JOY_AXIS_RIGHT_X,-1],["look_right",JOY_AXIS_RIGHT_X,1],["look_up",JOY_AXIS_RIGHT_Y,-1],["look_down",JOY_AXIS_RIGHT_Y,1],["spell_3",JOY_AXIS_TRIGGER_LEFT,1]]:
		var axis=InputEventJoypadMotion.new();axis.device=-1;axis.axis=binding[1];axis.axis_value=binding[2]
		if not InputMap.action_has_event(binding[0],axis): InputMap.action_add_event(binding[0],axis)
		if binding[0].begins_with("move_"):
			var ui_action="ui_"+binding[0].trim_prefix("move_");ensure_action(ui_action)
			if not InputMap.action_has_event(ui_action,axis): InputMap.action_add_event(ui_action,axis)

func ensure_action(action:String) -> void:
	if not InputMap.has_action(action): InputMap.add_action(action,.18)

func movement() -> Vector2:
	var touch=Vector2(virtual_strength("move_right")-virtual_strength("move_left"),virtual_strength("move_down")-virtual_strength("move_up"))
	# Keep the existing public move_vector used by legacy gameplay helpers.
	if not game.move_vector.is_equal_approx(touch): touch=game.move_vector
	return (touch+Input.get_vector("move_left","move_right","move_up","move_down")).limit_length(1)

func set_virtual_movement(value:Vector2) -> void:
	game.move_vector=value.limit_length(1)
	virtual_actions={"move_left":maxf(0,-game.move_vector.x),"move_right":maxf(0,game.move_vector.x),"move_up":maxf(0,-game.move_vector.y),"move_down":maxf(0,game.move_vector.y)}

func virtual_strength(action:String) -> float:
	return float(virtual_actions.get(action,0)) if InputMap.has_action(action) else 0.0

func press(action:String,source:String) -> void:
	if not game.playing: return
	if not held.has(action): held[action]=[]
	if source in held[action]: return
	held[action].append(source)
	if action=="attack": game.attack_held=true
	trigger(action)

func release(action:String,source:String) -> void:
	if held.has(action): held[action].erase(source)
	if action=="attack": game.attack_held=held.has("attack") and not held.attack.is_empty()

func is_virtual_held(action:String) -> bool:
	return held.has(action) and not held[action].is_empty()

func reset_virtual() -> void:
	held.clear();set_virtual_movement(Vector2.ZERO);game.attack_held=false

func trigger(action:String) -> void:
	if action=="fullscreen": game.desktop.toggle_fullscreen();return
	if action=="pause":
		if game.playing and not game.build_recipe.is_empty(): game.cancel_build()
		else: game.hud.back()
		return
	if game.hero.is_empty(): return
	if action in ["inventory","camp","map","spellbook","needs"]:
		game.hud.show_character({"inventory":"gear","camp":"camp","map":"map","spellbook":"spells","needs":"needs"}[action]);return
	if not game.playing: return
	match action:
		"attack": game.attack()
		"dodge": game.dash()
		"skill": game.abilities.use()
		"spell_1","spell_2","spell_3": game.spellbook.request_slot(int(action.right(1))-1)
		"interact":
			if not game.spellbook.targeting.is_empty(): game.spellbook.confirm()
			else: game.interact()
		"auto": game.hero.auto=not game.hero.auto;game.hud.update_hud();game.save_game()
		"build_rotate":
			if not game.build_recipe.is_empty(): game.build_rotation=(game.build_rotation+1)%4
		"build_cancel": game.cancel_build()
		"cast_confirm": game.spellbook.confirm()
		"cast_cancel": game.spellbook.cancel_target()

func handle_event(event:InputEvent) -> bool:
	if game.hud!=null and game.hud.controls!=null and game.hud.controls.editing():
		if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"): game.hud.back()
		elif event.is_action_pressed("fullscreen"): game.desktop.toggle_fullscreen()
		return true
	if event is InputEventJoypadMotion:
		if event.axis!=JOY_AXIS_TRIGGER_LEFT: return false
		var down=event.axis_value>.5;var previous=trigger_down.get(event.device,false);trigger_down[event.device]=down
		if down and not previous: trigger("spell_3");return true
		return false
	if not game.playing and event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_B:
		game.hud.back();return true
	if event is InputEventKey and event.echo: return false
	if not (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion or event is InputEventAction): return false
	for action in KEYS:
		if action.begins_with("move_"): continue
		if event.is_action_pressed(action): trigger(action);return true
	return false

func update_aim() -> void:
	var aim=Input.get_vector("look_left","look_right","look_up","look_down")
	if aim.length()>.2 and game.dash_time<=0: game.facing=aim.normalized()
