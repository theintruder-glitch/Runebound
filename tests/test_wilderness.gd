extends SceneTree
const Data=preload("res://scripts/data.gd")
var checks=0
var game
func _initialize(): call_deferred("run")
func check(ok:bool,message:String):
	if not ok: push_error("FAIL: "+message);quit(1);assert(ok,message)
	checks+=1;print("PASS: "+message)
func descendants(node:Node) -> Array:
	var all:Array=[]
	for child in node.get_children(): all.append(child);all.append_array(descendants(child))
	return all
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.size=Vector2i(900,480) if "landscape" in OS.get_cmdline_user_args() else Vector2i(480,900)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false)
	game.enemies.clear();game.hero.auto=false;game.spawn_timer=10000
	check(not game.calm_exploration,"Existing encounter rules remain the default")
	var foe=game.create_enemy(Vector2(80,0),1,"goblin")
	game.enemies=[foe];foe.cooldown=0
	check(game.set_calm_exploration(true),"Calm exploration preference saves")
	check(game.survival.enemy_direction(foe,.1)==Vector2.ZERO and foe.aggro==0,"Unprovoked wilderness monster watches instead of chasing")
	foe.pos=Vector2(20,0);game.update_enemy_attack(foe,.1)
	check(foe.windup==0,"Calm monster cannot start a surprise melee attack")
	var hp=game.hero.hp
	for i in range(20): game.tick(.05)
	check(game.hero.hp>=hp and foe.aggro==0,"Actual simulation leaves an unprovoked calm traveler unharmed")
	foe.hp=foe.max_hp;game.hurt(foe,1,"melee")
	check(not game.unprovoked_wildlife(foe) and game.survival.enemy_direction(foe,.1).length()>0,"Attacked monsters still defend themselves")
	foe.hp=foe.max_hp*.1;foe.pos=Vector2(80,0)
	var direction=game.survival.enemy_direction(foe,.1)
	check(direction.x>0 and foe.retreating,"Wounded ordinary enemy retreats away from the player")
	foe.cooldown=0;game.update_enemy_attack(foe,.1)
	check(foe.windup==0,"Retreating enemy does not also launch a surprise strike")
	foe.boss=true;foe.hp=foe.max_hp;foe.aggro=0
	check(not game.unprovoked_wildlife(foe),"Boss encounters keep their combat rules")
	foe.boss=false;game.hero.dungeon={"floor":1}
	check(not game.unprovoked_wildlife(foe),"Dungeons remain dangerous")
	game.hero.dungeon=null
	var config=ConfigFile.new()
	check(config.load("user://encounters.cfg")==OK and config.get_value("world","calm")==true,"Encounter choice persists independently of character saves")
	game.hud.show_pause()
	check(descendants(game.hud.content).any(func(n):return n is Button and n.text.begins_with("SURVIVAL / ADVENTURE")),"Pause clearly exposes Survival selection")
	game.hud.show_character("camp")
	check(descendants(game.hud.content).any(func(n):return n is Button and n.text.begins_with("Survival mode")),"Camp exposes Survival and travel supplies")
	game.hud.resume();game.enemies.clear()
	var bounds=Rect2(Vector2(-1800,-1800),Vector2(3600,3600))
	var forms=game.world.landforms_for(bounds)
	check(forms.size()>5 and forms.size()<121,"Visible landforms remain bounded")
	check(forms==game.world.landforms_for(bounds),"Terraces and ruins keep deterministic positions")
	check(forms.all(func(f):return f.pos.length()>=350),"Starting camp stays clear of raised scenery")
	var place=forms[0].pos
	game.hero.survival.structures=[{"kind":"Shelter","x":place.x,"y":place.y,"fuel":0.0,"rotation":0,"open":false,"stash":{}}]
	check(not game.world.landforms_for(bounds).any(func(f):return f.pos==place),"Saved camps suppress nearby landform art")
	game.hero.survival.structures=[]
	game.camera.position=place;game.world.refresh(true)
	check(not game.world.scenery.landforms.is_empty(),"Scenery cache includes raised terraces")
	var rebuilds=game.world.scenery_rebuilds
	game.world.refresh_scenery()
	check(game.world.scenery_rebuilds==rebuilds,"Stationary landform geometry reuses retained drawing")
	game.world.profile_enabled=true
	game.enemies=[]
	for kind in ["slime","goblin","skeleton","wisp","guardian","wolf","frost_wolf","deer"]:
		var enemy=game.create_enemy(place+Vector2(game.enemies.size()*20,0),1,kind)
		game.enemies.append(enemy)
	game.world.queue_redraw();await process_frame;await process_frame
	check(game.world.profile_draw_samples.size()>0,"Monster details and terrain run through actual draw callbacks")
	check(game.save_game() and Data.read_save().className=="Warrior","World presentation preserves character save compatibility")
	game.set_calm_exploration(false)
	print(str(checks)+" WILDERNESS CHECKS PASSED")
	quit()
