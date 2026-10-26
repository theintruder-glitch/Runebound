extends RefCounted
const Data=preload("res://scripts/data.gd")
const SPRING=Vector2(160,-48)
const FOOD={"Grilled fish":35.0,"Fisher stew":55.0,"Berries":12.0,"Roasted berries":28.0,"Herbal stew":48.0,"Roasted meat":42.0,"Trail stew":65.0,"Warm tea":5.0,"Bog remedy":12.0}
var game
var notice_timer=0.0
func enabled() -> bool: return not game.hero.is_empty() and game.hero.mode=="survival"
func data() -> Dictionary: return game.hero.needs
func deprived() -> bool: return enabled() and (data().hunger<=0 or data().water<=0 or data().temperature<10 or data().temperature>90)
func speed_factor() -> float: return .78 if enabled() and (data().sleep<15 or data().water<15) else 1.0
func switch_mode(mode:String) -> bool:
	if mode not in ["classic","survival"] or game.hero.is_empty() or game.hero.dungeon!=null: return false
	game.hero.mode=mode;game.save_game();game.hud.update_hud();return true
func near_spring() -> bool:
	return game.hero.dungeon==null and game.player_position().distance_to(SPRING)<85 and game.line_clear(game.player_position(),SPRING)
func drink(refill:bool=false) -> bool:
	if not enabled(): return false
	if refill:
		if not near_spring(): return false
		data().flask=game.kit.capacity();data().water=100
	else:
		if data().flask<=0 or data().water>=100: return false
		data().flask-=1;data().water=minf(100,data().water+45)
	game.sound("cook");game.save_game();game.hud.update_hud();return true
func eat(food:String) -> bool:
	if not enabled() or not FOOD.has(food) or game.survival.count(food)<1 or data().hunger>=100: return false
	if food=="Berries":
		game.survival.add(food,-1);on_food(food);game.save_game();game.hud.update_hud();return true
	return game.survival.eat(food)
func on_food(food:String) -> void:
	if not enabled(): return
	data().hunger=minf(100,data().hunger+FOOD.get(food,0))
	if food in ["Warm tea","Herbal stew","Trail stew","Fisher stew"]: data().water=minf(100,data().water+18)
func sleep_at_bed() -> void:
	if not enabled(): return
	data().sleep=100;data().hunger=maxf(0,data().hunger-6);data().water=maxf(0,data().water-8)
func exposure_target() -> float:
	if not enabled(): return 50.0
	var target=base_exposure()
	if target<50: target=maxf(0,target-data().wetness*.12)
	return game.kit.exposure(target)
func base_exposure() -> float:
	if not enabled(): return 50.0
	if game.weather.near_fire() or game.weather.tea_remaining()>0: return 50.0
	var region=game.exploration.region_at(game.player_position());var cover=game.weather.covered_at(game.player_position())
	if game.hero.dungeon!=null or region=="caves" and not game.exploration.outdoor_highlands(game.player_position()): return 42.0
	if cover: return 45.0 if game.weather.season()=="Winter" or region=="snow" else 50.0
	if region=="snow": return 0.0
	if game.weather.season()=="Winter": return 5.0
	if game.weather.sky()=="Rain": return 22.0
	if game.weather.season()=="Summer" and Data.phase(game.hero.worldTime)=="Day": return 96.0
	return 38.0 if Data.phase(game.hero.worldTime)=="Night" else 50.0
func condition() -> String:
	if data().temperature<20: return "Freezing · find fire or cover"
	if data().temperature>80: return "Overheating · find shade and water"
	if data().water<20: return "Thirsty · drink from your flask"
	if data().hunger<20: return "Hungry · eat carried food"
	if data().sleep<20: return "Exhausted · rest at a bed"
	if data().wetness>=60: return "Soaked · dry off by a fire"
	return "Comfortable"
func tick(dt:float) -> void:
	if not enabled() or not game.playing or dt<=0: return
	var n=data();n.elapsed+=dt
	var cover=game.weather.covered_at(game.player_position())
	var sky=game.weather.sky()
	var wet_rate=-1.4 if game.weather.near_fire() else -.2 if cover else .65 if sky=="Rain" else .2 if sky=="Snow" else -.08
	if wet_rate>0:wet_rate*=game.mire.weather_multiplier()
	n.wetness=clampf(n.wetness+wet_rate*dt,0,100)
	n.hunger=maxf(0,n.hunger-dt*(.11 if game.is_walking else .08))
	n.water=maxf(0,n.water-dt*(.22 if n.temperature>80 else .14))
	n.sleep=maxf(0,n.sleep-dt*.06)
	n.temperature=move_toward(n.temperature,exposure_target(),dt*(.8 if game.weather.near_fire() else .22))
	if deprived(): game.hero.hp-=dt*(1.5 if n.water<=0 else .8)
	notice_timer-=dt
	if notice_timer<=0 and condition()!="Comfortable":
		game.notify(condition()+(" · V opens survival supplies" if game.desktop.enabled else " · Gear → Survival supplies"),4);notice_timer=25
	check_victory()
func objectives() -> Array:
	var kinds=[]
	for s in game.hero.survival.structures: kinds.append(s.kind)
	return [data().elapsed>=3000,"Shelter" in kinds and "Bed" in kinds,data().harvested,data().ruins]
func check_victory() -> void:
	if not enabled() or game.hero.hp<=0 or data().won or false in objectives(): return
	data().won=true;game.hero.gold+=500;game.hero.essence+=8
	game.notify("SURVIVAL CHAPTER COMPLETE · +500 gold and 8 essence. Your home and world remain playable.",8);game.save_game()
func reset_after_defeat() -> void:
	if not enabled(): return
	for key in ["hunger","water","sleep"]: data()[key]=60.0
	data().temperature=50.0;data().wetness=0.0;data().flask=maxi(1,data().flask)
	# A new attempt at surviving five days; building, harvest and dungeon goals persist.
	if not data().won: data().elapsed=0.0
