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
func descendants(node:Node) -> Array:
	var out=[]
	for child in node.get_children(): out.append(child);out.append_array(descendants(child))
	return out
func button(prefix:String) -> Button:
	for node in descendants(game.hud.content):
		if node is Button and node.text.begins_with(prefix): return node
	return null
func safe_bank(id:String="forest"):
	game.set_player_position(game.fishing.SPOTS[id].bank)
	game.enemies.clear();game.is_walking=false;game.dash_time=0;game.move_vector=Vector2.ZERO
	game.playing=true;game.spawn_timer=100000;game.hero.hp=Data.max_hp(game.hero)
	game.hero.dungeon=null;game.build_recipe="";game.fishing.reset()
func cast_bite(id:String="forest"):
	safe_bank(id)
	if not game.fishing.cast_line(): push_error("Fixture could not cast");failures+=1;return
	game.fishing.timer=.01;game.tick(.02)
func run():
	seed(1522)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
	game.set_physics_process(false)
	var old=Data.fresh("Warrior");old.erase("angler");var hero=Data.migrate(old)
	check(not hero.angler.rod and hero.angler.records.is_empty(),"Existing characters gain an empty fishing journal, not a free rod")
	for value in [null,[],"bad",{"rod":false,"records":{},"rewarded":true}]:
		var invalid=hero.duplicate(true);invalid.angler=value
		check(Data.migrate(invalid).is_empty(),"Malformed angler state is rejected")
	for value in [-1,1.5,INF,NAN,"bad",1000001]:
		var invalid=hero.duplicate(true);invalid.angler.records={"Silver trout":value}
		check(Data.migrate(invalid).is_empty(),"Invalid fish count is rejected")
	var invalid=hero.duplicate(true);invalid.angler.records={"invented fish":1}
	check(Data.migrate(invalid).is_empty(),"Unknown fish cannot enter the journal")
	invalid=hero.duplicate(true);invalid.angler.target="caves"
	check(Data.migrate(invalid).is_empty(),"Unknown fishing target is rejected")
	game.start_character(hero);game.set_physics_process(false);game.hero.auto=false
	var fish=game.fishing;var camp=game.survival
	safe_bank();check(not fish.cast_line(),"A rod is required at a fishing bank")
	check(not fish.craft_rod(),"Missing ingredients cannot craft a rod")
	camp.add("Wood",100);camp.add("Fiber",100);camp.add("Rope",100)
	game.hud.show_character("fishing");await settle();var craft=button("Craft fishing rod")
	check(craft!=null and not craft.disabled,"Fishing menu offers a real craft action")
	craft.pressed.emit();check(fish.data().rod and camp.count("Wood")==96 and camp.count("Fiber")==94 and camp.count("Rope")==99,"The UI crafts one rod and spends exact carried ingredients")
	check(not fish.craft_rod() and camp.count("Wood")==96,"Duplicate rod crafting spends nothing")
	safe_bank();check(not fish.cast_line(),"Fishing requires carried berry bait")
	camp.add("Berries",1000);game.set_player_position(Vector2.ZERO)
	check(not fish.cast_line(),"Casting requires visiting a real fishing bank")
	safe_bank();game.is_walking=true;check(not fish.cast_line(),"Stop moving before casting")
	safe_bank();game.enemies=[game.create_enemy(game.player_position()+Vector2(100,0),1,"goblin")]
	check(not fish.cast_line(),"Nearby hostile enemies prevent casting")
	safe_bank();game.hero.survival.structures=[{"kind":"Wall","x":340,"y":355,"rotation":0,"fuel":0.0,"open":false,"stash":{}}]
	game.set_player_position(Vector2(340,325));check(not fish.cast_line(),"A wall blocks reaching the fishing bank")
	game.hero.survival.structures=[];safe_bank();var bait=camp.count("Berries")
	game.interact();check(fish.stage=="waiting" and camp.count("Berries")==bait-1,"The normal world action casts a line and consumes one berry")
	check(Data.read_save().survival.materials.Berries==bait-1,"Cast bait consumption is immediately saved")
	check(not fish.cast_line() and camp.count("Berries")==bait-1,"A second cast cannot consume extra bait during an attempt")
	check(not fish.reel() and not fish.active() and camp.count("Raw fish")==0,"Reeling too early consumes the attempt without rewarding fish")
	cast_bite();check(fish.stage=="bite" and game.hud.interaction.text.contains("REEL IN!"),"The real game tick produces a timed BITE interaction")
	var raw=camp.count("Raw fish")
	game.interact();check(camp.count("Raw fish")==raw+1 and not fish.active(),"Reeling through the normal world action catches one fish")
	check(not fish.reel() and camp.count("Raw fish")==raw+1,"Duplicate reeling cannot duplicate a catch")
	check(fish.data().records.values().reduce(func(a,b):return a+b,0)==1,"Exactly one species is recorded per catch")
	cast_bite();raw=camp.count("Raw fish");game.tick(2.6)
	check(not fish.active() and camp.count("Raw fish")==raw,"Missing the bite window loses the fish")
	safe_bank();fish.cast_line();game.move_vector=Vector2.RIGHT;game.tick(.1)
	check(not fish.active(),"Actual movement cancels fishing")
	safe_bank();fish.cast_line();game.dash()
	check(not fish.active(),"Dodging cancels fishing immediately")
	safe_bank();fish.cast_line();game.attack()
	check(not fish.active(),"Manual attack cancels fishing")
	safe_bank();fish.cast_line();check(not game.attack(true) and fish.active(),"Automatic combat cannot interrupt a safe fishing attempt")
	game.hero.mp=Data.max_mp(game.hero);game.spellbook.request_slot(2)
	check(not fish.active(),"Casting a hotbar spell cancels fishing")
	safe_bank();fish.cast_line();bait=camp.count("Berries");game.pause_game();fish.tick(30)
	check(not fish.active() and camp.count("Berries")==bait,"Menus pack away the line without refund or offline catch")
	safe_bank();fish.cast_line();game.enemies=[game.create_enemy(game.player_position()+Vector2(100,0),1,"goblin")];fish.tick(.1)
	check(not fish.active(),"An approaching hostile interrupts the active cast")
	safe_bank();fish.cast_line();game.hero.dungeon={};fish.tick(.1)
	check(not fish.active(),"Changing into a dungeon cancels fishing")
	safe_bank();camp.add("Raw fish",99999)
	check(not fish.cast_line(),"A full raw-fish stack prevents wasting bait")
	game.hero.survival.materials["Raw fish"]=10
	var reward_gold_before=game.hero.gold;var reward_essence_before=game.hero.essence
	for id in fish.SPOTS:
		for attempt in range(30):
			cast_bite(id);fish.reel()
			if fish.data().records.get(fish.SPOTS[id].fish,0)>0: break
		check(fish.data().records.get(fish.SPOTS[id].fish,0)>0,"Real casts catch the regional species at "+id)
	check(fish.data().rewarded,"Catching all three regional species completes the angler journey")
	check(game.hero.gold==reward_gold_before+150 and game.hero.essence==reward_essence_before+3,"The completed regional collection grants exactly 150 gold and 3 essence")
	var gold=game.hero.gold;var essence=game.hero.essence
	cast_bite();fish.reel()
	check(game.hero.gold==gold and game.hero.essence==essence,"The collection reward cannot be claimed twice")
	var record=fish.data().duplicate(true);game.save_game();var saved=Data.read_save()
	check(saved.angler==record and not Data.migrate(JSON.parse_string(JSON.stringify(saved))).is_empty(),"Catches, rod and reward survive disk saves and JSON transfer")
	for attempt in range(40):
		if fish.data().records.get("Starfin",0)>0: break
		cast_bite();fish.reel()
	check(fish.data().records.get("Starfin",0)>0,"Rare Starfin catches are recorded through the real catch path")
	safe_bank();var fire={"kind":"Campfire","x":340,"y":445,"rotation":0,"fuel":0.0,"open":false,"stash":{}}
	game.hero.survival.structures=[fire];camp.add("Herbs",100)
	check(not camp.craft("Grilled fish"),"Fish meals require a lit campfire")
	fire.fuel=90;raw=camp.count("Raw fish");var herbs=camp.count("Herbs")
	check(camp.craft("Grilled fish") and camp.count("Raw fish")==raw-1 and camp.count("Herbs")==herbs-1,"Grilled fish consumes one catch and one herb")
	game.hero.mode="survival";game.hero.needs.hunger=0;game.hero.hp=10
	check(game.expedition.eat("Grilled fish") and game.hero.needs.hunger==35 and game.hero.hp==65,"Eating grilled fish restores real food and health")
	raw=camp.count("Raw fish");var berries=camp.count("Berries");herbs=camp.count("Herbs")
	check(camp.craft("Fisher stew") and camp.count("Raw fish")==raw-2 and camp.count("Herbs")==herbs-2 and camp.count("Berries")==berries-1,"Fish stew consumes its displayed ingredients exactly")
	game.hero.needs.hunger=0;game.hero.needs.water=0
	check(game.expedition.eat("Fisher stew") and game.hero.needs.hunger==55 and game.hero.needs.water==18,"Fish stew restores Survival food and water")
	game.hero.survival.materials["Grilled fish"]=99999;raw=camp.count("Raw fish")
	check(not camp.craft("Grilled fish") and camp.count("Raw fish")==raw,"Full cooked-food stacks preserve raw ingredients")
	game.hero.survival.structures.append({"kind":"Wall","x":340,"y":420,"rotation":0,"fuel":0.0,"open":false,"stash":{}})
	check(not camp.craft("Fisher stew"),"Cooking fish through a wall is refused")
	game.hero.survival.structures=[]
	game.facing=Vector2.UP;game.set_player_position(Vector2(340,454));game.build_rotation=0
	check(camp.reason("Wall").contains("fishing"),"New construction keeps pools and banks approachable")
	game.build_recipe="";game.hero.mode="classic"
	for size in [Vector2i(480,900),Vector2i(900,480),Vector2i(1280,720)]:
		game.desktop.enabled=size.x==1280;root.size=size;game.adapt_screen();await settle()
		game.hud.show_character("fishing");await settle()
		check(not game.playing and game.hud.current_page=="fishing","Fishing journal pauses at "+str(size))
		check(game.hud.content.size.x<=game.hud.scroll.size.x+1,"Fishing journal fits the scrolling view at "+str(size))
		for action in descendants(game.hud.content).filter(func(n):return n is Button):
			check(action.size.x<=game.hud.scroll.size.x+1,"Fishing button fits: "+action.text)
	var track=button("Track Reedwater")
	track.pressed.emit();check(fish.data().target=="swamp" and game.playing,"The native tracking action selects the correct pond and resumes")
	check(fish.objective().contains("Reedwater"),"Tracked fishing directions reach the world objective")
	game.hero.exploration.target="home"
	check(fish.objective().is_empty(),"A selected map destination takes priority over old fishing tracking")
	game.hero.exploration.target=""
	game.set_physics_process(false);game.world.profile_enabled=true;game.world.refresh(true);game.world.queue_redraw();await settle()
	check(game.world.profile_draw_samples.size()>0,"New fishing visuals coexist with native world draw callbacks")
	print("%d FISHING CHECKS; %d FAILURES" % [checks,failures]);quit(1 if failures else 0)
