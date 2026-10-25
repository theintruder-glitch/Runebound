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
	game.audio.enabled=false;game.audio.music.stop()
	var hero=Data.fresh("Warrior")
	hero.chapter={"accepted":true,"clues":{"watch":true,"cart":true,"grove":true},"translated":true,"cleared":true,"claimed":true,"tracking":true,"return_until":0.0}
	hero.forge_chapter={"accepted":true,"inspected":true,"cleared":false,"claimed":false}
	hero.exploration.challenges.caves=true
	game.start_character(hero);game.set_physics_process(false);game.hero.auto=false;game.enemies.clear();game.set_player_position(game.forge.point());game.camera.position=game.player_position();game.camera.reset_smoothing();game.world.refresh(true)
	game.hud.show_character("chapter");game.hud.scroll.scroll_vertical=10000;await capture("ash-and-oath-journal-portrait")
	root.size=Vector2i(1200,540);await process_frame;game.adapt_screen();game.hud.layout();game.hud.show_character("chapter");game.hud.scroll.scroll_vertical=10000;await capture("ash-and-oath-journal-landscape")
	game.forge.begin();game.hud.resume()
	for e in game.forge.foes: e.cooldown=0;game.update_enemy_attack(e,.01)
	game.hud.update_hud();await capture("ash-and-oath-encounter-landscape")
	game.queue_free();await process_frame;await process_frame;quit()
