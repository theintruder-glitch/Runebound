extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var checks=0
func _initialize(): call_deferred("run")
func check(ok:bool,message:String):
	if not ok: push_error("FAIL: "+message);quit(1);assert(ok,message)
	checks+=1;print("PASS: "+message)
func settle(): await process_frame;await process_frame
func structure(kind:String,pos:Vector2=Vector2.ZERO) -> Dictionary:
	return {"kind":kind,"x":pos.x,"y":pos.y,"fuel":90.0 if kind=="Campfire" else 0.0,"rotation":0,"open":false,"stash":{}}
func descendants(node:Node) -> Array:
	var out=[]
	for child in node.get_children(): out.append(child);out.append_array(descendants(child))
	return out
func run():
	root.size=Vector2i(1280,720)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
	var old=Data.fresh("Mage");old.erase("mode");old.erase("needs")
	var migrated=Data.migrate(old)
	check(migrated.mode=="classic" and migrated.needs.hunger==100,"Old saves migrate to Classic without imposing hunger")
	for key in ["hunger","water","sleep","temperature","elapsed","flask"]:
		for value in [-1,"bad",null,INF,NAN]:
			var invalid=migrated.duplicate(true);invalid.needs[key]=value
			check(Data.migrate(invalid).is_empty(),"Invalid survival value rejected: "+key)
	var invalid=migrated.duplicate(true);invalid.needs.flask=4;check(Data.migrate(invalid).is_empty(),"Oversized flask is rejected")
	invalid=migrated.duplicate(true);invalid.needs.water=101;check(Data.migrate(invalid).is_empty(),"Gauge overflow is rejected")
	game.start_character(migrated);game.set_physics_process(false);game.hero.auto=false;game.enemies.clear();game.spawn_timer=99999
	var exp=game.expedition
	var before=game.hero.needs.duplicate();game.tick(10)
	check(game.hero.needs==before,"Classic has no survival drain or clock progress")
	check(exp.switch_mode("survival"),"Existing character can select Survival in the wilds")
	game.hero.worldTime=600;game.set_player_position(Vector2.ZERO)
	game.playing=true
	game.tick(10)
	check(game.hero.needs.hunger<100 and game.hero.needs.water<100 and game.hero.needs.sleep<100,"Live gameplay drains food, water and rest")
	var n=game.hero.needs
	game.pause_game();before=n.duplicate();exp.tick(30);await settle()
	check(n==before,"Survival pauses when a menu or focus loss pauses gameplay")
	game.hud.resume();game.set_physics_process(false)
	n.water=10;n.flask=3
	check(exp.drink() and n.water==55 and n.flask==2,"A flask drink restores 45 water and consumes one charge")
	n.flask=0;check(not exp.drink(),"An empty flask cannot create water")
	game.set_player_position(Vector2(1000,0));check(not exp.drink(true),"Refilling requires physically visiting the spring")
	game.set_player_position(exp.SPRING);check(exp.drink(true) and n.flask==3 and n.water==100,"Spring refills the flask and thirst gauge")
	n.water=1;n.flask=0;game.interact();check(n.flask==3 and n.water==100,"E interaction refills at the marked spring")
	game.set_player_position(Vector2.ZERO);n.hunger=10;game.survival.add("Berries",2)
	check(exp.eat("Berries") and n.hunger==22 and game.survival.count("Berries")==1,"Raw berries provide food and are consumed")
	n.hunger=20;game.survival.add("Roasted meat",1)
	check(exp.eat("Roasted meat") and n.hunger==62 and game.survival.count("Roasted meat")==0,"Existing cooked foods also restore hunger")
	n.hunger=20;n.water=20;game.survival.add("Warm tea",1)
	check(game.survival.eat("Warm tea") and n.water==38 and game.weather.tea_remaining()==180,"Tea hydrates and provides its existing warming effect")
	game.hero.warmUntil=0;game.hero.worldTime=3600
	check(exp.exposure_target()==5,"Winter outdoors is dangerously cold")
	game.hero.survival.structures=[structure("Roof")]
	check(exp.exposure_target()==45,"A roof protects from winter exposure")
	game.hero.survival.structures=[structure("Campfire")];n.temperature=5;exp.tick(10)
	check(n.temperature>5 and exp.exposure_target()==50,"A fueled campfire warms you toward comfort")
	game.hero.survival.structures[0].fuel=0
	check(exp.exposure_target()==5,"An unlit fire does not protect from exposure")
	game.hero.survival.structures=[];game.hero.worldTime=1200
	check(exp.exposure_target()==96,"Summer sun can cause heat exposure")
	game.set_player_position(Vector2(0,-1600));check(exp.exposure_target()==0,"Snow region remains cold even during summer")
	game.set_player_position(Vector2.ZERO);n.temperature=50;n.water=0;n.hunger=100;game.hero.hp=80
	game.tick(1)
	check(game.hero.hp<80,"Dehydration causes real damage without passive regeneration cancelling it")
	n.water=100;n.hunger=0;game.hero.survival.structures=[structure("Shelter")];game.hero.hp=80
	game.tick(1);check(game.hero.hp<80,"A shelter does not cancel starvation damage")
	n.hunger=100;n.sleep=0;check(exp.speed_factor()<1,"Exhaustion slows movement")
	game.hero.survival.structures=[structure("Bed")];game.enemies.clear()
	check(game.survival.rest(game.hero.survival.structures[0]) and n.sleep==100 and n.hunger==94,"Rest at an accessible bed restores sleep and costs supplies")
	var time=game.hero.worldTime
	check(game.survival.rest(game.hero.survival.structures[0]) and game.hero.worldTime==time,"Bed rest does not skip the world calendar")
	n.sleep=0;game.enemies=[game.create_enemy(Vector2(25,0),1,"goblin")]
	check(not game.survival.rest(game.hero.survival.structures[0]) and n.sleep==0,"Enemies prevent unsafe bed rest")
	game.enemies.clear();game.hero.survival.structures=[]
	var plot=structure("Garden");plot.crop="Berries";plot.growth=180.0;game.hero.survival.structures=[plot]
	check(game.farming.harvest(plot) and n.harvested,"Harvesting a real garden completes the food objective")
	game.hero.survival.structures=[structure("Shelter"),structure("Bed",Vector2(80,0))]
	n.water=30;n.hunger=40;n.sleep=50;n.elapsed=3000;n.ruins=true
	var gold=game.hero.gold;var essence=game.hero.essence;exp.check_victory()
	check(n.won and game.hero.gold==gold+500 and game.hero.essence==essence+8,"Completing all Survival goals pays the chapter reward")
	exp.check_victory();check(game.hero.gold==gold+500,"Chapter rewards cannot be claimed twice")
	check(exp.switch_mode("classic") and exp.switch_mode("survival") and n.water==30,"Changing modes preserves needs rather than refilling them")
	game.hero.survival.structures=[];game.set_player_position(Vector2(520,320));game.enter_dungeon()
	check(not exp.switch_mode("classic"),"Mode switching is blocked inside expeditions")
	game.hero.dungeon.floor=5;game.build_floor(true);game.enemies.clear();game.check_floor_clear()
	check(n.ruins,"Clearing floor five completes the expedition goal")
	check(game.advance_floor() and game.hero.dungeon==null,"Survival's final staircase returns home instead of generating floor six")
	exp.switch_mode("classic");game.enter_dungeon();game.hero.dungeon.floor=5;game.build_floor(true);game.enemies.clear();game.check_floor_clear()
	check(game.advance_floor() and game.hero.dungeon.floor==6,"Classic keeps its optional endless dungeon")
	game.leave_dungeon();exp.switch_mode("survival");n.won=false;n.elapsed=900;n.water=0;n.hunger=0
	exp.reset_after_defeat();check(n.elapsed==0 and n.water==60 and n.hunger==60 and n.flask>=1,"Defeat starts a new five-day attempt without a starvation loop")
	game.hud.show_character("needs");await settle()
	check(game.hud.current_page=="needs" and not game.playing,"Survival supplies opens a native scrolling menu and pauses needs")
	for size in [Vector2i(960,540),Vector2i(1366,768)]:
		root.size=size;await settle();game.hud.layout();game.hud.update_hud();await settle()
		var panel=game.hud.advanced.needs_panel
		check(panel.position.x>=0 and panel.position.x+panel.size.x<=game.get_viewport_rect().size.x,"Survival meters fit the desktop view")
		check(game.hud.content.size.x<=game.hud.scroll.size.x+1,"Survival supplies fit without horizontal clipping")
	check(not Data.migrate(JSON.parse_string(JSON.stringify(game.hero))).is_empty(),"Survival state round-trips through character export")
	game.hud.resume();game.set_physics_process(false);await settle()
	check(game.hud.advanced.needs_panel.visible,"Survival gauges are visible during live gameplay")
	game.free();print("%d SURVIVAL MODE CHECKS PASSED" % checks);quit(0)
