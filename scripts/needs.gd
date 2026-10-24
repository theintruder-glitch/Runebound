extends RefCounted

# Additive save data; the active simulation clock is the only source of depletion.
const DEFAULTS={"food":100.0,"water":100.0,"fatigue":0.0,"exposure":0.0,"flask":3,"difficulty":"normal"}
var game

static func migrate(hero:Dictionary) -> bool:
	hero.gameMode=hero.get("gameMode","adventure")
	if hero.gameMode not in ["adventure","survival"]: return false
	hero.needs=hero.get("needs",{})
	if not hero.needs is Dictionary: return false
	for key in DEFAULTS:
		hero.needs[key]=hero.needs.get(key,DEFAULTS[key])
	if hero.needs.difficulty not in ["normal","gentle"]: return false
	for key in ["food","water","fatigue","exposure","flask"]:
		var value=hero.needs[key]
		if not (value is int or value is float) or not is_finite(float(value)): return false
		if value<0 or value>(3 if key=="flask" else 100): return false
	if floor(hero.needs.flask)!=hero.needs.flask: return false
	hero.needs.flask=int(hero.needs.flask)
	return true

func active() -> bool:
	return not game.hero.is_empty() and game.hero.gameMode=="survival"

func configure(mode:String,difficulty:String) -> bool:
	if game.hero.is_empty() or mode not in ["adventure","survival"] or difficulty not in ["normal","gentle"]: return false
	var old_mode=game.hero.gameMode
	var old_difficulty=game.hero.needs.difficulty
	game.hero.gameMode=mode
	game.hero.needs.difficulty=difficulty
	if not game.save_game():
		game.hero.gameMode=old_mode
		game.hero.needs.difficulty=old_difficulty
		return false
	return true

func tick(dt:float) -> void:
	if not active() or not game.playing or not is_finite(dt) or dt<=0: return
	var n=game.hero.needs
	var pace=.5 if n.difficulty=="gentle" else 1.0
	n.food=maxf(0,n.food-dt*.04*pace)
	n.water=maxf(0,n.water-dt*.06*pace)
	n.fatigue=minf(100,n.fatigue+dt*.02*pace)
	var covered=game.weather.covered_at(game.player_position())
	var cold=game.exploration.region_at(game.player_position())=="snow" or game.weather.season()=="Winter"
	var rate=-.2
	if game.weather.near_fire() or game.weather.tea_remaining()>0: rate=-.8
	elif covered: rate=-.4
	elif cold: rate=.15*pace
	elif game.weather.sky()=="Rain": rate=.06*pace
	n.exposure=clampf(n.exposure+dt*rate,0,100)

func speed_scale() -> float:
	if not active(): return 1.0
	var n=game.hero.needs
	var burden=int(n.food<20)+int(n.water<20)+int(n.fatigue>80)+int(n.exposure>80)
	return maxf(.9 if n.difficulty=="gentle" else .7,1-burden*.1)

func summary() -> String:
	var n=game.hero.needs
	return "Food %d · Water %d · Tired %d · Cold %d" % [ceil(n.food),ceil(n.water),ceil(n.fatigue),ceil(n.exposure)]

func at_camp() -> bool:
	return game.hero.dungeon==null and game.player_position().length()<=110

func commit_needs(before:Dictionary) -> bool:
	if not game.save_game():
		game.hero.needs=before
		return false
	game.hud.update_hud()
	return true

func drink() -> bool:
	if not active() or game.hero.needs.flask<=0 or game.hero.needs.water>=100: return false
	var before=game.hero.needs.duplicate(true)
	game.hero.needs.flask-=1
	game.hero.needs.water=minf(100,game.hero.needs.water+40)
	return commit_needs(before)

func refill() -> bool:
	if not active() or not at_camp(): return false
	var before=game.hero.needs.duplicate(true)
	game.hero.needs.flask=3
	game.hero.needs.water=100.0
	return commit_needs(before)

func can_rest() -> bool:
	if not active(): return false
	if not at_camp() and not game.survival.sheltered() and game.survival.near("Bed",110).is_empty(): return false
	for enemy in game.enemies:
		if not enemy.dead and not enemy.get("neutral",false) and enemy.pos.distance_to(game.player_position())<240: return false
	return true

func rest() -> bool:
	if not can_rest(): return false
	var before=game.hero.needs.duplicate(true)
	game.hero.needs.fatigue=0.0
	return commit_needs(before)

func feed(food:String) -> void:
	if not active(): return
	var n=game.hero.needs
	n.food=minf(100,n.food+(5 if food=="Warm tea" else 25 if food=="Roasted berries" else 40))
	if food in ["Warm tea","Herbal stew","Trail stew","Bog remedy"]:
		n.water=minf(100,n.water+(35 if food=="Warm tea" else 15))
