extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var output=OS.get_environment("RUNEBOUND_VISUAL_OUTPUT")
func _initialize(): call_deferred("run")
func capture(name:String):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
func run():
	if output.is_empty(): output="user://visual-touch-combat"
	DirAccess.make_dir_recursive_absolute(output);root.size=Vector2i(540,1200)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	var hero=Data.fresh("Mage");hero.level=12;hero.worldTime=240;hero.mode="survival"
	hero.spells.known.meteor=1;hero.spells.known.blizzard=1;hero.spells.slots=["meteor","blizzard","heal"]
	game.start_character(hero);game.set_physics_process(false);game.hero.auto=false;game.enemies.clear();game.hud.toast_time=0
	game.set_player_position(Vector2.ZERO);game.camera.position=Vector2.ZERO;game.camera.force_update_scroll();game.facing=Vector2.RIGHT
	var foe=game.create_enemy(Vector2(100,-70),2,"goblin");foe.windup=.45;foe.windup_max=.65;foe.strike=Vector2.ZERO;game.enemies=[foe]
	game.spellbook.request_slot(0);game.spellbook.mobile_point=Vector2(100,-70);game.spellbook.mobile_point_set=true
	game.world.refresh(true);game.hud.toast_time=0;game.hud.update_hud();await capture("portrait-targeting")
	root.size=Vector2i(1200,540);await process_frame;game.adapt_screen();game.hud.layout()
	game.spellbook.request_slot(1);game.spellbook.mobile_point=Vector2(100,-70);game.spellbook.mobile_point_set=true
	game.hud.toast_time=0;game.hud.update_hud();await capture("landscape-targeting")
	game.hero.survival.structures=[{"kind":"Wall","x":50.0,"y":-35.0,"rotation":1,"fuel":0.0,"open":false,"stash":{}}]
	game.world.refresh(true);await capture("landscape-blocked-target")
	game.spellbook.cancel_target();game.hero.survival.structures=[];game.hero=Data.fresh("Warrior");game.hero.worldTime=240;game.hero.auto=false
	foe=game.create_enemy(Vector2(45,0),2,"goblin");game.enemies=[foe];game.facing=Vector2.RIGHT;game.attack_cooldown=0
	game.attack();game.swing_time=.12;foe.stagger=.07;game.world.refresh(true);game.hud.update_hud();game.hud.toast_time=0
	await capture("landscape-melee-hit")
	game.queue_free();game=null;await process_frame;await process_frame
	print("TOUCH COMBAT VISUAL CAPTURES COMPLETE");quit()
