extends SceneTree
const Data = preload("res://scripts/data.gd")
var scene
var output = ""

func _initialize() -> void:
	call_deferred("run")

func capture(name_value: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image = root.get_texture().get_image()
	image.save_png(output.path_join(name_value+".png"))

func run() -> void:
	output = OS.get_environment("RUNEBOUND_QA_DIR")
	if output.is_empty():
		output = OS.get_user_data_dir().path_join("visual-check")
	DirAccess.make_dir_recursive_absolute(output)
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await capture("title")
	scene.start_character(Data.fresh("Mage"))
	scene.hero.auto = false
	scene.hero.gold = 1000
	scene.hero.essence = 10
	for i in range(4):
		scene.hero.inventory.append(Data.roll_loot(3))
	scene.build_building("Blacksmith")
	scene.playing = false
	for i in range(5):
		var e = scene.create_enemy(scene.player_position()+Vector2.from_angle(i*TAU/5)*140,1,"guardian" if i==0 else "goblin",i==0)
		scene.enemies.append(e)
	await capture("wilds")
	scene.hud.show_character("gear")
	await capture("gear")
	scene.hud.show_character("realm")
	await capture("realm")
	scene.enter_dungeon()
	scene.hud.resume()
	scene.playing = false
	await capture("dungeon")
	DisplayServer.window_set_size(Vector2i(800,400))
	await create_timer(.3).timeout
	await capture("landscape")
	DisplayServer.window_set_size(Vector2i(360,800))
	await create_timer(.3).timeout
	scene.hud.show_character("classes")
	await capture("classes-phone")
	print("VISUAL CAPTURES COMPLETE: "+output)
	quit()
