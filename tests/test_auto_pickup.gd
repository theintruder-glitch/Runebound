extends SceneTree
const Data=preload("res://scripts/data.gd")
var checks=0
var game
func check(ok:bool,message:String):
	if not ok:
		push_error("FAIL: "+message);quit(1);assert(ok,message)
	checks+=1;print("PASS: "+message)
func _initialize(): call_deferred("run")
func fixture(kind:String="Wood",offset:Vector2=Vector2(20,0)):
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false)
	game.hero.auto=false;game.enemies.clear();game.spawn_timer=10000
	game.survival.auto_pickup=true;game.survival.gather_cooldown=0
	game.survival.refresh_timer=100;game.survival.pickup_timer=0
	game.survival.nodes=[{"id":"pickup-test","kind":kind,"pos":offset}]
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_physics_process(false)
	check(game.survival.auto_pickup,"Auto pickup starts enabled on a clean profile")
	fixture();game.tick(.02)
	check(game.survival.count("Wood")==6,"The actual gameplay tick collects nearby wood")
	check(game.hero.journey.wood,"Automatic wood collection advances the opening journey")
	check(game.hero.survival.harvested.has("pickup-test"),"Collected nodes receive the existing respawn timer")
	check(Data.read_save().survival.materials.Wood==6,"Automatic rewards are saved immediately")
	game.tick(.02);check(game.survival.count("Wood")==6,"Repeated frames cannot duplicate a reward")
	fixture();game.survival.auto_pickup=false;game.tick(.02)
	check(game.survival.count("Wood")==0,"Switching auto pickup off prevents collection")
	check(game.survival.gather() and game.survival.count("Wood")==6,"Manual gathering still works with auto pickup off")
	fixture();game.pause_game();game.survival.pickup_tick(.5)
	check(game.survival.count("Wood")==0,"Paused menus cannot collect materials")
	fixture();game.build_recipe="Wall";game.survival.pickup_tick(.5)
	check(game.survival.count("Wood")==0,"Building ghosts suspend collection")
	fixture();game.hero.dungeon={};game.survival.pickup_tick(.5)
	check(game.survival.count("Wood")==0,"Dungeons do not collect outdoor resources")
	fixture();game.hero.hp=0;game.survival.pickup_tick(.5)
	check(game.survival.count("Wood")==0,"Defeated characters cannot collect resources")
	fixture("Wood",Vector2(66,0));game.survival.pickup_tick(.5)
	check(game.survival.count("Wood")==0,"Resources outside the gather radius stay in place")
	game.move_vector=Vector2.RIGHT;game.tick(.21)
	check(game.survival.count("Wood")==6,"Walking into range collects without pressing interact")
	fixture("Wood",Vector2(55,0))
	game.hero.survival.structures=[{"kind":"Door","x":30,"y":0,"rotation":0,"open":false,"fuel":0.0,"stash":{}}]
	game.survival.pickup_tick(.5)
	check(game.survival.count("Wood")==0,"A closed door blocks automatic collection")
	game.hero.survival.structures[0].open=true;game.survival.pickup_tick(.5)
	check(game.survival.count("Wood")==6,"Opening the door allows reachable collection")
	fixture();game.hero.survival.materials.Wood=99998;game.survival.pickup_tick(.5)
	check(game.survival.count("Wood")==99998 and not game.hero.survival.harvested.has("pickup-test"),"A nearly full stack leaves the entire node waiting")
	check(not game.survival.gather() and not game.hero.survival.harvested.has("pickup-test"),"Manual gathering also protects excess materials")
	game.survival.nodes.append({"id":"pickup-other","kind":"Herbs","pos":Vector2(30,0)})
	game.survival.pickup_tick(.5)
	check(game.survival.count("Herbs")==3,"A full nearby stack cannot block another collectible material")
	fixture("Herbs");game.survival.pickup_tick(.5)
	check(game.survival.count("Herbs")==3,"Automatic collection retains spring gathering bonuses")
	fixture();game.survival.gather_cooldown=.5;game.survival.pickup_tick(.5)
	check(game.survival.count("Wood")==0,"Manual and automatic gathering share a cooldown")
	fixture();game.survival.set_auto_pickup(false);game.survival.auto_pickup=true;game.survival.load_pickup_settings()
	check(not game.survival.auto_pickup,"The disabled preference persists to disk")
	game.survival.set_auto_pickup(true);game.survival.auto_pickup=false;game.survival.load_pickup_settings()
	check(game.survival.auto_pickup,"The enabled preference persists to disk")
	game.hud.show_pause();var toggle:Button=null
	for node in game.hud.content.get_children():
		if node is Button and node.text=="Auto pickup: ON": toggle=node
	check(toggle!=null,"Pause exposes the enabled Auto pickup button")
	toggle.pressed.emit();check(not game.survival.auto_pickup and not game.playing,"The Pause button toggles without resuming gameplay")
	game.survival.set_auto_pickup(true)
	print("AUTO PICKUP CHECKS: ",checks);quit()
