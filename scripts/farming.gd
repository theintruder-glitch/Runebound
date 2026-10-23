extends RefCounted

const Weather=preload("res://scripts/weather.gd")
const MAX_PLOTS=12
const CROPS={
	"Berries":{"cost":2,"yield":6,"seconds":180.0,"discovery":""},
	"Herbs":{"cost":2,"yield":5,"seconds":210.0,"discovery":""},
	"Glowcap":{"cost":2,"yield":5,"seconds":240.0,"discovery":"swamp"}
}
var game

func plots() -> Array:
	return game.hero.survival.structures.filter(func(s):return s.kind=="Garden")

func owns(plot:Dictionary) -> bool:
	for stored in plots():
		if is_same(stored,plot): return true
	return false

func nearby(plot:Dictionary) -> bool:
	return game.hero.dungeon==null and game.survival.at(plot).distance_to(game.player_position())<110 and game.line_clear(game.player_position(),game.survival.at(plot))

func nearest(radius:float=110) -> Dictionary:
	var result:Dictionary={};var distance=radius
	for plot in plots():
		var candidate=game.survival.at(plot).distance_to(game.player_position())
		if candidate<distance and nearby(plot): result=plot;distance=candidate
	return result

func access_reason(plot:Dictionary) -> String:
	if not owns(plot): return "This garden is no longer in your camp"
	if game.hero.dungeon!=null: return "Return to your garden in the wilds"
	if not nearby(plot): return "Stand within 110 units with a clear path to this garden"
	return ""

func plant_reason(plot:Dictionary,crop:String) -> String:
	var why=access_reason(plot)
	if not why.is_empty(): return why
	if not CROPS.has(crop): return "Unknown crop"
	if not plot.get("crop","").is_empty(): return "Harvest or clear the current crop first"
	if game.exploration.region_at(game.survival.at(plot))=="caves": return "Plant on outdoor ground"
	var info=CROPS[crop]
	if info.discovery!="" and not game.hero.exploration.discovered.get(info.discovery,false): return "Discover the Veil Altar to learn glowcap cultivation"
	if game.survival.count(crop)<info.cost: return "Carry %d %s to plant" % [info.cost,crop]
	return ""

func plant(plot:Dictionary,crop:String) -> bool:
	var why=plant_reason(plot,crop)
	if not why.is_empty(): game.notify(why,3);return false
	game.survival.add(crop,-CROPS[crop].cost)
	plot.crop=crop;plot.growth=0.0
	game.survival.revision+=1;game.sound("gather")
	game.notify("Planted "+crop+". Keep adventuring while it grows.",3)
	game.save_game();return true

func ready(plot:Dictionary) -> bool:
	return CROPS.has(plot.get("crop","")) and float(plot.get("growth",0))>=CROPS[plot.crop].seconds

func stage(plot:Dictionary) -> int:
	if not CROPS.has(plot.get("crop","")): return 0
	if ready(plot): return 3
	return 2 if float(plot.get("growth",0))>=CROPS[plot.crop].seconds*.5 else 1

func ready_count() -> int:
	return plots().filter(func(plot):return ready(plot)).size()

func rate() -> float:
	return 1.25 if game.weather.season()=="Spring" else .75 if game.weather.season()=="Winter" else 1.0

# Integral of the saved seasonal clock: exact across boundaries and whole years.
# No offline timestamp, per-plot timer node, particles, or redraw every frame.
static func growth_clock(time:float) -> float:
	var length=Weather.SEASON_SECONDS
	var year=length*4
	var t=maxf(0,time)
	var within=fmod(t,year)
	return floor(t/year)*year+minf(within,length)*1.25+clampf(within-length,0,length*2)+maxf(0,within-length*3)*.75

func tick(dt:float) -> void:
	if dt<=0: return
	var gain=growth_clock(game.hero.worldTime)-growth_clock(game.hero.worldTime-dt)
	for plot in plots():
		if not CROPS.has(plot.get("crop","")) or ready(plot): continue
		var before=stage(plot)
		plot.growth=minf(CROPS[plot.crop].seconds,float(plot.get("growth",0))+gain)
		if stage(plot)!=before: game.survival.revision+=1

func status(plot:Dictionary) -> String:
	if not CROPS.has(plot.get("crop","")): return "Empty soil · ready to plant"
	var info=CROPS[plot.crop]
	if ready(plot): return "%s · ready · harvest %d" % [plot.crop,info.yield]
	return "%s · %d%% · about %ds at the current season's rate" % [plot.crop,floori(plot.growth/info.seconds*100),ceili((info.seconds-plot.growth)/rate())]

func harvest_reason(plot:Dictionary) -> String:
	var why=access_reason(plot)
	if not why.is_empty(): return why
	if not ready(plot): return "This crop is still growing" if not plot.get("crop","").is_empty() else "Plant a crop first"
	if game.survival.count(plot.crop)+CROPS[plot.crop].yield>99999: return "Make room in carried supplies before harvesting"
	return ""

func harvest(plot:Dictionary) -> bool:
	var why=harvest_reason(plot)
	if not why.is_empty(): game.notify(why,3);return false
	var crop=plot.crop;var amount=CROPS[crop].yield
	plot.crop="";plot.growth=0.0
	game.survival.add(crop,amount);game.survival.revision+=1
	game.sound("gather");game.notify("Harvested +%d %s. This plot can be planted again." % [amount,crop],3)
	game.save_game();return true

func clear_reason(plot:Dictionary) -> String:
	var why=access_reason(plot)
	if not why.is_empty(): return why
	if not CROPS.has(plot.get("crop","")): return "This plot is already empty"
	if game.survival.count(plot.crop)+CROPS[plot.crop].cost>99999: return "Make room in carried supplies before recovering ingredients"
	return ""

func clear_crop(plot:Dictionary) -> bool:
	var why=clear_reason(plot)
	if not why.is_empty(): game.notify(why,3);return false
	var crop=plot.crop;var amount=CROPS[crop].cost
	plot.crop="";plot.growth=0.0
	game.survival.add(crop,amount);game.survival.revision+=1;game.sound("gather")
	game.notify("Plot cleared. Recovered %d %s; growth was reset." % [amount,crop],3)
	game.save_game();return true
