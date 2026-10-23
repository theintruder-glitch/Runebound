extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720)
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await process_frame;await process_frame
	var ok=game.desktop.enabled and game.desktop.view_name=="Close" and not game.desktop.fullscreen and game.low_power and Engine.max_fps==30 and not game.weather.particles_enabled
	if not ok:
		push_error("FAIL: Laptop safe-mode boot settings");quit(1);return
	print("1 DESKTOP SAFE BOOT CHECKS PASSED")
	quit()
