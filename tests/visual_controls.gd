extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
func _initialize(): call_deferred("run")
func settle():
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
func capture(name_value:String):
	await settle()
	root.get_texture().get_image().save_png("res://builds/control-visuals/"+name_value+".png")
func run():
	DirAccess.make_dir_recursive_absolute("res://builds/control-visuals")
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(600,1100)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false);game.hero.auto=false;game.enemies.clear();game.set_player_position(Vector2(1000,1150));game.camera.position=game.player_position();game.camera.reset_smoothing();game.world.refresh(true)
	await capture("portrait-joystick")
	game.hud.controls.open_editor();await capture("portrait-editor")
	var editor=game.hud.controls.editor;editor.selected="attack";editor.refresh();editor.show_properties();await capture("portrait-properties")
	editor.hide_properties();editor.minimize_tools();await capture("portrait-tools-minimized");editor.toolbar.show();editor.tools_toggle.hide();game.hud.controls.model.data.options.movement="dpad";game.hud.controls.apply();editor.begin_preview();await capture("portrait-dpad-preview")
	editor.end_preview();root.size=Vector2i(1152,648);game.adapt_screen();await settle();game.hud.layout();await capture("landscape-editor")
	editor.selected="movement";editor.refresh();editor.show_properties();await capture("landscape-properties")
	editor.cancel_edit();game.hud.show_settings();game.hud.controls.show_settings();await capture("controls-settings")
	print("CONTROL VISUALS CAPTURED");quit()
