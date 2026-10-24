extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var checks=0
var failures=0
func _initialize(): call_deferred("run")
func check(ok:bool,message:String):
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error("FAIL: "+message)
func settle(): await process_frame;await process_frame
func find_button(node:Node,prefix:String) -> Button:
	if node is Button and node.text.begins_with(prefix): return node
	for child in node.get_children():
		var result=find_button(child,prefix)
		if result!=null: return result
	return null
func mouse(at:Vector2,down:bool):
	var event=InputEventMouseButton.new();event.device=-1;event.position=at;event.global_position=at
	event.button_index=MOUSE_BUTTON_LEFT;event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0;event.pressed=down
	root.push_input(event,true)
func motion(at:Vector2,delta:Vector2,held:bool):
	var event=InputEventMouseMotion.new();event.device=-1;event.position=at;event.global_position=at;event.relative=delta
	event.button_mask=MOUSE_BUTTON_MASK_LEFT if held else 0;root.push_input(event,true)
func touch(at:Vector2,down:bool):
	var event=InputEventScreenTouch.new();event.index=0;event.position=at;event.pressed=down;root.push_input(event,true)
func drag(at:Vector2,delta:Vector2):
	var event=InputEventScreenDrag.new();event.index=0;event.position=at;event.relative=delta;root.push_input(event,true)
func reveal(node:Control):
	game.hud.scroll.scroll_vertical+=roundi(node.global_position.y-game.hud.scroll.global_position.y-60);await settle()
func run():
	Input.set_emulate_touch_from_mouse(true)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size=Vector2i(1080,2400)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false);game.enemies.clear();game.hero.auto=false
	game.hero.survival.materials={"Wood":100,"Fiber":100,"Rope":100}
	for size in [Vector2i(1080,2400),Vector2i(2400,1080)]:
		root.size=size;game.adapt_screen();await settle();game.hero.angler.rod=false
		game.hud.show_character("fishing");await settle()
		var action=find_button(game.hud.content,"Craft fishing rod")
		check(action!=null and not action.disabled,"Rod crafting is enabled in the touch test")
		await reveal(action)
		var before=game.hud.scroll.scroll_vertical;var supplies=game.hero.survival.materials.duplicate()
		var limit=game.hud.scroll.get_v_scroll_bar().max_value-game.hud.scroll.get_v_scroll_bar().page
		var amount=-75.0 if before<limit-20 else 75.0
		var at=action.get_global_rect().intersection(game.hud.scroll.get_global_rect().grow(-8)).get_center()
		motion(at,Vector2.ZERO,false);touch(at,true);mouse(at,true);await process_frame
		for step in range(3):
			var delta=Vector2(0,amount/3);at+=delta;drag(at,delta);motion(at,delta,true);await process_frame
		touch(at,false);mouse(at,false);await settle()
		check(not game.hero.angler.rod and game.hero.survival.materials==supplies,"A swipe over Craft never crafts or spends materials "+str(size))
		check(absf(game.hud.scroll.scroll_vertical-before)>15 if limit>15 else game.hud.scroll.scroll_vertical==0,"Craft-button swipes scroll or respect short-list bounds "+str(size))
		game.hud.show_character("fishing");await settle();action=find_button(game.hud.content,"Craft fishing rod");await reveal(action)
		at=action.get_global_rect().intersection(game.hud.scroll.get_global_rect().grow(-8)).get_center()
		motion(at,Vector2.ZERO,false);touch(at,true);mouse(at,true);await process_frame;touch(at,false);mouse(at,false);await settle()
		check(game.hero.angler.rod and game.survival.count("Wood")==supplies.Wood-4 and game.survival.count("Fiber")==supplies.Fiber-6 and game.survival.count("Rope")==supplies.Rope-1,"A tap crafts exactly once "+str(size))
		check(not game.playing and game.move_vector==Vector2.ZERO,"Fishing menu gestures do not control the character")
	Input.set_emulate_touch_from_mouse(false)
	print("%d FISHING TOUCH CHECKS; %d FAILURES" % [checks,failures]);quit(1 if failures else 0)
