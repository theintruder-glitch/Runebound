extends Button

# Normal menu Buttons use Godot's touch-to-mouse support. Combat buttons handle
# each touch index explicitly, so a second finger can cast while the first moves.
var finger = -1
var cooldown_fraction = 0.0

func show_cooldown(remaining: float, duration: float) -> void:
	var fraction=clampf(remaining/maxf(duration,.001),0,1)
	if not is_equal_approx(fraction,cooldown_fraction):
		cooldown_fraction=fraction
		queue_redraw()

func _draw() -> void:
	if cooldown_fraction>0:
		var track=Rect2(Vector2(8,size.y-7),Vector2(maxf(0,size.x-16),3))
		draw_rect(track,Color("203e48"))
		track.size.x*=1-cooldown_fraction
		draw_rect(track,Color("b9ecdc"))

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
