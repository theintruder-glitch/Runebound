extends Button

# Normal menu Buttons use Godot's touch-to-mouse support. Combat buttons handle
# each touch index explicitly, so a second finger can cast while the first moves.
var finger = -1

func release_touch() -> void:
	var held = finger!=-1
	finger = -1
	self_modulate = Color.WHITE
	if held:
		button_up.emit()

func _notification(what: int) -> void:
	if what==NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		release_touch()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		release_touch()
		return
	if event is InputEventScreenTouch:
		if event.index==finger and (not event.pressed or event.canceled):
			release_touch()
			get_viewport().set_input_as_handled()
		elif event.pressed and not event.canceled and finger==-1 and not disabled and get_global_rect().has_point(event.position):
			finger = event.index
			self_modulate = Color(1.25,1.25,1.25)
			button_down.emit()
			pressed.emit()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.device==-1 and get_global_rect().has_point(event.position):
		# The touch above already activated this action; suppress its emulated click.
		get_viewport().set_input_as_handled()
