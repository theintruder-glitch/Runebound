extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
func _initialize(): call_deferred("run")
func touch(at:Vector2,index:int,down:bool=true):
	var event=InputEventScreenTouch.new();event.position=at;event.index=index;event.pressed=down;root.push_input(event,true)
func drag(at:Vector2,index:int):
	var event=InputEventScreenDrag.new();event.position=at;event.index=index;root.push_input(event,true)
func run():
	root.size=Vector2i(1080,2400);game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await process_frame;await process_frame
	var hero=Data.fresh("Mage");hero.level=30;hero.int=80
	game.start_character(hero);game.set_physics_process(false);game.hero.auto=false;game.spawn_timer=99999
	var results=[]
	for mode in ["joystick","dpad"]:
		game.clear_scene();game.playing=true;game.hud.resume();game.hero.hp=Data.max_hp(game.hero);game.hero.mp=Data.max_mp(game.hero);game.set_player_position(Vector2.ZERO)
		game.hud.controls.model.data.options.movement=mode;game.hud.controls.apply()
		for i in range(6):
			var e=game.create_enemy(Vector2(90,0).rotated(i*TAU/6),5,"goblin");e.hp=100000;e.max_hp=e.hp;game.enemies.append(e)
		var stick=game.hud.stick;var center=stick.get_global_rect().get_center();var attack=game.hud.attack_button.get_global_rect().get_center()
		touch(center+Vector2(50,0),0);touch(attack,1)
		var samples=[];var events=2
		for frame in range(360):
			var before=Time.get_ticks_usec()
			drag(center+Vector2(50 if frame%80<40 else -50,0),0);events+=1
			if frame%90==0:
				var spell=game.hud.spell_buttons.fire.get_global_rect().get_center();touch(spell,2);touch(spell,2,false);events+=2
			game.tick(1.0/60.0)
			if frame>=60: samples.append(Time.get_ticks_usec()-before)
		touch(center,0,false);touch(attack,1,false)
		samples.sort();var total=0.0
		for value in samples: total+=value
		results.append({"mode":mode,"active_enemies":game.enemies.filter(func(e):return not e.dead).size(),"samples":samples.size(),"input_events":events+2,"mean_us":total/samples.size(),"p95_us":samples[int(samples.size()*.95)],"virtual_released":game.move_vector==Vector2.ZERO and not game.attack_held})
	var file=FileAccess.open("res://builds/controls-benchmark.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope":"Headless CPU simulation with injected multi-touch; excludes renderer, GPU, Android hardware and heat","results":results},"  "));file.close()
	print(JSON.stringify(results));quit()
