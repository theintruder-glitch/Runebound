extends SceneTree
const Data=preload("res://scripts/data.gd")
const Card=preload("res://scripts/ui_card.gd")
var checks=0
var game
var hud
func _initialize(): call_deferred("run")
func check(ok:bool,message:String):
	if not ok:
		push_error("FAIL: "+message);quit(1);assert(ok,message)
	checks+=1;print("PASS: "+message)
func descendants(node:Node) -> Array:
	var out:Array=[]
	for child in node.get_children(): out.append(child);out.append_array(descendants(child))
	return out
func find_button(prefix:String) -> Button:
	for node in descendants(hud.content):
		if node is Button and node.text.begins_with(prefix): return node
	return null
func settle():
	await process_frame;await process_frame
func reveal(node:Control):
	hud.scroll.scroll_vertical+=roundi(node.global_position.y-hud.scroll.global_position.y-60)
	await settle()
func mouse(at:Vector2,down:bool):
	var event=InputEventMouseButton.new();event.device=-1
	event.button_index=MOUSE_BUTTON_LEFT;event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
	event.pressed=down;event.position=at;event.global_position=at
	root.push_input(event,true)
func motion(at:Vector2,delta:Vector2,held:bool):
	var event=InputEventMouseMotion.new();event.device=-1
	event.position=at;event.global_position=at;event.relative=delta
	event.button_mask=MOUSE_BUTTON_MASK_LEFT if held else 0
	root.push_input(event,true)
func touch(at:Vector2,down:bool):
	var event=InputEventScreenTouch.new();event.index=0;event.position=at;event.pressed=down
	root.push_input(event,true)
func drag(at:Vector2,delta:Vector2):
	var event=InputEventScreenDrag.new();event.index=0;event.position=at;event.relative=delta
	root.push_input(event,true)
func swipe(node:Control,amount:float=-90):
	await reveal(node)
	var visible=node.get_global_rect().intersection(hud.scroll.get_global_rect().grow(-10))
	check(visible.size.y>10,"Swipe starts on visible content")
	var at=visible.get_center()
	motion(at,Vector2.ZERO,false);touch(at,true);mouse(at,true)
	await process_frame
	for i in range(3):
		var delta=Vector2(0,amount/3);at+=delta
		drag(at,delta);motion(at,delta,true)
		await process_frame
	touch(at,false);mouse(at,false)
	await process_frame
func tap(node:Control):
	await reveal(node)
	var at=node.get_global_rect().intersection(hud.scroll.get_global_rect().grow(-5)).get_center()
	motion(at,Vector2.ZERO,false);touch(at,true);mouse(at,true)
	await process_frame
	touch(at,false);mouse(at,false);await settle()
func run():
	# Android delivers touch plus emulated mouse events to native Controls. Turn
	# on the engine's touchscreen availability for the same native drag path here.
	Input.set_emulate_touch_from_mouse(true)
	check(DisplayServer.is_touchscreen_available(),"Native touchscreen scrolling is enabled for the test")
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size=Vector2i(1080,2400)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false)
	game.enemies.clear();game.hero.auto=false;game.spawn_timer=10000
	hud=game.hud;game.hero.gold=100000;game.hero.essence=50;game.hero.points=10
	for i in range(39):
		var item=game.hero.inventory[0].duplicate();item.id="scroll-"+str(i);item.name="Scroll item "+str(i)
		game.hero.inventory.append(item)
	for dims in [Vector2i(1080,2400),Vector2i(2400,1080)]:
		root.size=dims;game.adapt_screen();await settle()
		hud.show_character("gear");await settle()
		var cards=descendants(hud.content).filter(func(n):return n.get_script()==Card)
		var card=cards[0]
		await reveal(card);var before=hud.scroll.scroll_vertical;var selected=hud.gear_selected
		await swipe(card)
		check(hud.scroll.scroll_vertical>before+25,"Swiping an inventory card scrolls the list "+str(dims))
		check(hud.gear_selected==selected,"A scrolling gesture does not select an inventory item "+str(dims))
		await reveal(card);before=hud.scroll.scroll_vertical
		await swipe(card,60)
		check(hud.scroll.scroll_vertical<before-20,"Dragging down scrolls inventory back toward the top "+str(dims))
		hud.show_character("gear");await settle()
		var panel:Control=hud.content.get_children().filter(func(n):return n is PanelContainer)[0]
		var heading=descendants(panel).filter(func(n):return n is Label)[0]
		await reveal(heading);before=hud.scroll.scroll_vertical
		await swipe(heading,-60)
		check(hud.scroll.scroll_vertical>before+20,"Swiping item details scrolls through the panel "+str(dims))
		hud.show_character("gear");await settle()
		var upgrade=find_button("Upgrade ");var gold=game.hero.gold;var old_upgrade=game.hero.inventory[0].upgrade
		await reveal(upgrade);before=hud.scroll.scroll_vertical
		await swipe(upgrade,-60)
		check(hud.scroll.scroll_vertical>before+20,"Swiping over an upgrade button scrolls "+str(dims))
		check(game.hero.gold==gold and game.hero.inventory[0].upgrade==old_upgrade,"Swiping an upgrade button spends no gold "+str(dims))
		hud.show_character("gear");await settle()
		var cost=Data.upgrade_cost(game.hero,game.hero.inventory[0])
		await tap(find_button("Upgrade "))
		check(game.hero.gold==gold-cost and game.hero.inventory[0].upgrade==old_upgrade+1,"A normal tap upgrades exactly once "+str(dims))
		cards=descendants(hud.content).filter(func(n):return n.get_script()==Card)
		var target_id=game.hero.inventory.filter(func(item):return item.name==cards[1].caption)[0].id
		await tap(cards[1])
		check(hud.gear_selected==target_id,"A normal tap still selects an inventory card "+str(dims))
		hud.gear_selected="starter-sword"
		hud.show_character("stats");await settle()
		var add=find_button("Add point");var points=game.hero.points;var strength=game.hero.str
		await swipe(add,-60)
		check(game.hero.points==points and game.hero.str==strength,"Swiping a stat button spends no points "+str(dims))
		hud.show_character("stats");await settle();await tap(find_button("Add point"))
		check(game.hero.points==points-1 and game.hero.str==strength+1,"A normal tap spends one stat point "+str(dims))
		# Swiping across crop actions must scroll, without planting or clearing.
		game.set_player_position(Vector2.ZERO)
		var garden={"kind":"Garden","x":0.0,"y":96.0,"rotation":0,"fuel":0.0,"open":false,"stash":{},"crop":"","growth":0.0}
		game.hero.survival.structures=[garden];game.hero.survival.materials.Berries=10
		for i in range(4):
			var other_garden=garden.duplicate();other_garden.x=400+i*96
			game.hero.survival.structures.append(other_garden)
		hud.show_character("farm");await settle()
		var plant=find_button("Plant Berries");var berries=game.survival.count("Berries")
		await reveal(plant);before=hud.scroll.scroll_vertical
		await swipe(plant,-60)
		check(hud.scroll.scroll_vertical>before+20 and garden.crop=="" and game.survival.count("Berries")==berries,"Swipe over Plant scrolls without planting "+str(dims))
		hud.show_character("farm");await settle();await tap(find_button("Plant Berries"))
		check(garden.crop=="Berries" and game.survival.count("Berries")==berries-2,"A garden tap plants once "+str(dims))
		var growth=garden.growth
		await swipe(find_button("Clear crop"),-60)
		check(garden.crop=="Berries" and garden.growth==growth and game.survival.count("Berries")==berries-2,"Swipe over Clear preserves crop and ingredients "+str(dims))
		garden.growth=180;hud.show_character("farm");await settle()
		await swipe(find_button("Harvest Berries"),-60)
		check(garden.crop=="Berries" and game.survival.count("Berries")==berries-2,"Swipe over Harvest scrolls without collecting crops "+str(dims))
		hud.show_character("farm");await settle();await tap(find_button("Harvest Berries"))
		check(garden.crop=="" and game.survival.count("Berries")==berries+4,"A normal tap harvests exactly once "+str(dims))
		for page in ["camp","classes","realm","quests","trader","farm","guide","kit","fishing"]:
			hud.show_character(page);await settle()
			var target:Control
			if page=="classes": target=find_button("Current class")
			elif page=="camp": target=hud.content.get_children().filter(func(n):return n is PanelContainer)[0]
			elif page=="realm": target=find_button("Build ·")
			elif page in ["quests","trader","farm","kit","fishing"]: target=hud.content.get_children().filter(func(n):return n is PanelContainer)[0]
			else: target=hud.content.get_child(1)
			await reveal(target);before=hud.scroll.scroll_vertical
			var limit=hud.scroll.get_v_scroll_bar().max_value-hud.scroll.get_v_scroll_bar().page
			var direction=-60.0 if before<limit-15 else 60.0
			await swipe(target,direction)
			check(absf(hud.scroll.scroll_vertical-before)>15 if limit>15 else hud.scroll.scroll_vertical==0,"Content swipe handles the "+page+" menu and its bounds "+str(dims))
		# New menu pages must stop the preceding page's momentum and start at top.
		hud.show_character("gear");await settle();await create_timer(.12).timeout
		check(hud.scroll.scroll_vertical==0,"Changing pages cancels old scroll momentum "+str(dims))
		check(game.move_vector==Vector2.ZERO and not game.playing,"Menu gestures stay out of character controls "+str(dims))
	Input.set_emulate_touch_from_mouse(false)
	print(str(checks)+" MENU SCROLL CHECKS PASSED")
	quit()
