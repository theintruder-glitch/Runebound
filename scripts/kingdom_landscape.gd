extends RefCounted
# Hand-authored first zone; old region IDs and saved coordinates remain stable.
const AREA=Rect2(96,648,1200,744)
const KEEP=Vector2(1040,1240)
const CASTLE=preload("res://assets/thornwatch.png")
const TRAIL=[Vector2(170,690),Vector2(240,820),Vector2(390,912),Vector2(590,912),Vector2(780,1010),Vector2(780,1120),Vector2(780,1320),Vector2(1040,1320),KEEP]
const CAMP=Vector2(220,1060)
const SITES={
 "emerald-falls-cache":{"point":Vector2(305,785),"name":"Fallkeeper Cache","text":"A sealed coffer rests above the waterfall. +45 gold, +2 essence.","gold":45,"essence":2},
 "emerald-moon-grove":{"point":Vector2(600,1240),"name":"Moonroot Grove","text":"The old inscription names Thornwatch: cross Old King's Bridge, follow the eastern ramp, seek the green gate. +3 essence.","gold":0,"essence":3}
}
var realms=preload("res://scripts/realm_landscapes.gd").new()
var game:
 set(value):
  game=value;realms.game=value
var road=PackedVector2Array()
func _init() -> void:
 var curve=Curve2D.new()
 for i in range(TRAIL.size()):
  var tangent=(TRAIL[mini(TRAIL.size()-1,i+1)]-TRAIL[maxi(0,i-1)]).limit_length(160)*.22
  curve.add_point(TRAIL[i],-tangent,tangent)
 road=curve.get_baked_points()
func intersects_authored(a:Vector2,b:Vector2) -> bool:
 var bounds=Rect2(a.min(b),(a-b).abs()+Vector2.ONE)
 if bounds.intersects(AREA):return true
 for info in realms.Catalog.ZONES.values():
  if bounds.intersects(info.area):return true
 return false
func inside(p:Vector2) -> bool:return AREA.has_point(p)
func river_x(y:float) -> float:return 460+sin((y-650)/180)*42
func bridge(p:Vector2) -> bool:return absf(p.y-912)<44 and absf(p.x-river_x(p.y))<100
func trail_distance(p:Vector2) -> float:
 var d=1e9
 for i in range(TRAIL.size()-1):d=minf(d,Geometry2D.get_closest_point_to_segment(p,TRAIL[i],TRAIL[i+1]).distance_to(p))
 return d
func raw_solid(p:Vector2) -> bool:
 if not inside(p):return realms.raw_solid(p)
 if Rect2(KEEP-Vector2(235,480),Vector2(470,420)).has_point(p):return true
 if bridge(p):return false
 if absf(p.x-river_x(p.y))<42 or p.distance_to(Vector2(250,1240))<88:return true
 return absf(p.y-1060)<27 and p.x>570 and p.x<1230 and absf(p.x-780)>=64
func solid(p:Vector2) -> bool:
 if not raw_solid(p):return false
 for s in game.hero.survival.structures:
  if game.survival.footprint(s.kind,game.survival.at(s),int(s.get("rotation",0))).grow(32).has_point(p):return false
 return true
func elevation(p:Vector2) -> int:return (2 if p.y>1087 else 1 if p.x>560 else 0) if inside(p) else 0
func terrain_id(p:Vector2,base:int) -> int:return (1 if elevation(p)>0 else 0) if inside(p) else realms.terrain_id(p,base)
func clear_route(p:Vector2) -> bool:
 for site in SITES.values():
  if p.distance_to(site.point)<100:return true
 return realms.clear_route(p) or inside(p) and (Rect2(KEEP-Vector2(300,600),Vector2(600,600)).has_point(p) or trail_distance(p)<60 or bridge(p) or absf(p.x-780)<64 and absf(p.y-1060)<100 or p.distance_to(KEEP)<130)
func site_near() -> String:
 if game.hero.dungeon!=null:return ""
 for id in SITES:
  var p:Vector2=SITES[id].point
  if not game.hero.opened.get(id,false) and game.player_position().distance_to(p)<58 and game.line_clear(game.player_position(),p):return id
 return ""
func feature_near() -> String:
 if game.hero.dungeon!=null:return ""
 if not realms.interaction().is_empty():return realms.interaction()
 if not site_near().is_empty():return "EXPLORE "+SITES[site_near()].name.to_upper()
 if game.player_position().distance_to(KEEP)<90:return "ENTER THORNWATCH KEEP"
 if game.player_position().distance_to(CAMP)<65 and not game.hero.opened.get("emerald-woodcutters",false):return "SEARCH WOODCUTTER CAMP"
 return ""
func interact() -> void:
 if game.hero.dungeon!=null:return
 if not realms.interaction().is_empty():realms.interact();return
 var site_id=site_near()
 if not site_id.is_empty():
  game.hero.opened[site_id]=true;game.hero.gold+=SITES[site_id].gold;game.hero.essence+=SITES[site_id].essence
  game.notify(SITES[site_id].text,8);game.sound("reward");game.world.refresh_scenery(true);game.save_game();return
 if game.player_position().distance_to(KEEP)<90:game.castle.enter();return
 if feature_near()=="SEARCH WOODCUTTER CAMP" and game.survival.count("Wood")<=99995 and game.survival.count("Roasted berries")<=99997:
  game.hero.opened["emerald-woodcutters"]=true;game.survival.add("Wood",4);game.survival.add("Roasted berries",2);game.hero.gold+=25;game.notify("Lost camp · +4 wood, +2 roasted berries, +25 gold",5);game.save_game()
 elif feature_near()=="SEARCH WOODCUTTER CAMP":game.notify("Make room for 4 wood and 2 roasted berries, then search again.",4)
func draw_cliff(c:CanvasItem,start:float,finish:float) -> void:
 var top=PackedVector2Array();var foot=PackedVector2Array()
 for x in range(int(start),int(finish)+1,12):
  top.append(Vector2(x,1032+sin(x*.047)*5+sin(x*.109)*3))
  foot.append(Vector2(x,1094+sin(x*.036)*7))
 var face=top.duplicate();var reversed=foot.duplicate();reversed.reverse();face.append_array(reversed)
 c.draw_polyline(foot,Color("142b2777"),24,true);c.draw_colored_polygon(face,Color("4c5852"))
 for x in range(int(start)+8,int(finish)-8,23):
  var y=1032+sin(x*.047)*5+sin(x*.109)*3;var base=1094+sin(x*.036)*7
  c.draw_colored_polygon(PackedVector2Array([Vector2(x,y),Vector2(x+12,y+5),Vector2(x+8,base-8),Vector2(x-4,base)]),Color("647064") if x%3 else Color("56635b"))
  c.draw_polyline(PackedVector2Array([Vector2(x+12,y+7),Vector2(x+7,y+29),Vector2(x+10,base-6)]),Color("293c34"),1.5,true)
  for j in range(3):
   var sy=y+17+j*16;c.draw_line(Vector2(x-6,sy),Vector2(x+15,sy+3),Color("9fa28a33"),1,true)
 c.draw_polyline(top,Color("7b9469"),10,true);c.draw_polyline(top,Color("a2ae7a66"),2,true)
 for x in range(int(start)+7,int(finish)-10,33):
  var p=Vector2(x,1100+sin(x*.036)*7)
  c.draw_colored_polygon(PackedVector2Array([p+Vector2(-9,1),p+Vector2(-5,-5),p+Vector2(4,-7),p+Vector2(10,0),p+Vector2(3,4)]),Color("718071"))
  if x%2:c.draw_polyline(PackedVector2Array([Vector2(x,1036),Vector2(x-3,1052),Vector2(x+2,1060)]),Color("66815a"),3,true)
func draw(c:CanvasItem,b:Rect2) -> void:
 realms.draw(c,b)
 if not b.intersects(AREA.grow(600)):return
 for p in [Vector2(760,815),Vector2(1130,880),Vector2(200,770)]:
  if not b.grow(250).has_point(p):continue
  for i in range(6):
   var contour=PackedVector2Array()
   for k in range(36):
    var angle=k*TAU/36;var r=(235-i*20)*(1+sin(angle*3+p.x)*.065+cos(angle*5)*.035)
    contour.append(p+Vector2(cos(angle)*r,sin(angle)*r*.45+i*4))
   c.draw_colored_polygon(contour,Color("71995d0b"))
 var left=PackedVector2Array();var right=PackedVector2Array()
 for y in range(648,1393,12):left.append(Vector2(river_x(y)-50-sin(y*.073)*3,y));right.append(Vector2(river_x(y)+50+cos(y*.061)*4,y))
 var water=left.duplicate();right.reverse();water.append_array(right)
 c.draw_colored_polygon(water,Color("193b48"));c.draw_polyline(left,Color("657a67"),9,true);c.draw_polyline(right,Color("1c2e33"),12,true)
 for y in range(672,1380,47):
  var q=Vector2(river_x(y)-61,y)
  if not b.grow(50).has_point(q) or bridge(q):continue
  c.draw_circle(q,8,Color("536e55"));c.draw_line(q+Vector2(-4,0),q+Vector2(-7,-17),Color("81946b"),2,true);c.draw_line(q,q+Vector2(4,-23),Color("8b9a70"),2,true)
 if b.intersects(Rect2(570,1015,680,110)):draw_cliff(c,574,706);draw_cliff(c,850,1234)
 c.draw_polyline(road,Color("23372b77"),65,true);c.draw_polyline(road,Color("70664a"),52,true);c.draw_polyline(road,Color("94836044"),39,true)
 for i in range(4,road.size()-2,8):
  var q=road[i]+Vector2(sin(i*8.3)*19,cos(i*3.2)*12)
  if not b.has_point(q) or bridge(q):continue
  c.draw_line(q-Vector2(3,0),q+Vector2(4,1),Color("b0a48055"),2,true);c.draw_circle(q+Vector2(8,8),2,Color("4f594240"))
 var bx=river_x(912)
 c.draw_rect(Rect2(bx-102,870,204,84),Color("36372e"))
 for x in range(int(bx)-96,int(bx)+102,12):c.draw_rect(Rect2(x,875,10,74),Color("9d8a5d"));c.draw_line(Vector2(x,877),Vector2(x,945),Color("c1aa77"),1)
 for y in [871,953]:c.draw_line(Vector2(bx-105,y),Vector2(bx+105,y),Color("b6aa85"),8)
 for x in [bx-102,bx+102]:
  for y in [865,949]:c.draw_rect(Rect2(x-7,y-12,14,24),Color("9c9d7a"));c.draw_rect(Rect2(x-9,y-15,18,5),Color("c2bb94"))
 for y in range(1020,1110,12):c.draw_line(Vector2(722,y),Vector2(838,y),Color("b6a47c"),3)
 c.draw_circle(Vector2(250,1240),88,Color("203f48"));c.draw_arc(Vector2(250,1240),90,0,TAU,40,Color("708b83"),6)
 var falls=Vector2(river_x(702),702)
 for side in [-1,1]:
  var p=falls+Vector2(side*52,12)
  c.draw_colored_polygon(PackedVector2Array([p+Vector2(-24,-37),p+Vector2(-8,-48),p+Vector2(20,-31),p+Vector2(28,-9),p+Vector2(17,31),p+Vector2(-6,43),p+Vector2(-30,16)]),Color("53685f"))
  c.draw_polyline(PackedVector2Array([p+Vector2(-24,-37),p+Vector2(-8,-48),p+Vector2(20,-31)]),Color("88967a"),6,true)
  for i in range(3):c.draw_line(p+Vector2(-14,-15+i*15),p+Vector2(18,-19+i*17),Color("2f4a4266"),2,true)
 if b.grow(120).has_point(CAMP):game.world.field_visuals.draw_prop(c,"watch",CAMP);game.world.field_visuals.draw_prop(c,"Wood",CAMP+Vector2(65,30))
 for id in SITES:
  var site=SITES[id];var p:Vector2=site.point
  if not b.grow(230).has_point(p):continue
  if id=="emerald-moon-grove":
   realms.props.draw(c,"oak",p+Vector2(10,-55),Vector2(250,285))
   c.draw_arc(p,38,0,TAU,24,Color("a9bc8d"),3)
   for dx in [-34,34]:c.draw_rect(Rect2(p+Vector2(dx-7,-28),Vector2(14,32)),Color("7e8f77"));c.draw_line(p+Vector2(dx,-21),p+Vector2(dx,-4),Color("aacdb3"),3)
  elif not game.hero.opened.get(id,false):game.world.field_visuals.draw_prop(c,"cache",p)
  c.draw_string(ThemeDB.fallback_font,p+Vector2(-50,42),site.name.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("d3c597"))
 var castle_rect=Rect2(KEEP-Vector2(300,600),Vector2(600,600))
 if b.intersects(castle_rect):c.draw_texture_rect(CASTLE,castle_rect,false);c.draw_string(ThemeDB.fallback_font,KEEP+Vector2(-95,36),"THORNWATCH KEEP",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("dfc98f"))
func atmosphere(c:CanvasItem,b:Rect2,clock:float) -> void:
 realms.atmosphere(c,b,clock)
 if game.weather.particles_enabled:
  var count=0
  for d in game.world.scenery.decorations:
   if d.kind!="tree" or not b.has_point(d.pos):continue
   var p:Vector2=d.pos+Vector2(sin(clock*1.8+d.pos.x)*3,-78)
   c.draw_line(p-Vector2(5,0),p+Vector2(5,-2),Color("a5ba7b44"),2,true)
   count+=1
   if count>=(4 if game.low_power else 8):break
 if not b.intersects(AREA):return
 var p=Vector2(river_x(702),702)
 if b.grow(100).has_point(p):
  c.draw_colored_polygon(PackedVector2Array([p+Vector2(-30,-25),p+Vector2(29,-25),p+Vector2(37,79),p+Vector2(21,90),p+Vector2(-35,83)]),Color("86bac4"))
  for i in range(6):
   var q=p+Vector2(-22+i*9,fposmod(clock*38+i*17,64));c.draw_line(q,q+Vector2(0,25),Color("c0ddd9"),2)
  for i in range(4):c.draw_circle(p+Vector2(-25+i*17,83+sin(clock*2+i)*4),9,Color("d6e7df66"))
 for i in range(8):
  var y=690+fposmod(clock*20+i*83,660);var q=Vector2(river_x(y),y)
  if b.has_point(q) and not bridge(q):c.draw_arc(q,13,0,PI,8,Color("91b9bd66"),1)
