extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
	checks+=1
	if ok:print("PASS: "+message)
	else:failures+=1;push_error("FAIL: "+message)
func settle():await process_frame;await process_frame
func reload_hero():
	var restored=Data.migrate(JSON.parse_string(JSON.stringify(game.hero)))
	check(not restored.is_empty(),"Castle save roundtrips through the real migration validator")
	game.start_character(restored);game.set_physics_process(false);game.spawn_timer=99999;game.hero.auto=false
func visit(id:String):
	game.set_player_position(game.cell_center(game.castle.features()[id].cell));game.hud.resume();game.set_physics_process(false)
	return game.castle.use_feature()
func clear_required():
	for e in game.enemies.duplicate():
		if not e.dead and not e.get("castle_optional",false):game.kill_enemy(e,"melee")
func reachable(cell:Vector2i) -> bool:
	return not game.astar.get_id_path(game.dungeon_map.start,cell).is_empty()
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false);game.spawn_timer=99999;game.enemies.clear();game.hero.auto=false
	var land=game.landscape
	var route_clear=true
	for i in range(land.TRAIL.size()-1):
		var a=land.TRAIL[i];var b=land.TRAIL[i+1];var steps=ceili(a.distance_to(b)/6)
		for n in range(steps+1):
			if not game.walkable(a.lerp(b,float(n)/steps),12):route_clear=false
	check(route_clear,"Entire authored approach has full player-radius clearance, including bridge, ramp and gate")
	var bx=land.river_x(912)
	var from=Vector2(bx-100,912);var to=game.move_position(from,Vector2(200,0),12)
	check(to.distance_to(from+Vector2(200,0))<.1,"Actual movement crosses Old King's Bridge in one continuous journey")
	from=Vector2(bx+100,912);to=game.move_position(from,Vector2(-200,0),12)
	check(to.distance_to(from-Vector2(200,0))<.1,"Bridge is equally usable on the way home")
	check(not game.walkable(Vector2(land.river_x(1000),1000),12),"Deep river blocks walking away from its marked crossing")
	check(not game.walkable(Vector2(650,1060),12),"Visible cliff face blocks direct traversal")
	from=Vector2(780,1000);to=game.move_position(from,Vector2(0,140),12)
	check(to.distance_to(from+Vector2(0,140))<.1 and land.elevation(to)>land.elevation(from),"Marked hillside ramp connects the lower valley and upper terrace")
	check(not game.walkable(land.KEEP-Vector2(0,200),12),"Castle walls have collision rather than allowing travel through the exterior art")
	var legacy={"kind":"Storage","x":land.river_x(1000),"y":1000.0,"rotation":0,"fuel":0.0,"open":false,"stash":{"Wood":7}}
	game.hero.survival.structures.append(legacy)
	check(game.walkable(Vector2(legacy.x,legacy.y),12) and legacy.stash.Wood==7,"Pre-existing camps retain usable ground and stored supplies after the terrain update")
	game.hero.survival.structures.clear()
	var old=Data.fresh("Warrior");old.x=650;old.y=1060;old.gold=876;old.level=9
	game.start_character(old);game.set_physics_process(false);game.spawn_timer=99999
	check(game.walkable(game.player_position(),12) and game.hero.gold==876 and game.hero.level==9,"An old character inside a new cliff moves to nearby safe ground without losing progress")
	game.set_player_position(land.CAMP);var wood=game.survival.count("Wood");var gold=game.hero.gold
	land.interact();land.interact()
	check(game.survival.count("Wood")==wood+4 and game.hero.gold==gold+25,"Woodcutter camp pays once and remains claimed")
	reload_hero();check(game.hero.opened.get("emerald-woodcutters",false),"Camp discovery survives save reload")
	game.set_player_position(Vector2.ZERO);check(not game.castle.enter(),"Castle cannot be entered remotely")
	game.set_player_position(land.KEEP);check(game.castle.enter() and game.castle.active(),"Physical gate enters the separate authored castle")
	check(game.enemies.size()==5 and game.chests.is_empty(),"Only the current castle floor and its five authored guards are loaded")
	game.hud._process(0)
	check(game.hud.objective_label.text.contains("armory key"),"Castle objectives replace the outdoor tutorial while inside")
	check(reachable(Vector2i(4,17)) and reachable(Vector2i(27,14)),"Both gate objectives are reachable before either lock is opened")
	check(not reachable(game.dungeon_map.exit) and not reachable(Vector2i(4,4)),"Upper gate and optional vault initially block their routes")
	check(visit("key"),"Armory key is collectible through the real nearby interaction")
	reload_hero();check(game.castle.has("key") and not game.castle.has("seal"),"Partial key progress survives reload without silently granting the seal")
	check(not reachable(game.dungeon_map.exit),"Key alone cannot bypass the library seal")
	check(visit("seal") and reachable(game.dungeon_map.exit) and reachable(Vector2i(4,4)),"Lighting the seal rebuilds collision/pathfinding and unlocks both passages")
	game.set_player_position(game.cell_center(Vector2i(16,15)));var before_trap=game.hero.hp;game.castle.trap_clock=1.9;game.castle.tick(.5)
	check(game.hero.hp==before_trap,"Briar rune warning does not deal early damage")
	game.castle.tick(.9);check(game.hero.hp<before_trap,"Visible rune hazard strikes only after the warning interval")
	before_trap=game.hero.hp;game.castle.trap_clock=3.1;game.dash_time=.2;game.castle.tick(.2)
	check(game.hero.hp==before_trap,"Dashing through the warned trap avoids its pulse")
	game.dash_time=0;game.hud.show_pause();game.castle.trap_clock=3.1;game.castle.tick(.2)
	check(game.castle.trap_clock==3.1,"Opening a menu freezes the castle trap clock")
	game.hud.resume();game.set_physics_process(false)
	gold=game.hero.gold;check(not visit("vault") and game.hero.gold==gold,"Guarded side vault refuses to pay while its sentinel lives")
	clear_required();check(game.floor_clear() and game.enemies.any(func(e):return not e.dead and e.get("castle_optional",false)),"Optional sentinel cannot lock the main stairs")
	for e in game.enemies.duplicate():
		if not e.dead:game.kill_enemy(e,"melee")
	gold=game.hero.gold;check(visit("vault") and game.hero.gold==gold+100,"Defeated optional sentinel permits the hidden vault reward")
	check(not visit("vault"),"The same hidden vault cannot pay twice")
	reload_hero();check(game.enemies.is_empty() and reachable(game.dungeon_map.exit),"Reload retains dead guards, unlocked gate and optional rewards")
	game.set_player_position(game.cell_center(game.dungeon_map.exit));game.interact()
	check(game.hero.dungeon.floor==2 and game.enemies.size()==4,"Functional stairs unload the gatehouse and load the four lower-floor guards")
	for r in game.castle.rooms(2):check(reachable(r[0].get_center()),"Lower-floor room has a connected usable route: "+r[1])
	check(visit("checkpoint"),"Castle checkpoint can be bound")
	var dead_id=game.enemies[0].castle_index;game.kill_enemy(game.enemies[0],"melee")
	gold=game.hero.gold;game.hero.hp=0;game.defeated()
	check(game.hero.dungeon.floor==2 and not game.playing and game.hero.hp>0,"Defeat returns to the bound checkpoint and leaves the game paused")
	check(game.hero.gold==gold-int(gold*.15) and not game.enemies.any(func(e):return e.castle_index==dead_id),"Checkpoint applies the stated loss while retaining defeated guards")
	reload_hero();check(game.hero.dungeon.floor==2 and game.enemies.size()==3,"Checkpoint and remaining guards survive reloading")
	game.hud.resume();game.set_physics_process(false);gold=game.hero.gold;check(visit("archive") and game.hero.gold==gold+100,"Ancient archive provides optional lore and supplies")
	clear_required();check(game.castle.advance() and game.hero.dungeon.floor==3,"Lower-level stairs reach the royal floor")
	for r in game.castle.rooms(3):check(reachable(r[0].get_center()),"Royal room connects to the arrival stair: "+r[1])
	check(not visit("relic"),"Treasury refuses the legendary reward before the guardian is defeated")
	var boss=game.enemies.filter(func(e):return e.get("thornwatch_boss",false))[0]
	game.hud._process(0);check(game.hud.boss_bar.visible and game.hud.boss_bar.max_value==boss.max_hp,"Castle guardian has a real health bar")
	game.set_player_position(boss.pos+Vector2(0,90));boss.cooldown=0;boss.windup=0;game.update_enemy_attack(boss,.016)
	check(boss.windup>1 and boss.strike_radius==55 and boss.strike.distance_to(game.player_position())<.1,"Colossus warns before a targeted root strike")
	boss.cooldown=0;boss.windup=0;boss.hp=boss.max_hp*.4;game.update_enemy_attack(boss,.016)
	check(boss.windup<1 and boss.strike_radius==110 and boss.strike==boss.pos,"Wounded Colossus alternates into a wider, faster ground slam")
	game.dash_time=.3;game.set_player_position(boss.strike);var hp=game.hero.hp;game.update_enemy_attack(boss,2)
	check(game.hero.hp==hp,"Existing dodge protection remains effective against the castle boss")
	game.dash_time=0;clear_required();check(game.hero.opened.get("thornwatch-cleared",false),"Actual guardian defeat records the keep as reclaimed")
	var original_items=game.hero.inventory.duplicate(true)
	while game.hero.inventory.size()<40:
		var item=original_items[0].duplicate(true);item.id="bag-test-"+str(game.hero.inventory.size());game.hero.inventory.append(item)
	check(not visit("relic") and not game.hero.opened.get("thornwatch-relic",false),"Full inventory retains the unclaimed legendary reward for a later attempt")
	game.hero.inventory=original_items
	var item_count=game.hero.inventory.size();check(visit("relic") and game.hero.inventory.size()==item_count+1,"Legendary Thornwatch Oath enters the real inventory")
	check(Data.migrate(JSON.parse_string(JSON.stringify(game.hero))).inventory.any(func(item):return item.id=="thornwatch-oath"),"Legendary blade survives character validation and save migration")
	check(not visit("relic"),"Legendary reward cannot be duplicated")
	game.set_player_position(game.cell_center(game.dungeon_map.exit));game.interact()
	check(game.hero.dungeon==null and game.player_position().distance_to(land.KEEP)<.1 and game.walkable(game.player_position(),12),"Final stairs return to the precise safe outdoor gate position")
	check(game.castle.enter(),"Reclaimed keep can be revisited")
	game.set_player_position(game.cell_center(game.dungeon_map.start));game.interact()
	check(game.hero.dungeon==null,"Entrance stair always permits leaving an unfinished castle")
	for dims in [Vector2i(1080,2400),Vector2i(2400,1080)]:
		root.size=dims;game.adapt_screen();game.set_player_position(land.KEEP);game.hud.show_character("map");await settle()
		var map=game.hud.map_widget;check(map.canvas_point(land.KEEP).distance_to(map.player_marker)<.1,"Map projects the actual castle position in "+str(dims))
		game.hud.resume();game.set_physics_process(false);game.castle.enter();game.update_interaction();game.hud.update_hud();await settle()
		check(game.hud.subheading.text.contains("Thornwatch Keep"),"Castle floor heading remains visible in "+str(dims))
		game.leave_dungeon()
	var malformed=game.hero.duplicate(true);malformed.dungeon={"castle":"thornwatch","floor":4,"seed":1,"returnX":0,"returnY":0,"run":"bad","cleared":[],"rewarded":false}
	check(Data.migrate(malformed).is_empty(),"Invalid castle floor is rejected before indexing layouts")
	check(game.roaming_limit()==6,"Default Android roaming crowd remains six after the castle update")
	print("%d THORNWATCH CHECKS; %d FAILURES" % [checks,failures]);quit(1 if failures else 0)
