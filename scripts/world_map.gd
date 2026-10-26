extends Control
signal marker_selected(id:String)
var game
var selected="forest"
var local_view=false
var world_bounds=Rect2(-3200,-3000,6400,6000)
var markers:Dictionary={}
var player_marker=Vector2.ZERO
const OVERVIEW=Rect2(-3200,-3000,6400,6000)
func position_in_wilds() -> Vector2:
 var point=game.player_position() if game.hero.dungeon==null else Vector2(game.hero.dungeon.returnX,game.hero.dungeon.returnY)
 return point if point.is_finite() else Vector2.ZERO
func inner_size() -> Vector2: return (size-Vector2(20,20)).max(Vector2.ONE)
func _ready() -> void:
 if custom_minimum_size.y<=0: custom_minimum_size.y=330
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 mouse_filter=Control.MOUSE_FILTER_STOP
 clip_contents=true
 resized.connect(queue_redraw)
func canvas_point(at:Vector2) -> Vector2:
 return Vector2(10,10)+(at-world_bounds.position)/world_bounds.size*inner_size()
func world_point(at:Vector2) -> Vector2:
 return world_bounds.position+(at-Vector2(10,10))/inner_size()*world_bounds.size
func refresh_bounds() -> void:
 if local_view:
  world_bounds=Rect2(position_in_wilds()-Vector2(1000,1000),Vector2(2000,2000))
 else:
  var low=OVERVIEW.position;var high=OVERVIEW.end
  for point in [position_in_wilds(),Vector2(game.hero.respawn.x,game.hero.respawn.y)]:
   if not point.is_finite(): continue
   low=low.min(point-Vector2(640,640));high=high.max(point+Vector2(640,640))
  # Grow in stable blocks so walking does not continuously reframe the overview.
  if low.x<OVERVIEW.position.x: low.x=floorf(low.x/1000)*1000
  if low.y<OVERVIEW.position.y: low.y=floorf(low.y/1000)*1000
  if high.x>OVERVIEW.end.x: high.x=ceilf(high.x/1000)*1000
  if high.y>OVERVIEW.end.y: high.y=ceilf(high.y/1000)*1000
  world_bounds=Rect2(low,high-low)
func _draw() -> void:
 if game==null or game.hero.is_empty(): return
 markers.clear()
 if size.x<40 or size.y<40: return
 refresh_bounds()
 var colors={"forest":Color("305b43"),"caves":Color("46465c"),"swamp":Color("314e55"),"snow":Color("a6c5d0")}
 var inner=size-Vector2(20,20)
 for x in range(18):
  for y in range(18):
   var rect=Rect2(Vector2(10,10)+Vector2(x,y)*inner/18,inner/18+Vector2.ONE)
   var id=game.exploration.region_at(world_point(rect.get_center()))
   var color=colors[id]
   if not game.hero.exploration.visited.get(id,false): color=color.darkened(.5)
   draw_rect(rect,color)
 # Use the same authored coordinates as collision and landscape rendering.
 if world_bounds.intersects(game.landscape.AREA):
  var river=PackedVector2Array()
  for y in range(648,1393,24):river.append(canvas_point(Vector2(game.landscape.river_x(y),y)))
  draw_polyline(river,Color("77b7c8"),maxf(2,84*inner.x/world_bounds.size.x),true)
  var trail=PackedVector2Array()
  for p in game.landscape.TRAIL:trail.append(canvas_point(p))
  draw_polyline(trail,Color("d0b77c"),2,true)
  var bridge=canvas_point(Vector2(game.landscape.river_x(912),912))
  draw_line(bridge-Vector2(6,0),bridge+Vector2(6,0),Color("f4dfb3"),4)
 draw_rect(Rect2(Vector2(10,10),inner),Color("b2c6b188"),false,2)
 for id in game.exploration.REGIONS:
  var info=game.exploration.REGIONS[id]
  marker(id,info.point,info.landmark,game.hero.exploration.discovered.get(id,false),game.hero.journey.warden if id=="forest" else game.hero.exploration.challenges.get(id,false))
 for id in game.landscape.realms.Catalog.ZONES:
  var zone=game.landscape.realms.Catalog.ZONES[id]
  var path=PackedVector2Array()
  for p in zone.trail:path.append(canvas_point(p))
  draw_polyline(path,Color(zone.accent,.6),1.5,true)
  marker(id,zone.gate,zone.castle,true,game.hero.opened.get(id+"-cleared",false))
 for trail in game.landscape.realms.Catalog.SIDE_TRAILS.values():
  var route=PackedVector2Array()
  for p in trail:route.append(canvas_point(p))
  draw_polyline(route,Color("c5b788"),1.5,true)
 for id in game.castle.caves.SITES:
  var cave=game.castle.caves.SITES[id]
  marker(id,cave.point,cave.name,true,game.hero.opened.get(id+"-cleared",false))
 marker("keep",game.landscape.KEEP,"Thornwatch",true,game.hero.opened.get("thornwatch-cleared",false))
 marker("trader",game.trader.POSITION,"Mara",true,false)
 marker("ruins",game.exploration.RUINS,"Ruins",game.hero.journey.dungeon_entered,game.hero.journey.first_floor)
 var home=Vector2(game.hero.respawn.x,game.hero.respawn.y)
 marker("home",home,"Home",true,false)
 for structure in game.hero.survival.structures:
  var point=canvas_point(Vector2(structure.x,structure.y))
  if Rect2(Vector2(12,12),size-Vector2(24,24)).has_point(point): draw_rect(Rect2(point-Vector2(2,2),Vector2(4,4)),Color("e0d4a8"))
 var player=canvas_point(position_in_wilds())
 player_marker=player
 draw_circle(player,12,Color("11232ed9"))
 var angle=game.facing.angle()+PI/2
 draw_colored_polygon(PackedVector2Array([player+Vector2(0,-9).rotated(angle),player+Vector2(-6,6).rotated(angle),player+Vector2(6,6).rotated(angle)]),Color("f9f3d6"))
 draw_string(ThemeDB.fallback_font,Vector2(size.x-29,25),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("f4e5b9"))
func marker(id:String,pos:Vector2,title:String,known:bool,complete:bool) -> void:
 var point=canvas_point(pos)
 if not Rect2(Vector2(18,18),size-Vector2(36,36)).has_point(point): return
 markers[id]=point
 var color=Color("ebcf91") if complete or id=="home" else Color("a5dace") if known else Color("a5afb1")
 draw_circle(point,7,color if known else color.darkened(.5))
 draw_arc(point,12 if selected==id else 9,0,TAU,24,color,2)
 var caption=title if known else title+" ?"
 var font=ThemeDB.fallback_font
 var width=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
 var label_x=clampf(point.x-width/2,12,maxf(12,size.x-width-12))
 var label_y=point.y+24
 if id=="trader":
  label_x=clampf(point.x-width-14,12,maxf(12,size.x-width-12));label_y=point.y+4
 elif id=="forest": label_y=point.y-14
 draw_string(font,Vector2(label_x,clampf(label_y,24,size.y-12)),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,11,color)
func _gui_input(event:InputEvent) -> void:
 var pressed=(event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.device!=-1 and event.button_index==MOUSE_BUTTON_LEFT and event.pressed)
 if not pressed: return
 var best="";var distance=25.0
 for id in markers:
  var candidate=event.position.distance_to(markers[id])
  if candidate<distance: distance=candidate;best=id
 if not best.is_empty():
  selected=best;marker_selected.emit(best);queue_redraw();accept_event()
