extends Button

# Normal menu Buttons use Godot's touch-to-mouse support. Combat buttons handle
# each touch index explicitly, so a second finger can cast while the first moves.
var finger = -1

func _ready() -> void:
	visibility_changed.connect(func():
		if not is_visible_in_tree(): reset())

func reset() -> void:
	var held=finger!=-1
	finger=-1
	if held: button_up.emit()

func _notification(what:int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]: reset()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		reset()
		return
	if event is InputEventScreenTouch:
		if event.pressed and finger==-1 and not disabled and get_global_rect().has_point(event.position):
			finger = event.index
			button_down.emit()
			pressed.emit()
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index==finger:
			reset()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.device==-1 and get_global_rect().has_point(event.position):
		# The touch above already activated this action; suppress its emulated click.
		get_viewport().set_input_as_handled()
