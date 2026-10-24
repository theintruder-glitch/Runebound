extends Control

var game
var finger = -1
var direction = Vector2.ZERO
const DEAD_ZONE = 0.12

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(116,116)
	visibility_changed.connect(func():
		if not is_visible_in_tree(): reset())

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or game==null or not game.playing:
		if finger!=-1: reset()
		return
	if event is InputEventScreenTouch:
		if event.pressed and finger==-1 and get_global_rect().has_point(event.position):
			finger = event.index
			move_knob(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index==finger:
			reset()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index==finger:
		move_knob(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.device!=-1 and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed and finger==-1 and get_global_rect().has_point(event.position):
			finger = -2
			move_knob(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and finger==-2:
			reset()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and finger==-2:
		move_knob(event.position)
		get_viewport().set_input_as_handled()

func move_knob(at: Vector2) -> void:
	var offset = (at-global_position-size/2)/(size.x*.33)
	var strength = clampf((offset.length()-DEAD_ZONE)/(1.0-DEAD_ZONE),0,1)
	direction = offset.normalized()*strength
	game.move_vector = direction
	queue_redraw()

func _notification(what:int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]: reset()

func reset() -> void:
	finger = -1
	direction = Vector2.ZERO
	if game!=null:
		game.move_vector = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	draw_circle(size/2,size.x/2,Color("0b1f2355"))
	draw_arc(size/2,size.x/2-1,0,TAU,48,Color("c6e4ca66"),1)
	var knob = size/2+direction*size.x*.33
	draw_circle(knob,size.x*.20,Color("8daea044"))
	draw_arc(knob,size.x*.20,0,TAU,32,Color("caeacf88"),1)
	draw_string(ThemeDB.fallback_font,Vector2(size.x/2-20,size.y+19),"MOVE",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("a4beae"))
