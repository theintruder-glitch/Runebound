extends SceneTree
func _initialize():call_deferred("run")
func run():
	var output=OS.get_environment("VYRNSPIRE_CAPTURE")
	root.size=Vector2i(1280,720)
	var game=load("res://main.tscn").instantiate();root.add_child(game)
	for i in range(60):await physics_frame
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output)
	print("3D PREVIEW CAPTURE COMPLETE");game.queue_free();quit()
