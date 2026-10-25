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
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
	var old=Data.fresh("Warrior");old.erase("chapter");old.gold=876;old.level=8
	var migrated=Data.migrate(old)
	check(migrated.gold==876 and not migrated.chapter.accepted,"Older characters retain progress and receive an unstarted chapter")
	for key in ["accepted","translated","cleared","claimed","tracking","clues","return_until"]:
		var bad=migrated.duplicate(true);bad.chapter[key]=null
		check(Data.migrate(bad).is_empty(),"Malformed chapter field rejected: "+key)
	var bad=migrated.duplicate(true);bad.chapter.claimed=true;check(Data.migrate(bad).is_empty(),"Unearned chapter reward state is rejected")
	game.start_character(migrated);game.set_physics_process(false);game.hero.auto=false;game.enemies.clear();game.spawn_timer=99999
	var story=game.chapter
	check(not story.accept(),"Starting the story requires visiting Mara")
	game.set_player_position(game.trader.POSITION);check(story.accept() and story.stage()==1,"Mara starts the story once")
	check(not story.accept(),"Accepting twice cannot reset progress")
	check(not story.translate(),"Mara cannot translate missing clues")
	check(not story.investigate("watch"),"A clue cannot be collected remotely")
	for id in story.CLUES:
		game.set_player_position(story.CLUES[id].point)
		check(story.interaction().begins_with("INVESTIGATE"),"A real camp exposes its investigation: "+id)
		var xp=game.hero.xp
		check(story.investigate(id) and story.data().clues.has(id),"Investigating records the actual camp clue: "+id)
		check(not story.investigate(id) and game.hero.xp==xp+25,"Clue experience cannot be collected twice: "+id)
		if id=="watch":
			var restored_clue=Data.migrate(JSON.parse_string(JSON.stringify(game.hero)))
			game.start_character(restored_clue);game.set_physics_process(false);game.hero.auto=false;game.enemies.clear()
			check(story.data().clues.size()==1 and story.data().clues.watch,"Reload during investigation preserves collected clues")
	check(story.stage()==2,"All three clues unlock the return-to-Mara step")
	game.set_player_position(game.trader.POSITION);var gold=game.hero.gold
	check(story.translate() and story.stage()==3 and game.hero.gold==gold+40,"Mara translates the rune and gives the preparation reward")
	check(not story.translate() and game.hero.gold==gold+40,"Translation reward is paid once")
	check(not story.begin(),"Story entry requires reaching the ruins")
	game.set_player_position(game.exploration.RUINS);check(story.begin() and story.story_run(),"The chapter starts a separate story expedition")
	check(game.hero.dungeon.floor==1 and story.traps.size()==2,"The first story floor contains actual warning runes")
	var pos=story.traps[0];game.set_player_position(pos);game.hero.hp=100;story.tick(2.81)
	check(game.hero.hp<100,"A rune pulse damages a player standing on it")
	story.trap_clock=0;game.hero.hp=100;game.dash_time=.2;story.tick(2.81)
	check(game.hero.hp==100,"Dodging protects against a rune pulse")
	game.dash_time=0;game.pause_game();var clock=story.trap_clock;story.tick(10)
	check(story.trap_clock==clock,"Rune pulses pause in menus")
	game.hud.resume();game.set_physics_process(false);game.set_player_position(story.cache_position());gold=game.hero.gold
	check(story.cache_near(),"Optional runic cache is physically reachable on the dungeon floor")
	story.interact();check(game.hero.gold==gold+20 and not story.cache_near(),"The optional cache pays once and closes")
	story.interact();check(game.hero.gold==gold+20,"A used cache cannot pay again")
	check(not game.advance_floor(),"Story stairs remain locked while enemies live")
	for floor_number in [1,2]:
		for e in game.enemies.duplicate(): game.kill_enemy(e,"melee")
		check(game.check_floor_clear() and game.advance_floor() and game.hero.dungeon.floor==floor_number+1,"Clearing a real floor unlocks the next story floor")
	var resumed=Data.migrate(JSON.parse_string(JSON.stringify(game.hero)))
	game.start_character(resumed);game.set_physics_process(false);game.hero.auto=false
	check(story.story_run() and game.hero.dungeon.floor==3 and story.traps.size()==2,"Reload in the expedition restores its story floor and runes")
	var bosses=game.enemies.filter(func(e):return e.get("chapter_boss",false))
	check(bosses.size()==1 and bosses[0].named=="The Hollow Heart","Floor three contains the named chapter boss")
	var boss=bosses[0];game.set_player_position(boss.pos+Vector2(5,0));boss.cooldown=0
	game.update_enemy_attack(boss,.01);var radius=boss.strike_radius
	boss.windup=0;boss.cooldown=0;boss.hp=boss.max_hp*.4;game.update_enemy_attack(boss,.01)
	check(boss.strike_radius>radius and boss.windup<1,"The Hollow Heart changes its attack pattern below half health")
	game.kill_enemy(boss,"melee");check(not story.data().cleared,"Killing only the boss leaves surviving enemies to clear")
	resumed=Data.migrate(JSON.parse_string(JSON.stringify(game.hero)));game.start_character(resumed);game.set_physics_process(false);game.hero.auto=false
	check(not game.enemies.any(func(e):return e.get("chapter_boss",false)),"Reload after boss defeat does not duplicate the boss or its rewards")
	for e in game.enemies.duplicate():
		if not e.dead: game.kill_enemy(e,"magic")
	check(story.data().cleared and story.stage()==4,"Clearing the final chamber records chapter completion")
	check(not story.claim(),"Claiming the chapter reward requires returning to Mara")
	check(game.advance_floor() and game.hero.dungeon==null,"The story's final stairs return to the wilds after three floors")
	game.set_player_position(game.trader.POSITION);gold=game.hero.gold;var points=game.hero.points
	check(story.claim() and game.hero.gold==gold+250 and game.hero.points==points+2,"Mara grants Hearthcall and the completion rewards")
	check(not story.claim() and game.hero.gold==gold+250,"The chapter reward cannot be claimed twice")
	game.hero.respawn={"x":-200.0,"y":50.0};game.enemies.clear();game.hero.hp=50;game.hero.needs.water=25;clock=game.hero.worldTime
	check(story.recall() and game.player_position()==Vector2(-200,50),"Hearthcall returns to the saved bed return point")
	check(game.hero.hp==50 and game.hero.needs.water==25 and game.hero.worldTime==clock,"Hearthcall does not heal, create supplies or skip time")
	check(not story.recall(),"Hearthcall observes its saved active-time cooldown")
	var restored=Data.migrate(JSON.parse_string(JSON.stringify(game.hero)))
	check(not restored.is_empty() and restored.chapter.claimed and restored.chapter.return_until>clock,"Chapter rewards and cooldown survive character export/reload")
	game.hero.worldTime+=121;game.enemies=[game.create_enemy(game.player_position()+Vector2(20,0),1,"goblin")]
	check(not story.recall(),"Nearby enemies prevent escaping combat through Hearthcall")
	game.enemies.clear();game.enter_dungeon();check(not story.story_run(),"Regular expeditions remain separate after story completion")
	game.hero.dungeon.floor=5;game.build_floor(true);game.enemies.clear();game.check_floor_clear()
	check(game.advance_floor() and game.hero.dungeon.floor==6,"Classic still offers its endless dungeon")
	game.leave_dungeon();game.expedition.switch_mode("survival");game.enter_dungeon();game.hero.dungeon.floor=5;game.build_floor(true);game.enemies.clear();game.check_floor_clear()
	check(game.advance_floor() and game.hero.dungeon==null,"Regular Survival still returns home after floor five")
	for dims in [Vector2i(1080,2400),Vector2i(2400,1080)]:
		root.size=dims;game.adapt_screen();await settle();game.hud.show_character("chapter");await settle()
		check(not game.playing and game.hud.content.size.x<=game.hud.scroll.size.x+1,"Chapter journal fits and pauses play: "+str(dims))
	print("%d CHAPTER CHECKS; %d FAILURES" % [checks,failures]);quit(1 if failures else 0)
