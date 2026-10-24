extends RefCounted

const Data=preload("res://scripts/data.gd")
const VIEWS={"Close":Vector2i(1000,563),"Balanced":Vector2i(1280,720),"Wide":Vector2i(1536,864)}
var game
var enabled=false
var view_name="Balanced"
var mouse_aim=true
var fullscreen=false
var mouse_attack=false
var pointer_seen=false
var pointer_screen=Vector2.ZERO

func initialize() -> void:
	enabled=OS.has_feature("laptop") or "--desktop" in OS.get_cmdline_user_args() or (OS.has_feature("pc") and DisplayServer.get_name()!="headless")
	if "--mobile" in OS.get_cmdline_user_args(): enabled=false
	if not enabled: return
	var config=ConfigFile.new()
	if config.load("user://desktop.cfg")==OK:
		var selected=config.get_value("display","view","Balanced")
		if selected is String and VIEWS.has(selected): view_name=selected
		var aim=config.get_value("controls","mouse_aim",true)
		if aim is bool: mouse_aim=aim
		var full=config.get_value("display","fullscreen",false)
		if full is bool: fullscreen=full
	if "--safe-mode" in OS.get_cmdline_user_args():
		view_name="Close";fullscreen=false
	var window=game.get_window()
	window.min_size=Vector2i(960,540)
	window.title="Runebound · Focused Combat"
	if DisplayServer.get_name()!="headless":
		var usable=DisplayServer.screen_get_usable_rect()
		window.size=Vector2i(mini(1152,maxi(960,usable.size.x-80)),mini(648,maxi(540,usable.size.y-100)))
		window.move_to_center()
		window.mode=Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED

func save_settings() -> void:
	var config=ConfigFile.new()
	config.set_value("display","view",view_name)
	config.set_value("display","fullscreen",fullscreen)
	config.set_value("controls","mouse_aim",mouse_aim)
	config.save("user://desktop.cfg")

func set_view(selected:String) -> void:
	if not VIEWS.has(selected): return
	view_name=selected;save_settings();game.adapt_screen()
	if game.hud!=null: game.hud.layout()
	if game.world!=null and not game.hero.is_empty(): game.world.refresh(true)

func toggle_fullscreen() -> void:
	fullscreen=not fullscreen
	if DisplayServer.get_name()!="headless": game.get_window().mode=Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
	clear_input();save_settings()

func toggle_aim() -> void:
	mouse_aim=not mouse_aim;clear_input();save_settings()

func clear_input() -> void:
	mouse_attack=false

func keyboard_direction() -> Vector2:
	return Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))).limit_length(1)

func aim_point() -> Vector2:
	return game.get_canvas_transform().affine_inverse()*pointer_screen

func aim_direction() -> Vector2:
	if mouse_aim and pointer_seen and aim_point().distance_to(game.player_position())>8:
		return game.player_position().direction_to(aim_point())
	return game.facing

func update_aim() -> void:
	if enabled and mouse_aim and pointer_seen and game.dash_time<=0: game.facing=aim_direction()

func release_input(event:InputEvent) -> void:
	# Releases must clear a held world attack even if the pointer is now over UI.
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed: mouse_attack=false

func handle_input(event:InputEvent) -> void:
	if not enabled or not game.playing: return
	if (event is InputEventMouseMotion or event is InputEventMouseButton) and game.hud.blocks_world_pointer(event.position): return
	if event is InputEventMouseMotion:
		pointer_screen=event.position;pointer_seen=true;update_aim()
	elif event is InputEventMouseButton and event.pressed:
		pointer_screen=event.position;pointer_seen=true;update_aim()
		if not game.spellbook.targeting.is_empty():
			if event.button_index==MOUSE_BUTTON_LEFT: game.spellbook.confirm()
			elif event.button_index==MOUSE_BUTTON_RIGHT: game.spellbook.cancel_target()
			game.get_viewport().set_input_as_handled();return
		if event.button_index==MOUSE_BUTTON_LEFT:
			if not game.build_recipe.is_empty(): game.interact()
			else: mouse_attack=true;game.attack()
			game.get_viewport().set_input_as_handled()
		elif event.button_index==MOUSE_BUTTON_RIGHT:
			game.dash();game.get_viewport().set_input_as_handled()

func handle_key(event:InputEventKey) -> bool:
	if not enabled: return false
	var code=event.physical_keycode if event.physical_keycode!=0 else event.keycode
	if code==KEY_F11:
		toggle_fullscreen();return true
	if not game.playing: return false
	match code:
		KEY_ESCAPE:
			if not game.spellbook.targeting.is_empty(): game.spellbook.cancel_target();return true
			if not game.build_recipe.is_empty(): game.cancel_build();return true
		KEY_R:
			if not game.build_recipe.is_empty(): game.build_rotation=(game.build_rotation+1)%4;return true
		KEY_B: game.hud.show_character("spells");return true
		KEY_V: game.hud.show_character("needs");return true
		KEY_C: game.hud.show_character("camp");return true
		KEY_T:
			game.hero.auto=not game.hero.auto;game.hud.update_hud();game.save_game();return true
	return false

func manual_attack() -> bool:
	if not game.build_recipe.is_empty(): return false
	return game.directional_attack(aim_direction())

func shoot(direction:Vector2,kind:String,amount:float,enchant:int=0) -> void:
	game.shots.append({"pos":game.player_position()+Vector2(0,-4),"velocity":direction.normalized()*(390 if kind=="bow" else 310),"kind":kind,"damage":amount,"enchant":enchant,"life":1.7})

func draw_reticle(canvas:CanvasItem) -> void:
	if not enabled or not mouse_aim or not pointer_seen or not game.playing: return
	var at=aim_point();var color=Color("e8dfabbb")
	canvas.draw_arc(at,8,0,TAU,20,color,1.5)
	for direction in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]: canvas.draw_line(at+direction*11,at+direction*16,color,1.5)
