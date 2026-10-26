extends Control

var game
var finger=-1
var direction=Vector2.ZERO
var mode="joystick"
var floating=false
var sensitivity=1.0
var dead_zone=.12
var spacing=.08
var input_enabled=true
var fingers:Dictionary={}
var origin=Vector2.ZERO
var touch_origin=Vector2.ZERO
var accent=Color("c6d8bb")

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(func():
		if not is_visible_in_tree(): reset())

func available() -> bool: return input_enabled and is_visible_in_tree() and game!=null and game.playing

func accepts(at:Vector2) -> bool:
	if get_global_rect().has_point(at): return true
	if not floating or mode!="joystick" or game.hud==null: return false
	var safe=game.hud.controls.safe_rect();var right=get_global_rect().get_center().x>safe.get_center().x
	var area=Rect2(Vector2(safe.get_center().x if right else safe.position.x,safe.position.y+safe.size.y*.3),Vector2(safe.size.x*.5,safe.size.y*.7))
	return area.has_point(at) and not game.hud.controls.over_button(at)

func _input(event:InputEvent) -> void:
	if not available():
		if finger!=-1 or not fingers.is_empty(): reset()
		return
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled and accepts(event.position):
			if mode=="dpad":
				fingers[event.index]=dpad_direction(event.position);update_dpad()
			elif finger==-1: begin(event.index,event.position)
			else: return
			get_viewport().set_input_as_handled()
		elif not event.pressed or event.canceled:
			if mode=="dpad" and fingers.has(event.index):
				fingers.erase(event.index);update_dpad();get_viewport().set_input_as_handled()
			elif finger==event.index: reset();get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if mode=="dpad" and fingers.has(event.index):
			fingers[event.index]=dpad_direction(event.position);update_dpad();get_viewport().set_input_as_handled()
		elif event.index==finger: move_knob(event.position);get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.device!=-1 and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed and finger==-1 and fingers.is_empty() and accepts(event.position):
			if mode=="dpad": fingers[-2]=dpad_direction(event.position);update_dpad()
			else: begin(-2,event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed:
			if mode=="dpad" and fingers.has(-2): fingers.erase(-2);update_dpad();get_viewport().set_input_as_handled()
			elif finger==-2: reset();get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if mode=="dpad" and fingers.has(-2): fingers[-2]=dpad_direction(event.position);update_dpad();get_viewport().set_input_as_handled()
		elif finger==-2: move_knob(event.position);get_viewport().set_input_as_handled()

func begin(index:int,at:Vector2) -> void:
	finger=index
	origin=at-global_position if floating else size/2
	touch_origin=origin
	if floating and game.hud!=null:
		var safe=game.hud.controls.safe_rect()
		origin=(at.clamp(safe.position+size/2,safe.end-size/2))-global_position
	move_knob(at)

func move_knob(at:Vector2) -> void:
	var offset=(at-global_position-touch_origin)/(size.x*.33)*sensitivity
	var strength=clampf((offset.length()-dead_zone)/(1.0-dead_zone),0,1)
	direction=offset.normalized()*strength
	publish()

func dpad_direction(at:Vector2) -> Vector2:
	if not get_global_rect().has_point(at): return Vector2.ZERO
	var p=(at-get_global_rect().get_center())/(size*.5)
	if p.length()<.18: return Vector2.ZERO
	var result=Vector2.ZERO
	if absf(p.x)>=absf(p.y)*.42: result.x=signf(p.x)
	if absf(p.y)>=absf(p.x)*.42: result.y=signf(p.y)
	return result.normalized()

func update_dpad() -> void:
	direction=Vector2.ZERO
	for value in fingers.values(): direction+=value
	direction=direction.limit_length(1);publish()

func publish() -> void:
	if game!=null: game.input_router.set_virtual_movement(direction)
	queue_redraw()

func reset() -> void:
	finger=-1;fingers.clear();direction=Vector2.ZERO;origin=size/2;touch_origin=size/2;publish()

func _notification(what:int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]: reset()

func _draw() -> void:
	if mode=="dpad":
		var center=size/2;var width=size.x*(.3-spacing*.25);var offset=size.x*(.32+spacing*.2)
		for axis in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
			var at=center+axis*offset;var box=Rect2(at-Vector2.ONE*width/2,Vector2.ONE*width)
			var active=direction.dot(axis)>.4
			draw_style_box(pad_style(active),box)
			var side=Vector2(-axis.y,axis.x)
			draw_colored_polygon(PackedVector2Array([at+axis*width*.23,at-axis*width*.18+side*width*.2,at-axis*width*.18-side*width*.2]),accent)
	else:
		var center=origin if finger!=-1 else size/2
		draw_circle(center,size.x/2,Color("101822dd"))
		draw_arc(center,size.x/2-2,0,TAU,48,accent,.9,true)
		draw_arc(center,size.x*.43,0,TAU,40,Color(accent,.28),1,true)
		var knob=center+direction*size.x*.33
		draw_circle(knob,size.x*.20,Color("384252ee"))
		draw_arc(knob,size.x*.20,0,TAU,32,accent,2,true)

func pad_style(active:bool) -> StyleBoxFlat:
	var style=StyleBoxFlat.new();style.bg_color=Color("48546e") if active else Color("151e2b")
	style.border_color=accent;style.set_border_width_all(1);style.set_corner_radius_all(7)
	return style
