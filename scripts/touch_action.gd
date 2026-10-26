extends Button

# Capture each finger explicitly. No synthetic mouse click is allowed to fire
# the same action twice, and sliding off releases a held attack immediately.
var finger=-1
var game
var input_enabled=true
var slot_id=""

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(func():
		if not is_visible_in_tree(): reset())

func reset() -> void:
	var held=finger!=-1;finger=-1
	if held: button_up.emit();queue_redraw()

func _notification(what:int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]: reset()

func activate(index:int) -> void:
	finger=index;button_down.emit();pressed.emit();queue_redraw()

func _input(event:InputEvent) -> void:
	# Cooldowns can finish between the slower HUD text refreshes. Recheck the
	# live action on a press so a stale disabled appearance cannot drop input.
	var press_here=false
	if event is InputEventScreenTouch:
		press_here=event.pressed and not event.canceled and get_global_rect().has_point(event.position)
	elif event is InputEventMouseButton:
		press_here=event.device!=-1 and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and get_global_rect().has_point(event.position)
	if press_here and disabled and input_enabled and is_visible_in_tree() and game!=null and game.playing and not slot_id.is_empty():
		if game.hud.controls.action_ready(slot_id): disabled=false
	if not input_enabled or not is_visible_in_tree() or disabled or (game!=null and not game.playing):
		reset();return
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled and finger==-1 and get_global_rect().has_point(event.position):
			activate(event.index);get_viewport().set_input_as_handled()
		elif (not event.pressed or event.canceled) and event.index==finger:
			reset();get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index==finger:
		if not get_global_rect().has_point(event.position): reset()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.device==-1:
			if get_global_rect().has_point(event.position): get_viewport().set_input_as_handled()
		elif event.pressed and finger==-1 and get_global_rect().has_point(event.position):
			activate(-2);get_viewport().set_input_as_handled()
		elif not event.pressed and finger==-2: reset();get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and finger==-2:
		if not get_global_rect().has_point(event.position): reset()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	if finger!=-1: draw_rect(Rect2(Vector2(2,2),size-Vector2(4,4)),Color("f6d99c"),false,2)
