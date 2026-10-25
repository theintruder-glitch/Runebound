extends RefCounted
const Data=preload("res://scripts/data.gd")
const Catalog=preload("res://scripts/realm_catalog.gd")
const RUINS=Vector2(520,320)
const REGIONS={
 "forest":{"name":"Emerald Wilds · Mossveil","point":Vector2(760,-520),"landmark":"Elder Shrine","material":"Resin","class":"Arcane Archer"},
 "caves":{"name":"Shattered Highlands · Hollowdeep","point":Vector2(2050,0),"landmark":"Emberforge","material":"Crystal","class":"Spellblade"},
 "swamp":{"name":"Drowned Mire · Whisperfen","point":Vector2(-2050,0),"landmark":"Veil Altar","material":"Glowcap","class":"Reaper"},
 "snow":{"name":"Frostbound Peaks · Frostfall","point":Vector2(0,-2050),"landmark":"Winter Oath","material":"Frost shard","class":"Arcane Archer"}
}
var game
var trial=""
var foes:Array=[]
var hits:Dictionary={}
var dodged=false
func data() -> Dictionary: return game.hero.exploration
static func region_at(pos:Vector2) -> String:
 if pos.y< -1400: return "snow"
 if pos.x>1400: return "caves"
 if pos.x< -1400: return "swamp"
 return "forest"
static func cave_wall(pos:Vector2) -> bool:
 if Catalog.zone_at(pos)=="stormbreak" and Catalog.distance_to_trail(pos,Catalog.ZONES.stormbreak.trail)<74:return false
 if region_at(pos)!="caves" or absf(pos.y)<95 or pos.distance_to(REGIONS.caves.point)<220: return false
 var cell=Vector2i(floori(pos.x/48),floori(pos.y/48))
 return (posmod(cell.x,10)==0 and posmod(cell.y,10)>2) or (posmod(cell.y,10)==0 and posmod(cell.x,10)>2)
static func outdoor_highlands(pos:Vector2) -> bool:return Catalog.zone_at(pos)=="stormbreak" and pos.distance_to(REGIONS.caves.point)>340
static func terrain_id(pos:Vector2) -> int:
 match region_at(pos):
  "caves": return 7 if cave_wall(pos) else 4
  "swamp": return 8 if sin(pos.x*.011)*cos(pos.y*.013)>.35 else 3
  "snow": return 5 if sin(pos.x*.01+pos.y*.02)>0 else 9
 if Geometry2D.get_closest_point_to_segment(pos,Vector2.ZERO,RUINS).distance_to(pos)<20: return 11
 var value=sin(floor(pos.x/48)*127.1+floor(pos.y/48)*311.7)*43758.5453123
 return int((value-floor(value))*3)
func active() -> bool:
 return not trial.is_empty() and foes.any(func(e):return not e.dead and game.enemies.has(e))
func tick(_dt:float) -> void:
 if active() and (game.hero.dungeon!=null or game.player_position().distance_to(REGIONS[trial].point)>550):
  for enemy in foes: game.enemies.erase(enemy)
  trial=""; foes.clear(); hits.clear(); dodged=false
  game.notify("Trial abandoned. Return to the landmark to try again.",4)
 if game.hero.dungeon!=null: return
 var region=region_at(game.player_position())
 if not data().visited.get(region,false):
  data().visited[region]=true
  game.notify("DISCOVERED: "+REGIONS[region].name+" · Track its landmark from Camp.",5)
  game.sound("reward"); game.save_game()
func bearing(to:Vector2) -> String:
 var offset=to-game.player_position()
 var dir="E" if offset.x>=0 else "W"
 if absf(offset.x)<absf(offset.y)*.45: dir=""
 if absf(offset.y)>absf(offset.x)*.45: dir=("N" if offset.y<0 else "S")+dir
 return "%s · %dm" % [dir,int(offset.length()/10)]
func objective() -> String:
 var target=data().get("target","")
 if target=="trader": return "Mara · Leave dungeon via entrance stairs" if game.hero.dungeon!=null else "Trader Mara · "+bearing(game.trader.POSITION)
 if target=="ruins": return "Mossveil Ruins · "+bearing(RUINS)
 if Catalog.ZONES.has(target):return Catalog.ZONES[target].castle+" · "+bearing(Catalog.ZONES[target].gate)
 if target=="keep":return "Thornwatch Keep · "+bearing(game.landscape.KEEP)
 if target=="home": return "Home · "+bearing(Vector2(game.hero.respawn.x,game.hero.respawn.y))
 if not REGIONS.has(target): return "Explore · Track a regional landmark from Camp"
 return REGIONS[target].landmark+" · "+bearing(REGIONS[target].point)
func track(id:String) -> void:
 if id not in ["forest","caves","swamp","snow","ruins","home","trader","keep","frostspire","blackmire","stormbreak"]: return
 data().target=id;game.hero.contracts.target="";game.hero.angler.target=""
 game.save_game();game.hud.resume()
func nearby() -> String:
 if game.hero.dungeon!=null: return ""
 for id in ["caves","swamp","snow"]:
  if game.player_position().distance_to(REGIONS[id].point)<80: return id
 return ""
func interaction() -> String:
 var id=nearby()
 if id.is_empty() or active() or game.forge.active(): return ""
 if not data().discovered.get(id,false): return "DISCOVER "+REGIONS[id].landmark.to_upper()
 if data().pending.get(id,false): return "CLAIM TRIAL RELIC"
 if data().challenges.get(id,false): return REGIONS[id].landmark.to_upper()+" · COMPLETED"
 return "TRIAL: "+REGIONS[id]["class"].to_upper()
func instructions(id:String) -> String:
 match id:
  "caves": return "Strike the Forge Sentinel with a sword AND magic before defeating it. Unlocks Spellblade."
  "swamp": return "Defeat three Veil Shades and use DASH during the encounter. Unlocks Reaper."
  "snow": return "Defeat the Winter Sentinel after landing a bow hit and using DASH. Unlocks Arcane Archer."
 return "Defeat the Root Warden at the Elder Shrine."
func interact() -> void:
 var id=nearby()
 if id.is_empty() or game.forge.active(): return
 if not data().discovered.get(id,false):
  data().discovered[id]=true
  game.hero.gold+=30; game.hero.essence+=2
  game.notify("Landmark discovered · +30 gold, +2 essence · Regional recipes unlocked. "+instructions(id),7)
  game.survival.revision+=1; game.sound("reward"); game.save_game(); return
 if data().pending.get(id,false): claim(id); return
 if data().challenges.get(id,false) or active(): return
 begin_trial(id)
func begin_trial(id:String) -> void:
 if game.forge.active(): return
 trial=id; foes.clear(); hits.clear(); dodged=false
 var center=REGIONS[id].point
 for i in range(3 if id=="swamp" else 1):
  var pos=center+Vector2.from_angle(-PI/2+i*TAU/3)*100
  var kind="wisp" if id=="swamp" else "ice_archer" if id=="snow" else "guardian"
  var enemy=game.create_enemy(pos,maxi(2,game.hero.level),kind,true)
  enemy["named"]="Veil Shade" if id=="swamp" else "Winter Sentinel" if id=="snow" else "Forge Sentinel"
  enemy.hp=float(80+game.hero.level*16) if id=="swamp" else float(240+game.hero.level*35)
  enemy.max_hp=enemy.hp; enemy.contact_damage=9+game.hero.level if id=="swamp" else 15+game.hero.level*2
  enemy.home=center; enemy.aggro=60; enemy.cooldown=i*.35
  enemy["trial"]=id
  foes.append(enemy); game.enemies.append(enemy)
 game.notify(instructions(id),7); game.sound("spell")
func on_hit(enemy:Dictionary,kind:String) -> void:
 if active() and foes.has(enemy): hits[kind]=true
func on_kill(enemy:Dictionary) -> void:
 if trial.is_empty() or not foes.has(enemy) or foes.any(func(e):return not e.dead): return
 var success=(hits.get("melee",false) and hits.get("magic",false)) if trial=="caves" else dodged and (trial=="swamp" or hits.get("bow",false))
 if not success:
  game.notify("Trial incomplete · "+instructions(trial)+" Return to try again.",7)
  trial=""; return
 var id=trial; trial=""
 data().challenges[id]=true; data().pending[id]=true
 var unlocked=REGIONS[id]["class"]
 if not unlocked in game.hero.unlocked: game.hero.unlocked.append(unlocked)
 game.hero.gold+=70; game.hero.essence+=4
 game.notify("TRIAL COMPLETE · "+unlocked+" unlocked! Claim your relic at the landmark.",7)
 game.sound("reward"); game.save_game()
func claim(id:String) -> bool:
 if not data().pending.get(id,false): return false
 if game.hero.inventory.size()>=40: game.notify("Make room in Gear before claiming the relic.",3); return false
 var kind="sword" if id=="caves" else "staff" if id=="swamp" else "bow"
 game.hero.inventory.append({"id":"region-relic-"+id,"kind":kind,"name":{"caves":"Emberforge Oath","swamp":"Veilkeeper Staff","snow":"Winter's Promise"}[id],"level":game.hero.level,"rarity":3,"power":int((10+game.hero.level*3)*3),"upgrade":0,"enchant":1 if id=="caves" else 4 if id=="swamp" else 2})
 data().pending[id]=false; game.notify("Epic regional relic added to Gear.",4); game.sound("reward"); game.save_game(); return true
func spawn_kind(region:String) -> String:
 var types={"forest":["wolf","wolf","archer","slime","deer"],"caves":["crystal_wisp","skeleton","goblin"],"swamp":["bog_toad","wisp","archer","deer"],"snow":["frost_wolf","ice_archer","frost_wolf","deer"]}
 return types[region].pick_random()
func pack_alert(enemy:Dictionary) -> void:
 if int(enemy.get("pack",0))==0: return
 for ally in game.enemies:
  if ally.get("pack",-1)==enemy.pack and not ally.dead: ally.aggro=maxf(ally.aggro,4)
 if not enemy.get("howled",false): enemy.howled=true; game.sound("howl")
