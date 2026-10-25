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
	var hero=Data.fresh("Warrior");hero.x=-5200;hero.y=-6200
	game.start_character(hero);game.set_physics_process(false);game.hero.auto=false;game.audio.enabled=false;game.audio.music.stop();game.enemies.clear()
	game.hud.show_character("map");await capture("snow-map-local-portrait")
	game.hud.map_widget.local_view=false;game.hud.map_widget.queue_redraw();await capture("snow-map-overview-portrait")
	game.hud.show_position_recovery();await capture("recover-character-portrait")
	root.size=Vector2i(1200,540);await process_frame;game.adapt_screen();game.hud.layout();game.hud.show_character("map");await capture("snow-map-local-landscape")
	game.recover_stuck_character();game.set_physics_process(false);game.hud.toast_time=0;game.hud.update_hud();await capture("recovered-camp-landscape")
	game.queue_free();await process_frame;await process_frame;quit()
