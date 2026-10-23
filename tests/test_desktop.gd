extends SceneTree
const Data=preload("res://scripts/data.gd")
var checks=0
var game
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
	if not ok:
		push_error("FAIL: "+message);quit(1);assert(ok,message)
	checks+=1;print("PASS: "+message)
func settle():await process_frame;await process_frame
func key(code:Key,down:bool=true):
	var event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down
	Input.parse_input_event(event)
func motion(at:Vector2):
	var event=InputEventMouseMotion.new();event.position=at;event.global_position=at
	root.push_input(event,true)
func click(at:Vector2,button:MouseButton,down:bool):
	var event=InputEventMouseButton.new();event.position=at;event.global_position=at
	event.button_index=button;event.pressed=down;event.button_mask=button if down else 0
	root.push_input(event,true)
func world_screen(at:Vector2) -> Vector2:return game.get_canvas_transform()*at
func descendants(node:Node) -> Array:
	var out:Array=[]
	for child in node.get_children():out.append(child);out.append_array(descendants(child))
	return out
func find_button(prefix:String) -> Button:
	for node in descendants(game.hud.content):
		if node is Button and node.text.begins_with(prefix):return node
	return null
func foe(at:Vector2) -> Dictionary:
	return {"pos":at,"hp":1000.0,"max_hp":1000.0,"dead":false,"radius":14,"aggro":0.0,"type":"slime","home":at,"cooldown":100.0,"flash":0.0,"slow":0.0,"burn":0.0,"burn_tick":0.0,"windup":0.0,"speed":0.0,"wander_time":100.0,"wander":0.0,"motion":Vector2.ZERO}
func run():
	root.size=Vector2i(1280,720)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
	check(game.desktop.enabled,"The shipped laptop feature or explicit desktop mode enables the desktop interface")
	game.desktop.set_view("Balanced");game.desktop.mouse_aim=true;game.desktop.fullscreen=false
	game.start_character(Data.fresh("Ranger"));game.set_physics_process(false)
	game.hero.auto=false;game.enemies.clear();game.spawn_timer=100000;game.set_player_position(Vector2.ZERO)
	game.camera.position=Vector2.ZERO;game.camera.force_update_scroll();await settle()
	check(root.content_scale_size==Vector2i(1280,720),"Laptop uses a wider 1280 by 720 logical world view")
	check(not game.hud.stick.is_visible_in_tree(),"Laptop hides the touch joystick")
	check(game.hud.attack_button.get_script()==null,"Laptop hotbar uses native mouse buttons")
	check(game.hud.attack_button.text.contains("LMB") and game.hud.spell_buttons.fire.text.contains("[1]"),"Hotbar shows keyboard and mouse shortcuts")
	key(KEY_D);await process_frame
	check(Input.is_physical_key_pressed(KEY_D),"Native injected physical keys reach the movement polling path")
	game.tick(.1);key(KEY_D,false);await process_frame
	check(is_equal_approx(game.hero.x,14.2),"Holding D moves the Ranger continuously at the correct speed")
	var at=game.player_position();game.tick(.1)
	check(game.player_position()==at,"Releasing D stops keyboard movement")
	key(KEY_D);key(KEY_S);await process_frame
	var start=game.player_position();game.tick(.1);key(KEY_D,false);key(KEY_S,false);await process_frame
	check(is_equal_approx(game.player_position().distance_to(start),14.2),"Diagonal keyboard movement is normalized")
	game.set_player_position(Vector2.ZERO)
	motion(world_screen(Vector2(260,0)));await process_frame
	check(game.facing.dot(Vector2.RIGHT)>.99,"Mouse motion aims the character toward its world position")
	click(world_screen(Vector2(260,0)),MOUSE_BUTTON_LEFT,true);await process_frame
	check(game.desktop.mouse_attack and game.shots.size()==1,"Left click fires and starts a held attack even without a nearby enemy")
	check(game.shots[0].velocity.normalized().dot(Vector2.RIGHT)>.99 and game.shots[0].kind=="bow","Arrows follow the mouse rather than nearest-target assistance")
	game.tick(.7)
	check(game.shots.size()>=2,"Holding the left button repeats attacks on cooldown")
	click(game.hud.top.get_node("Gear").get_global_rect().get_center(),MOUSE_BUTTON_LEFT,false);await process_frame
	check(not game.desktop.mouse_attack,"Releasing over a GUI button clears a world attack")
	game.shots.clear();game.attack_cooldown=0
	key(KEY_SPACE);await process_frame;game.tick(.01);key(KEY_SPACE,false);await process_frame
	check(game.shots.size()==1,"Space uses the same directional attack as the mouse")
	game.shots.clear();game.attack_cooldown=0
	var attack_at=game.hud.attack_button.get_global_rect().get_center()
	click(attack_at,MOUSE_BUTTON_LEFT,true);await process_frame;click(attack_at,MOUSE_BUTTON_LEFT,false);await process_frame
	check(game.shots.size()==1 and not game.desktop.mouse_attack and not game.attack_held,"A native hotbar mouse click attacks once without leaking a held world attack")
	check(game.desktop.aim_direction().dot(Vector2.RIGHT)>.99,"Moving onto a hotbar button preserves the last world aiming direction")
	game.hero.mp=Data.max_mp(game.hero);var mana=game.hero.mp;game.shots.clear()
	key(KEY_1);await process_frame;key(KEY_1,false);await process_frame
	check(game.shots.size()==1 and game.shots[0].kind=="fire" and game.hero.mp==mana-12,"Key 1 fires a mouse-aimed bolt and spends its actual mana cost")
	check(game.shots[0].velocity.normalized().dot(Vector2.RIGHT)>.99,"Firebolts preserve the mouse direction")
	game.spell_cooldowns.fire=0;game.hero.mp=Data.max_mp(game.hero);game.shots.clear()
	var modified=InputEventKey.new();modified.keycode=KEY_EXCLAM;modified.physical_keycode=KEY_1;modified.shift_pressed=true;modified.pressed=true
	Input.parse_input_event(modified);await process_frame;modified.pressed=false;Input.parse_input_event(modified);await process_frame
	check(game.shots.size()==1 and game.shots[0].kind=="fire","Physical skill keys still work while Shift changes their typed character")
	game.shots.clear();game.attack_cooldown=0
	var sword=Data.fresh("Warrior").inventory[0].duplicate();sword.id="desktop-sword";game.hero.inventory.append(sword);game.hero.equipped.weapon=sword.id
	var front=foe(Vector2(45,0));var behind=foe(Vector2(-45,0));game.enemies=[front,behind]
	check(game.attack() and front.hp<1000 and behind.hp==1000,"Directional sword swings hit in front and spare targets behind the player")
	game.enemies.clear();game.attack_cooldown=0
	check(game.attack() and game.swing_time>0,"Sword attacks animate even when the player misses")
	game.hero.survival.structures=[{"kind":"Shelter","x":0.0,"y":0.0,"fuel":0.0,"rotation":0,"open":false,"stash":{}}]
	game.attack_cooldown=0;check(not game.attack(),"Desktop manual attacks preserve shelter safety restrictions")
	game.hero.survival.structures=[]
	key(KEY_W);await process_frame;key(KEY_SHIFT);await process_frame
	check(game.dash_time>0 and game.facing.dot(Vector2.UP)>.99,"Keyboard dodge follows movement instead of mouse aim")
	key(KEY_SHIFT,false);key(KEY_W,false);await process_frame
	motion(world_screen(Vector2(-260,0)));await process_frame
	check(game.facing.dot(Vector2.UP)>.99,"Moving the mouse cannot bend an active dodge")
	game.tick(.3);game.dash_cooldown=0
	click(world_screen(Vector2(-260,0)),MOUSE_BUTTON_RIGHT,true);await process_frame
	check(game.dash_time>0,"Right mouse button activates dodge")
	click(world_screen(Vector2(-260,0)),MOUSE_BUTTON_RIGHT,false);game.dash_time=0
	game.set_player_position(Vector2.ZERO);game.facing=Vector2.DOWN
	for material in ["Wood","Stone","Fiber"]:game.survival.add(material,100)
	game.begin_build("Garden");var rotation=game.build_rotation
	key(KEY_R);await process_frame;key(KEY_R,false);await process_frame
	check(game.build_rotation==(rotation+1)%4,"R rotates a building ghost")
	key(KEY_ESCAPE);await process_frame;key(KEY_ESCAPE,false);await process_frame
	check(game.build_recipe=="" and game.playing,"Escape cancels construction without leaving the world")
	game.begin_build("Garden");game.facing=Vector2.DOWN
	key(KEY_E);await process_frame;key(KEY_E,false);await process_frame
	check(game.farming.plots().size()==1 and game.build_recipe=="","E places structures through the normal material and collision rules")
	key(KEY_C);await process_frame;key(KEY_C,false);await process_frame
	check(game.hud.current_page=="camp" and not game.playing,"C opens camp and pauses gameplay")
	var clock=game.hero.worldTime;game.set_physics_process(true);await create_timer(.12).timeout;game.set_physics_process(false)
	check(game.hero.worldTime==clock,"Desktop menus pause the saved calendar")
	var mouse_at=world_screen(Vector2(260,0))
	click(mouse_at,MOUSE_BUTTON_LEFT,true);click(mouse_at,MOUSE_BUTTON_LEFT,false)
	check(not game.desktop.mouse_attack,"Menu clicks cannot start world attacks")
	game.hud.resume();var old_auto=game.hero.auto
	key(KEY_T);await process_frame;key(KEY_T,false);await process_frame
	check(game.hero.auto!=old_auto,"T toggles automatic combat")
	game.hero.auto=false
	key(KEY_I);await process_frame;key(KEY_I,false);await process_frame
	check(game.hud.current_page=="gear","I opens equipment")
	key(KEY_M);await process_frame;key(KEY_M,false);await process_frame
	check(game.hud.current_page=="map","M opens the world map")
	game.hud.resume();game.desktop.mouse_attack=true;game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not game.playing and not game.desktop.mouse_attack,"Alt-tab focus loss pauses and releases held attacks")
	for dims in [Vector2i(1366,768),Vector2i(1920,1080),Vector2i(960,540)]:
		root.size=dims;game.adapt_screen();await settle();game.hud.layout();await settle()
		var last:Rect2=Rect2()
		for button in [game.hud.attack_button,game.hud.dash_button,game.hud.spell_buttons.fire,game.hud.spell_buttons.frost,game.hud.spell_buttons.heal,game.hud.skill_button,game.hud.auto_button]:
			var rect=button.get_global_rect()
			check(rect.position.x>=0 and rect.end.x<=game.hud.size.x+1 and rect.end.y<=game.hud.size.y+1,"Desktop hotbar stays within the view "+str(dims))
			check(last.size==Vector2.ZERO or not last.intersects(rect),"Desktop hotbar targets do not overlap "+str(dims));last=rect
		for page in ["gear","camp","farm","trader","map"]:
			game.hud.show_character(page);await settle()
			var bounded=true
			for node in descendants(game.hud.content):
				if node is Control and node.size.x>0:bounded=bounded and node.get_global_rect().end.x<=game.hud.scroll.get_global_rect().end.x+2
			check(bounded,"Desktop "+page+" content fits its wider panel "+str(dims))
	game.hud.show_desktop_settings();await settle()
	check(find_button("Fullscreen:")!=null and find_button("Frame cap:")!=null,"Laptop settings expose fullscreen and performance controls")
	var fullscreen=game.desktop.fullscreen
	key(KEY_F11);await process_frame;key(KEY_F11,false);await process_frame
	check(game.desktop.fullscreen!=fullscreen,"F11 changes the saved fullscreen preference while a menu is open")
	key(KEY_F11);await process_frame;key(KEY_F11,false);await process_frame
	for view in ["Close","Wide","Balanced"]:
		game.desktop.set_view(view);await settle()
		check(root.content_scale_size==game.desktop.VIEWS[view],"World view can change live: "+view)
	var config=ConfigFile.new();config.load("user://desktop.cfg")
	check(config.get_value("display","view")=="Balanced","View preference is saved outside the character file")
	var old_aim=game.desktop.mouse_aim;game.desktop.toggle_aim();config.load("user://desktop.cfg")
	check(config.get_value("controls","mouse_aim")==not old_aim,"Aiming preference persists")
	game.desktop.toggle_aim()
	game.set_low_power(true);check(Engine.max_fps==30,"Battery saver caps laptop rendering at thirty FPS")
	game.set_low_power(false);check(Engine.max_fps==60,"Laptop performance option restores a sixty FPS cap")
	game.hero.gold=4321;game.hero.level=7
	game.hero.exploration.discovered.swamp=true
	var plot=game.farming.plots()[0];plot.crop="Glowcap";plot.growth=123.5
	check(game.hud.export_dialog.file_mode==FileDialog.FILE_MODE_SAVE_FILE and game.hud.export_dialog.use_native_dialog,"Character transfer uses a real native Save dialog")
	var path="user://desktop-transfer-test.json"
	check(game.hud.export_save(path),"Character can be exported to a real JSON file")
	var transferred=Data.migrate(JSON.parse_string(FileAccess.get_file_as_string(path)))
	check(not transferred.is_empty() and transferred.gold==4321 and transferred.level==7,"Exported JSON preserves character progression")
	check(transferred.survival.structures[0].crop=="Glowcap" and transferred.survival.structures[0].growth==123.5,"Character transfer includes camp structures and partial crop growth")
	game.hud.import_save(path);game.enemies.clear();game.set_physics_process(false)
	check(game.hero.gold==4321 and game.hero.level==7 and game.farming.plots()[0].growth==123.5,"The same JSON imports back through the actual game interface")
	check(game.hud.export_save("user://missing-directory/transfer.json")==false,"Unwritable export locations report failure instead of claiming a saved transfer")
	game.hud.resume();game.desktop.mouse_attack=false;game.hero.auto=false
	game.camera.position=game.player_position();game.camera.force_update_scroll()
	motion(world_screen(game.player_position()+Vector2(200,0)));game.world.profile_enabled=true;game.world.refresh(true);game.world.queue_redraw();await settle()
	check(game.world.profile_draw_samples.size()>0,"Desktop world and mouse reticle run native draw callbacks")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print(str(checks)+" DESKTOP CHECKS PASSED")
	quit()
