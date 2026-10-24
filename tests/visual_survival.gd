extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var output="user://visual-survival"
func _initialize():call_deferred("run")
func capture(name:String):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
func run():
	DirAccess.make_dir_recursive_absolute(output)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	root.size=Vector2i(1280,720);await process_frame
	game.hud.advanced.show_modes(true);await capture("modes")
	var hero=Data.fresh("Mage");hero.mode="survival";hero.level=9;hero.gold=2000
	hero.survival.materials={"Berries":8,"Roasted meat":3}
	hero.survival.structures=[{"kind":"Campfire","x":-80.0,"y":0.0,"fuel":90.0,"rotation":0,"open":false,"stash":{}},{"kind":"Bed","x":-140.0,"y":-120.0,"fuel":0.0,"rotation":0,"open":false,"stash":{}},{"kind":"Shelter","x":-210.0,"y":-80.0,"fuel":0.0,"rotation":0,"open":false,"stash":{}}]
	hero.spells.known={"fire":1,"frost":1,"heal":1,"meteor":1,"blizzard":1,"arc":1};hero.spells.slots=["meteor","arc","heal"]
	game.start_character(hero);game.set_physics_process(false);game.hero.auto=false;game.hero.worldTime=500;game.enemies.clear();game.graphics.set_quality("Balanced")
	game.set_player_position(Vector2.ZERO);game.camera.position=Vector2.ZERO;game.camera.force_update_scroll();game.world.refresh(true)
	game.hero.needs.hunger=68;game.hero.needs.water=42;game.hero.needs.sleep=77;game.hud.update_hud()
	await capture("survival-night")
	game.desktop.pointer_screen=game.get_canvas_transform()*Vector2(180,110);game.desktop.pointer_seen=true
	game.spellbook.request_slot(0);await capture("meteor-placement")
	game.hud.show_character("needs");await capture("supplies")
	game.hud.show_character("spells");await capture("spells")
	game.hud.show_character("spellshop");await capture("spellshop")
	game.hud.show_desktop_settings();await capture("settings")
	game.hud.resume();game.set_physics_process(false);game.hero.worldTime=180;game.world.refresh(true);game.hud.update_hud();await capture("survival-day")
	game.desktop.set_view("Close");root.size=Vector2i(960,540);await process_frame;game.hud.layout();await capture("survival-small")
	print("VISUAL SURVIVAL CAPTURES COMPLETE");game.free();quit()
