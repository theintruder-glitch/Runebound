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
func fresh() -> void:
	game.hero.dungeon=null;game.hero.survival.structures=[];game.enemies.clear();game.shots.clear()
	game.hero.hp=Data.max_hp(game.hero);game.hero.auto=false;game.abilities.stealth=0;game.dash_time=0
	game.spawn_timer=99999;game.set_player_position(Vector2.ZERO);game.hud.resume();game.set_physics_process(false)
func enemy(at:Vector2,kind:String="archer") -> Dictionary:
	var e=game.create_enemy(at,1,kind);e.aggro=2;game.enemies.append(e);return e
func wall(at:Vector2) -> void:
	game.hero.survival.structures.append({"kind":"Wall","x":at.x,"y":at.y,"rotation":1,"fuel":0.0,"open":false,"stash":{}})
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;await process_frame
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false)
	game.hud.show_title(false)
	var labels=game.hud.content.find_children("*","Label",true,false)
	check(labels.any(func(label):return label.text.contains("Version "+str(ProjectSettings.get_setting("application/config/version")))),"Title shows the actual installed build version")
	game.hud.show_pause();labels=game.hud.content.find_children("*","Label",true,false)
	check(labels.any(func(label):return label.text=="Version "+str(ProjectSettings.get_setting("application/config/version"))),"Pause shows the actual installed build version")
	var ai=game.tactics
	for kind in ai.RANGED:
		fresh();var e=enemy(Vector2(150,0),kind);ai.prepare()
		check(ai.direction(e,Vector2.LEFT)==Vector2.ZERO,kind+" holds a clear firing distance")
		e.pos=Vector2(70,0);ai.prepare();check(ai.direction(e,Vector2.LEFT).x>0,kind+" backs away from a nearby hero")
		e.pos=Vector2(205,0);ai.prepare();check(ai.direction(e,Vector2.LEFT).x<0,kind+" closes range instead of fleeing forever")
	fresh();var e=enemy(Vector2(70,0));wall(Vector2(100,0));ai.prepare()
	check(ai.direction(e,Vector2.LEFT)==Vector2.ZERO,"A cornered shooter does not steer through a wall")
	fresh();e=enemy(Vector2(150,0));wall(Vector2(75,0));ai.prepare()
	check(ai.direction(e,Vector2.UP).y<0,"A blocked sight line follows its supplied path around the obstacle")
	fresh();e=enemy(Vector2(160,0),"goblin");var other=enemy(Vector2(160,8),"goblin");ai.prepare()
	var a=ai.direction(e,Vector2.LEFT);var b=ai.direction(other,Vector2.LEFT)
	check(a.x<0 and a.y<0 and b.x<0 and b.y>0,"An approaching melee pair spreads while continuing toward the hero")
	check(a.length()<=1.001 and b.length()<=1.001,"Crowd steering never grants a movement speed boost")
	other.pos=e.pos;ai.prepare();a=ai.direction(e,Vector2.LEFT);b=ai.direction(other,Vector2.LEFT)
	check(a.y<0 and b.y>0,"Coincident spawns separate deterministically in opposite directions")
	other.dead=true;ai.prepare();check(ai.direction(e,Vector2.LEFT)==Vector2.LEFT,"Dead actors do not repel living enemies")
	e.returning=true;check(ai.direction(e,Vector2.RIGHT)==Vector2.RIGHT,"Disengaging enemies keep their homeward route")
	e.returning=false;e.aggro=0;check(ai.direction(e,Vector2.UP)==Vector2.UP,"Idle enemies retain their original wandering behavior")
	e.aggro=2;e.neutral=true;check(ai.direction(e,Vector2.UP)==Vector2.UP,"Peaceful wildlife retains its flee direction")
	e.neutral=false;e.windup=.5;check(ai.direction(e,Vector2.ZERO)==Vector2.ZERO,"A winding-up enemy cannot shuffle its attack position")
	fresh();e=enemy(Vector2(150,0));e.named="Warden";ai.prepare()
	check(not ai.ranged(e) and ai.direction(e,Vector2.LEFT)==Vector2.LEFT,"Named bosses retain their existing approach pattern")
	e.erase("named");e.boss=true;check(not ai.ranged(e),"Large bosses are not converted into retreating shooters")
	# Exercise actual simulation movement, not just steering vectors.
	fresh();e=enemy(Vector2(70,0));e.cooldown=10;var start=e.pos;game.tick(.1)
	check(e.pos.x>start.x,"The wilds tick actually moves a close shooter away")
	fresh();e=enemy(Vector2(150,0));e.cooldown=10;start=e.pos;game.tick(.1)
	check(e.pos==start,"The wilds tick holds a clear ranged firing position")
	fresh();game.enter_dungeon();game.hero.dungeon.seed=12345;game.build_floor(true);game.enemies.clear()
	var start_cell=Vector2i.ZERO;var found=false
	for c in game.dungeon_map.floors:
		if game.dungeon_map.floors.has(c+Vector2i.RIGHT) and game.dungeon_map.floors.has(c+Vector2i.RIGHT*2) and game.dungeon_map.floors.has(c+Vector2i.RIGHT*3) and game.dungeon_map.floors.has(c+Vector2i.RIGHT*4):
			start_cell=c;found=true;break
	check(found,"Seeded dungeon has a walkable firing lane for integration checks")
	if found:
		game.set_player_position(game.cell_center(start_cell));e=enemy(game.player_position()+Vector2(150,0));e.aggro=0;e.cooldown=10;start=e.pos
		game.tick(.1);check(e.pos==start,"A newly detected dungeon shooter holds range before its first shot")
		e.pos=game.player_position()+Vector2(65,0);start=e.pos;game.tick(.1)
		check(e.pos.x>start.x and game.walkable(e.pos,e.radius),"Dungeon shooters retreat along actual walkable floor")
		game.enemies.clear()
		var room=Vector2.ZERO;var has_room=false
		for c in game.dungeon_map.floors:
			var center=game.cell_center(c)
			if game.walkable(center+Vector2(-26,-18),11) and game.walkable(center+Vector2(-26,26),11) and game.walkable(center+Vector2(-80,0),11):
				room=center;has_room=true;break
		check(has_room,"Melee integration fixture has space to spread without crossing walls")
		if has_room:
			game.set_player_position(room-Vector2(80,0));e=enemy(room,"goblin");other=enemy(e.pos+Vector2(0,8),"goblin");e.aggro=0;other.aggro=0;e.cooldown=10;other.cooldown=10
			ai.prepare();check(ai.direction(e,Vector2.LEFT).y<0 and ai.direction(other,Vector2.LEFT).y>0,"Newly detected dungeon melee enemies spread before landing a hit")
	fresh();e=enemy(Vector2(150,0));game.update_enemy_attack(e,.01)
	check(e.windup>0 and e.strike==Vector2.ZERO,"A ranged attack locks the hero's original ground position")
	var locked=e.strike;game.set_player_position(Vector2(0,90));var hp=game.hero.hp;game.update_enemy_attack(e,1)
	check(e.strike==locked and game.hero.hp==hp,"Moving out of a locked warning avoids damage without retargeting")
	check(e.cooldown>0,"A missed attack still incurs recovery")
	fresh();e=enemy(Vector2(150,0));game.update_enemy_attack(e,.01);hp=game.hero.hp;wall(Vector2(75,0));game.update_enemy_attack(e,.1)
	check(e.windup==0 and e.cooldown>=.3 and game.hero.hp==hp,"Closing cover cancels an attack before impact")
	fresh();e=enemy(Vector2(150,0));game.update_enemy_attack(e,.01);game.set_player_position(Vector2(600,0));hp=game.hero.hp;game.update_enemy_attack(e,1)
	check(e.windup==0 and game.hero.hp==hp,"Disengaging beyond ranged reach cancels a stale warning")
	fresh();e=enemy(Vector2(30,0),"goblin");game.update_enemy_attack(e,.01);game.set_player_position(Vector2(170,0));game.update_enemy_attack(e,.1)
	check(e.windup==0,"A melee enemy cannot finish a strike after losing reach")
	fresh();e=enemy(Vector2(150,0));game.update_enemy_attack(e,.01);hp=game.hero.hp;game.dash_time=.2;game.update_enemy_attack(e,1)
	check(game.hero.hp==hp,"Dodge protects the hero through a ranged impact")
	fresh();e=enemy(Vector2(150,0));game.update_enemy_attack(e,.01);hp=game.hero.hp;game.update_enemy_attack(e,1)
	check(game.hero.hp<hp and e.get("attack_pose",0)>0,"Standing in the warning still takes real damage and animates the attack")
	fresh();e=enemy(Vector2(150,0));game.update_enemy_attack(e,.01);var pending=e.windup;hp=game.hero.hp;game.pause_game();game.update_enemy_attack(e,1)
	check(e.windup==pending and game.hero.hp==hp,"Menus pause enemy attack timers and damage")
	game.hud.resume();game.set_physics_process(false);game.abilities.stealth=1;game.update_enemy_attack(e,1)
	check(e.windup==0,"Stealth cancels the pending attack on resume")
	fresh();e=enemy(Vector2(150,0));game.update_enemy_attack(e,.01);game.update_enemy_attack(e,0)
	check(e.windup>0,"A zero-time update cannot advance or resolve a warning")
	var before=JSON.stringify(game.hero);ai.prepare();ai.direction(e,Vector2.LEFT)
	check(JSON.stringify(game.hero)==before and not Data.migrate(JSON.parse_string(before)).is_empty(),"Tactics do not alter the character schema or progression")
	# Dense encounters remain bounded and finite; spatial buckets rebuild each tick.
	fresh()
	for i in range(48): enemy(Vector2(150+i%6*4,i/6*4),"goblin")
	ai.prepare();var finite=true
	for foe in game.enemies:
		var v=ai.direction(foe,Vector2.LEFT);finite=finite and v.is_finite() and v.length()<=1.001
	check(finite,"A dense 48-enemy encounter produces finite capped movement")
	game.enemies.clear();ai.prepare();check(ai.buckets.is_empty(),"Defeat or scene changes release the transient neighbor cache")
	print("%d ENEMY TACTICS CHECKS; %d FAILURES" % [checks,failures]);game.queue_free();await process_frame;quit(1 if failures else 0)
