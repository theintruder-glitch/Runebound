extends RefCounted
const Catalog=preload("res://scripts/realm_catalog.gd")
const SITES={
 "frost-refuge":{"zone":"frostspire","point":Vector2(70,-1840),"name":"Frostfall Refuge","text":"A ruined mountain refuge shelters a surveyor's coffer. The citadel road crosses the ice ravine to the north.","gold":60},
 "frost-cave":{"zone":"frostspire","point":Vector2(-260,-2440),"name":"Glacier Hollow","text":"Blue crystals glitter inside the glacier's hidden mouth. A forgotten cache yields frost shards.","gold":75},
 "mire-watch":{"zone":"blackmire","point":Vector2(-1850,650),"name":"Sunken Watch","text":"The scout's last note: take the northern boardwalk, cross the blackwater, then climb the ruined causeway.","gold":60},
 "mire-grove":{"zone":"blackmire","point":Vector2(-3040,-140),"name":"Witchroot Grove","text":"A pilgrim's offering rests between the enormous roots. Blackmire's drainage wheel lies beyond its gate.","gold":75},
 "highland-mine":{"zone":"stormbreak","point":Vector2(1870,-260),"name":"Oathstone Mine","text":"The last miners sealed their crystal cache before the great bridge fell. A southern crossing still stands.","gold":60},
 "highland-camp":{"zone":"stormbreak","point":Vector2(2460,1030),"name":"Broken Siege Camp","text":"Wagon debris and abandoned siege supplies mark an army's last ascent toward Stormbreak.","gold":75}
}
var props=preload("res://scripts/realm_props.gd").new()
var game
var textures={}
var visible_zone=""
func zone_at(p:Vector2) -> String:return Catalog.zone_at(p)
func trail_distance(p:Vector2,id:String) -> float:return Catalog.distance_to_trail(p,Catalog.ZONES[id].trail)
func clear_route(p:Vector2) -> bool:
 if Catalog.side_trail(p):return true
 var id=zone_at(p)
 if id.is_empty():return false
 if trail_distance(p,id)<74 or p.distance_to(Catalog.ZONES[id].gate)<100:return true
 for site in SITES.values():
  if p.distance_to(site.point)<100:return true
 return false
func river_x(y:float) -> float:return -2180+sin(y/210.0)*50
func raw_solid(p:Vector2) -> bool:
 if Catalog.side_trail(p):return false
 var id=zone_at(p)
 if id.is_empty():return false
 if Catalog.foundation(id).has_point(p):return true
 # Access corridors always match the roads and bridge decks drawn below.
 if trail_distance(p,id)<56:return false
 match id:
  "frostspire":return Rect2(-380,-2250,1780,92).has_point(p) or p.distance_to(Vector2(-70,-2490))<118 or Rect2(420,-2500,800,65).has_point(p)
  "blackmire":return absf(p.x-river_x(p.y))<58 or Rect2(-3040,490,1000,58).has_point(p)
  "stormbreak":return absf(p.x-2400)<67 or Rect2(2280,760,1040,62).has_point(p)
 return false
func feature_id() -> String:
 if game.hero.dungeon!=null:return ""
 var p=game.player_position()
 for id in Catalog.ZONES:
  if p.distance_to(Catalog.ZONES[id].gate)<78:return id
 for id in SITES:
  var site=SITES[id]
  if (game.castle.caves.SITES.has(id) or not game.hero.opened.get(id,false)) and p.distance_to(site.point)<60 and game.line_clear(p,site.point):return id
 return ""
func interaction() -> String:
 var id=feature_id()
 if Catalog.ZONES.has(id):return "ENTER "+Catalog.ZONES[id].castle.to_upper()
 if game.castle.caves.SITES.has(id):return "ENTER "+SITES[id].name.to_upper()
 if SITES.has(id):return "EXPLORE "+SITES[id].name.to_upper()
 return ""
func interact() -> void:
 var id=feature_id()
 if Catalog.ZONES.has(id):game.castle.enter_region(id);return
 if not SITES.has(id):return
 if game.castle.caves.SITES.has(id):game.castle.caves.enter(id);return
 var site=SITES[id];var material=Catalog.ZONES[site.zone].material
 if game.survival.count(material)>99996:game.notify("Make room for 3 "+material+" and try again.",4);return
 game.hero.opened[id]=true;game.hero.gold+=site.gold;game.hero.essence+=2;game.survival.add(material,3)
 game.notify(site.text+" +%d gold, +2 essence, +3 %s." % [site.gold,material],8);game.sound("reward");game.world.refresh_scenery(true);game.save_game()
func terrain_id(p:Vector2,base:int) -> int:
 var id=zone_at(p)
 return (base if id=="stormbreak" and base==7 else Catalog.ZONES[id].floor) if not id.is_empty() else base
func polygon(c:CanvasItem,points:Array,color:Color) -> void:c.draw_colored_polygon(PackedVector2Array(points),color)
func cliff(c:CanvasItem,a:Vector2,b:Vector2,accent:Color) -> void:
 var v=(b-a).normalized();var n=Vector2(-v.y,v.x);var top=PackedVector2Array();var foot=PackedVector2Array()
 var count=maxi(2,ceili(a.distance_to(b)/24))
 for i in range(count+1):
  var p=a.lerp(b,float(i)/count);var j=sin(i*2.4)*6
  top.append(p+n*j);foot.append(p+n*(72+j*.6))
 var face=top.duplicate();var reverse=foot.duplicate();reverse.reverse();face.append_array(reverse)
 c.draw_polyline(foot,Color("101b2588"),26,true);c.draw_colored_polygon(face,Color("48555e"))
 for i in range(count):
  if i%2==0:polygon(c,[top[i],top[i+1],foot[i+1],foot[i]],Color("687279"))
  c.draw_line(top[i]+n*8,foot[i]-n*10,Color("273641"),2,true)
 c.draw_polyline(top,accent.darkened(.25),8,true)
 for k in [20,42,60]:c.draw_polyline(PackedVector2Array([a+n*k,b+n*k]),Color("9a9b9c33"),1,true)
func draw_bridge(c:CanvasItem,p:Vector2,vertical:bool,stone:bool,accent:Color) -> void:
 c.draw_set_transform(p,PI/2 if vertical else 0)
 c.draw_rect(Rect2(-125,28,250,40),Color("09152277"))
 c.draw_rect(Rect2(-125,-48,250,96),Color("5e6b70") if stone else Color("67563d"))
 for x in range(-120,125,16):
  c.draw_rect(Rect2(x,-42,14,84),Color("a5b6bc") if stone else Color("a38c61"));c.draw_line(Vector2(x,-40),Vector2(x,40),Color("334550"),1)
 for y in [-48,48]:
  c.draw_line(Vector2(-133,y),Vector2(133,y),accent.darkened(.15),8)
  for x in [-125,-65,65,125]:c.draw_rect(Rect2(x-5,y-18,10,24),Color("b7b8a1"))
 c.draw_set_transform(Vector2.ZERO)
func mountain(c:CanvasItem,p:Vector2,r:float,snow:bool) -> void:
 props.draw(c,"snow-mountain" if snow else "mountain",p+Vector2(0,70),Vector2(r*2.1,r*2.1))
func tree_roots(c:CanvasItem,p:Vector2) -> void:
 props.draw(c,"swamp-tree",p,Vector2(200,235))
func draw(c:CanvasItem,b:Rect2) -> void:
 var id=zone_at(game.player_position())
 if id!=visible_zone:textures.clear();visible_zone=id
 for zone in Catalog.ZONES:
  var info=Catalog.ZONES[zone]
  if not b.intersects(info.area.grow(400)):continue
  var accent:Color=info.accent
  if zone=="frostspire":
   for p in [Vector2(-210,-2700),Vector2(500,-3040),Vector2(1140,-2700)]:
    if b.grow(350).has_point(p):mountain(c,p,280,true)
   c.draw_circle(Vector2(-70,-2490),124,Color("527b91"));c.draw_arc(Vector2(-70,-2490),118,0,TAU,32,Color("bddce8"),8)
   cliff(c,Vector2(-380,-2250),Vector2(200,-2250),Color("c9dfe2"));cliff(c,Vector2(360,-2250),Vector2(1400,-2250),Color("c9dfe2"))
   draw_bridge(c,Vector2(280,-2204),true,true,accent)
   cliff(c,Vector2(420,-2500),Vector2(705,-2500),accent);cliff(c,Vector2(875,-2500),Vector2(1220,-2500),accent)
  elif zone=="blackmire":
   var l=PackedVector2Array();var r=PackedVector2Array()
   for y in range(-900,1001,18):l.append(Vector2(river_x(y)-65,y));r.append(Vector2(river_x(y)+65,y))
   var water=l.duplicate();var back=r.duplicate();back.reverse();water.append_array(back);c.draw_colored_polygon(water,Color("172f39"));c.draw_polyline(l,Color("4e6453"),9,true);c.draw_polyline(r,Color("3b4a43"),10,true)
   for p in [Vector2(-1850,650),Vector2(-3040,-140),Vector2(-2950,-150)]:
    if b.grow(150).has_point(p):tree_roots(c,p+Vector2(-90,-70))
   cliff(c,Vector2(-3040,490),Vector2(-2600,490),Color("647d57"));cliff(c,Vector2(-2410,490),Vector2(-2040,490),Color("647d57"))
   draw_bridge(c,Vector2(river_x(180),180),false,false,Color("919b71"))
  else:
   for p in [Vector2(1660,-700),Vector2(2940,-620),Vector2(3180,500)]:
    if b.grow(350).has_point(p):mountain(c,p,250,false)
   c.draw_rect(Rect2(2333,-1250,134,2600),Color("152631"));cliff(c,Vector2(2333,-1250),Vector2(2333,330),accent);cliff(c,Vector2(2333,530),Vector2(2333,1350),accent)
   draw_bridge(c,Vector2(2400,430),false,true,accent)
   cliff(c,Vector2(2280,760),Vector2(2350,760),Color("8a9784"));cliff(c,Vector2(2530,760),Vector2(3320,760),Color("8a9784"))
  var path=PackedVector2Array(info.trail)
  c.draw_polyline(path,Color("10232966"),78,true);c.draw_polyline(path,Color("81969d") if zone=="frostspire" else Color("716a52"),58,true);c.draw_polyline(path,Color("cbd8c933"),40,true)
  # Draw bridge surfaces after paths, keeping handrails readable.
  if zone=="frostspire":draw_bridge(c,Vector2(280,-2204),true,true,accent)
  elif zone=="blackmire":draw_bridge(c,Vector2(river_x(180),180),false,false,Color("919b71"))
  else:draw_bridge(c,Vector2(2400,430),false,true,accent)
  var ramp=Vector2(800,-2460) if zone=="frostspire" else Vector2(-2440,515) if zone=="blackmire" else Vector2(2440,790)
  for dy in range(-40,45,10):c.draw_line(ramp+Vector2(-55,dy),ramp+Vector2(55,dy),Color("d0bea477"),3,true)
  var rect=Rect2(info.gate-Vector2(350,650),Vector2(700,650))
  if b.intersects(rect):
   if not textures.has(zone) and ResourceLoader.exists(info.image):textures[zone]=load(info.image)
   if textures.has(zone):c.draw_texture_rect(textures[zone],rect,false)
   c.draw_string(ThemeDB.fallback_font,info.gate+Vector2(-110,35),info.castle.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("e0cb92"))
 for trail in Catalog.SIDE_TRAILS.values():
  var route=PackedVector2Array(trail)
  c.draw_polyline(route,Color("182b3266"),44,true);c.draw_polyline(route,Color("8e95816b"),30,true)
 for site_id in SITES:
  var site=SITES[site_id];var p:Vector2=site.point
  if not b.grow(120).has_point(p):continue
  if "cave" in site_id or "mine" in site_id:
   polygon(c,[p+Vector2(-62,15),p+Vector2(-48,-55),p+Vector2(-9,-82),p+Vector2(39,-56),p+Vector2(64,17)],Color("576d73"));c.draw_arc(p,34,PI,TAU,16,Color("16252e"),28,true)
  else:game.world.field_visuals.draw_prop(c,"cart" if "camp" in site_id else "watch",p)
  if not game.hero.opened.get(site_id,false) and not game.castle.caves.SITES.has(site_id):game.world.field_visuals.draw_prop(c,"cache",p+Vector2(0,15))
  c.draw_string(ThemeDB.fallback_font,p+Vector2(-60,55),site.name.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("cdbd9c"))
func atmosphere(c:CanvasItem,b:Rect2,clock:float) -> void:
 var id=zone_at(game.player_position())
 if id.is_empty() or not game.weather.particles_enabled:return
 var accent:Color=Catalog.ZONES[id].accent
 if game.graphics.enhanced():
  for i in range(2):
   var p=b.position+Vector2(fposmod(clock*9+i*410,b.size.x+240)-120,110+i*240)
   c.draw_set_transform(p,-.15,Vector2(3.4,.7));c.draw_circle(Vector2.ZERO,70,Color("0a1e2510"));c.draw_set_transform(Vector2.ZERO)
 var count=6 if game.low_power else 12
 for i in range(count):
  var p=b.position+Vector2(fposmod(clock*(7 if id=="blackmire" else 28)+i*131,b.size.x),fposmod(i*173+sin(clock*.3+i)*20,b.size.y))
  if id=="blackmire":
   c.draw_set_transform(p,0,Vector2(3,.6));c.draw_circle(Vector2.ZERO,48,Color(.42,.49,.52,.035));c.draw_set_transform(Vector2.ZERO);c.draw_circle(p+Vector2(20,-20),2,Color(accent,.4))
  elif id=="frostspire":c.draw_circle(p,1.5,Color("e1f3f366"))
  else:c.draw_line(p,p+Vector2(18,-3),Color("b8c8d522"),1,true)
