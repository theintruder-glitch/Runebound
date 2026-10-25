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
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false);game.hero.auto=false;game.audio.enabled=false;game.audio.music.stop();game.enemies.clear()
	game.survival.add("Wood",30);game.hud.show_craft_batch("Plank",10);await capture("parts-batch-portrait")
	game.hero.survival.structures=[{"kind":"Campfire","x":70.0,"y":0.0,"rotation":0,"fuel":90.0,"open":false,"stash":{}}]
	game.survival.add("Raw fish",8);game.survival.add("Herbs",12);game.survival.add("Berries",6);game.hud.show_craft_batch("Fisher stew",5);await capture("food-shortage-portrait")
	root.size=Vector2i(1200,540);await process_frame;game.adapt_screen();game.hud.layout();game.hud.show_craft_batch("Fisher stew",3);await capture("food-batch-landscape")
	game.queue_free();await process_frame;await process_frame;quit()
