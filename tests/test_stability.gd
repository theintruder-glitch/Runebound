extends SceneTree
const Data=preload("res://scripts/data.gd")
var checks=0
var game
func _initialize(): call_deferred("run")
func check(ok:bool,message:String):
	if not ok: push_error("FAIL: "+message);quit(1);assert(ok,message)
	checks+=1;print("PASS: "+message)
func structure(kind:String,pos:Vector2=Vector2.ZERO) -> Dictionary:
	return {"kind":kind,"x":pos.x,"y":pos.y,"rotation":0,"fuel":90.0 if kind=="Campfire" else 0.0,"open":false,"stash":{}}
func corrupt(path:String,value:String="broken") -> void:
	var file=FileAccess.open(path,FileAccess.WRITE);file.store_string(value);file.close()
func touch(control:Control,index:int,offset:Vector2,pressed:bool=true) -> void:
	var event=InputEventScreenTouch.new();event.index=index;event.position=control.get_global_rect().get_center()+offset;event.pressed=pressed
	control._input(event)
func run():
	root.size=Vector2i(1080,2400)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await process_frame;await process_frame
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false);game.hero.auto=false;game.enemies.clear();game.spawn_timer=99999
	var stick=game.hud.stick
	touch(stick,0,Vector2(2,1))
	check(game.move_vector==Vector2.ZERO,"Joystick center ignores thumb jitter")
	touch(stick,0,Vector2.ZERO,false);touch(stick,1,Vector2(40,0))
	check(game.move_vector.x>.7,"Joystick still responds immediately beyond dead zone")
	var mouse=InputEventMouseButton.new();mouse.device=0;mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=true;mouse.position=stick.get_global_rect().get_center()
	stick._input(mouse)
	check(stick.finger==1 and game.move_vector.x>.7,"A physical mouse cannot steal an active touch")
	touch(stick,2,Vector2.ZERO,false)
	check(stick.finger==1,"Releasing a second finger leaves movement held")
	stick.hide();check(stick.finger==-1 and game.move_vector==Vector2.ZERO,"Hiding joystick clears held movement")
	stick.show();touch(stick,3,Vector2(40,0))
	game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not game.playing and stick.finger==-1 and game.move_vector==Vector2.ZERO,"App focus loss pauses and releases touch")
	game.hud.resume();game.set_physics_process(false)
	touch(game.hud.attack_button,4,Vector2.ZERO)
	check(game.attack_held,"Touch attack can be held")
	game.hud.attack_button.hide()
	check(not game.attack_held and game.hud.attack_button.finger==-1,"Hidden attack emits release instead of sticking")
	game.hud.attack_button.show();game.hud.reset_stick()
	var old=Data.fresh("Mage");old.needs.erase("wetness");old.gold=876;old.level=7
	var migrated=Data.migrate(old)
	check(migrated.needs.wetness==0 and migrated.gold==876 and migrated.level==7,"Older saves gain dry clothing without losing progression")
	for value in [-1,101,"bad",null,NAN,INF]:
		var bad=migrated.duplicate(true);bad.needs.wetness=value
		check(Data.migrate(bad).is_empty(),"Invalid wetness rejected: "+str(value))
	var path="user://stability-character.json"
	check(Data.write_save(migrated,path) and Data.write_save(migrated,path),"Fixture creates a valid primary and backup")
	var backup=FileAccess.get_file_as_string(path+".bak")
	corrupt(path);var recovered=Data.read_save(path)
	check(recovered.gold==876 and recovered.level==7,"Corrupt primary recovers real progression")
	recovered.gold=999;check(Data.write_save(recovered,path),"Saving a recovered character succeeds")
	check(FileAccess.get_file_as_string(path+".bak")==backup,"Saving recovery preserves the last good backup")
	corrupt(path,"{\"className\":\"Warrior\",\"inventory\":[]}")
	check(Data.read_save(path).gold==876,"Structurally invalid primary also falls back")
	check(Data.write_save(recovered,path) and FileAccess.get_file_as_string(path+".bak")==backup,"Invalid JSON structure cannot overwrite good backup")
	check(not Data.write_save(recovered,"user://missing-dir/character.json"),"Unwritable saves report failure")
	game.hero.mode="survival";game.hero.worldTime=0;game.set_player_position(Vector2.ZERO)
	var exp=game.expedition;var n=game.hero.needs
	check(game.weather.sky()=="Rain","Rain fixture uses the real seasonal calendar")
	exp.tick(60);check(n.wetness>30,"Uncovered rain soaks clothing during live survival")
	var wet=n.wetness;game.pause_game();exp.tick(60)
	check(n.wetness==wet,"Paused survival does not soak or dry clothing")
	game.hud.resume();game.set_physics_process(false)
	game.hero.survival.structures=[structure("Roof")];exp.tick(10)
	check(n.wetness<wet,"Roof cover dries clothing even in rain")
	game.hero.survival.structures=[];game.hero.worldTime=420;n.wetness=0
	var dry=exp.exposure_target();n.wetness=100
	check(exp.exposure_target()<dry,"Soaked clothing makes actual night exposure colder")
	game.hero.survival.structures=[structure("Campfire",Vector2(80,0))]
	wet=n.wetness;exp.tick(10)
	check(n.wetness<=wet-14 and exp.exposure_target()==50,"Reachable fire dries quickly and restores comfortable target")
	game.hero.survival.structures.append(structure("Wall",Vector2(40,0)))
	check(not game.weather.near_fire(),"Walls block campfire warming and drying")
	game.hero.survival.structures=[];n.wetness=100;game.hero.worldTime=3600;game.set_player_position(Vector2(0,-1600))
	exp.tick(1000);check(n.wetness>=0 and n.wetness<=100,"Wetness stays within bounds during long exposure")
	exp.reset_after_defeat();check(n.wetness==0,"Defeat resets wetness to avoid an exposure loop")
	game.set_player_position(Vector2.ZERO);game.hero.worldTime=0;game.hero.hp=100
	var enemy=game.create_enemy(Vector2(30,0),1,"wolf");enemy.windup=.2;enemy.strike=Vector2.ZERO;enemy.returning=true
	game.update_enemy_attack(enemy,1)
	check(enemy.windup==0 and game.hero.hp==100,"Disengaging cancels pending attacks")
	enemy.returning=false;enemy.windup=.2;game.hero.survival.structures=[structure("Shelter")]
	game.update_enemy_attack(enemy,1)
	check(enemy.windup==0 and game.hero.hp==100,"Entering shelter cancels a pending enemy strike")
	game.hero.survival.structures=[];enemy.windup=.2;enemy.dead=true;game.update_enemy_attack(enemy,1)
	check(game.hero.hp==100,"Dead enemies cannot finish a pending attack")
	var bed=structure("Bed",Vector2(80,0));game.hero.survival.structures=[bed,structure("Wall",Vector2(40,0))];game.enemies.clear()
	check(not game.survival.rest(bed),"A wall blocks using a nearby bed")
	check(not game.survival.rest({}),"Missing bed selection is handled safely")
	game.hero.survival.structures=[bed];game.enemies=[game.create_enemy(Vector2(20,0),1,"deer")]
	check(game.survival.rest(bed),"Peaceful wildlife no longer prevents bed rest")
	check(not game.survival.rest(structure("Bed",Vector2(20,0))),"A removed bed cannot be used through a stale menu")
	check(not Data.migrate(JSON.parse_string(JSON.stringify(game.hero))).is_empty(),"New survival state round-trips through shared character format")
	print("%d STABILITY CHECKS PASSED" % checks);quit(0)
