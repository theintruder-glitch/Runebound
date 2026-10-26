extends RefCounted
const Data=preload("res://scripts/data.gd")
const FLOORS=["Gatehouse & Great Hall","Prisons & Forgotten Library","Throne of the Briar King"]
var caves=preload("res://scripts/side_caves.gd").new()
var regional=preload("res://scripts/regional_castles.gd").new()
var game:
 set(value):
  game=value;regional.game=value;caves.game=value
var trap_clock=0.0
func active() -> bool:return not game.hero.is_empty() and game.hero.dungeon!=null and game.hero.dungeon.get("castle","") in ["thornwatch","frostspire","blackmire","stormbreak","frost-cave","highland-mine"]
func title() -> String:return caves.title() if caves.active() else regional.title() if regional.active() else "Thornwatch Keep · "+FLOORS[game.hero.dungeon.floor-1]
func enter_region(id:String) -> bool:return regional.enter(id)
func retreat() -> bool:
 if not active():return false
 if game.hero.dungeon.floor==1:game.leave_dungeon();return true
 game.hero.dungeon.floor-=1;game.hero.dungeon.cleared=[];game.hero.dungeon.rewarded=false;game.build_floor(true)
 game.set_player_position(game.cell_center(game.dungeon_map.exit));game.camera.position=game.player_position();game.camera.reset_smoothing();game.world.refresh(true);game.save_game();return true
func token(id:String) -> String:return "%s:%s:%d:%s" % [game.hero.dungeon.castle,game.hero.dungeon.run,game.hero.dungeon.floor,id]
func has(id:String) -> bool:return game.hero.opened.get(token(id),false)
func enter() -> bool:
 if game.hero.dungeon!=null or game.player_position().distance_to(game.landscape.KEEP)>=90 or game.exploration.active() or game.forge.active() or game.forest.active() or game.beacons.active():return false
 game.hero.dungeon={"floor":1,"seed":735931,"run":str(Time.get_ticks_usec()),"cleared":[],"rewarded":false,"returnX":game.hero.x,"returnY":game.hero.y,"story":false,"castle":"thornwatch"}
 game.hero.journey.dungeon_entered=true;game.build_floor(true);game.save_game();game.notify("THORNWATCH KEEP · Find the armory key and light the library seal. Entrance stairs lead outside; upper landings allow backtracking.",8);return true
func rooms(f:int) -> Array:
 if caves.active():return caves.rooms(f)
 if regional.active():return regional.rooms(f)
 if f==1:return [[Rect2i(12,24,9,6),"Gatehouse"],[Rect2i(10,12,13,10),"Great Hall"],[Rect2i(2,14,6,8),"Armory"],[Rect2i(24,12,6,9),"Rune Library"],[Rect2i(12,2,9,7),"Upper Stairs"],[Rect2i(2,2,6,6),"Hidden Vault"]]
 if f==2:return [[Rect2i(12,24,9,6),"Lower Landing"],[Rect2i(3,18,7,9),"Prison Cells"],[Rect2i(22,19,8,8),"Buried Archive"],[Rect2i(3,4,8,9),"Knight's Crypt"],[Rect2i(21,3,9,10),"Reliquary"],[Rect2i(12,2,8,7),"Throne Stairs"]]
 return [[Rect2i(12,24,9,6),"Royal Stair"],[Rect2i(7,12,19,10),"Throne Hall"],[Rect2i(2,14,5,8),"Royal Chambers"],[Rect2i(26,14,4,9),"Ancient Treasury"],[Rect2i(10,2,14,8),"Briar King's Arena"]]
func carve(grid:Array,r:Rect2i) -> void:
 for y in range(r.position.y,r.end.y):
  for x in range(r.position.x,r.end.x):grid[y][x]=true
func hall(grid:Array,a:Vector2i,b:Vector2i) -> void:
 carve(grid,Rect2i(mini(a.x,b.x)-1,a.y-1,absi(a.x-b.x)+3,3));carve(grid,Rect2i(b.x-1,mini(a.y,b.y)-1,3,absi(a.y-b.y)+3))
func layout() -> Dictionary:
 if caves.active():return caves.layout()
 if regional.active():return regional.layout()
 var f=game.hero.dungeon.floor;var grid=[]
 for y in range(32):
  var row=[];row.resize(32);row.fill(false);grid.append(row)
 for r in rooms(f):carve(grid,r[0])
 var edges=[]
 if f==1:edges=[[Vector2i(16,27),Vector2i(16,17)],[Vector2i(16,17),Vector2i(5,18)],[Vector2i(16,17),Vector2i(27,17)],[Vector2i(16,17),Vector2i(16,4)],[Vector2i(5,18),Vector2i(5,5)]]
 elif f==2:edges=[[Vector2i(16,27),Vector2i(6,23)],[Vector2i(6,23),Vector2i(6,8)],[Vector2i(6,8),Vector2i(16,4)],[Vector2i(16,27),Vector2i(25,23)],[Vector2i(25,23),Vector2i(25,7)],[Vector2i(25,7),Vector2i(16,4)]]
 else:edges=[[Vector2i(16,27),Vector2i(16,17)],[Vector2i(16,17),Vector2i(4,18)],[Vector2i(16,17),Vector2i(28,18)],[Vector2i(16,17),Vector2i(16,5)]]
 for e in edges:hall(grid,e[0],e[1])
 if f==1:
  if not has("key") or not has("seal"):
   for x in range(15,18):grid[10][x]=false
  if not has("seal"):
   for x in range(4,7):grid[11][x]=false
 var floors=[]
 for y in range(32):
  for x in range(32):
   if grid[y][x]:floors.append(Vector2i(x,y))
 return {"grid":grid,"size":32,"floors":floors,"start":Vector2i(16,27),"exit":Vector2i(16,4)}
func setup() -> void:
 if caves.active():caves.setup();return
 if regional.active():regional.setup();return
 trap_clock=0;var f=game.hero.dungeon.floor
 var places=[Vector2i(16,20),Vector2i(5,19),Vector2i(27,18),Vector2i(16,6)] if f==1 else [Vector2i(6,22),Vector2i(25,23),Vector2i(6,8),Vector2i(25,7)] if f==2 else [Vector2i(11,18),Vector2i(22,18),Vector2i(16,5)]
 for i in range(places.size()):
  if has("kill-"+str(i)):continue
  var boss=f==3 and i==places.size()-1;var mini_boss=f==2 and i==2;var level=maxi(3,game.hero.level)
  var e=game.create_enemy(game.cell_center(places[i]),level,"guardian" if boss or mini_boss else "skeleton" if i%2 else "goblin",boss)
  e.dungeon_id="%d:%d" % [f,i];e["castle_index"]=i
  if boss:e.named="The Thornbound Colossus";e["thornwatch_boss"]=true;e.hp=float(450+level*32);e.max_hp=e.hp;e.contact_damage=16+level
  elif mini_boss:e.named="Castellan of the Crypt";e.hp=float(160+level*15);e.max_hp=e.hp;e.contact_damage=11+level
  game.enemies.append(e)
 if f==1 and not has("kill-vault"):
  var e=game.create_enemy(game.cell_center(Vector2i(5,5)),maxi(3,game.hero.level),"guardian");e.named="Vault Sentinel";e["castle_optional"]=true;e["castle_index"]="vault";e.dungeon_id="1:vault";game.enemies.append(e)
func defeated(e:Dictionary) -> void:
 if caves.active():caves.defeated(e);return
 if regional.active():regional.defeated(e);return
 if not active() or not e.has("castle_index"):return
 game.hero.opened[token("kill-"+str(e.castle_index))]=true
 if e.get("thornwatch_boss",false):game.hero.opened["thornwatch-cleared"]=true;game.notify("THORNWATCH RECLAIMED · Claim the legendary blade in the treasury, then return outside.",8)
func required_clear() -> bool:return not game.enemies.any(func(e):return not e.dead and not e.get("castle_optional",false))
func objective() -> String:
 if caves.active():return caves.objective()
 if regional.active():return regional.objective()
 if not active():return ""
 if game.floor_clear():return "KEEP RECLAIMED · Claim the treasury blade · Gold stairs return outside" if game.hero.dungeon.floor==3 else "LEVEL CLEARED · Explore side rooms or take the gold stairs"
 if game.hero.dungeon.floor==1:
  return "THORNWATCH · "+("Find the armory key" if not has("key") else "Light the library seal" if not has("seal") else "Defeat the remaining castle guards")
 if game.hero.dungeon.floor==2:return "THORNWATCH · Bind the checkpoint near the entrance · Explore crypts and archives"
 return "THORNBOUND COLOSSUS · Dodge root strikes and the wide ground slam"
func advance() -> bool:
 if caves.active():return caves.advance()
 if regional.active():return regional.advance()
 if not active() or not required_clear():return false
 if game.hero.dungeon.floor==1 and (not has("key") or not has("seal")):game.notify("The upper gate needs the armory key and library seal.",4);return false
 if game.hero.dungeon.floor==3:game.leave_dungeon();return true
 game.hero.dungeon.floor+=1;game.hero.dungeon.cleared=[];game.hero.dungeon.rewarded=false;game.build_floor(true);game.save_game();return true
func features() -> Dictionary:
 if caves.active():return caves.features()
 if regional.active():return regional.features()
 if game.hero.dungeon.floor==1:return {"key":{"cell":Vector2i(4,17),"label":"TAKE ARMORY KEY"},"seal":{"cell":Vector2i(27,14),"label":"LIGHT LIBRARY SEAL"},"vault":{"cell":Vector2i(4,4),"label":"OPEN HIDDEN VAULT"}}
 if game.hero.dungeon.floor==2:return {"checkpoint":{"cell":Vector2i(16,26),"label":"BIND CASTLE CHECKPOINT"},"archive":{"cell":Vector2i(25,21),"label":"READ ANCIENT ARCHIVE"}}
 return {"relic":{"cell":Vector2i(28,19),"label":"CLAIM THORNWATCH OATH"}}
func nearby() -> String:
 if not active():return ""
 for id in features():
  if has(id):continue
  var p=game.cell_center(features()[id].cell)
  if game.player_position().distance_to(p)<50 and game.line_clear(game.player_position(),p):return id
 return ""
func interaction() -> String:
 var id=nearby();return features()[id].label if not id.is_empty() else ""
func use_feature() -> bool:
 if caves.active():return caves.use_feature()
 if regional.active():return regional.use_feature()
 var id=nearby()
 if id.is_empty():return false
 if id=="vault" and game.enemies.any(func(e):return not e.dead and e.get("castle_optional",false)):game.notify("Defeat the Vault Sentinel first.",3);return false
 if id=="relic":
  if not game.hero.opened.get("thornwatch-cleared",false):game.notify("Defeat the Colossus first.",3);return false
  if game.hero.opened.get("thornwatch-relic",false):game.hero.opened[token(id)]=true;return false
  if game.hero.inventory.size()>=40:game.notify("Make room in Gear for the legendary blade.",3);return false
  if game.survival.count("Thorn sigil")>99996:game.notify("Make room for 3 Thorn sigils, then claim again.",4);return false
  game.hero.inventory.append({"id":"thornwatch-oath","kind":"sword","name":"Thornwatch Oath","level":game.hero.level,"rarity":4,"power":60+game.hero.level*8,"upgrade":0,"enchant":4});game.hero.opened["thornwatch-relic"]=true;game.hero.spells.known["briarheart"]=1;game.survival.add("Thorn sigil",3)
 elif id in ["vault","archive"]:game.hero.gold+=100;game.hero.essence+=3
 game.hero.opened[token(id)]=true
 if id=="checkpoint":game.hero.opened["thornwatch:%s:checkpoint" % game.hero.dungeon.run]=true
 if id in ["key","seal"]:
  game.dungeon_map=layout()
  for y in range(32):
   for x in range(32):game.astar.set_point_solid(Vector2i(x,y),not game.dungeon_map.grid[y][x])
  game.world.refresh(true)
 game.notify({"key":"Armory key recovered.","seal":"Library seal lit · upper gate and hidden vault passage unlocked.","checkpoint":"Checkpoint bound · defeat returns here with current run progress.","archive":"The kings chained a living guardian beneath their throne. +100 gold, +3 essence.","vault":"Secret vault · +100 gold, +3 essence.","relic":"Legendary Thornwatch Oath and Briarheart spell recovered. Assign it in Spells."}[id],6)
 game.world.refresh_scenery(true);game.save_game();return true
func checkpoint_defeat() -> bool:
 if caves.active():return caves.checkpoint_defeat()
 if regional.active():return regional.checkpoint_defeat()
 if not active():return false
 var loss=int(game.hero.gold*.15);game.hero.gold-=loss;game.hero.deaths+=1;game.expedition.reset_after_defeat()
 game.hero.dungeon.floor=2 if game.hero.opened.get("thornwatch:%s:checkpoint" % game.hero.dungeon.run,false) else 1
 game.hero.dungeon.cleared=[];game.hero.dungeon.rewarded=true;game.hero.hp=Data.max_hp(game.hero)*.65;game.hero.mp=Data.max_mp(game.hero)*.5
 game.build_floor(true);game.save_game();game.hud.show_pause("Castle checkpoint · %d gold lost. Keys, defeated foes and claimed treasure retained." % loss);return true
func draw_rooms(c:CanvasItem,b:Rect2) -> void:
 if caves.active():caves.draw_rooms(c,b);return
 if regional.active():regional.draw_rooms(c,b);return
 if not active():return
 for r in rooms(game.hero.dungeon.floor):
  var rect=Rect2(Vector2(r[0].position)*48,Vector2(r[0].size)*48)
  if not b.intersects(rect):continue
  c.draw_rect(rect.grow(-8),Color("6b796511"));c.draw_rect(rect.grow(-12),Color("a99b6533"),false,2);c.draw_string(ThemeDB.fallback_font,rect.position+Vector2(20,30),r[1].to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("bba789"))
  if "Library" in r[1] or "Archive" in r[1]:
   for dy in range(35,int(rect.size.y)-20,48):
    var p=rect.position+Vector2(rect.size.x-24,dy);c.draw_rect(Rect2(p,Vector2(14,32)),Color("755d43"))
    for k in range(5):c.draw_rect(Rect2(p+Vector2(2,2+k*6),Vector2(10,4)),Color("a7936b") if k%2 else Color("667a71"))
  elif "Crypt" in r[1] or "Prison" in r[1]:
   for dy in range(45,int(rect.size.y)-20,80):
    var p=rect.position+Vector2(20,dy);c.draw_rect(Rect2(p,Vector2(30,55)),Color("62716d"));c.draw_rect(Rect2(p+Vector2(4,4),Vector2(22,47)),Color("344847"));c.draw_line(p+Vector2(15,13),p+Vector2(15,40),Color("afa68b"),3);c.draw_line(p+Vector2(7,22),p+Vector2(23,22),Color("afa68b"),3)
  elif "Arena" in r[1]:
   var p=rect.get_center()+Vector2(0,-110);c.draw_rect(Rect2(p-Vector2(30,35),Vector2(60,50)),Color("9a875a"));c.draw_rect(Rect2(p-Vector2(20,28),Vector2(40,40)),Color("34584a"));c.draw_line(p+Vector2(-35,22),p+Vector2(35,22),Color("ada075"),7)
 if game.hero.dungeon.floor==1 and (not has("key") or not has("seal")):
  var p=game.cell_center(Vector2i(16,10));c.draw_rect(Rect2(p-Vector2(70,24),Vector2(140,48)),Color("253034"))
  for x in range(-60,65,15):c.draw_line(p+Vector2(x,-24),p+Vector2(x,24),Color("baaa75"),4)
  c.draw_string(ThemeDB.fallback_font,p+Vector2(-85,-35),"UPPER GATE · KEY + SEAL",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("d9c794"))
 for id in features():
  var p=game.cell_center(features()[id].cell)
  if has(id) or not b.has_point(p):continue
  if id in ["vault","relic"]:game.world.field_visuals.draw_prop(c,"cache",p)
  elif id=="key":c.draw_circle(p+Vector2(-10,-8),9,Color("cfb277"),false,4);c.draw_line(p+Vector2(-3,-2),p+Vector2(17,16),Color("cfb277"),5);c.draw_line(p+Vector2(12,10),p+Vector2(18,5),Color("cfb277"),4)
  elif id=="archive":c.draw_rect(Rect2(p-Vector2(21,12),Vector2(42,28)),Color("bbaa84"));c.draw_line(p+Vector2(0,-11),p+Vector2(0,15),Color("57594b"),2)
  else:c.draw_circle(p,23,Color("465c56"));c.draw_arc(p,24,0,TAU,24,Color("b6bd8c"),3);c.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-19),p+Vector2(12,0),p+Vector2(0,13),p+Vector2(-12,0)]),Color("a4d1a2"))
  c.draw_string(ThemeDB.fallback_font,p+Vector2(-32,28),id.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("dcc998"))
func draw_traps(c:CanvasItem) -> void:
 if caves.active():caves.draw_traps(c);return
 if regional.active():regional.draw_traps(c);return
 if not active():return
 for cell in [Vector2i(16,15),Vector2i(16,9)]:
  var p=game.cell_center(cell)
  if not game.walkable(p):continue
  var warning=fposmod(trap_clock,3.2)>2.0;c.draw_circle(p,29,Color("a6c97555") if warning else Color("7c917c22"));c.draw_arc(p,29,0,TAU,18,Color("c8d39a") if warning else Color("61736b"),2)
func tick(dt:float) -> void:
 if caves.active():caves.tick(dt);return
 if regional.active():regional.tick(dt);return
 if not active() or not game.playing or dt<=0:return
 var before=floori(trap_clock/3.2);trap_clock+=dt
 if floori(trap_clock/3.2)==before:return
 for cell in [Vector2i(16,15),Vector2i(16,9)]:
  var p=game.cell_center(cell)
  if game.walkable(p) and game.player_position().distance_to(p)<29 and game.dash_time<=0:game.hero.hp-=maxf(3,Data.max_hp(game.hero)*.04);game.floating(p,"BRIAR RUNE",Color("c9d4a1"))
