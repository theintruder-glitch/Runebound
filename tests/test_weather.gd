extends SceneTree
const Data=preload("res://scripts/data.gd")
const Weather=preload("res://scripts/weather.gd")
var checks=0
func _initialize(): call_deferred("run")
func check(ok:bool,message:String):
	if not ok:
		push_error("FAIL: "+message);quit(1);assert(ok,message)
	checks+=1;print("PASS: "+message)
func structure(kind:String,pos:Vector2,fuel:float=0) -> Dictionary:
	return {"kind":kind,"x":pos.x,"y":pos.y,"rotation":0,"fuel":fuel,"open":false,"stash":{}}
func run():
	root.size=Vector2i(1080,2400)
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);await process_frame
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false)
	game.enemies.clear();game.hero.auto=false;game.spawn_timer=100000
	var weather=game.weather;var camp=game.survival
	for i in range(4):
		check(Weather.season_at(i*1200)==Weather.SEASONS[i],"Season boundary: "+Weather.SEASONS[i])
		check(Weather.season_at(i*1200+1199.99)==Weather.SEASONS[i],"Season lasts two full game days: "+Weather.SEASONS[i])
	check(Weather.season_at(4800)=="Spring","Annual cycle repeats")
	check(Weather.sky_at(0,"forest")=="Rain" and Weather.sky_at(120,"forest")=="Rain" and Weather.sky_at(240,"forest")=="Clear","Weather changes in deterministic two-minute blocks")
	check(Weather.sky_at(0,"snow")=="Snow" and Weather.sky_at(1320,"snow")=="Snow","Northern snow is independent of the current season")
	check(Weather.sky_at(0,"swamp")=="Fog","Swamp has regional fog")
	check(Weather.sky_at(0,"caves")=="Underground" and Weather.sky_at(3600,"forest",true)=="Underground","Caves and dungeons exclude outdoor weather")
	check(Weather.sky_at(3720,"forest")=="Snow","Winter brings snow to the forest")
	var legacy=Data.fresh("Ranger");legacy.erase("warmUntil")
	check(Data.migrate(legacy).warmUntil==0,"Old characters receive weather defaults")
	legacy.worldTime="bad";check(Data.migrate(legacy).is_empty(),"Invalid calendar data is rejected")
	legacy=Data.fresh("Mage");legacy.warmUntil="bad";check(Data.migrate(legacy).is_empty(),"Invalid tea duration is rejected")
	for i in range(4):
		game.hero.worldTime=i*1200
		weather.tick();game.world.refresh()
		check(game.world.palette_season==Weather.SEASONS[i],"Terrain palette updates: "+Weather.SEASONS[i])
		for material in Weather.GATHER_BONUS[Weather.SEASONS[i]]:
			check(weather.gather_bonus(material)==1,"Seasonal harvest bonus: "+Weather.SEASONS[i]+" "+material)
		check(weather.gather_bonus("Iron")==0,"Ore yields remain stable: "+Weather.SEASONS[i])
	game.hero.worldTime=0;weather.tick();game.set_player_position(Vector2.ZERO)
	var roof=structure("Roof",Vector2.ZERO)
	var fire=structure("Campfire",Vector2(40,0),90)
	game.hero.survival.structures=[roof,fire]
	check(weather.covered_at(Vector2.ZERO) and not weather.covered_at(Vector2(40,0)),"Roof cover follows its actual footprint")
	check(weather.comfort()=="Cozy camp" and weather.recovery_rate()==Vector2(1,2),"Roof and lit fire provide cozy recovery")
	game.hero.hp=30;game.hero.mp=10
	game.tick(1)
	check(is_equal_approx(game.hero.mp,16),"Cozy camp restores two extra mana per second")
	check(game.hero.hp>31,"Cozy camp adds health recovery to normal regeneration")
	game.hero.survival.structures=[fire]
	check(not weather.covered_at(Vector2.ZERO) and weather.recovery_rate()==Vector2(0,1),"Fire alone gives mana recovery without cover")
	fire.fuel=0
	check(weather.recovery_rate()==Vector2.ZERO,"An exhausted fire stops its recovery bonus")
	game.hero.survival.structures=[roof]
	check(weather.comfort()=="Under cover" and weather.recovery_rate()==Vector2.ZERO,"A roof alone keeps precipitation off without a fire bonus")
	var shelter=structure("Shelter",Vector2.ZERO)
	game.hero.survival.structures=[shelter,fire];fire.fuel=90
	check(weather.covered_at(Vector2(0,59)) and weather.recovery_rate()==Vector2(1,2),"Shelter cover combines with a lit fire")
	game.hero.survival.structures=[fire]
	camp.add("Herbs",4);camp.add("Berries",2)
	check(camp.craft("Warm tea") and camp.count("Warm tea")==1,"Tea can be cooked using herbs and berries")
	game.hero.hp=10;game.hero.mp=10
	check(camp.eat("Warm tea") and game.hero.hp==25 and game.hero.mp==25,"Tea is consumed and restores health and mana")
	check(weather.tea_remaining()==180,"Tea lasts three active-play minutes")
	game.hero.survival.structures=[]
	check(weather.recovery_rate()==Vector2(0,1),"Tea grants portable mana recovery")
	game.hero.worldTime+=50;camp.add("Warm tea",1);camp.eat("Warm tea")
	check(weather.tea_remaining()==180,"Additional tea refreshes the duration without stacking")
	game.hero.survival.structures=[roof,fire]
	check(weather.recovery_rate()==Vector2(1,2),"Tea does not stack with cozy camp recovery")
	game.save_game();var saved=Data.read_save()
	check(saved.worldTime==game.hero.worldTime and saved.warmUntil==game.hero.warmUntil,"Calendar and tea expiry survive save/reload")
	game.pause_game();var time=game.hero.worldTime;var fuel=fire.fuel
	game.set_physics_process(true);await create_timer(.12).timeout;game.set_physics_process(false)
	check(game.hero.worldTime==time and fire.fuel==fuel and weather.tea_remaining()==180,"Menus pause season time, fuel, and tea duration")
	game.hero.worldTime+=181
	check(weather.tea_remaining()==0,"Tea expires with active play time")
	game.hero.survival.structures=[];game.playing=true
	game.hero.worldTime=3720;game.move_vector=Vector2.RIGHT
	game.set_player_position(Vector2.ZERO);game.tick(.1)
	check(is_equal_approx(game.hero.x,13),"Winter weather preserves live movement speed")
	game.move_vector=Vector2.ZERO
	game.enemies=[game.create_enemy(game.player_position()+Vector2(145,0),1,"archer")]
	game.enemies[0].aggro=1
	game.hero.warmUntil=game.hero.worldTime+180;game.hero.mp=10
	game.tick(.1)
	check(is_equal_approx(game.hero.mp,10.4),"Weather recovery is disabled during combat")
	game.enemies.clear();game.world.profile_enabled=true
	weather.particles_enabled=true;game.low_power=true
	check(weather.particle_count()==18,"Low-power weather is capped at eighteen particles")
	game.low_power=false;check(weather.particle_count()==42,"Normal weather is capped at forty-two particles")
	for scenario in [{"time":0,"pos":Vector2.ZERO},{"time":3720,"pos":Vector2.ZERO},{"time":0,"pos":Vector2(-2050,0)},{"time":0,"pos":Vector2(2050,0)}]:
		game.hero.worldTime=scenario.time;game.set_player_position(scenario.pos);game.camera.position=scenario.pos
		weather.tick();game.world.refresh(true);game.world.profile_draw_samples.clear();game.world.queue_redraw()
		await process_frame;await process_frame
		check(game.world.profile_draw_samples.size()>0,"Weather executes real native draw callbacks: "+weather.sky())
	game.set_player_position(Vector2.ZERO);game.hero.worldTime=0
	weather.particles_enabled=false;check(weather.particle_count()==0,"Weather effects can be disabled")
	check(weather.sky()=="Rain" and weather.season()=="Spring","Disabling effects preserves weather simulation")
	weather.particles_enabled=true;game.hero.warmUntil=0
	game.hud.camp_page="Journal";game.hud.show_character("camp");await process_frame
	check(game.hud.current_page=="camp","Calendar and seasonal guidance open in Camp Journal")
	print(str(checks)+" WEATHER CHECKS PASSED")
	quit()
