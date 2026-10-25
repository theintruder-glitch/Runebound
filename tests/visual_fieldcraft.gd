extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var output=OS.get_environment("RUNEBOUND_VISUAL_OUTPUT")
func _initialize():call_deferred("run")
func capture(name:String):
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output.path_join(name+".png"))
func view_at(pos:Vector2):
 game.set_player_position(pos);game.camera.position=pos;game.camera.reset_smoothing();game.world.refresh(true);game.hud.update_hud()
func run():
 DirAccess.make_dir_recursive_absolute(output);root.size=Vector2i(1200,720)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.audio.enabled=false;game.audio.music.stop();game.start_character(Data.fresh("Warrior"));game.set_physics_process(false);game.hero.auto=false;game.enemies.clear();game.hud.toast_time=0;game.hud.toast_label.text=""
 game.world.field_visuals.ATLAS.get_image().save_png(output.path_join("field-props-atlas.png"))
 view_at(game.chapter.CLUES.cart.point+Vector2(0,75));await capture("broken-caravan-landscape")
 view_at(game.chapter.CLUES.watch.point+Vector2(0,70));await capture("silent-watch-landscape")
 view_at(game.chapter.CLUES.grove.point+Vector2(0,70));await capture("ashen-grove-landscape")
 root.size=Vector2i(540,1200);game.adapt_screen();game.hud.layout();view_at(game.chapter.CLUES.cart.point+Vector2(0,75));await capture("broken-caravan-portrait")
 game.queue_free();await process_frame;await process_frame;quit()
