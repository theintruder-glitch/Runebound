extends Control
var direction=Vector2.ZERO
var move_id=-1
var look_id=-1
var center=Vector2.ZERO
var look_delta=Vector2.ZERO
var radius=62.0
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
func reset() -> void:
	move_id=-1;look_id=-1;direction=Vector2.ZERO;look_delta=Vector2.ZERO;queue_redraw()
func _notification(what:int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]: reset()
func _input(e:InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed and not e.canceled:
			if e.position.x < size.x*.5 and move_id==-1:
				move_id=e.index;center=e.position;direction=Vector2.ZERO;queue_redraw()
			elif e.position.x>=size.x*.5 and look_id==-1: look_id=e.index
		elif not e.pressed or e.canceled:
			if e.index==move_id: move_id=-1;direction=Vector2.ZERO;queue_redraw()
			if e.index==look_id: look_id=-1
	elif e is InputEventScreenDrag:
		if e.index==move_id:
			var delta=(e.position-center)/radius
			direction=Vector2.ZERO if delta.length()<.12 else delta.limit_length(1)
			queue_redraw()
		elif e.index==look_id: look_delta+=e.relative
func take_look() -> Vector2:
	var result=look_delta;look_delta=Vector2.ZERO;return result
func _draw() -> void:
	var c=center if move_id!=-1 else Vector2(90,size.y-95)
	draw_circle(c,radius,Color(.04,.08,.12,.45));draw_arc(c,radius,0,TAU,48,Color(.90,.78,.53,.8),2,true)
	draw_circle(c+direction*radius*.65,25,Color(.85,.75,.54,.7))
