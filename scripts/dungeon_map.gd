extends Control
signal destination_selected(id:String)
var game
var selected="entrance"
var markers={}
var player_marker=Vector2.ZERO
var scale_value=1.0
var origin=Vector2.ZERO
var render_key=""
func _ready():
 mouse_filter=Control.MOUSE_FILTER_PASS;size_flags_horizontal=Control.SIZE_EXPAND_FILL
 resized.connect(queue_redraw)
func canvas_point(p:Vector2) -> Vector2:return origin+p/48.0*scale_value
func _process(_dt:float):
 if game==null or not game.atlas.active():return
 var key=str(game.player_position())+str(game.facing)+str(game.atlas.revision)+selected
 if key!=render_key:render_key=key;queue_redraw()
func _draw():
 markers.clear()
 if game==null or not game.atlas.active() or size.x<40 or size.y<40:return
 var map=game.dungeon_map;scale_value=minf((size.x-24)/map.size,(size.y-24)/map.size);origin=(size-Vector2.ONE*map.size*scale_value)/2
 draw_style_box(panel(),Rect2(Vector2.ZERO,size))
 for cell in map.floors:
  if not game.atlas.known(cell):continue
  draw_rect(Rect2(canvas_point(Vector2(cell)*48),Vector2.ONE*maxf(1,scale_value-.7)),Color("617d79"))
 var route=game.atlas.route(selected)
 if route.size()>1:
  var points=PackedVector2Array()
  for p in route:points.append(canvas_point(p))
  draw_polyline(points,Color("e6c67a"),2,true)
 var places=game.atlas.destinations()
 for id in places:
  var info=places[id];var p=canvas_point(game.cell_center(info.cell));markers[id]=p
  var color=Color("a6e0c5") if id=="entrance" else Color("e8c97e") if id=="stairs" else Color("cbb0eb") if id.begins_with("feature:") else Color("b3c4c3")
  draw_circle(p,4 if id.begins_with("room:") else 6,color)
  if id==selected:draw_arc(p,10,0,TAU,24,Color("fff0bc"),2)
 player_marker=canvas_point(game.player_position())
 var angle=game.facing.angle()+PI/2
 draw_circle(player_marker,10,Color("10252e"))
 draw_colored_polygon(PackedVector2Array([player_marker+Vector2(0,-8).rotated(angle),player_marker+Vector2(-5,5).rotated(angle),player_marker+Vector2(5,5).rotated(angle)]),Color("f9f1ce"))
 draw_string(ThemeDB.fallback_font,Vector2(12,size.y-9),"N ↑ · White arrow: you",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("d6d8be"))
func panel() -> StyleBoxFlat:
 var style=StyleBoxFlat.new();style.bg_color=Color("10262c");style.border_color=Color("637b73");style.set_border_width_all(1);style.set_corner_radius_all(10);return style
func _gui_input(event:InputEvent):
 var pressed=event is InputEventScreenTouch and event.pressed or event is InputEventMouseButton and event.device!=-1 and event.button_index==MOUSE_BUTTON_LEFT and event.pressed
 if not pressed:return
 var best="";var distance=22.0
 for id in markers:
  var d=event.position.distance_to(markers[id])
  if d<distance:distance=d;best=id
 if not best.is_empty():selected=best;destination_selected.emit(best);queue_redraw();accept_event()
