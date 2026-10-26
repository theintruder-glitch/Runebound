extends RefCounted
# Side expeditions reuse the existing floor lifecycle, InputMap and save paths.
const Data=preload("res://scripts/data.gd")
const SITES={
 "frost-cave":{"name":"Glacier Hollow","point":Vector2(-260,-2440),"level":5,"material":"Frost shard","accent":Color("9ddbea"),"boss":"Hollow's Icebound Sentinel","clue":"The surveyor marked a thaw brazier in the western refuge. Light it to open the crystal seam.","switch":"LIGHT THAW BRAZIER","treasure":"Surveyor's winter cache","kind":"crystal_wisp"},
 "highland-mine":{"name":"Oathstone Mine","point":Vector2(1870,-260),"level":6,"material":"Crystal","accent":Color("dab87a"),"boss":"The Oathstone Foreman","clue":"The last shift left a counterweight lever in the eastern workshop. It raises the ore-vault grille.","switch":"PULL COUNTERWEIGHT LEVER","treasure":"Foreman's sealed strongbox","kind":"skeleton"}
}
const PLANS={
 "frost-cave":[[Rect2i(12,24,8,6),"Snowbound Mouth"],[Rect2i(10,12,12,8),"Bluewater Grotto"],[Rect2i(2,13,6,7),"Surveyor's Refuge"],[Rect2i(11,2,10,7),"Icebound Sanctuary"],[Rect2i(25,5,6,7),"Sealed Crystal Seam"]],
 "highland-mine":[[Rect2i(2,22,7,8),"Abandoned Lift"],[Rect2i(2,11,9,7),"Ore Sorting Floor"],[Rect2i(22,22,9,8),"Counterweight Workshop"],[Rect2i(20,9,12,9),"Foreman's Excavation"],[Rect2i(22,2,8,5),"Sealed Ore Vault"]]
}
var game
func active() -> bool:return not game.hero.is_empty() and game.hero.dungeon!=null and SITES.has(game.hero.dungeon.get("castle",""))
func id() -> String:return game.hero.dungeon.castle
func info() -> Dictionary:return SITES[id()]
func has(flag:String) -> bool:return game.castle.has(flag)
func mark(flag:String) -> void:game.hero.opened[game.castle.token(flag)]=true
func rooms(_floor:int=1) -> Array:return PLANS[id()]
func title() -> String:return info().name+" · Hidden expedition"
func enter(site:String) -> bool:
 if not SITES.has(site) or game.hero.dungeon!=null or game.exploration.active() or game.forest.active() or game.forge.active():return false
 if game.player_position().distance_to(SITES[site].point)>=60 or not game.line_clear(game.player_position(),SITES[site].point):return false
 game.hero.dungeon={"floor":1,"seed":91573,"run":str(Time.get_unix_time_from_system())+"-"+str(Time.get_ticks_usec()),"cleared":[],"rewarded":false,"returnX":game.hero.x,"returnY":game.hero.y,"story":false,"castle":site}
 game.hero.journey.dungeon_entered=true;game.build_floor(true);game.save_game()
 game.notify(info().name.to_upper()+" · Entrance stairs always return outside. Read the expedition journal, find the mechanism and explore the sealed side chamber.",9);return true
func layout() -> Dictionary:
 var grid=[];var plan=rooms()
 for y in range(34):
  var row=[];row.resize(34);row.fill(false);grid.append(row)
 for i in range(plan.size()):
  if i==4 and not has("mechanism"):continue
  var r:Rect2i=plan[i][0];game.castle.carve(grid,r)
  if id()=="frost-cave":
   for y in range(r.position.y,r.end.y):
    for x in range(r.position.x,r.end.x):
     var edge_x=mini(x-r.position.x,r.end.x-1-x);var edge_y=mini(y-r.position.y,r.end.y-1-y)
     if edge_x+edge_y<2:grid[y][x]=false
 var edges=[[0,1],[1,2],[1,3],[3,4]] if id()=="frost-cave" else [[0,1],[0,2],[1,3],[2,3],[3,4]]
 for edge in edges:
  if edge.has(4) and not has("mechanism"):continue
  game.castle.hall(grid,plan[edge[0]][0].get_center(),plan[edge[1]][0].get_center())
 var floors=[]
 for y in range(34):
  for x in range(34):
   if grid[y][x]:floors.append(Vector2i(x,y))
 return {"grid":grid,"size":34,"floors":floors,"start":plan[0][0].get_center(),"exit":plan[3][0].get_center()}
func setup() -> void:
 game.castle.trap_clock=0
 var cells=[Vector2i(16,16),Vector2i(5,16),Vector2i(16,5),Vector2i(28,8)] if id()=="frost-cave" else [Vector2i(6,14),Vector2i(26,25),Vector2i(26,13),Vector2i(26,4)]
 for i in range(cells.size()):
  if has("kill-"+str(i)):continue
  var boss=i==2;var e=game.create_enemy(game.cell_center(cells[i]),maxi(info().level,game.hero.level),"guardian" if boss or i==3 else info().kind,boss)
  e.dungeon_id="1:"+str(i);e["castle_index"]=i;e["castle_optional"]=i==3
  if boss:
   e.named=info().boss;e["cave_boss"]=true;e.hp=220.0+maxi(info().level,game.hero.level)*22;e.max_hp=e.hp
  elif i==3:e.named="Crystal Seam Guardian" if id()=="frost-cave" else "Vault Watchman"
  game.enemies.append(e)
func defeated(enemy:Dictionary) -> void:
 if not enemy.has("castle_index"):return
 mark("kill-"+str(enemy.castle_index))
 if enemy.get("cave_boss",false):game.hero.opened[id()+"-cleared"]=true
func features() -> Dictionary:
 var plan=rooms()
 return {"journal":{"cell":plan[0][0].get_center()+Vector2i(2,0),"label":"READ EXPEDITION JOURNAL"},"mechanism":{"cell":plan[2][0].get_center()+Vector2i(0,-1),"label":info().switch},"treasure":{"cell":plan[4][0].get_center()+Vector2i(1,0),"label":"OPEN "+info().treasure.to_upper()}}
func use_feature() -> bool:
 var feature=game.castle.nearby()
 if feature.is_empty():return false
 if feature=="treasure":
  if not has("kill-2") or not has("kill-3"):game.notify("Defeat the expedition guardian and the vault watchman first.",4);return false
  if game.hero.opened.get(id()+"-treasure",false):mark(feature);game.save_game();game.notify("The expedition treasure has already been recovered.",4);return false
  if game.survival.count(info().material)>99994:game.notify("Make room for 5 "+info().material+" before opening the cache.",4);return false
  game.hero.gold+=180;game.hero.essence+=4;game.survival.add(info().material,5);game.hero.opened[id()+"-treasure"]=true
  game.notify(info().treasure+" · +180 gold, +4 essence, +5 "+info().material+". Expedition treasure is claimed once per character.",7);game.sound("reward")
 elif feature=="journal":game.notify(info().clue,9)
 else:game.notify("The sealed side passage opens. A stronger guardian watches its treasure.",6);game.sound("craft")
 mark(feature)
 if feature=="mechanism":
  game.dungeon_map=layout()
  for y in range(game.dungeon_map.size):
   for x in range(game.dungeon_map.size):game.astar.set_point_solid(Vector2i(x,y),not game.dungeon_map.grid[y][x])
  game.world.refresh(true)
 game.world.refresh_scenery(true);game.save_game();return true
func objective() -> String:
 if not has("mechanism"):return info().name.to_upper()+" · Find the "+("thaw brazier" if id()=="frost-cave" else "counterweight lever")+" · Entrance stairs: leave anytime"
 if not has("kill-2"):return info().name.to_upper()+" · Defeat "+info().boss+" · Optional treasure beyond the opened passage"
 return "GUARDIAN DEFEATED · Search the optional vault · Gold stairs return outside"
func advance() -> bool:
 if not game.castle.required_clear():return false
 game.leave_dungeon();return true
func checkpoint_defeat() -> bool:
 var loss=int(game.hero.gold*.15);game.hero.gold-=loss;game.hero.deaths+=1;game.expedition.reset_after_defeat()
 game.hero.hp=Data.max_hp(game.hero)*.65;game.hero.mp=Data.max_mp(game.hero)*.5
 game.build_floor(true);game.save_game();game.hud.show_pause("Expedition entrance · %d gold lost. Open passages, defeated foes and recovered treasure retained." % loss);return true
func prepare_attack(enemy:Dictionary) -> void:
 enemy["cave_pattern"]=enemy.get("cave_pattern",0)+1
 var slam=enemy.cave_pattern%2==0
 enemy.windup=.85 if enemy.hp<enemy.max_hp*.5 else 1.3
 enemy.strike_radius=95.0 if slam else 48.0
 enemy.strike=enemy.pos if slam else game.player_position()
 enemy["castle_attack"]=("ICE SHATTER" if id()=="frost-cave" else "ORE COLLAPSE") if slam else ("FROST MARK" if id()=="frost-cave" else "PICK STRIKE")
func traps() -> Array:return [Vector2i(16,11)] if id()=="frost-cave" else [Vector2i(15,14),Vector2i(19,26)]
func draw_traps(c:CanvasItem) -> void:
 for cell in traps():
  var p=game.cell_center(cell);var warning=fposmod(game.castle.trap_clock,4.0)>2.6
  c.draw_circle(p,27,Color(info().accent,.28 if warning else .08));c.draw_arc(p,27,0,TAU,16,info().accent if warning else info().accent.darkened(.6),2)
func tick(dt:float) -> void:
 if not game.playing or dt<=0:return
 var before=floori(game.castle.trap_clock/4.0);game.castle.trap_clock+=dt
 if floori(game.castle.trap_clock/4.0)==before:return
 for cell in traps():
  var p=game.cell_center(cell)
  if game.player_position().distance_to(p)<27 and game.dash_time<=0:
   game.hero.hp-=maxf(3,Data.max_hp(game.hero)*.04);game.floating(p,"ICE FISSURE" if id()=="frost-cave" else "FALLING ORE",info().accent)
func draw_rooms(c:CanvasItem,b:Rect2) -> void:
 var accent:Color=info().accent
 for i in range(rooms().size()):
  if i==4 and not has("mechanism"):continue
  var room=rooms()[i];var rect=Rect2(Vector2(room[0].position)*48,Vector2(room[0].size)*48)
  if not b.intersects(rect):continue
  c.draw_rect(rect.grow(-5),Color("183d4a77") if id()=="frost-cave" else Color("54493655"))
  c.draw_string(ThemeDB.fallback_font,rect.position+Vector2(14,30),room[1].to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,12,accent)
  if id()=="frost-cave":
   # Faceted ice is placed along chamber edges, leaving the route clear.
   for dx in range(28,int(rect.size.x)-20,65):
    var p=rect.position+Vector2(dx,rect.size.y-15)
    c.draw_colored_polygon(PackedVector2Array([p+Vector2(-13,0),p+Vector2(-8,-30),p+Vector2(0,-49),p+Vector2(10,-29),p+Vector2(15,0)]),accent.darkened(.35))
    c.draw_colored_polygon(PackedVector2Array([p,p+Vector2(0,-49),p+Vector2(10,-29),p+Vector2(15,0)]),accent)
   if i==1:
    var p=rect.position+Vector2(rect.size.x-62,85)
    c.draw_circle(p,42,Color("315e6a"));c.draw_arc(p,43,0,TAU,24,Color("87b4bb"),3)
  else:
   var x=rect.position.x+38
   for y in range(int(rect.position.y)+60,int(rect.end.y)-30,30):c.draw_line(Vector2(x-13,y),Vector2(x+33,y),Color("82704e"),5)
   for dx in [0,20]:c.draw_line(Vector2(x+dx,rect.position.y+50),Vector2(x+dx,rect.end.y-30),Color("a9a7a0"),3)
   # Braced timber supports and a wheeled mine cart have a readable silhouette.
   var p=rect.position+Vector2(rect.size.x-45,65)
   for dx in [-25,25]:c.draw_line(p+Vector2(dx,-15),p+Vector2(dx,48),Color("806346"),9)
   c.draw_line(p+Vector2(-31,-15),p+Vector2(31,-15),Color("a08057"),10)
   c.draw_rect(Rect2(p+Vector2(-19,15),Vector2(38,23)),Color("59656a"))
   for dx in [-12,12]:c.draw_circle(p+Vector2(dx,43),6,Color("272e34"));c.draw_circle(p+Vector2(dx,43),2,accent)
 for flag in features():
  if has(flag):continue
  if flag=="treasure" and not has("mechanism"):continue
  var p=game.cell_center(features()[flag].cell)
  if not b.grow(50).has_point(p):continue
  if flag=="treasure":game.world.field_visuals.draw_prop(c,"cache",p)
  elif flag=="journal":
   c.draw_rect(Rect2(p-Vector2(19,12),Vector2(38,26)),Color("c4b68f"));c.draw_line(p+Vector2(0,-11),p+Vector2(0,13),Color("655440"),2)
  else:
   c.draw_circle(p,20,Color("35454c"));c.draw_arc(p,21,0,TAU,20,accent,3)
   c.draw_line(p+Vector2(-5,9),p+Vector2(5,-15),accent,5)
  c.draw_string(ThemeDB.fallback_font,p+Vector2(-35,36),flag.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,11,accent)
