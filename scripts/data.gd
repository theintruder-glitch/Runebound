class_name RuneboundData
extends RefCounted

const SAVE_PATH = "user://character.json"
const CLASSES = {
	"Warrior": {"weapon":"sword", "color":"dca58d", "desc":"Sword damage +35%. Maximum health +35."},
	"Mage": {"weapon":"staff", "color":"b9a4ed", "desc":"Magic damage +35%. Maximum mana +40."},
	"Ranger": {"weapon":"bow", "color":"9ed2a2", "desc":"Bow damage +40%. Faster movement."},
	"Rogue": {"weapon":"sword", "color":"c5bacf", "desc":"Critical chance +25%. Faster dash recovery."},
	"Cleric": {"weapon":"staff", "color":"e8d8a1", "desc":"Stronger healing and passive health recovery."},
	"Spellblade": {"weapon":"sword", "color":"e5aaff", "desc":"Sword and magic damage +35%. Melee hits restore mana.", "goal":"40 melee kills and 30 magic kills, or complete the Emberforge sword-and-magic trial."},
	"Arcane Archer": {"weapon":"bow", "color":"8de8e3", "desc":"Bow damage +40%. Arrows splash arcane damage.", "goal":"60 bow kills and 20 magic kills, or defeat the Root Warden."},
	"Reaper": {"weapon":"sword", "color":"ed96a7", "desc":"Hits steal health. Critical hits deal triple damage.", "goal":"Defeat 5 guardians or dungeon lords, or complete the Veil Altar trial."}
}
const RARITIES = [
	{"name":"Common", "color":"c3cec3", "mult":1.0, "weight":60},
	{"name":"Uncommon", "color":"94db9e", "mult":1.4, "weight":25},
	{"name":"Rare", "color":"8bbdf1", "mult":2.0, "weight":10},
	{"name":"Epic", "color":"c6a1f2", "mult":3.0, "weight":4},
	{"name":"Legendary", "color":"f1c671", "mult":5.0, "weight":1}
]
const ENCHANTS = ["None", "Ember", "Frost", "Storm", "Leech"]
const TITLES = ["Peasant", "Squire", "Knight", "Baron", "Duke", "Prince", "King", "Endless King"]
const BUILDINGS = {
	"Blacksmith":{"cost":180, "desc":"+10% damage; upgrades cost 20% less gold."},
	"Tavern":{"cost":120, "desc":"Double recovery outside combat; +1.5 mana per second."},
	"Barracks":{"cost":250, "desc":"Incoming enemy damage reduced by 10%."}
}
const ITEM_NAMES = {
	"sword":["Ironbrand", "Thorncleaver", "Moonsteel Edge"],
	"bow":["Willow Longbow", "Windpiercer", "Huntsman Bow"],
	"staff":["Runewood Staff", "Starcall Staff", "Elder Wand"],
	"shield":["Oakguard Shield", "Iron Aegis", "Runic Ward"],
	"helmet":["Warden Helm", "Dusk Hood", "Crown of Ash"],
	"ring":["Moonstone Ring", "Amber Band", "Spirit Ring"],
	"armor":["Warden Mail", "Wildwalker Coat", "Runeweave Robe"],
	"charm":["Moonstone Charm", "Amber Talisman", "Spirit Sigil"]
}
static var serial = 0

static func fresh(class_name_value: String) -> Dictionary:
	var kind = CLASSES[class_name_value].weapon
	var weapon = {"id":"starter-"+kind, "kind":kind, "name":{"sword":"Wayfarer Sword", "bow":"Ashwood Bow", "staff":"Apprentice Staff"}[kind], "level":1, "rarity":0, "power":9, "upgrade":0, "enchant":0}
	return migrate({"version":1, "className":class_name_value, "x":0.0, "y":0.0, "level":1, "xp":0, "gold":35, "essence":0, "points":0, "str":0, "int":0, "dex":0, "vit":0, "hp":143 if class_name_value=="Warrior" else 108, "mp":103 if class_name_value=="Mage" else 63, "kills":0, "bestDistance":0.0, "inventory":[weapon], "equipped":{"weapon":weapon.id}, "opened":{}, "unlocked":[], "stats":{"melee":0,"magic":0,"bow":0,"bosses":0,"chests":0}, "auto":true,"deaths":0})

static func migrate(hero: Dictionary) -> Dictionary:
	if not CLASSES.has(hero.get("className", "")) or not hero.get("inventory", null) is Array:
		return {}
	for key in ["x","y","level","xp","gold","essence","points","str","int","dex","vit","hp","mp","kills","bestDistance","deaths"]:
		if not hero.get(key) is int and not hero.get(key) is float:
			return {}
		if not is_finite(float(hero[key])):
			return {}
	if hero.level<1 or not hero.get("equipped") is Dictionary or not hero.get("stats") is Dictionary or not hero.get("opened") is Dictionary or not hero.get("unlocked") is Array:
		return {}

	# Optional beacon progress is additive; old saves need no new top-level state.
	var beacon_ids=["beacon-emerald","beacon-frost","beacon-mire","beacon-storm"]
	for id in beacon_ids:
		for key in ["read","step-0","step-1","step-2","solved","cleared","claimed"]:
			if hero.opened.has(id+":"+key) and not hero.opened[id+":"+key] is bool:return {}
		var previous=true
		for key in ["read","step-0","step-1","step-2","solved","cleared","claimed"]:
			var value=hero.opened.get(id+":"+key,false)
			if value and not previous:return {}
			previous=value
		if hero.opened.get(id+":step-2",false) and not hero.opened.get(id+":solved",false):return {}
	if hero.opened.has("waykeeper-accord"):
		if not hero.opened["waykeeper-accord"] is bool:return {}
		if hero.opened["waykeeper-accord"] and not beacon_ids.all(func(id):return hero.opened.get(id+":claimed",false)):return {}
	for item in hero.inventory:
		if not item is Dictionary:
			return {}
		for key in ["id","kind","name","level","rarity","power","upgrade","enchant"]:
			if not item.has(key):
				return {}
		if not ITEM_NAMES.has(item.kind) or item.rarity<0 or item.rarity>4 or item.enchant<0 or item.enchant>4:
			return {}
	if not hero.has("kingdom"):
		hero.kingdom = {"renown":0,"buildings":[]}
	hero.worldTime = hero.get("worldTime",120.0)
	if not (hero.worldTime is int or hero.worldTime is float) or not is_finite(float(hero.worldTime)) or hero.worldTime<0: return {}
	hero.warmUntil=hero.get("warmUntil",0.0)
	if not (hero.warmUntil is int or hero.warmUntil is float) or not is_finite(float(hero.warmUntil)): return {}
	hero.warmUntil=clampf(hero.warmUntil,0,hero.worldTime+180)
	hero.highestFloor = hero.get("highestFloor",0)
	hero.floorsCleared = hero.get("floorsCleared",0)
	hero.dungeon = hero.get("dungeon",null)
	for slot in ["armor","charm","shield","helmet","ring"]:
		if not hero.equipped.has(slot):
			hero.equipped[slot] = null
	# Old dungeon seeds used a JavaScript-specific generator. Keep character and
	# treasure progress, but return imported characters to the safe wilds.
	if hero.get("engine", "") != "godot" and hero.dungeon != null:
		hero.x = hero.dungeon.get("returnX",0)
		hero.y = hero.dungeon.get("returnY",0)
		hero.dungeon = null
	if not hero.has("survival"):
		hero.survival = {"materials":{},"structures":[],"harvested":{}}
	var camp = hero.survival
	if not camp is Dictionary or not camp.get("materials") is Dictionary or not camp.get("structures") is Array or not camp.get("harvested") is Dictionary:
		return {}
	if camp.structures.size()>64 or camp.harvested.size()>10000:
		return {}
	for value in camp.materials.values():
		if not (value is int or value is float) or not is_finite(float(value)) or value<0 or value>99999: return {}
	for key in camp.materials: camp.materials[key]=int(camp.materials[key])
	for value in camp.harvested.values():
		if not (value is int or value is float) or not is_finite(float(value)): return {}
	var gardens=0
	for structure in camp.structures:
		if not structure is Dictionary or structure.get("kind","") not in ["Campfire","Shelter","Workbench","Wall","Door","Bed","Storage","Roof","Garden"]: return {}
		for key in ["x","y","fuel"]:
			if not (structure.get(key) is int or structure.get(key) is float) or not is_finite(float(structure[key])): return {}
		structure.fuel=clampf(structure.fuel,0,600)
		if not (structure.get("rotation",0) is int or structure.get("rotation",0) is float): return {}
		structure.rotation=posmod(int(structure.get("rotation",0)),4)
		structure.open=bool(structure.get("open",false))
		structure.stash=structure.get("stash",{})
		if not structure.stash is Dictionary: return {}
		for key in structure.stash:
			var value=structure.stash[key]
			if not (value is int or value is float) or not is_finite(float(value)) or value<0 or value>99999: return {}
			structure.stash[key]=int(value)
		if structure.kind=="Garden":
			gardens+=1
			if gardens>12: return {}
			structure.crop=structure.get("crop","")
			structure.growth=structure.get("growth",0.0)
			if not structure.crop is String or structure.crop not in ["","Berries","Herbs","Glowcap"]: return {}
			if not (structure.growth is int or structure.growth is float) or not is_finite(float(structure.growth)): return {}
			if structure.growth<0 or structure.growth>{"":0,"Berries":180,"Herbs":210,"Glowcap":240}[structure.crop]: return {}
	hero.chapter=hero.get("chapter",{"accepted":false,"clues":{},"translated":false,"cleared":false,"claimed":false,"tracking":false,"return_until":0.0})
	var chapter=hero.chapter
	if not chapter is Dictionary or chapter.size()!=7: return {}
	for key in ["accepted","translated","cleared","claimed","tracking"]:
		if not chapter.get(key) is bool: return {}
	if not chapter.get("clues") is Dictionary or chapter.clues.size()>3: return {}
	for key in chapter.clues:
		if key not in ["watch","cart","grove"] or not chapter.clues[key] is bool or not chapter.clues[key]: return {}
	if not (chapter.get("return_until") is int or chapter.get("return_until") is float) or not is_finite(float(chapter.return_until)) or chapter.return_until<0 or chapter.return_until>hero.worldTime+120.01: return {}
	if not chapter.accepted and (not chapter.clues.is_empty() or chapter.translated): return {}
	if chapter.translated and chapter.clues.size()!=3: return {}
	if chapter.cleared and not chapter.translated: return {}
	if chapter.claimed and not chapter.cleared: return {}
	if chapter.return_until>0 and not chapter.claimed: return {}
	if hero.dungeon!=null:
		if not hero.dungeon.get("castle","") is String or hero.dungeon.get("castle","") not in ["","thornwatch","frostspire","blackmire","stormbreak","frost-cave","highland-mine"]:return {}
		if hero.dungeon.get("castle","") in ["thornwatch","frostspire","blackmire","stormbreak","frost-cave","highland-mine"]:
			for key in ["floor","seed","returnX","returnY"]:
				var value=hero.dungeon.get(key)
				if not (value is int or value is float) or not is_finite(float(value)):return {}
			if hero.dungeon.floor<1 or hero.dungeon.floor>(1 if hero.dungeon.castle in ["frost-cave","highland-mine"] else 3) or floor(hero.dungeon.floor)!=hero.dungeon.floor or hero.dungeon.get("story",false):return {}
			if not hero.dungeon.get("run") is String or hero.dungeon.run.is_empty() or hero.dungeon.run.length()>80:return {}
			if not hero.dungeon.get("cleared") is Array or not hero.dungeon.get("rewarded") is bool:return {}
			for flag in hero.opened:
				if str(flag).split(":")[0] in ["thornwatch","frostspire","blackmire","stormbreak","frost-cave","highland-mine"] and not hero.opened[flag] is bool:return {}
		# Survey corruption discards only optional map memory, preserving the character.
		var survey=hero.dungeon.get("atlas",{})
		if not survey is Dictionary or survey.size()>8:survey={}
		for floor_key in survey.keys():
			if not floor_key is String or not floor_key.is_valid_int() or int(floor_key)<1:
				survey.erase(floor_key);continue
			var cells=survey[floor_key]
			if not cells is Array or cells.size()>1600:
				survey.erase(floor_key);continue
			if not cells.all(func(v):return (v is int or v is float) and is_finite(float(v)) and v==floor(v) and v>=0 and v<1600):survey.erase(floor_key)
		hero.dungeon.atlas=survey
		if not hero.dungeon.get("story",false) is bool: return {}
		if hero.dungeon.get("story",false) and (not chapter.translated or hero.dungeon.floor<1 or hero.dungeon.floor>3): return {}
	hero.forge_chapter=hero.get("forge_chapter",{"accepted":false,"inspected":false,"cleared":false,"claimed":false})
	var forge=hero.forge_chapter
	if not forge is Dictionary or forge.size()!=4: return {}
	for key in ["accepted","inspected","cleared","claimed"]:
		if not forge.get(key) is bool: return {}
	if forge.accepted and not chapter.claimed: return {}
	if forge.inspected and not forge.accepted: return {}
	if forge.cleared and not forge.inspected: return {}
	if forge.claimed and not forge.cleared: return {}
	hero.mire_chapter=hero.get("mire_chapter",{"accepted":false,"clues":{},"testament":false,"claimed":false})
	var mire=hero.mire_chapter
	if not mire is Dictionary or mire.size()!=4 or not mire.get("clues") is Dictionary or mire.clues.size()>2:return {}
	for key in ["accepted","testament","claimed"]:
		if not mire.get(key) is bool:return {}
	for id in mire.clues:
		if id not in ["mire-watch","mire-grove"] or not mire.clues[id] is bool or not mire.clues[id]:return {}
	if mire.accepted and not forge.claimed:return {}
	if not mire.accepted and (not mire.clues.is_empty() or mire.testament or mire.claimed):return {}
	if mire.testament and (mire.clues.size()!=2 or hero.opened.get("blackmire-cleared",false)!=true):return {}
	if mire.claimed and not mire.testament:return {}
	hero.journey=hero.get("journey",{})
	if not hero.journey is Dictionary: return {}
	for key in ["wood","cooked","warden","reward","dungeon_entered","first_floor","opening_reward"]: hero.journey[key]=bool(hero.journey.get(key,false))
	if hero.highestFloor>0: hero.journey.dungeon_entered=true
	if hero.floorsCleared>0: hero.journey.first_floor=true
	hero.exploration=hero.get("exploration",{})
	if not hero.exploration is Dictionary: return {}
	for key in ["visited","discovered","challenges","pending"]:
		hero.exploration[key]=hero.exploration.get(key,{})
		if not hero.exploration[key] is Dictionary or hero.exploration[key].size()>8: return {}
		for region in hero.exploration[key]:
			if region not in ["forest","caves","swamp","snow"]: return {}
			hero.exploration[key][region]=bool(hero.exploration[key][region])
	if forge.inspected and not hero.exploration.challenges.get("caves",false): return {}
	if mire.testament and not hero.exploration.challenges.get("swamp",false):return {}
	hero.exploration.visited.forest=true
	hero.exploration.discovered.forest=true
	hero.exploration.target=str(hero.exploration.get("target",""))
	if hero.exploration.target not in ["forest","caves","swamp","snow","ruins","home","trader","keep","frostspire","blackmire","stormbreak","frost-cave","highland-mine","beacon-emerald","beacon-frost","beacon-mire","beacon-storm"]: hero.exploration.target=""
	hero.respawn=hero.get("respawn",{"x":0.0,"y":0.0})
	if not hero.respawn is Dictionary: return {}
	for key in ["x","y"]:
		if not (hero.respawn.get(key) is int or hero.respawn.get(key) is float) or not is_finite(float(hero.respawn[key])): return {}
	hero.contracts=hero.get("contracts",{"active":{},"completed":0,"cooldowns":{},"target":""})
	var jobs=hero.contracts
	if not jobs is Dictionary or not jobs.get("active") is Dictionary or not jobs.get("cooldowns") is Dictionary: return {}
	if jobs.active.size()>3 or jobs.cooldowns.size()>6: return {}
	if not (jobs.get("completed") is int or jobs.get("completed") is float) or not is_finite(float(jobs.completed)) or jobs.completed<0 or jobs.completed>1000000 or floor(jobs.completed)!=jobs.completed: return {}
	jobs.completed=int(jobs.completed)
	var known_jobs=["supplies","rations","wolves","archers","survey","delve"]
	for id in jobs.cooldowns:
		var value=jobs.cooldowns[id]
		if id not in known_jobs or not (value is int or value is float) or not is_finite(float(value)) or value<0: return {}
		jobs.cooldowns[id]=minf(value,hero.worldTime+600)
	for id in jobs.active:
		if id not in known_jobs or not jobs.active[id] is Dictionary: return {}
		var entry=jobs.active[id]
		for key in ["level","progress"]:
			if not (entry.get(key) is int or entry.get(key) is float) or not is_finite(float(entry[key])) or entry[key]<0 or floor(entry[key])!=entry[key]: return {}
			entry[key]=int(entry[key])
		if entry.level<1 or entry.level>1000 or entry.progress>{"supplies":1,"rations":1,"wolves":6,"archers":4,"survey":3,"delve":2}[id]: return {}
		if not entry.get("visited") is Dictionary or entry.visited.size()>3: return {}
		for region in entry.visited:
			if region not in ["caves","swamp","snow"]: return {}
			entry.visited[region]=bool(entry.visited[region])
		if id=="survey": entry.progress=entry.visited.values().count(true)
	jobs.target=str(jobs.get("target",""))
	if jobs.target!="board" and not jobs.active.has(jobs.target): jobs.target=""
	hero.trader=hero.get("trader",{"cycle":-1,"level":1,"bought":{},"buyback":[]})
	var market=hero.trader
	if not market is Dictionary or not market.get("bought") is Dictionary or not market.get("buyback") is Array: return {}
	for key in ["cycle","level"]:
		if not (market.get(key) is int or market.get(key) is float) or not is_finite(float(market[key])) or floor(market[key])!=market[key]: return {}
		market[key]=int(market[key])
	if market.cycle< -1 or market.level<1 or market.level>1000 or market.bought.size()>13 or market.buyback.size()>8: return {}
	var limits={"wood":5,"stone":4,"fiber":4,"herbs":3,"iron":2,"rations":4,"stew":3,"tea":3,"sword":1,"bow":1,"staff":1,"armor":1,"relic":1}
	for key in market.bought:
		var value=market.bought[key]
		if not limits.has(key) or not (value is int or value is float) or not is_finite(float(value)) or value<0 or value>limits[key] or floor(value)!=value: return {}
		market.bought[key]=int(value)
	var receipt_ids=[]
	for entry in market.buyback:
		if not entry is Dictionary or not entry.get("item") is Dictionary: return {}
		var item=entry.item
		for key in ["id","kind","name"]:
			if not item.get(key) is String or item[key].length()>200: return {}
		if item.id.is_empty() or item.id in receipt_ids or not ITEM_NAMES.has(item.kind): return {}
		receipt_ids.append(item.id)
		for key in ["level","rarity","power","upgrade","enchant"]:
			if not (item.get(key) is int or item.get(key) is float) or not is_finite(float(item[key])) or item[key]<0 or floor(item[key])!=item[key]: return {}
			item[key]=int(item[key])
		if item.level<1 or item.rarity>4 or item.enchant>4: return {}
		if not (entry.get("price") is int or entry.get("price") is float) or not is_finite(float(entry.price)) or entry.price<1 or entry.price>1000000000 or floor(entry.price)!=entry.price: return {}
		entry.price=int(entry.price)
	hero.mode=hero.get("mode","classic")
	if hero.mode not in ["classic","survival"]: return {}
	hero.kit=hero.get("kit",{})
	if not hero.kit is Dictionary or hero.kit.size()>5: return {}
	for key in hero.kit:
		if key not in ["waterskin","cloak","bedroll","cloak_worn","rest_until"]: return {}
	for key in ["waterskin","cloak","bedroll","cloak_worn"]:
		hero.kit[key]=hero.kit.get(key,false)
		if not hero.kit[key] is bool: return {}
	if hero.kit.cloak_worn and not hero.kit.cloak: return {}
	hero.kit.rest_until=hero.kit.get("rest_until",0.0)
	if not (hero.kit.rest_until is int or hero.kit.rest_until is float) or not is_finite(float(hero.kit.rest_until)) or hero.kit.rest_until<0 or hero.kit.rest_until>hero.worldTime+120.01: return {}
	if not hero.kit.bedroll and hero.kit.rest_until>0: return {}
	hero.needs=hero.get("needs",{})
	if not hero.needs is Dictionary: return {}
	for key in ["hunger","water","sleep","temperature","elapsed","flask","wetness"]:
		var default_value=50.0 if key=="temperature" else 0.0 if key in ["elapsed","wetness"] else 3 if key=="flask" else 100.0
		var value=hero.needs.get(key,default_value)
		if not (value is int or value is float) or not is_finite(float(value)) or value<0: return {}
		if key=="flask" and (value>(6 if hero.kit.waterskin else 3) or floor(value)!=value): return {}
		if key not in ["elapsed","flask"] and value>100: return {}
		hero.needs[key]=int(value) if key=="flask" else float(value)
	for key in ["harvested","ruins","won"]:
		hero.needs[key]=hero.needs.get(key,false)
		if not hero.needs[key] is bool: return {}
	hero.spells=hero.get("spells",{"known":{"fire":1,"frost":1,"heal":1},"slots":["fire","frost","heal"]})
	if not hero.spells is Dictionary or not hero.spells.get("known") is Dictionary or not hero.spells.get("slots") is Array: return {}
	if hero.spells.slots.size()!=3 or hero.spells.known.size()>13: return {}
	for id in hero.spells.known:
		if id not in ["fire","frost","heal","arc","lance","ward","meteor","sunburst","blizzard","briarheart","wintercrown","mireward","stormlance"]: return {}
		var value=hero.spells.known[id]
		if not (value is int or value is float) or not is_finite(float(value)) or value<1 or value>3 or floor(value)!=value: return {}
		hero.spells.known[id]=int(value)
	for id in ["fire","frost","heal"]: hero.spells.known[id]=1
	for castle_id in ["thornwatch","frostspire","blackmire","stormbreak"]:
		if hero.opened.get(castle_id+"-relic",false)==true:hero.spells.known[{"thornwatch":"briarheart","frostspire":"wintercrown","blackmire":"mireward","stormbreak":"stormlance"}[castle_id]]=1
	var unique=[]
	for id in hero.spells.slots:
		if not id is String or not hero.spells.known.has(id) or id in unique: return {}
		unique.append(id)
	hero.angler=hero.get("angler",{"rod":false,"records":{},"rewarded":false,"target":""})
	var angler=hero.angler
	if not angler is Dictionary or angler.size()>4 or not angler.get("rod") is bool or not angler.get("rewarded") is bool or not angler.get("records") is Dictionary: return {}
	for key in angler:
		if key not in ["rod","records","rewarded","target"]: return {}
	if not angler.get("target","") is String or angler.get("target","") not in ["","forest","swamp","snow"] or angler.records.size()>4: return {}
	angler.target=angler.get("target","")
	for key in angler.records:
		var value=angler.records[key]
		if key not in ["Silver trout","Marsh eel","Frost salmon","Starfin"] or not (value is int or value is float) or not is_finite(float(value)) or value<0 or value>1000000 or floor(value)!=value: return {}
		angler.records[key]=int(value)
	if angler.rewarded and ["Silver trout","Marsh eel","Frost salmon"].any(func(name):return int(angler.records.get(name,0))<1): return {}
	hero.engine = "godot"
	return hero

static func equipped(hero: Dictionary, slot: String) -> Dictionary:
	for item in hero.inventory:
		if item.id == hero.equipped.get(slot):
			return item
	return {}

static func power(hero: Dictionary, slot: String) -> float:
	return float(equipped(hero,slot).get("power",0))

static func has_building(hero: Dictionary, name_value: String) -> bool:
	return name_value in hero.kingdom.buildings

static func max_hp(hero: Dictionary) -> int:
	return int(100+hero.level*8+hero.vit*12+(35 if hero.className=="Warrior" else 0)+power(hero,"armor")+floor(power(hero,"helmet")*.6))

static func max_mp(hero: Dictionary) -> int:
	return int(60+hero.level*3+hero.int*5+(40 if hero.className=="Mage" else 0)+power(hero,"ring")*2)

static func damage(hero: Dictionary, kind: String) -> float:
	var weapon = equipped(hero,"weapon")
	var amount = weapon.get("power",6)+hero.level*1.7+power(hero,"charm")*.45+power(hero,"ring")*.6
	amount += hero.int*2.8 if kind=="magic" else hero.dex*2.8 if kind=="bow" else hero.str*2.8
	if (kind=="melee" and hero.className in ["Warrior","Spellblade"]) or (kind=="magic" and hero.className in ["Mage","Spellblade"]):
		amount *= 1.35
	if kind=="bow" and hero.className in ["Ranger","Arcane Archer"]:
		amount *= 1.4
	return amount*(1.1 if has_building(hero,"Blacksmith") else 1.0)

static func needed_xp(hero: Dictionary) -> int:
	return int(35*pow(hero.level,1.3))

static func upgrade_cost(hero: Dictionary,item: Dictionary) -> int:
	return maxi(1,int((18*(item.upgrade+1)+item.level*6)*(.8 if has_building(hero,"Blacksmith") else 1.0)))

static func roll_loot(level_value: int, boss: bool=false) -> Dictionary:
	var chance = randf()*100.0
	var rarity = 0 if chance<60 else 1 if chance<85 else 2 if chance<95 else 3 if chance<99 else 4
	if boss:
		rarity = maxi(rarity,2)
	var kind = ITEM_NAMES.keys().pick_random()
	var base = 18+level_value*3 if kind=="armor" else 3+level_value if kind in ["charm","ring"] else 5+level_value*2
	serial += 1
	return {"id":"item-%d-%d" % [Time.get_ticks_usec(),serial], "kind":kind,"name":ITEM_NAMES[kind].pick_random(),"level":level_value,"rarity":rarity,"power":int(base*RARITIES[rarity].mult*randf_range(.9,1.1)),"upgrade":0,"enchant":randi_range(1,4) if kind in ["sword","bow","staff"] and randf()<.16+rarity*.16 else 0}

static func phase(tick: float) -> String:
	var t = fposmod(tick,600.0)/600.0
	return "Day" if t<.6 else "Dusk" if t<.7 else "Night" if t<.95 else "Dawn"

static func spawn_chance(phase_value: String) -> float:
	return {"Day":.05,"Dusk":.1,"Night":.25,"Dawn":.08}[phase_value]

static func title(renown: int) -> String:
	return TITLES[mini(7,int(renown/100.0))]

static func scaled_enemy(floor_value: int,boss: bool=false) -> Dictionary:
	var mult = 4 if boss else 1
	return {"hp":floor(exp(minf(log(20.0)+floor_value*log(1.15),log(1e12/mult))))*mult,"dmg":floor(exp(minf(log(3.0)+floor_value*log(1.12),log(1e9/(2 if boss else 1)))))*(2 if boss else 1),"gold":mini(1000000000,(5+floor_value*3)*mult)}

static func make_dungeon(seed_value: int,size_value: int=21,steps: int=280) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	var grid: Array = []
	for y in range(size_value):
		var row: Array = []
		row.resize(size_value)
		row.fill(false)
		grid.append(row)
	var start = Vector2i(size_value/2,size_value/2)
	var cell = start
	var dirs = [Vector2i.RIGHT,Vector2i.LEFT,Vector2i.UP,Vector2i.DOWN]
	for step in range(steps):
		grid[cell.y][cell.x] = true
		if step%55==0:
			for dx in range(-1,2):
				for dy in range(-1,2):
					var cx = clampi(cell.x+dx,1,size_value-2)
					var cy = clampi(cell.y+dy,1,size_value-2)
					grid[cy][cx] = true
		cell += dirs[rng.randi_range(0,3)]
		cell.x = clampi(cell.x,1,size_value-2)
		cell.y = clampi(cell.y,1,size_value-2)
	var queue: Array = [start]
	var seen = {start:0}
	var last = start
	var index = 0
	while index<queue.size():
		var c: Vector2i = queue[index]
		index += 1
		last = c
		for dir in dirs:
			var n: Vector2i = c+dir
			if n.x>=0 and n.y>=0 and n.x<size_value and n.y<size_value and grid[n.y][n.x] and not seen.has(n):
				seen[n] = seen[c]+1
				queue.append(n)
	return {"grid":grid,"start":start,"exit":last,"floors":queue,"size":size_value}

static func write_save(hero: Dictionary,path: String=SAVE_PATH) -> bool:
	# Write to a temporary file first; retain the previous save on write failure.
	var file = FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:
		return false
	file.store_string(JSON.stringify(hero))
	file.flush()
	var error = file.get_error()
	file.close()
	if error!=OK:
		return false
	# Never replace a good recovery copy with an unreadable primary after recovery.
	if not read_candidate(path).is_empty():
		if DirAccess.copy_absolute(path,path+".bak.tmp")!=OK:
			return false
		if DirAccess.rename_absolute(path+".bak.tmp",path+".bak")!=OK:
			return false
	return DirAccess.rename_absolute(path+".tmp",path)==OK

static func read_candidate(path:String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var parser=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK: return {}
	return migrate(parser.data) if parser.data is Dictionary else {}

static func read_save(path: String=SAVE_PATH) -> Dictionary:
	for candidate in [path,path+".bak"]:
		var converted=read_candidate(candidate)
		if not converted.is_empty(): return converted
	return {}
