extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
func _initialize():call_deferred("run")
func measure(label:String):
	game.set_physics_process(false);game.hero.auto=false;game.spawn_timer=999999;game.hero.vit=1000;game.hero.hp=Data.max_hp(game.hero);game.save_timer=0
	var samples=[]
	for i in range(300):
		game.hero.hp=Data.max_hp(game.hero);var start=Time.get_ticks_usec();game.tick(1.0/60);samples.append((Time.get_ticks_usec()-start)/1000.0)
	samples.sort();var total=0.0
	for value in samples:total+=value
	print(JSON.stringify({"scenario":label,"frames":samples.size(),"enemies":game.enemies.size(),"mean_ms":total/samples.size(),"p50_ms":samples[150],"p95_ms":samples[285],"scope":"headless desktop CPU simulation; excludes rendering, Android, GPU and phone heat"}))
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;await process_frame
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false);game.set_player_position(Vector2(780,1240));game.enemies.clear()
	for i in range(6):game.enemies.append(game.create_enemy(Vector2(780,1240)+Vector2.from_angle(i*TAU/6)*55,8,"wolf"))
	measure("Emerald ramp combat / default crowd")
	game.hero.dungeon=null;game.set_player_position(game.landscape.KEEP);game.castle.enter();measure("Gatehouse / all five authored guards")
	game.hero.dungeon.floor=3;game.build_floor(true);game.set_player_position(game.cell_center(Vector2i(16,8)));measure("Throne arena / Colossus plus royal guards")
	quit()
