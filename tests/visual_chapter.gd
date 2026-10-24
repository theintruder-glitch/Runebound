extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var output=OS.get_environment("RUNEBOUND_VISUAL_OUTPUT")
func _initialize():call_deferred("run")
func capture(name:String):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
func run():
	if output.is_empty(): output="user://chapter-visuals"
	DirAccess.make_dir_recursive_absolute(output);root.size=Vector2i(540,1200)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_character(Data.fresh("Mage"));game.set_physics_process(false);game.hero.auto=false;game.enemies.clear();game.audio.enabled=false;game.audio.music.stop()
	game.set_player_position(game.trader.POSITION);game.hud.show_character("chapter");await capture("mara-portrait")
	game.chapter.accept()
	for id in game.chapter.CLUES:
		game.set_player_position(game.chapter.CLUES[id].point);game.chapter.investigate(id)
	game.hud.show_character("chapter");await capture("clues-portrait")
	game.set_player_position(game.trader.POSITION);game.chapter.translate();game.set_player_position(game.exploration.RUINS);game.chapter.begin()
	game.hero.dungeon.floor=3;game.build_floor(true)
	var boss=game.enemies.filter(func(e):return e.get("chapter_boss",false))[0]
	game.set_player_position(boss.pos+Vector2(5,0));game.camera.position=game.player_position();game.camera.force_update_scroll();game.update_enemy_attack(boss,.01)
	game.hud.resume();game.set_physics_process(false);game.hud.toast_time=0;game.hud.update_hud();await capture("heart-chamber-portrait")
	root.size=Vector2i(1200,540);await process_frame;game.adapt_screen();game.hud.layout();game.hud.show_character("chapter");await capture("journal-landscape")
	game.queue_free();game=null;await process_frame;await process_frame;call_deferred("quit")
