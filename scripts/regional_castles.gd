extends RefCounted
const Catalog=preload("res://scripts/realm_catalog.gd")
const Data=preload("res://scripts/data.gd")
const PLANS={
 "frostspire":[
  [[Rect2i(14,28,11,9),"Frozen Gatehouse"],[Rect2i(14,2,11,7),"Royal Ascent"],[Rect2i(2,17,9,9),"Winter Armory"],[Rect2i(28,17,9,9),"Thaw Chapel"],[Rect2i(13,13,13,13),"Hall of Blue Glass"],[Rect2i(2,2,9,7),"Frozen Treasury"]],
  [[Rect2i(14,28,11,9),"Crypt Landing"],[Rect2i(14,2,11,7),"King's Stair"],[Rect2i(2,18,9,9),"Icebound Prison"],[Rect2i(28,18,9,9),"Astral Library"],[Rect2i(2,3,9,10),"Royal Crypt"],[Rect2i(28,3,9,10),"Star Vault"]],
  [[Rect2i(14,28,11,9),"Royal Landing"],[Rect2i(10,2,20,11),"Frost King's Arena"],[Rect2i(2,17,9,10),"Queen's Chambers"],[Rect2i(28,17,9,10),"Crown Treasury"],[Rect2i(13,16,14,10),"Hall of Frozen Oaths"],[Rect2i(2,2,7,9),"Abandoned Observatory"]]
 ],
 "blackmire":[
  [[Rect2i(2,28,10,9),"Flooded Gate"],[Rect2i(27,2,10,7),"Chain Lift"],[Rect2i(2,14,9,10),"Drowned Armory"],[Rect2i(26,18,11,10),"Drainage Works"],[Rect2i(14,16,9,9),"Sunken Court"],[Rect2i(2,2,10,7),"Gaoler's Vault"]],
  [[Rect2i(2,28,10,9),"Lower Sluice"],[Rect2i(27,2,10,7),"Throne Lift"],[Rect2i(2,14,9,10),"Flooded Cells"],[Rect2i(26,18,11,10),"Poison Laboratory"],[Rect2i(2,2,10,10),"Drowned Library"],[Rect2i(15,11,8,8),"Sealed Ossuary"]],
  [[Rect2i(2,28,10,9),"Royal Sluice"],[Rect2i(24,2,13,12),"Abomination's Cistern"],[Rect2i(2,14,9,10),"Rotten Royal Chambers"],[Rect2i(26,21,11,10),"Chainbound Treasury"],[Rect2i(14,16,9,9),"Drowned Throne"],[Rect2i(2,2,10,9),"Forgotten Chapel"]]
 ],
 "stormbreak":[
  [[Rect2i(14,28,11,9),"Siege Gatehouse"],[Rect2i(14,2,11,7),"Storm Stair"],[Rect2i(2,15,9,9),"Western Barracks"],[Rect2i(28,15,9,9),"Conduit Tower"],[Rect2i(14,13,11,10),"Hall of Statues"],[Rect2i(2,2,8,7),"Old Marshal's Vault"]],
  [[Rect2i(14,28,11,9),"Prison Landing"],[Rect2i(14,2,11,7),"Sky Stair"],[Rect2i(2,16,9,10),"Tower Prison"],[Rect2i(28,16,9,10),"Runic Laboratory"],[Rect2i(14,14,11,9),"Storm Archive"],[Rect2i(2,2,8,7),"Thunder Vault"]],
  [[Rect2i(14,28,11,9),"Royal Skybridge"],[Rect2i(12,2,16,10),"Storm Warden's Arena"],[Rect2i(2,17,9,10),"Marshal's Chambers"],[Rect2i(28,17,9,10),"Bastion Treasury"],[Rect2i(14,16,11,10),"Hall of Lightning"],[Rect2i(2,2,8,10),"Ancient War Library"]]
 ]
}
var game
func active() -> bool:return not game.hero.is_empty() and game.hero.dungeon!=null and Catalog.ZONES.has(game.hero.dungeon.get("castle",""))
func id() -> String:return game.hero.dungeon.castle
func info() -> Dictionary:return Catalog.ZONES[id()]
func has(flag:String) -> bool:return game.castle.has(flag)
func mark(flag:String,value:bool=true) -> void:game.hero.opened[game.castle.token(flag)]=value
func rooms(f:int) -> Array:return PLANS[id()][f-1]
func title() -> String:return info().castle+" · "+rooms(game.hero.dungeon.floor)[0][1]
func enter(region:String) -> bool:
 if not Catalog.ZONES.has(region) or game.hero.dungeon!=null or game.exploration.active() or game.forge.active() or game.forest.active() or game.beacons.active():return false
 if game.player_position().distance_to(Catalog.ZONES[region].gate)>=78:return false
 game.hero.dungeon={"floor":1,"seed":735931,"run":str(Time.get_unix_time_from_system())+"-"+str(Time.get_ticks_usec()),"cleared":[],"rewarded":false,"returnX":game.hero.x,"returnY":game.hero.y,"story":false,"castle":region}
 game.hero.journey.dungeon_entered=true;game.build_floor(true);game.save_game();game.notify(info().castle.to_upper()+" · Find the armory key and activate the regional mechanism. Entrance stairs return outside; upper landings allow backtracking.",9);return true
func edges(f:int) -> Array:
 if id()=="blackmire":return [[0,2],[0,3],[2,4],[4,3],[4,1],[1,5]] if f==1 else [[0,2],[2,4],[4,1],[0,3],[3,1],[4,5]] if f==2 else [[0,2],[0,3],[2,4],[4,1],[2,5]]
 if id()=="stormbreak":return [[0,2],[0,3],[2,4],[3,4],[4,1],[1,5]] if f==1 else [[0,2],[0,3],[2,4],[3,4],[4,1],[1,5]] if f==2 else [[0,4],[4,2],[4,3],[4,1],[2,5]]
 return [[0,4],[4,2],[4,3],[4,1],[1,5]] if f==1 else [[0,2],[2,4],[4,1],[0,3],[3,1],[1,5]] if f==2 else [[0,4],[4,2],[4,3],[4,1],[2,5]]
func layout() -> Dictionary:
 var grid=[];var f=game.hero.dungeon.floor;var plan=rooms(f)
 for y in range(40):
  var row=[];row.resize(40);row.fill(false);grid.append(row)
 for i in range(plan.size()):
  if f==2 and i==5 and not has("puzzle"):continue
  game.castle.carve(grid,plan[i][0])
 for edge in edges(f):
  if f==2 and edge.has(5) and not has("puzzle"):continue
  game.castle.hall(grid,plan[edge[0]][0].get_center(),plan[edge[1]][0].get_center())
 if f==2 and has("puzzle"):
  game.castle.hall(grid,plan[5][0].get_center(),plan[2 if id()=="stormbreak" else 3][0].get_center())
 if f==1 and (not has("key") or not has("seal")):
  for x in range(40):grid[10][x]=false
 var floors=[]
 for y in range(40):
  for x in range(40):
   if grid[y][x]:floors.append(Vector2i(x,y))
 return {"grid":grid,"size":40,"floors":floors,"start":plan[0][0].get_center(),"exit":plan[1][0].get_center()}
func setup() -> void:
 game.castle.trap_clock=0
 var f=game.hero.dungeon.floor;var plan=rooms(f)
 var kinds=["ice_archer","skeleton","frost_wolf","guardian"] if id()=="frostspire" else ["skeleton","bog_toad","wisp","guardian"] if id()=="blackmire" else ["guardian","archer","crystal_wisp","guardian"]
 for i in range(4):
  var index="boss" if f==3 and i==3 else str(i)
  if has("kill-"+index):continue
  var boss=index=="boss";var mini_boss=f==2 and i==2
  var room_index=[2,3,4,1][i];var at=game.cell_center(plan[room_index][0].get_center())
  var level=maxi(info().level,game.hero.level)
  var e=game.create_enemy(at,level,kinds[i],boss)
  e.dungeon_id="%d:%s" % [f,index];e["castle_index"]=index;e["castle_region"]=id()
  if boss:
   e.named=info().boss;e["realm_boss"]=id();e.hp=float(440+level*36);e.max_hp=e.hp;e.contact_damage=16+level
  elif mini_boss:
   e.named="The Rime Castellan" if id()=="frostspire" else "The Chain Gaoler" if id()=="blackmire" else "The Oathstone Marshal"
   e.hp=float(150+level*18);e.max_hp=e.hp
  game.enemies.append(e)
 if f==1 and not has("kill-vault"):
  var e=game.create_enemy(game.cell_center(plan[5][0].get_center()),maxi(info().level,game.hero.level),"guardian")
  e.named="Vault Sentinel";e["castle_optional"]=true;e["castle_index"]="vault";e["castle_region"]=id();e.dungeon_id="1:vault";game.enemies.append(e)
func defeated(e:Dictionary) -> void:
 if not e.has("castle_index"):return
 mark("kill-"+str(e.castle_index))
 if game.hero.dungeon.floor==2 and str(e.castle_index)=="2":game.survival.add(info().core,1)
 if e.has("realm_boss"):game.hero.opened[id()+"-cleared"]=true;game.notify(info().castle+" reclaimed. Claim the treasury relic before returning outside.",7)
func advance() -> bool:
 if not game.castle.required_clear():return false
 if game.hero.dungeon.floor==1 and (not has("key") or not has("seal")):game.notify("Find the armory key and activate "+info().mechanism.to_lower()+".",5);return false
 if game.hero.dungeon.floor==3:game.leave_dungeon();return true
 game.hero.dungeon.floor+=1;game.hero.dungeon.cleared=[];game.hero.dungeon.rewarded=false;game.build_floor(true);game.save_game();return true
func features() -> Dictionary:
 var plan=rooms(game.hero.dungeon.floor)
 if game.hero.dungeon.floor==1:return {"key":{"cell":plan[2][0].get_center()+Vector2i(-2,-1),"label":"TAKE ARMORY KEY"},"seal":{"cell":plan[3][0].get_center()+Vector2i(2,-1),"label":info().mechanism},"vault":{"cell":plan[5][0].get_center()+Vector2i(0,-1),"label":"OPEN GUARDED VAULT"}}
 if game.hero.dungeon.floor==2:return {"checkpoint":{"cell":plan[0][0].get_center()+Vector2i(-2,0),"label":"BIND CASTLE CHECKPOINT"},"archive":{"cell":plan[4][0].get_center()+Vector2i(2,2),"label":"READ RUNE ORDER"},"rune-a":{"cell":plan[2][0].get_center(),"label":"TURN SUN RUNE"},"rune-b":{"cell":plan[3][0].get_center(),"label":"TURN STAR RUNE"},"rune-c":{"cell":plan[4][0].get_center()+Vector2i(-1,-1),"label":"TURN MOON RUNE"},"puzzle-vault":{"cell":plan[5][0].get_center(),"label":"CLAIM SEALED TREASURE"}}
 return {"relic":{"cell":plan[3][0].get_center()+Vector2i(0,-2),"label":"CLAIM "+info().relic.to_upper()}}
func refresh_layout() -> void:
 game.dungeon_map=layout()
 for y in range(40):
  for x in range(40):game.astar.set_point_solid(Vector2i(x,y),not game.dungeon_map.grid[y][x])
 game.world.refresh(true)
func use_feature() -> bool:
 var feature=game.castle.nearby()
 if feature.is_empty():return false
 if feature=="vault" and game.enemies.any(func(e):return not e.dead and e.get("castle_optional",false)):game.notify("Defeat the Vault Sentinel first.",4);return false
 if feature=="puzzle-vault" and not has("puzzle"):return false
 if feature=="relic":
  if not has("kill-boss"):game.notify("Defeat "+info().boss+" first.",4);return false
  if game.hero.opened.get(id()+"-relic",false):mark(feature);return false
  if game.hero.inventory.size()>=40:game.notify("Make room in Gear, then return for the relic.",4);return false
  if game.survival.count(info().core)>99996:game.notify("Make room for 3 "+info().core+" before claiming.",4);return false
  game.hero.inventory.append({"id":id()+"-relic","kind":info().kind,"name":info().relic,"level":game.hero.level,"rarity":4,"power":62+game.hero.level*8,"upgrade":0,"enchant":3})
  game.hero.opened[id()+"-relic"]=true;game.hero.spells.known[info().spell]=1;game.survival.add(info().core,3)
 if feature.begins_with("rune-"):
  var next=0
  for rune in info().order:
   if has(rune):next+=1
  if next<3 and feature!=info().order[next]:
   for rune in info().order:mark(rune,false)
   game.notify("The inscription rejects that order. "+info().clue,7);game.world.refresh_scenery(true);game.save_game();return false
  mark(feature)
  if next==2:mark("puzzle");refresh_layout();game.notify("The hidden vault opens. A sealed passage becomes an optional shortcut.",7)
  else:game.notify("Rune aligned · %d/3. %s" % [next+1,info().clue],6)
 elif feature=="archive":mark(feature);game.notify(info().clue,9)
 else:
  if feature in ["vault","puzzle-vault"]:game.hero.gold+=130;game.hero.essence+=4
  mark(feature)
  if feature=="checkpoint":game.hero.opened[id()+":%s:checkpoint" % game.hero.dungeon.run]=true
  if feature in ["key","seal"]:refresh_layout()
  game.notify({"key":"Armory key recovered.","seal":"Mechanism activated · upper gate unlocked when the key is recovered.","checkpoint":"Checkpoint bound. Defeat retains this run's keys, enemies and treasure.","vault":"Guarded vault · +130 gold, +4 essence.","puzzle-vault":"Secret vault · +130 gold, +4 essence.","relic":"Legendary "+info().relic+" and "+game.spellbook.BOOK[info().spell].name+" spell recovered. Assign it in Spells."}.get(feature,"Inscription discovered."),6)
 game.world.refresh_scenery(true);game.sound("reward");game.save_game();return true
func checkpoint_defeat() -> bool:
 var loss=int(game.hero.gold*.15);game.hero.gold-=loss;game.hero.deaths+=1;game.expedition.reset_after_defeat()
 game.hero.dungeon.floor=2 if game.hero.opened.get(id()+":%s:checkpoint" % game.hero.dungeon.run,false) else 1
 game.hero.dungeon.cleared=[];game.hero.dungeon.rewarded=true;game.hero.hp=Data.max_hp(game.hero)*.65;game.hero.mp=Data.max_mp(game.hero)*.5
 game.build_floor(true);game.save_game();game.hud.show_pause("Castle checkpoint · %d gold lost. Progress retained." % loss);return true
func objective() -> String:
 if game.hero.dungeon.floor==1:return "Find armory key · "+("found" if has("key") else "missing")+" · "+info().mechanism.to_lower()+" · "+("done" if has("seal") else "pending")
 if game.hero.dungeon.floor==2:return "Bind checkpoint · Read the rune order · Solve the optional vault · Defeat the Castellan"
 return "Defeat "+info().boss+" · Claim "+info().relic+" · Return outside"
func traps() -> Array:
 var plan=rooms(game.hero.dungeon.floor)
 return [plan[4][0].get_center()+Vector2i(0,2),plan[2][0].get_center()+Vector2i(0,2)]
func draw_traps(c:CanvasItem) -> void:
 var accent:Color=info().accent
 for cell in traps():
  var p=game.cell_center(cell);var warning=fposmod(game.castle.trap_clock,3.8)>2.5
  c.draw_circle(p,34,Color(accent,.22 if warning else .05));c.draw_arc(p,34,0,TAU,24,accent if warning else accent.darkened(.65),2)
  if warning:c.draw_string(ThemeDB.fallback_font,p+Vector2(-5,5),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,17,accent)
func tick(dt:float) -> void:
 if not game.playing or dt<=0:return
 var before=floori(game.castle.trap_clock/3.8);game.castle.trap_clock+=dt
 if floori(game.castle.trap_clock/3.8)==before:return
 for cell in traps():
  var p=game.cell_center(cell)
  if game.player_position().distance_to(p)<34 and game.dash_time<=0:
   game.hero.hp-=maxf(3,Data.max_hp(game.hero)*.045)
   game.floating(p,"FROST" if id()=="frostspire" else "POISON" if id()=="blackmire" else "LIGHTNING",info().accent)
func prepare_attack(enemy:Dictionary) -> void:
 var pattern=int(enemy.get("realm_pattern",0))%3;enemy["realm_pattern"]=pattern+1
 var wounded=enemy.hp<enemy.max_hp*.5
 enemy.windup=.85 if wounded else 1.3
 if enemy.realm_boss=="frostspire":
  enemy["castle_attack"]=["ICE LANCE","ROYAL FROST","SHATTER"][pattern];enemy.strike_radius=[45.0,135.0,80.0][pattern]
  if pattern==1:enemy.strike=enemy.pos
 elif enemy.realm_boss=="blackmire":
  enemy["castle_attack"]=["VENOM SPIT","CHAIN CRUSH","MIASMA"][pattern];enemy.strike_radius=[64.0,95.0,125.0][pattern]
  if pattern==2:enemy.strike=enemy.pos
 else:
  enemy["castle_attack"]=["LIGHTNING MARK","THUNDER SLAM","SKYFALL"][pattern];enemy.strike_radius=[48.0,115.0,85.0][pattern]
  if pattern==1:enemy.strike=enemy.pos
func draw_rooms(c:CanvasItem,b:Rect2) -> void:
 var accent:Color=info().accent
 for room in rooms(game.hero.dungeon.floor):
  var r=Rect2(Vector2(room[0].position)*48,Vector2(room[0].size)*48)
  if not b.intersects(r):continue
  c.draw_rect(r.grow(-10),Color(accent,.035));c.draw_rect(r.grow(-17),Color("a8935633"),false,2)
  c.draw_string(ThemeDB.fallback_font,r.position+Vector2(20,29),room[1].to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("c8bc9f"))
  for side in [r.position+Vector2(28,50),Vector2(r.end.x-28,r.position.y+50)]:
   c.draw_circle(side+Vector2(5,8),19,Color("0d1c2588"));c.draw_circle(side,15,Color("64737b"));c.draw_circle(side-Vector2(3,4),10,Color("93a0a0"));c.draw_arc(side,15,0,TAU,12,accent.darkened(.35),2)
  var name=room[1]
  if "Library" in name or "Archive" in name or "Laboratory" in name:
   for dy in range(65,int(r.size.y)-25,50):
    var p=r.position+Vector2(r.size.x-30,dy);c.draw_rect(Rect2(p,Vector2(18,38)),Color("80694a"))
    for k in range(5):c.draw_rect(Rect2(p+Vector2(2,3+k*6),Vector2(12,4)),accent.darkened(.3) if k%2 else Color("b0a078"))
  elif "Prison" in name or "Cells" in name or "Crypt" in name:
   for dy in range(75,int(r.size.y)-50,88):
    var p=r.position+Vector2(24,dy);c.draw_rect(Rect2(p,Vector2(52,60)),Color("33434d"));c.draw_rect(Rect2(p,Vector2(52,60)),Color("819098"),false,3)
    for dx in range(8,50,12):c.draw_line(p+Vector2(dx,0),p+Vector2(dx,60),Color("a3a896"),3)
  elif "Arena" in name or "Cistern" in name:
   var p=r.get_center();c.draw_arc(p,115,0,TAU,48,Color(accent,.3),5);c.draw_arc(p,140,0,TAU,48,Color("baa57444"),3)
   var throne=p+Vector2(0,-150);c.draw_rect(Rect2(throne-Vector2(28,38),Vector2(56,65)),Color("ae955e"));c.draw_rect(Rect2(throne-Vector2(19,27),Vector2(38,41)),accent.darkened(.65))
  elif "Armory" in name or "Barracks" in name:
   for dx in range(40,int(r.size.x)-20,65):
    var p=r.position+Vector2(dx,80);c.draw_rect(Rect2(p-Vector2(12,26),Vector2(24,50)),Color("705c43"));c.draw_line(p+Vector2(0,-35),p+Vector2(0,15),Color("c9d2d2"),4);c.draw_line(p+Vector2(-10,7),p+Vector2(10,7),Color("c7a569"),4)
  elif "Chambers" in name:
   var p=r.position+Vector2(55,90);c.draw_rect(Rect2(p,Vector2(70,115)),Color("7f6c50"));c.draw_rect(Rect2(p+Vector2(7,25),Vector2(56,80)),accent.darkened(.45));c.draw_rect(Rect2(p+Vector2(9,7),Vector2(52,20)),Color("d7d3bd"))
  if id()=="blackmire":c.draw_rect(Rect2(r.position+Vector2(10,r.size.y-48),Vector2(r.size.x-20,27)),Color("49666d33"))
 for feature in features():
  if has(feature):continue
  var p=game.cell_center(features()[feature].cell)
  if not b.has_point(p) or not game.walkable(p):continue
  if feature in ["vault","puzzle-vault","relic"]:game.world.field_visuals.draw_prop(c,"cache",p)
  else:
   c.draw_circle(p,22,Color("344751"));c.draw_arc(p,23,0,TAU,20,accent,3);c.draw_string(ThemeDB.fallback_font,p+Vector2(-6,6),"☀" if feature=="rune-a" else "★" if feature=="rune-b" else "☽" if feature=="rune-c" else "+" if feature=="checkpoint" else "?",HORIZONTAL_ALIGNMENT_LEFT,-1,18,accent)
  c.draw_string(ThemeDB.fallback_font,p+Vector2(-30,33),feature.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ddcda3"))
 if game.hero.dungeon.floor==1 and (not has("key") or not has("seal")):
  for x in range(40):
   var p=game.cell_center(Vector2i(x,10))
   if not b.has_point(p):continue
   if x>0 and x<39 and game.dungeon_map.grid[11][x]:
    for dx in [-15,0,15]:c.draw_line(p+Vector2(dx,-24),p+Vector2(dx,24),Color("b6a26c"),4)
