extends SceneTree
const Data=preload("res://scripts/data.gd")
var checks=0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool,message: String) -> void:
	if not value:
		push_error("FAIL: "+message)
		quit(1)
		assert(value,message)
	checks+=1
	print("PASS: "+message)

func run() -> void:
	# Headless windows do not honor physical --resolution consistently. Set
	# the logical viewport explicitly to exercise both phone orientations.
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.size=Vector2i(1688,900) if "landscape" in OS.get_cmdline_user_args() else Vector2i(480,900)
	await process_frame
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_character(Data.fresh("Warrior"))
	game.set_physics_process(false)
	game.hero.auto=false
	var stick=game.hud.stick
	for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
		game.set_player_position(Vector2.ZERO)
		game.camera.position=Vector2.ZERO
		game.camera.force_update_scroll()
		game.enemies.clear()
		game.spawn_timer=1000
		var start=root.canvas_transform*game.player_position()
		var landmark=root.canvas_transform*Vector2(50,50)
		var touch=InputEventScreenTouch.new()
		touch.index=3
		touch.pressed=true
		touch.position=stick.get_global_rect().get_center()
		root.push_input(touch,true)
		var drag=InputEventScreenDrag.new()
		drag.index=3
		drag.position=touch.position+direction*stick.size.x*.33
		root.push_input(drag,true)
		check(game.move_vector.dot(direction)>.99,"Touch drag reaches full movement "+str(direction))
		for i in range(60):
			game.tick(1.0/60.0)
		game.camera.force_update_scroll()
		var movement=root.canvas_transform*game.player_position()-start
		check(movement.dot(direction)>125,"Character travels visibly across the screen "+str(direction))
		check(game.camera.position==Vector2.ZERO,"Camera stays fixed during joystick movement "+str(direction))
		check((root.canvas_transform*Vector2(50,50)).is_equal_approx(landmark),"World landmark stays still "+str(direction))
		check(game.is_walking,"Touch movement activates walking animation "+str(direction))
		touch.pressed=false
		root.push_input(touch,true)
		var stopped=game.player_position()
		game.tick(1.0/60.0)
		check(game.move_vector==Vector2.ZERO and game.player_position()==stopped and not game.is_walking,"Releasing joystick stops character "+str(direction))
	var view=game.get_viewport_rect().size
	print("Logical viewport: ",view)
	var side=maxf(60,view.x*.5-40)
	var top=-view.y*.5+minf(170,view.y*.22)
	var bottom=view.y*.5-minf(210,view.y*.25)
	for at in [Vector2(side+1,0),Vector2(-side-1,0),Vector2(0,top-1),Vector2(0,bottom+1)]:
		game.camera.position=Vector2.ZERO
		game.set_player_position(at)
		game.update_edge_camera(at)
		check(game.camera.position!=Vector2.ZERO,"Crossing an edge scrolls the view "+str(at))
		check(game.camera.position.length()<1.01,"Crossing boundary by one pixel scrolls only one pixel "+str(at))
		var relative=at-game.camera.position
		check(absf(relative.x)<=side+.001 and relative.y>=top-.001 and relative.y<=bottom+.001,"Scrolling keeps hero in the playable area "+str(at))
		var page=game.camera.position
		game.update_edge_camera(at)
		check(game.camera.position==page,"Camera stays still without further movement "+str(at))
		game.world.refresh_scenery(true)
		var visible=Rect2(page-view/2,view)
		check(game.world.scenery.bounds.encloses(visible),"Cached scenery covers the camera view "+str(at))
		var coverage=true
		for corner in [visible.position,visible.end,Vector2(visible.end.x,visible.position.y),Vector2(visible.position.x,visible.end.y)]:
			coverage=coverage and game.world.terrain_cells.has(Vector2i(floori(corner.x/48),floori(corner.y/48)))
		check(coverage,"Terrain covers both sides of the fixed view "+str(at))
	game.playing=false
	var rebuilds=game.world.scenery_rebuilds
	for i in range(20):
		game.world.refresh_scenery()
	check(game.world.scenery_rebuilds==rebuilds,"Stationary scenery is reused")
	game.set_low_power(true)
	check(Engine.max_fps==30,"Low-power mode caps rendering at 30 FPS")
	game.set_low_power(false)
	check(Engine.max_fps==60,"Normal mode caps rendering at 60 FPS")
	game.set_low_power(true)
	check(game.hero.level==1,"Camera changes preserve character progression")
	game.camera.position=Vector2.ZERO
	game.world.refresh(true)
	var old_cells=game.world.terrain_cells.duplicate()
	game.camera.position=Vector2(400,0)
	game.world.refresh()
	var retained=0
	for cell in game.world.terrain_cells:
		if old_cells.has(cell):retained+=1
	check(retained>old_cells.size()/2,"Area changes retain overlapping terrain")
	check(game.world.terrain_cells.size()<2500,"Terrain memory remains bounded")
	game.save_game()
	check(Data.read_save().className=="Warrior","Updated character saves remain loadable")
	print(str(checks)+" MOVEMENT AND PERFORMANCE CHECKS PASSED")
	quit()
