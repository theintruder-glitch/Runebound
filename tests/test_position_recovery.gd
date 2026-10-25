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
func touch(at:Vector2,index:int,down:bool=true):
	var e=InputEventScreenTouch.new();e.position=at;e.index=index;e.pressed=down;root.push_input(e,true)
func find_button(title:String) -> Button:
	for n in game.hud.content.find_children("*","Button",true,false):
		if n.text==title:return n
	return null
func fresh(at:Vector2):
	game.hero.dungeon=null;game.hero.survival.structures=[];game.enemies.clear();game.shots.clear();game.spawn_timer=999999
	game.hero.auto=false;game.hero.mode="classic";game.dash_time=0;game.set_player_position(at)
	game.camera.position=at;game.camera.force_update_scroll();game.hud.resume();game.set_physics_process(false);game.world.refresh(true)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false)
	for dims in [Vector2i(1080,2400),Vector2i(2400,1080)]:
		root.size=dims;game.adapt_screen();await settle();game.hud.layout()
		for start in [Vector2(0,-2050),Vector2(-5200,-6200)]:
			for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
				fresh(start);await settle()
				var stick=game.hud.stick;var center=stick.get_global_rect().get_center()
				touch(center,4);var drag=InputEventScreenDrag.new();drag.index=4;drag.position=center+direction*stick.size.x*.33;root.push_input(drag,true)
				check(game.move_vector.dot(direction)>.99,"Snow touch reaches movement "+str(direction)+" at "+str(start)+" / "+str(dims))
				for i in range(30):game.tick(1.0/60)
				check((game.player_position()-start).dot(direction)>60,"Actual snowy movement advances in "+str(direction)+" / "+str(dims))
				touch(drag.position,4,false);var stopped=game.player_position();game.tick(.016)
				check(game.move_vector==Vector2.ZERO and game.player_position()==stopped,"Snow touch release stops movement without sticking")
		fresh(Vector2(-5200,-6200));var at=game.player_position();game.hud.show_character("map");await settle()
		var map=game.hud.map_widget
		check(map.local_view and map.player_marker.distance_to(map.size/2)<.1,"Far-northwest map opens centered on the real character / "+str(dims))
		find_button("World overview").pressed.emit();await settle()
		check(map.world_bounds.has_point(at) and map.world_bounds.has_point(Vector2.ZERO),"Overview includes distant snow position and original camp")
		check(map.player_marker.distance_to(map.canvas_point(at))<.01 and map.player_marker.x>16 and map.player_marker.y>16,"Overview arrow uses true projection instead of pinning to the corner")
		var old_marker=map.player_marker;game.set_player_position(at+Vector2(200,150));map.queue_redraw();await settle()
		check(map.player_marker.distance_to(old_marker)>1,"Map arrow actually moves when the saved world position changes")
		find_button("Around me").pressed.emit();await settle()
		check(map.player_marker.distance_to(map.size/2)<.1,"Around me recenters after the character moves")
		var roundtrip=map.world_point(map.canvas_point(game.player_position()))
		check(roundtrip.distance_to(game.player_position())<.1,"Map world/screen conversion roundtrips far negative coordinates")
		check(game.player_position()==at+Vector2(200,150),"Map viewing and centering never teleport the character")
	# Normal snowy locations remain where they were saved; no blanket biome reset.
	var saved=Data.fresh("Warrior");saved.x=-5200;saved.y=-6200;saved.gold=777;saved.level=8
	game.start_character(saved);game.set_physics_process(false)
	check(game.player_position()==Vector2(-5200,-6200) and game.hero.gold==777,"Reload preserves a valid distant snow save and progression")
	# Demonstrate the separate precision failure on a finite but unusable position.
	check(Vector2(-1e10,-1e10)+Vector2(2,2)==Vector2(-1e10,-1e10),"Extreme finite coordinates swallow a normal frame's movement")
	saved=Data.fresh("Warrior");saved.x=-1e10;saved.y=-1e10;saved.gold=812;saved.level=9;saved.xp=17
	game.start_character(saved);game.set_physics_process(false)
	check(game.player_position().length()<100 and game.hero.gold==812 and game.hero.level==9 and game.hero.xp==17,"Unplayable extreme save position is repaired before nearby world generation")
	check(game.movement_precision_ok(game.player_position()) and game.walkable(game.player_position(),12),"Automatic repair restores usable movement precision and collision clearance")
	fresh(Vector2.ZERO);game.hero.survival.structures=[{"kind":"Wall","x":0.0,"y":0.0,"rotation":0,"fuel":0.0,"open":false,"stash":{}}]
	saved=game.hero.duplicate(true);game.start_character(saved);game.set_physics_process(false)
	check(game.player_position()!=Vector2.ZERO and game.walkable(game.player_position(),12),"Loading inside a saved wall moves to clear nearby ground")
	fresh(Vector2(-5200,-6200));game.hero.respawn={"x":0.0,"y":-2050.0};game.hero.gold=456;game.hero.essence=11;game.hero.points=3
	game.hero.hp=70;game.hero.mp=22;game.hero.needs.hunger=31;game.hero.needs.water=29;game.hero.needs.sleep=27;game.hero.needs.temperature=8;game.hero.needs.wetness=66
	var original=game.hero.duplicate(true);game.hud.show_pause();find_button("Recover stuck character").pressed.emit();await settle()
	check(game.hud.current_page=="recovery" and not game.playing,"Recovery opens a paused review screen before relocating")
	find_button("Cancel · stay here").pressed.emit();check(game.player_position()==Vector2(-5200,-6200),"Canceling recovery keeps the character's exact position")
	game.hud.show_position_recovery();find_button("Return to original camp · keep my character").pressed.emit();game.set_physics_process(false)
	check(game.player_position().length()<100 and game.camera.position==game.player_position(),"Confirmed recovery returns to original camp rather than a snowy bed")
	check(not game.playing and game.hud.current_page=="pause","Recovery stays paused so a freezing or injured character can review supplies")
	for key in ["inventory","equipped","level","xp","gold","essence","points","chapter","journey","stats","survival","needs","hp","mp","respawn","deaths","worldTime"]:
		check(game.hero[key]==original[key],"Recovery preserves "+key)
	check(game.hud.stick.finger==-1 and game.move_vector==Vector2.ZERO and not game.attack_held and game.dash_time==0,"Recovery releases all held movement, attack and dash state")
	var loaded=Data.read_save();check(Vector2(loaded.x,loaded.y).distance_to(game.player_position())<.01 and loaded.gold==456 and loaded.inventory==JSON.parse_string(JSON.stringify(original.inventory)),"Recovered position and real progression persist through the save file")
	game.hud.resume();game.set_physics_process(false);game.move_vector=Vector2.DOWN;var start=game.player_position();game.tick(.1);game.move_vector=Vector2.ZERO
	check(game.player_position().y>start.y,"Movement is live again after recovering")
	# Dungeons show the wilds entrance; emergency recovery cannot erase an expedition.
	fresh(Vector2(0,-4100));game.enter_dungeon();var run_id=game.hero.dungeon.run
	game.hud.show_character("map");await settle();var map=game.hud.map_widget
	check(map.position_in_wilds()==Vector2(0,-4100) and map.player_marker.distance_to(map.size/2)<.1,"Dungeon map arrow centers on its saved wilds entrance")
	game.hud.show_position_recovery();check(find_button("Return to original camp · keep my character").disabled and not game.recover_stuck_character() and game.hero.dungeon.run==run_id,"Recovery cannot discard an active dungeon run")
	print("%d POSITION RECOVERY CHECKS; %d FAILURES" % [checks,failures]);game.queue_free();await process_frame;quit(1 if failures else 0)
