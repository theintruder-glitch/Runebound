extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var output=OS.get_environment("RUNEBOUND_VISUAL_OUTPUT")
func _initialize(): call_deferred("run")
func capture(name:String):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
func run():
	if output.is_empty(): output="user://visual-mobile"
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(540,1200)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	var hero=Data.fresh("Ranger");hero.mode="survival";hero.level=5;hero.needs.wetness=85
	game.start_character(hero);game.set_physics_process(false);game.hero.auto=false;game.enemies.clear()
	game.hero.survival.structures=[{"kind":"Campfire","x":-100.0,"y":-80.0,"rotation":0,"fuel":90.0,"open":false,"stash":{}}]
	game.set_player_position(Vector2.ZERO);game.camera.position=Vector2.ZERO;game.camera.force_update_scroll()
	game.world.refresh(true);game.hud.update_hud();await capture("portrait-play")
	game.hud.show_character("gear");await capture("portrait-inventory")
	game.hud.show_character("needs");await capture("portrait-supplies")
	root.size=Vector2i(1200,540);await process_frame;game.adapt_screen();game.hud.layout()
	game.hud.resume();game.set_physics_process(false);game.hud.update_hud();await capture("landscape-play")
	game.hud.show_character("needs");await capture("landscape-supplies")
	print("MOBILE VISUAL CAPTURES COMPLETE");game.free();quit()
