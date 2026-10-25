extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
	checks+=1
	if ok:print("PASS: "+message)
	else:failures+=1;push_error("FAIL: "+message)
func chest(at:Vector2=Vector2(70,0)) -> Dictionary:
	var s={"kind":"Storage","x":at.x,"y":at.y,"rotation":0,"fuel":0.0,"open":false,"stash":{}}
	game.hero.survival.structures.append(s);return s
func reset():
	game.hero.dungeon=null;game.hero.survival.structures=[];game.hero.survival.materials={};game.enemies.clear();game.set_player_position(Vector2.ZERO)
func button(title:String) -> Button:
	for n in game.hud.content.find_children("*","Button",true,false):
		if n.text==title:return n
	return null
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;await process_frame
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false);game.hero.auto=false
	check(ProjectSettings.get_setting("application/config/name")=="VYRNSPIRE","Project metadata uses the new game name")
	check(game.get_window().title.begins_with("VYRNSPIRE"),"Native game window uses VYRNSPIRE")
	game.hud.show_title(false);check(game.hud.panel_title.text=="VYRNSPIRE","Title menu uses VYRNSPIRE")
	check(game.hud.export_dialog.current_file=="VYRNSPIRE-Character.json","New save exports use the new brand")
	check(ProjectSettings.get_setting("application/config/use_custom_user_dir") and ProjectSettings.get_setting("application/config/custom_user_dir_name")=="godot/app_userdata/Runebound Godot","Historical Linux and Android user-directory identity is pinned")
	check(ProjectSettings.get_setting("application/config/custom_user_dir_name.windows")=="Godot/app_userdata/Runebound Godot","Historical Windows user-directory identity is pinned")
	check(Data.SAVE_PATH=="user://character.json","Character filename and schema entry point stay compatible")
	game.hud.resume();game.set_physics_process(false);reset();var camp=game.survival;var box=chest();camp.add("Wood",25);camp.add("Berries",7)
	check(camp.transfer_item(box,"Wood",5,true) and camp.count("Wood")==20 and box.stash.Wood==5,"Selective deposit moves exactly five wood")
	check(camp.count("Berries")==7 and not box.stash.has("Berries"),"Selective deposit leaves food and unrelated supplies carried")
	check(camp.transfer_item(box,"Wood",1,false) and camp.count("Wood")==21 and box.stash.Wood==4,"Selective withdrawal moves exactly one wood")
	var before=game.hero.duplicate(true)
	for qty in [-1,0,100000]:check(not camp.transfer_item(box,"Wood",qty,true) and game.hero==before,"Invalid transfer amount spends nothing: "+str(qty))
	check(not camp.transfer_item(box,"Wood",22,true) and game.hero==before,"Unaffordable transfer never partially moves a stack")
	check(not camp.transfer_item(box,"invented",1,true) and game.hero==before,"Unknown materials cannot enter storage")
	var fake=box.duplicate(true)
	check(not camp.transfer_item(fake,"Wood",1,false) and not camp.transfer(fake,false) and game.hero==before,"A lookalike or stale chest cannot create or swallow supplies")
	box.x=140;check(not camp.transfer_item(box,"Wood",1,true) and camp.count("Wood")==21,"Remote chests cannot be accessed")
	box.x=70;game.hero.survival.structures.append({"kind":"Wall","x":35.0,"y":0.0,"rotation":1,"fuel":0.0,"open":false,"stash":{}})
	check(camp.storage_reason(box).contains("wall") and not camp.transfer_item(box,"Wood",1,true) and not camp.transfer(box,true),"Walls block selective and bulk chest access")
	game.hero.survival.structures.pop_back();box.stash.Wood=99998
	check(camp.transfer_amount(box,"Wood",true)==1,"Deposit maximum respects remaining chest stack capacity")
	before=game.hero.duplicate(true);check(not camp.transfer_item(box,"Wood",2,true) and game.hero==before,"Overflow transfer moves nothing")
	check(camp.transfer_item(box,"Wood",1,true) and box.stash.Wood==99999 and camp.count("Wood")==20,"Exact final stack slot transfers without loss")
	camp.add("Wood",99979);before=game.hero.duplicate(true)
	check(not camp.transfer_item(box,"Wood",1,false) and game.hero==before,"Withdrawal respects carried stack capacity")
	reset();box=chest();camp.add("Wood",12);camp.add("Stone",9);camp.add("Berries",8)
	check(camp.transfer(box,true) and camp.count("Wood")==0 and box.stash.Wood==12 and box.stash.Stone==9,"Existing bulk deposit retains its real behavior")
	check(camp.transfer(box,false) and camp.count("Wood")==12 and box.stash.is_empty(),"Existing bulk withdrawal retains its real behavior")
	check(camp.transfer_item(box,"Wood",5,true) and Data.read_save().survival.structures[0].stash.Wood==5,"Actual saved character retains selected chest contents")
	game.hero.survival.structures.erase(box);before=game.hero.duplicate(true)
	check(not camp.transfer_item(box,"Wood",1,false) and game.hero==before,"A removed chest cannot be used by a stale menu callback")
	for dims in [Vector2i(1080,2400),Vector2i(2400,1080)]:
		root.size=dims;game.adapt_screen();await process_frame;await process_frame;game.hud.layout();reset();box=chest();camp.add("Wood",20);camp.add("Berries",8)
		before=game.hero.duplicate(true);game.hud.show_storage(box)
		check(not game.playing and game.hero==before,"Opening chest selection pauses and moves nothing / "+str(dims))
		button("Wood · carry 20 / stored 0").pressed.emit();button("5").pressed.emit();await process_frame;await process_frame
		check(button("Store 5 Wood")!=null and not button("Store 5 Wood").disabled,"Native storage menu exposes the selected transfer amount")
		check(game.hud.content.get_global_rect().size.x<=game.hud.scroll.get_global_rect().size.x+1,"Storage controls fit the native scrolling menu")
		button("Store 5 Wood").pressed.emit();check(camp.count("Wood")==15 and box.stash.Wood==5 and camp.count("Berries")==8,"Real UI deposit retains carried food")
		button("Take 5 Wood").pressed.emit();check(camp.count("Wood")==20 and not box.stash.has("Wood"),"Real UI withdrawal erases empty stored stacks")
		button("Store maximum · 20").pressed.emit();check(camp.count("Wood")==0 and box.stash.Wood==20,"Maximum UI deposit uses the actual available amount")
		button("Take maximum · 20").pressed.emit();check(camp.count("Wood")==20 and box.stash.is_empty(),"Maximum UI withdrawal restores actual supplies")
		camp.add("Wood",-20);before=game.hero.duplicate(true);button("Store 5 Wood").pressed.emit()
		check(game.hero==before,"Execution revalidates stale supply amounts after preview")
	print("%d BRAND/STORAGE CHECKS; %d FAILURES" % [checks,failures]);game.queue_free();await process_frame;quit(1 if failures else 0)
