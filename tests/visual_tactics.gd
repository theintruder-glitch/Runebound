extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var output=OS.get_environment("RUNEBOUND_VISUAL_OUTPUT")
func _initialize(): call_deferred("run")
func capture(name:String):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
func run():
	DirAccess.make_dir_recursive_absolute(output);root.size=Vector2i(540,1200)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false);game.hero.auto=false
	game.audio.enabled=false;game.audio.music.stop();game.enter_dungeon();game.enemies.clear()
	var lane=game.dungeon_map.start
	for c in game.dungeon_map.floors:
		if game.dungeon_map.floors.has(c+Vector2i.RIGHT*3) and game.dungeon_map.floors.has(c+Vector2i.RIGHT*2) and game.dungeon_map.floors.has(c+Vector2i.RIGHT): lane=c;break
	var pos=game.cell_center(lane);game.set_player_position(pos);game.camera.position=pos;game.camera.force_update_scroll()
	var shooter=game.create_enemy(pos+Vector2(145,0),1,"archer");shooter.aggro=2;game.enemies.append(shooter)
	game.hud.resume();game.set_physics_process(false);game.update_enemy_attack(shooter,.01);shooter.windup=.4
	game.hud.toast_time=0;game.hud.update_hud();await capture("ranged-warning-portrait")
	root.size=Vector2i(1200,540);await process_frame;game.adapt_screen();game.hud.layout();game.camera.position=pos;game.camera.force_update_scroll()
	await capture("ranged-warning-landscape")
	game.leave_dungeon();game.enemies.clear();game.set_player_position(Vector2.ZERO);game.camera.position=Vector2.ZERO;game.camera.force_update_scroll();game.world.refresh(true)
	for i in range(5):
		var e=game.create_enemy(Vector2(-60+i*32,-90),1,"goblin");e.aggro=2;e.cooldown=3;game.enemies.append(e)
	game.tactics.prepare();game.tick(.1);game.hud.update_hud();await capture("mixed-melee-landscape")
	game.queue_free();game=null;await process_frame;await process_frame;quit()
