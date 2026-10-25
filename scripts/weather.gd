extends RefCounted

# The saved play clock is the only calendar. No wall-clock or offline catch-up.
const DAY_SECONDS=600.0
const SEASON_SECONDS=DAY_SECONDS*2
const SEASONS=["Spring","Summer","Autumn","Winter"]
const GATHER_BONUS={"Spring":["Herbs","Fiber"],"Summer":["Berries","Resin"],"Autumn":["Wood","Glowcap"],"Winter":["Frost shard","Pine resin"]}
var game
var particles_enabled=true
var last_season=""

static func season_at(time:float) -> String:
	return SEASONS[posmod(floori(maxf(0,time)/SEASON_SECONDS),4)]

static func sky_at(time:float,region:String,in_dungeon:bool=false) -> String:
	if in_dungeon or region=="caves": return "Underground"
	var season=season_at(time)
	var block=floori(maxf(0,time)/120)
	var roll=posmod(block*37+floori(block/7.0)*19,100)
	if region=="snow": return "Snow" if roll<78 else "Clear"
	if region=="swamp":
		if roll<38: return "Fog"
		if roll<73: return "Snow" if season=="Winter" else "Rain"
		return "Clear"
	if season=="Winter": return "Snow" if roll<68 else "Fog" if roll<80 else "Clear"
	if season=="Spring": return "Rain" if roll<46 else "Fog" if roll<61 else "Clear"
	if season=="Summer": return "Rain" if roll<20 else "Clear"
	return "Rain" if roll<30 else "Fog" if roll<55 else "Clear"

func season() -> String: return season_at(game.hero.worldTime)
func sky() -> String: return sky_at(game.hero.worldTime,"forest" if game.exploration.outdoor_highlands(game.player_position()) else game.exploration.region_at(game.player_position()),game.hero.dungeon!=null)
func day() -> int: return floori(game.hero.worldTime/DAY_SECONDS)+1
func day_in_season() -> int: return posmod(day()-1,2)+1

func covered_at(pos:Vector2) -> bool:
	if game.hero.dungeon!=null or game.exploration.region_at(pos)=="caves" and not game.exploration.outdoor_highlands(pos): return true
	for structure in game.hero.survival.structures:
		if structure.kind=="Shelter" and pos.distance_to(game.survival.at(structure))<60: return true
		if structure.kind=="Roof" and game.survival.footprint("Roof",game.survival.at(structure),structure.rotation).has_point(pos): return true
	return false

func near_fire() -> bool:
	if game.hero.dungeon!=null: return false
	for structure in game.hero.survival.structures:
		if structure.kind=="Campfire" and structure.fuel>0 and game.survival.at(structure).distance_to(game.player_position())<100 and game.line_clear(game.player_position(),game.survival.at(structure)):
			return true
	return false

func tea_remaining() -> float: return maxf(0,game.hero.warmUntil-game.hero.worldTime)

func comfort() -> String:
	if game.hero.dungeon!=null or game.exploration.region_at(game.player_position())=="caves" and not game.exploration.outdoor_highlands(game.player_position()): return "Underground"
	var cover=covered_at(game.player_position())
	if near_fire(): return "Cozy camp" if cover else "By the fire"
	if tea_remaining()>0: return "Warm tea · %ds" % ceili(tea_remaining())
	if cover: return "Under cover"
	if sky()=="Snow": return "Cold outdoors"
	if sky()=="Rain": return "Rain outdoors"
	return "Exploring" if game.is_walking else "At rest"

func recovery_rate() -> Vector2:
	if near_fire(): return Vector2(1,2) if covered_at(game.player_position()) else Vector2(0,1)
	return Vector2(0,1) if tea_remaining()>0 else Vector2.ZERO

func gather_bonus(material:String) -> int:
	return 1 if material in GATHER_BONUS[season()] else 0

func summary() -> String:
	return "%s · Day %d/2 · %s" % [season(),day_in_season(),sky()]

func tick() -> void:
	var current=season()
	if current!=last_season:
		if not last_season.is_empty(): game.notify(current+" has arrived. Open Camp → Journal for seasonal gathering bonuses.",5)
		last_season=current

func load_settings() -> void:
	var config=ConfigFile.new()
	if config.load("user://weather.cfg")==OK: particles_enabled=bool(config.get_value("weather","particles",true))

func toggle_particles() -> void:
	particles_enabled=not particles_enabled
	var config=ConfigFile.new()
	config.set_value("weather","particles",particles_enabled)
	config.save("user://weather.cfg")

func blizzard() -> bool:
	return game.hero.dungeon==null and game.exploration.region_at(game.player_position())=="snow" and sky()=="Snow" and fposmod(game.hero.worldTime,240)>180
func particle_count() -> int:
	if not particles_enabled or sky() not in ["Rain","Snow"]: return 0
	return 18 if game.low_power else 42
