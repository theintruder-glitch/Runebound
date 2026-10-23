extends SceneTree
const Data=preload("res://scripts/data.gd")
var checks=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
	if not ok:
		push_error("FAIL: "+message);quit(1);assert(ok,message)
	checks+=1;print("PASS: "+message)
func run():
	root.size=Vector2i(1280,720)
	check(OS.has_feature("laptop"),"Exported project carries its laptop feature tag")
	var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene)
	await process_frame;await process_frame
	check(scene.desktop.enabled,"Release pack boots the laptop interface without development flags")
	check(ProjectSettings.get_setting("application/config/version")=="0.12.0","Release pack has current application metadata")
	scene.start_character(Data.fresh("Ranger"));scene.set_physics_process(false)
	scene.hero.auto=false;scene.enemies.clear();scene.spawn_timer=100000
	check(scene.farming.CROPS.size()==3 and scene.trader.offers().size()==13,"Release pack includes farming and trader systems")
	var event=InputEventKey.new();event.keycode=KEY_D;event.physical_keycode=KEY_D;event.pressed=true
	Input.parse_input_event(event);await process_frame
	var at=scene.player_position();scene.tick(.1)
	event.pressed=false;Input.parse_input_event(event);await process_frame
	check(scene.player_position().x>at.x+14,"Release bytecode accepts real keyboard movement")
	scene.survival.auto_pickup=true;scene.survival.pickup_timer=0;scene.survival.gather_cooldown=0;scene.survival.refresh_timer=1000
	scene.survival.nodes=[{"id":"release-pickup","kind":"Wood","pos":scene.player_position()+Vector2(20,0)}]
	scene.tick(.01)
	check(scene.survival.count("Wood")==6,"Laptop release retains automatic resource pickup from the newer phone update")
	scene.camera.position=scene.player_position();scene.camera.force_update_scroll()
	var motion=InputEventMouseMotion.new();motion.position=scene.get_canvas_transform()*(scene.player_position()+Vector2(180,0));root.push_input(motion,true)
	await process_frame;scene.attack_cooldown=0
	check(scene.attack() and scene.shots.size()==1 and scene.shots[0].velocity.x>0,"Release bytecode executes aimed attacks")
	check(not scene.hud.stick.is_visible_in_tree(),"Release hides mobile controls")
	scene.hud.show_character("camp");await process_frame
	check(not scene.playing and scene.hud.content.get_child_count()>0,"Release camp menu opens and pauses")
	var path="user://release-pack-transfer.json"
	check(scene.hud.export_save(path),"Release exports character JSON")
	check(not Data.migrate(JSON.parse_string(FileAccess.get_file_as_string(path))).is_empty(),"Release export can be read by the shared save format")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	scene.hud.resume();scene.world.profile_enabled=true;scene.world.refresh(true);scene.world.queue_redraw()
	await process_frame;await process_frame
	check(scene.world.profile_draw_samples.size()>0,"Release world executes native draw callbacks")
	print(str(checks)+" RELEASE PACK CHECKS PASSED")
	quit()
