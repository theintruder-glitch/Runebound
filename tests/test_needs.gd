extends SceneTree
const Data=preload("res://scripts/data.gd")
var checks=0
var game
func _initialize(): call_deferred("run")
func check(ok:bool,message:String):
	if not ok:
		push_error("FAIL: "+message);quit(1);assert(ok,message)
	checks+=1;print("PASS: "+message)
func nodes(node:Node) -> Array:
	var all:Array=[]
	for child in node.get_children(): all.append(child);all.append_array(nodes(child))
	return all
func button(prefix:String):
	for node in nodes(game.hud.content):
		if node is Button and node.text.begins_with(prefix): return node
	return null
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.size=Vector2i(900,480) if "landscape" in OS.get_cmdline_user_args() else Vector2i(480,900)
	var legacy=Data.fresh("Warrior")
	legacy.gold=321;legacy.erase("gameMode");legacy.erase("needs")
	var migrated=Data.migrate(legacy.duplicate(true))
	check(migrated.gameMode=="adventure" and migrated.gold==321,"Legacy saves default to Adventure without losing progress")
	check(migrated.needs.food==100 and migrated.needs.water==100 and migrated.needs.flask==3,"Old saves receive safe full supplies")
	for key in ["food","water","fatigue","exposure","flask"]:
		for value in [-1,101,"bad",null,INF,NAN]:
			var bad=migrated.duplicate(true);bad.needs[key]=value
			check(Data.migrate(bad).is_empty(),"Reject invalid needs field "+key+" / "+str(value))
	var bad=migrated.duplicate(true);bad.needs.flask=1.5
	check(Data.migrate(bad).is_empty(),"Reject fractional flask charges")
	bad=migrated.duplicate(true);bad.gameMode="hardcore"
	check(Data.migrate(bad).is_empty(),"Reject unknown mode")
	bad=migrated.duplicate(true);bad.needs.difficulty="bad"
	check(Data.migrate(bad).is_empty(),"Reject unknown difficulty")
	bad=migrated.duplicate(true);bad.needs=[]
	check(Data.migrate(bad).is_empty(),"Reject malformed needs object")
	var partial=migrated.duplicate(true);partial.needs={"food":62}
	check(Data.migrate(partial).needs.food==62 and partial.needs.water==100,"Partial needs retain known values and safely default missing fields")
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await process_frame
	game.start_character(migrated);game.set_physics_process(false)
	game.enemies.clear();game.hero.auto=false;game.spawn_timer=10000
	var n=game.hero.needs
	var before=n.duplicate(true)
	game.tick(1)
	check(n==before and game.needs.speed_scale()==1,"Adventure simulation preserves original movement and freezes needs")
	game.hud.show_pause()
	button("SURVIVAL / ADVENTURE").pressed.emit()
	check(game.hud.current_page=="survival_mode" and game.hero.gameMode=="adventure","Opening mode menu does not opt in automatically")
	button("Enable Survival · Normal").pressed.emit()
	check(game.hero.gameMode=="survival" and Data.read_save().gameMode=="survival","Explicit menu choice enables and saves Survival")
	game.needs.tick(60)
	check(n==before,"Menus pause depletion")
	game.hud.resume();game.enemies.clear();game.spawn_timer=10000
	game.tick(1)
	check(n.food<100 and n.water<100 and n.fatigue>0,"Real gameplay tick depletes Survival needs")
	game.hero.worldTime=120;game.set_player_position(Vector2.ZERO)
	n.food=100;n.water=100;n.fatigue=0;n.exposure=0
	game.needs.tick(100)
	check(is_equal_approx(n.food,96) and is_equal_approx(n.water,94) and is_equal_approx(n.fatigue,2),"Normal active-play depletion has bounded documented rates")
	check(game.needs.configure("survival","gentle"),"Gentle difficulty can be selected")
	n.food=100;n.water=100;n.fatigue=0
	game.needs.tick(100)
	check(is_equal_approx(n.food,98) and is_equal_approx(n.water,97) and is_equal_approx(n.fatigue,1),"Gentle halves depletion")
	game.needs.configure("survival","normal")
	game.hero.worldTime=3700;n.exposure=10
	game.needs.tick(10)
	check(n.exposure>10,"Winter raises outdoor cold exposure")
	var shelter={"kind":"Shelter","x":0.0,"y":0.0,"fuel":0.0,"rotation":0,"open":false,"stash":{}}
	game.hero.survival.structures=[shelter];var cold=n.exposure
	game.needs.tick(10)
	check(n.exposure<cold,"Shelter reverses exposure even in winter")
	game.hero.survival.structures=[{"kind":"Campfire","x":0.0,"y":0.0,"fuel":90.0,"rotation":0,"open":false,"stash":{}}]
	n.exposure=50;game.needs.tick(10)
	check(is_equal_approx(n.exposure,42),"A fueled fire warms exposed travelers")
	game.hero.survival.structures=[]
	n.food=0;n.water=0;n.fatigue=100;n.exposure=100
	var hp=game.hero.hp
	game.needs.tick(10000)
	check(game.hero.hp==hp and game.needs.speed_scale()>=.7,"Exhaustion never damages health or slows movement below 70 percent")
	check(n.food==0 and n.water==0 and n.fatigue==100 and n.exposure==100,"Long play steps keep meters bounded")
	game.needs.configure("survival","gentle")
	check(game.needs.speed_scale()>=.9,"Gentle movement penalty stays below ten percent")
	game.set_player_position(Vector2(1000,0))
	check(not game.needs.refill() and not game.needs.rest(),"Remote travelers cannot refill or rest without a camp structure")
	n.flask=1;n.water=10
	check(game.needs.drink() and n.water==50 and n.flask==0,"Drinking consumes exactly one carried flask use")
	check(not game.needs.drink() and n.water==50,"Empty flask cannot restore water")
	game.set_player_position(Vector2.ZERO)
	check(game.needs.refill() and n.flask==3 and n.water==100,"Starting camp refills water and all flask uses")
	check(not game.needs.drink() and n.flask==3,"Full hydration does not waste flask uses")
	game.enemies=[game.create_enemy(Vector2(20,0),1,"goblin")]
	check(not game.needs.rest(),"Nearby enemies prevent safe rest")
	game.enemies.clear()
	check(game.needs.rest() and n.fatigue==0,"Safe camp rest recovers fatigue")
	game.survival.add("Roasted berries",1);n.food=10
	check(game.survival.eat("Roasted berries") and n.food==35,"Existing cooked food restores hunger and is consumed")
	check(not game.survival.eat("Roasted berries") and n.food==35,"Missing food cannot restore hunger")
	game.survival.add("Warm tea",1);n.water=10;n.exposure=50
	check(game.survival.eat("Warm tea") and n.water==45,"Warm tea restores hydration using existing inventory")
	game.needs.tick(10)
	check(n.exposure<50,"Tea also protects from cold")
	var held=n.duplicate(true)
	game.needs.configure("adventure",n.difficulty)
	game.needs.tick(10000)
	check(n==held and game.needs.speed_scale()==1,"Switching to Adventure freezes meters and removes penalties")
	game.needs.configure("survival",n.difficulty)
	check(n==held,"Switching back does not refill Survival resources")
	game.save_game();var saved=Data.read_save()
	check(saved.needs==n and saved.gameMode=="survival" and saved.gold==321,"Mode, difficulty, meters and progression survive disk round trip")
	game.start_character(saved);game.set_physics_process(false)
	check(game.hero.needs==saved.needs,"Reload does not apply offline depletion")
	game.hud.show_survival_mode();await process_frame;await process_frame
	check(game.hud.scroll!=null and game.hud.scroll.get_global_rect().end.x<=root.size.x,"Survival controls use the bounded scrolling menu in this orientation")
	check(button("Drink flask")!=null and button("Rest here")!=null and button("Food and camp supplies")!=null,"Survival menu exposes hydration, rest and existing food supplies")
	game.hud.resume();game.hud.update_hud()
	check(game.hud.movement_status.text.begins_with("Food"),"Active Survival meters are visible while playing")
	game.enemies.clear();game.set_player_position(Vector2.ZERO)
	game.needs.configure("survival","normal")
	game.hero.worldTime=120;game.hero.warmUntil=0
	game.set_player_position(Vector2(0,-2050));game.hero.needs.exposure=20
	game.needs.tick(10)
	check(game.hero.needs.exposure>20,"Snow biome causes exposure outside winter")
	game.set_player_position(Vector2(2050,0));game.hero.needs.exposure=20
	game.needs.tick(10)
	check(game.hero.needs.exposure<20,"Underground cover allows recovery")
	game.set_player_position(Vector2.ZERO);game.hero.survival.structures=[]
	game.hero.needs.food=0;game.hero.needs.water=0;game.hero.needs.fatigue=100;game.hero.needs.exposure=100
	game.move_vector=Vector2.RIGHT;game.dash_time=0;game.spawn_timer=10000
	game.tick(.1)
	check(game.player_position().x>8 and game.player_position().x<10,"Actual character movement applies the bounded Survival penalty")
	game.move_vector=Vector2.ZERO
	var current=game.hero.needs.duplicate(true)
	var temp=ProjectSettings.globalize_path(Data.SAVE_PATH+".tmp")
	check(DirAccess.make_dir_absolute(temp)==OK,"Create isolated write-failure fixture")
	check(not game.needs.configure("adventure","normal") and game.hero.gameMode=="survival","Failed mode save rolls back mode selection")
	check(game.hero.needs==current,"Failed mode save preserves difficulty and meters")
	game.hero.needs.water=10;game.hero.needs.flask=2
	check(not game.needs.drink() and game.hero.needs.water==10 and game.hero.needs.flask==2,"Failed drink save rolls back water and flask consumption")
	DirAccess.remove_absolute(temp)
	var path="user://needs-recovery.json"
	var backup=game.hero.duplicate(true)
	check(Data.write_save(backup,path),"Write survival recovery fixture")
	var newer=backup.duplicate(true);newer.gold+=10
	check(Data.write_save(newer,path),"Create atomic save backup")
	newer.needs.water="corrupt"
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(newer));file.close()
	var recovered=Data.read_save(path)
	var same=recovered.gameMode==backup.gameMode and recovered.needs.difficulty==backup.needs.difficulty
	for key in ["food","water","fatigue","exposure","flask"]:
		same=same and is_equal_approx(float(recovered.needs[key]),float(backup.needs[key]))
	check(same and recovered.gold==backup.gold,"Malformed needs recover the previous valid character backup")
	print(str(checks)+" NEEDS CHECKS PASSED")
	quit()
