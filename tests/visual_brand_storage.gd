extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var output=OS.get_environment("RUNEBOUND_VISUAL_OUTPUT")
func _initialize():call_deferred("run")
func capture(name:String):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
func run():
	DirAccess.make_dir_recursive_absolute(output);root.size=Vector2i(540,1200)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.audio.enabled=false;game.audio.music.stop();game.hud.show_title(false);await capture("vyrnspire-title-portrait")
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false);game.hero.auto=false;game.enemies.clear()
	var box={"kind":"Storage","x":70.0,"y":0.0,"rotation":0,"fuel":0.0,"open":false,"stash":{"Wood":14,"Stone":12}}
	game.hero.survival.structures.append(box);game.survival.add("Wood",20);game.survival.add("Berries",8)
	game.hud.show_storage(box);await capture("storage-selection-portrait")
	game.hud.show_storage_item(box,"Wood",5);await capture("storage-quantity-portrait")
	root.size=Vector2i(1200,540);await process_frame;game.adapt_screen();game.hud.layout();game.hud.show_storage_item(box,"Wood",10);await capture("storage-quantity-landscape")
	game.queue_free();await process_frame;await process_frame;quit()
