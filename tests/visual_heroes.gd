extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var output=OS.get_environment("RUNEBOUND_VISUAL_OUTPUT")
func _initialize(): call_deferred("run")
func run():
	if output.is_empty(): output="user://visual-heroes"
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1000,600)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	for cls in ["Warrior","Mage","Ranger","Rogue","Cleric","Spellblade","Arcane Archer","Reaper"]:
		game.start_character(Data.fresh(cls));game.set_physics_process(false);game.hero.auto=false;game.enemies.clear()
		game.set_player_position(Vector2.ZERO);game.camera.position=Vector2.ZERO;game.camera.zoom=Vector2(2,2);game.camera.force_update_scroll()
		game.world.refresh(true);game.hud.update_hud()
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(cls.replace(" ","_")+".png"))
	print("HERO VISUAL CAPTURES COMPLETE");game.free();quit()
