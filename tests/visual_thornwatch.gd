extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var output=OS.get_environment("RUNEBOUND_VISUAL_OUTPUT")
func _initialize():call_deferred("run")
func capture(name:String):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
func view_at(pos:Vector2):
	game.set_player_position(pos);game.camera.position=pos;game.camera.reset_smoothing();game.world.refresh(true);game.hud.update_hud();game.hud.toast_time=0;game.hud.toast_label.text=""
func run():
	DirAccess.make_dir_recursive_absolute(output);root.size=Vector2i(1200,720)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.audio.enabled=false;game.audio.music.stop();game.start_character(Data.fresh("Warrior"));game.set_physics_process(false);game.hero.auto=false;game.enemies.clear();game.spawn_timer=99999
	view_at(Vector2(470,860));await capture("emerald-bridge")
	view_at(Vector2(1040,1120));await capture("thornwatch-exterior-landscape")
	root.size=Vector2i(540,1200);game.adapt_screen();game.hud.layout();view_at(Vector2(1040,1050));await capture("thornwatch-exterior-portrait")
	root.size=Vector2i(1200,720);game.adapt_screen();game.hud.layout();view_at(game.landscape.KEEP);game.castle.enter();view_at(game.cell_center(Vector2i(16,18)));await capture("thornwatch-great-hall")
	game.hero.dungeon.floor=2;game.build_floor(true);view_at(game.cell_center(Vector2i(6,9)));await capture("thornwatch-crypt")
	game.hero.dungeon.floor=3;game.build_floor(true);view_at(game.cell_center(Vector2i(16,8)));game.enemies[-1].windup=1;game.enemies[-1].windup_max=1.35;game.enemies[-1].strike=game.player_position();game.enemies[-1].strike_radius=55
	await capture("thornwatch-boss")
	game.queue_free();await process_frame;await process_frame;quit()
