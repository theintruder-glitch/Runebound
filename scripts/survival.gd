extends RefCounted
const Data=preload("res://scripts/data.gd")
const STRUCTURES=["Campfire","Shelter","Workbench","Wall","Door","Bed","Storage","Roof","Garden"]
var moving:Dictionary={}
const FOODS={"Grilled fish":{"hp":55,"mp":0},"Fisher stew":{"hp":80,"mp":15},"Warm tea":{"hp":15,"mp":15},"Roasted berries":{"hp":35,"mp":0},"Herbal stew":{"hp":70,"mp":25},"Roasted meat":{"hp":50,"mp":0},"Bog remedy":{"hp":35,"mp":50},"Trail stew":{"hp":85,"mp":15}}
const MATERIALS=["Raw fish","Grilled fish","Fisher stew","Warm tea","Wood","Stone","Fiber","Berries","Herbs","Iron","Plank","Rope","Roasted berries","Herbal stew","Resin","Crystal","Glowcap","Reeds","Frost shard","Pine resin","Raw meat","Hide","Roasted meat","Bog remedy","Trail stew"]
const RECIPES={
 "Grilled fish":{"cost":{"Raw fish":1,"Herbs":1},"station":"fire","desc":"Restores 55 health. In Survival, restores 35 food. Use a reachable lit campfire."},
 "Fisher stew":{"cost":{"Raw fish":2,"Herbs":2,"Berries":1},"station":"fire","desc":"Restores 80 health and 15 mana. In Survival, restores 55 food and 18 water. Use a reachable lit campfire."},
 "Garden":{"cost":{"Wood":4,"Stone":2,"Fiber":2},"station":"","desc":"An outdoor garden plot. Plant carried berries, herbs or discovered glowcaps. Up to 12 plots; walk over them freely."},
 "Warm tea":{"cost":{"Herbs":2,"Berries":1},"station":"fire","desc":"Restores 15 health and mana, then +1 mana/sec outside combat for 3 minutes. Refreshes rather than stacks."},
 "Resin blade":{"cost":{"Resin":4,"Iron":4},"station":"bench","kind":"sword","enchant":1,"discovery":"forest","desc":"A Rare Ember-enchanted sword using forest resin."},
 "Crystal staff":{"cost":{"Crystal":6,"Plank":2},"station":"bench","kind":"staff","enchant":3,"discovery":"caves","desc":"A Rare Storm staff. Discover Emberforge to learn this recipe."},
 "Bog remedy":{"cost":{"Glowcap":3,"Herbs":2},"station":"fire","discovery":"swamp","desc":"Restores 35 health and 50 mana. Discover the Veil Altar."},
 "Frost bow":{"cost":{"Frost shard":6,"Pine resin":2,"Rope":2},"station":"bench","kind":"bow","enchant":2,"discovery":"snow","desc":"A Rare Frost bow. Discover Winter Oath to learn this recipe."},
 "Leather vest":{"cost":{"Hide":4,"Fiber":4},"station":"bench","kind":"armor","desc":"A Rare armor piece made from hunted wildlife hides."},
 "Roasted meat":{"cost":{"Raw meat":2},"station":"fire","desc":"Restores 50 health."},
 "Trail stew":{"cost":{"Raw meat":2,"Glowcap":1,"Herbs":1},"station":"fire","discovery":"swamp","desc":"Restores 85 health and 15 mana."},
 "Wall":{"cost":{"Plank":2},"station":"","desc":"Solid 64-unit wall. Rotate the ghost to change direction."},
 "Door":{"cost":{"Plank":2,"Rope":1},"station":"","desc":"A gate you can open and close. Blocks movement and attacks when closed."},
 "Bed":{"cost":{"Plank":3,"Fiber":6},"station":"","desc":"Rest near it to recover and set your return point after defeat."},
 "Storage":{"cost":{"Plank":4},"station":"","desc":"A persistent materials chest. Deposit or withdraw materials nearby."},
 "Roof":{"cost":{"Plank":3,"Fiber":3},"station":"","desc":"A canopy that keeps rain and snow off you. Combine with a lit fire for bonus recovery. Does not block walking."},
 "Plank":{"cost":{"Wood":2},"station":"","desc":"Building material."},
 "Reed rope":{"cost":{"Reeds":3},"station":"","product":"Rope","desc":"Weave swamp reeds into usable rope."},
 "Rope":{"cost":{"Fiber":3},"station":"","desc":"Bindings for shelters and bows."},
 "Campfire":{"cost":{"Wood":6,"Stone":4},"station":"","desc":"A cooking fire. Starts with 90 seconds of fuel."},
 "Shelter":{"cost":{"Plank":6,"Rope":2},"station":"","desc":"Stand inside its marked circle to rest safely and recover health."},
 "Workbench":{"cost":{"Wood":8,"Stone":6},"station":"","desc":"Stand near the bench to craft weapons."},
 "Roasted berries":{"cost":{"Berries":3},"station":"fire","desc":"Eat to restore 35 health."},
 "Herbal stew":{"cost":{"Berries":2,"Herbs":2},"station":"fire","desc":"Eat to restore 70 health and 25 mana."},
 "Crafted bow":{"cost":{"Plank":3,"Rope":2},"station":"bench","desc":"A Rare bow scaled to your level; added to Gear."},
 "Iron sword":{"cost":{"Iron":4,"Wood":2},"station":"bench","desc":"A Rare sword scaled to your level; added to Gear."}
}
const PICKUP_INTERVAL=0.2
var auto_pickup=true
var pickup_timer=0.0
var game
var nodes:Array=[]
var region=Vector2i(999999,999999)
var refresh_timer=0.0
var gather_cooldown=0.0
var revision=0
func data() -> Dictionary: return game.hero.survival
func at(s:Dictionary) -> Vector2: return Vector2(s.x,s.y)
func count(name:String) -> int: return int(data().materials.get(name,0))
func add(name:String,amount:int) -> void: data().materials[name]=clampi(count(name)+amount,0,99999)
func near(kind:String,radius:float=100) -> Dictionary:
 if game.hero.dungeon!=null: return {}
 var best:Dictionary={}
 for s in data().structures:
  var distance=at(s).distance_to(game.player_position())
  if s.kind==kind and distance<radius:
   best=s; radius=distance
 return best
func sheltered() -> bool: return not near("Shelter",60).is_empty()
func refresh(force:bool=false) -> void:
 var center=Vector2i(floori(game.hero.x/160),floori(game.hero.y/160))
 if not force and center==region: return
 region=center
 nodes.clear()
 if game.hero.dungeon!=null: return
 for x in range(center.x-6,center.x+7):
  for y in range(center.y-6,center.y+7):
   var id=str(x)+":"+str(y)
   if float(data().harvested.get(id,0))>game.hero.worldTime: continue
   var kind=["Wood","Stone","Fiber","Berries","Herbs","Iron"][posmod(x*3+y*5,6)]
   var pos=Vector2(x*160+70+sin(x*13+y*7)*30,y*160+70+cos(x*9-y*11)*30)
   var region_id=game.exploration.region_at(pos)
   if game.exploration.cave_wall(pos): continue
   var index=posmod(x*3+y*5,6)
   if region_id=="caves": kind=["Stone","Iron","Crystal","Crystal","Iron","Stone"][index]
   elif region_id=="swamp": kind=["Wood","Reeds","Fiber","Glowcap","Herbs","Berries"][index]
   elif region_id=="snow": kind=["Wood","Stone","Frost shard","Pine resin","Fiber","Frost shard"][index]
   elif index==5: kind="Resin"
   nodes.append({"id":id,"kind":kind,"pos":pos})
 revision+=1
func load_pickup_settings() -> void:
 var config=ConfigFile.new()
 auto_pickup=true
 if config.load("user://pickup.cfg")==OK:
  auto_pickup=bool(config.get_value("gameplay","auto_pickup",true))
func set_auto_pickup(enabled:bool) -> void:
 auto_pickup=enabled
 pickup_timer=0.0
 var config=ConfigFile.new()
 config.set_value("gameplay","auto_pickup",enabled)
 config.save("user://pickup.cfg")
func pickup_tick(dt:float) -> void:
 if not game.playing or game.hero.is_empty() or game.hero.hp<=0 or not auto_pickup or not game.build_recipe.is_empty() or game.hero.dungeon!=null: return
 pickup_timer=maxf(0,pickup_timer-dt)
 if pickup_timer>0 or gather_cooldown>0: return
 pickup_timer=PICKUP_INTERVAL
 gather(true)
func gather_amount(kind:String) -> int:
 return {"Wood":6,"Stone":4,"Fiber":3,"Berries":4,"Herbs":2,"Iron":2,"Resin":3,"Crystal":3,"Glowcap":3,"Reeds":4,"Frost shard":3,"Pine resin":2}[kind]+game.weather.gather_bonus(kind)
func nearest_node(available_only:bool=false) -> Dictionary:
 if game.hero.dungeon!=null: return {}
 refresh()
 var best:Dictionary={}; var radius=65.0
 for n in nodes:
  if available_only and count(n.kind)+gather_amount(n.kind)>99999: continue
  var distance=n.pos.distance_to(game.player_position())
  if distance<radius and game.line_clear(game.player_position(),n.pos): best=n; radius=distance
 return best
func gather(automatic:bool=false) -> bool:
 var n=nearest_node(automatic)
 if n.is_empty() or gather_cooldown>0: return false
 var amount=gather_amount(n.kind)
 if count(n.kind)+amount>99999:
  if not automatic: game.notify("Make room for "+n.kind+" before gathering.",2)
  return false
 add(n.kind,amount)
 if n.kind=="Wood": game.hero.journey.wood=true
 game.sound("gather")
 data().harvested[n.id]=game.hero.worldTime+180
 gather_cooldown=.5
 game.notify("Gathered +%d %s" % [amount,n.kind],2)
 refresh(true); game.save_game()
 return true
func tick(dt:float) -> void:
 gather_cooldown=maxf(0,gather_cooldown-dt)
 for s in data().structures:
  if s.kind=="Campfire":
   var was_lit=s.fuel>0
   s.fuel=maxf(0,s.fuel-dt)
   if was_lit and s.fuel==0: revision+=1
 if sheltered() and not game.expedition.deprived(): game.hero.hp=minf(Data.max_hp(game.hero),game.hero.hp+dt*6)
 refresh_timer-=dt
 if refresh_timer<=0:
  refresh_timer=1
  for id in data().harvested.keys():
   if data().harvested[id]<=game.hero.worldTime: data().harvested.erase(id)
  refresh(true)
func cost_text(recipe:String) -> String:
 var parts=PackedStringArray()
 for k in RECIPES[recipe].cost: parts.append("%d %s (%d owned)" % [RECIPES[recipe].cost[k],k,count(k)])
 return ", ".join(parts)
func reason(recipe:String,check_place:bool=true) -> String:
 if not RECIPES.has(recipe): return "Unknown recipe"
 var r=RECIPES[recipe]
 if recipe not in STRUCTURES and r.station!="bench" and count(r.get("product",recipe))>=99999: return "Make room in your carried supplies"
 if r.has("discovery") and not game.hero.exploration.discovered.get(r.discovery,false): return "Discover "+game.exploration.REGIONS[r.discovery].landmark+" to learn this recipe"
 if r.station=="fire":
  var fire=near("Campfire")
  if fire.is_empty() or fire.fuel<=0: return "Stand near a lit campfire"
  if recipe in ["Grilled fish","Fisher stew"] and not game.line_clear(game.player_position(),at(fire)): return "Reach the campfire without a wall in the way"
 if r.station=="bench" and near("Workbench").is_empty(): return "Stand near a workbench"
 if recipe in STRUCTURES:
  if game.hero.dungeon!=null: return "Build in the wilds"
  if data().structures.size()>=64 and moving.is_empty(): return "Camp limit reached (64 structures)"
  if recipe=="Garden":
   if moving.is_empty() and game.farming.plots().size()>=game.farming.MAX_PLOTS: return "Garden limit reached (12 plots)"
   if game.exploration.region_at(place_position())=="caves": return "Garden plots need outdoor ground"
  if check_place:
   var pos=place_position()
   for spot in game.fishing.SPOTS.values():
    if footprint(recipe,pos,game.build_rotation).grow(12).intersects(Rect2(spot.pond-Vector2(85,85),Vector2(170,170))): return "Keep fishing pools and their banks clear"
   if footprint(recipe,pos,game.build_rotation).grow(25).has_point(game.trader.POSITION): return "Keep Mara's trading stall approachable"
   if footprint(recipe,pos,game.build_rotation).grow(25).has_point(game.contracts.BOARD): return "Keep the quest board approachable"
   for region_info in game.exploration.REGIONS.values():
    if pos.distance_to(region_info.point)<240: return "Keep landmark clearings open"
   if pos.distance_to(game.exploration.RUINS)<100: return "Keep the ruins entrance open"
   for corner in [pos,footprint(recipe,pos,game.build_rotation).position,footprint(recipe,pos,game.build_rotation).end]:
    if game.exploration.cave_wall(corner): return "Build on open cave floor"
   var candidate=footprint(recipe,pos,game.build_rotation)
   if recipe in ["Wall","Door"] and candidate.grow(12).has_point(game.player_position()): return "Move clear of the building ghost"
   if recipe in ["Wall","Door"] and candidate.grow(12).has_point(Vector2(game.hero.respawn.x,game.hero.respawn.y)): return "Leave your return point clear"
   for item in data().structures:
    if is_same(item,moving): continue
    if (recipe=="Roof") != (item.kind=="Roof"): continue
    if candidate.grow(-1).intersects(footprint(item.kind,at(item),int(item.get("rotation",0)))): return "That space is occupied"
   for enemy in game.enemies:
    if not enemy.dead and enemy.pos.distance_to(game.player_position())<180: return "Move away from enemies before building"
 if r.station=="bench" and game.hero.inventory.size()>=40: return "Make room in Gear"
 for k in r.cost:
  if moving.is_empty() and count(k)<r.cost[k]: return "Gather more materials"
 return ""
func craft(recipe:String) -> bool:
 var why=reason(recipe)
 if not why.is_empty(): game.notify(why,3); return false
 if moving.is_empty():
  for k in RECIPES[recipe].cost: add(k,-RECIPES[recipe].cost[k])
 if recipe in STRUCTURES:
  var pos=place_position()
  if not moving.is_empty():
   if moving.kind=="Bed": game.hero.respawn={"x":0.0,"y":0.0}
   moving.x=pos.x; moving.y=pos.y; moving.rotation=game.build_rotation
   moving={}
  else:
   data().structures.append({"kind":recipe,"x":pos.x,"y":pos.y,"fuel":90.0 if recipe=="Campfire" else 0.0,"rotation":game.build_rotation,"open":false,"stash":{}})
   if recipe=="Garden":
    data().structures.back().crop="";data().structures.back().growth=0.0
  revision+=1
 elif RECIPES[recipe].station=="bench":
  var kind=RECIPES[recipe].get("kind","bow" if recipe=="Crafted bow" else "sword")
  game.hero.inventory.append({"id":"crafted-"+str(Time.get_ticks_usec())+"-"+str(randi()),"kind":kind,"name":recipe,"level":game.hero.level,"rarity":2,"power":int((18+game.hero.level*3)*2) if kind=="armor" else int((5+game.hero.level*2)*2),"upgrade":0,"enchant":int(RECIPES[recipe].get("enchant",0))})
 else: add(RECIPES[recipe].get("product",recipe),1)
 if recipe in FOODS: game.hero.journey.cooked=true
 game.sound("build" if recipe in STRUCTURES else "cook" if recipe in FOODS else "gather")
 game.notify("Made "+recipe,3); game.save_game()
 return true
func fuel_fire() -> bool:
 var fire=near("Campfire")
 if fire.is_empty() or count("Wood")<1 or fire.fuel>510: return false
 add("Wood",-1); fire.fuel+=90; revision+=1; game.save_game()
 return true
func eat(food:String) -> bool:
 if not FOODS.has(food) or count(food)<1: return false
 add(food,-1)
 game.hero.hp=minf(Data.max_hp(game.hero),game.hero.hp+FOODS[food].hp)
 game.hero.mp=minf(Data.max_mp(game.hero),game.hero.mp+FOODS[food].mp)
 if food=="Warm tea": game.hero.warmUntil=game.hero.worldTime+180
 game.expedition.on_food(food)
 game.save_game(); game.hud.update_hud()
 return true
func enemy_direction(e:Dictionary,dt:float) -> Vector2:
 var pos=game.player_position()
 var distance=e.pos.distance_to(pos)
 if not e.has("home"): e.home=e.pos
 if not e.has("returning"): e.returning=false
 if e.get("neutral",false):
  if distance<240: return -e.pos.direction_to(pos)*1.1
  return e.pos.direction_to(e.home)*.3 if e.pos.distance_to(e.home)>100 else Vector2.ZERO
 if e.type in ["wolf","frost_wolf"] and distance<175 and game.line_clear(e.pos,pos): game.exploration.pack_alert(e)
 if sheltered() or game.abilities.stealth>0 or distance>300 or e.pos.distance_to(e.home)>420:
  e.aggro=0; e.returning=true
 if e.returning:
  if e.pos.distance_to(e.home)>20: return e.pos.direction_to(e.home)
  e.returning=false
  return Vector2.ZERO
 var detection=110 if e.type=="slime" else 160
 if (distance<detection and game.line_clear(e.pos,pos)) or e.aggro>0:
  e.aggro=maxf(e.aggro,1)
  if e.type in ["wolf","frost_wolf"]:
   var flank=pos+Vector2.from_angle(float(e.get("pack_slot",0))*TAU/3)*34
   return e.pos.direction_to(flank) if distance>60 else e.pos.direction_to(pos)
  if e.type in ["wisp","skeleton","crystal_wisp","archer","ice_archer"]:
   if distance<110: return -e.pos.direction_to(pos)*.7
   if distance<190: return Vector2.ZERO
  return e.pos.direction_to(pos)
 e.wander_time-=dt
 if e.wander_time<=0:
  e.wander=randf()*TAU; e.wander_time=randf_range(2,5)
 return e.pos.direction_to(e.home)*.3 if e.pos.distance_to(e.home)>100 else Vector2.from_angle(e.wander)*.25

func place_position() -> Vector2:
 return (game.player_position()+game.facing.normalized()*96).snapped(Vector2(32,32))
func footprint(kind:String,pos:Vector2,rotation:int=0) -> Rect2:
 var size=Vector2(64,64)
 if kind in ["Wall","Door"]: size=Vector2(64,16) if rotation%2==0 else Vector2(16,64)
 elif kind=="Shelter": size=Vector2(96,96)
 elif kind=="Bed": size=Vector2(40,64) if rotation%2==0 else Vector2(64,40)
 return Rect2(pos-size/2,size)
func blocked(pos:Vector2,radius:float) -> bool:
 for s in data().structures:
  if s.kind not in ["Wall","Door"] or (s.kind=="Door" and s.get("open",false)): continue
  if footprint(s.kind,at(s),int(s.get("rotation",0))).grow(radius).has_point(pos): return true
 return false
func toggle_door(door:Dictionary) -> bool:
 if door.open and footprint("Door",at(door),door.rotation).grow(12).has_point(game.player_position()):
  game.notify("Step clear before closing the door.",2); return false
 door.open=not door.open; revision+=1; game.sound("build"); game.save_game()
 return true
func nearest_structure() -> Dictionary:
 if game.hero.dungeon!=null: return {}
 var result:Dictionary={}; var distance=110.0
 for s in data().structures:
  if at(s).distance_to(game.player_position())<distance:
   distance=at(s).distance_to(game.player_position()); result=s
 return result
func dismantle(s:Dictionary) -> bool:
 if not data().structures.has(s) or at(s).distance_to(game.player_position())>110: return false
 if s.kind=="Garden" and not s.get("crop","").is_empty():
  game.notify("Harvest or clear this crop before dismantling the garden.",3); return false
 if not s.get("stash",{}).is_empty():
  game.notify("Empty the storage chest before dismantling it.",3); return false
 for key in RECIPES[s.kind].cost:
  add(key,maxi(1,int(RECIPES[s.kind].cost[key]/2)))
 if s.kind=="Bed" and Vector2(game.hero.respawn.x,game.hero.respawn.y).distance_to(at(s)+Vector2(0,48))<1:
  game.hero.respawn={"x":0.0,"y":0.0}
 data().structures.erase(s); revision+=1; game.sound("build"); game.save_game()
 return true
func transfer(s:Dictionary,deposit:bool) -> bool:
 if s.kind!="Storage" or at(s).distance_to(game.player_position())>110: return false
 var source=data().materials if deposit else s.stash
 var target=s.stash if deposit else data().materials
 for key in source.keys():
  var amount=mini(int(source[key]),99999-int(target.get(key,0)))
  target[key]=int(target.get(key,0))+amount
  source[key]-=amount
  if source[key]==0: source.erase(key)
 game.save_game(); return true
func rest(s:Dictionary) -> bool:
 if s.is_empty() or s.get("kind","")!="Bed" or not s in data().structures or at(s).distance_to(game.player_position())>110 or not game.line_clear(game.player_position(),at(s)): return false
 for e in game.enemies:
  if not e.dead and not e.get("neutral",false) and e.pos.distance_to(game.player_position())<180:
   game.notify("Enemies are too close to rest.",3); return false
 var pos=at(s)+Vector2(0,48)
 if blocked(pos,12): game.notify("Clear space beside the bed first.",3); return false
 game.hero.respawn={"x":pos.x,"y":pos.y}
 game.expedition.sleep_at_bed()
 game.hero.hp=Data.max_hp(game.hero); game.hero.mp=Data.max_mp(game.hero)
 game.notify("Rested. This bed is now your return point after defeat.",4)
 game.save_game(); return true
