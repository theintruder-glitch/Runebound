extends SceneTree
const Layout=preload("res://scripts/control_layout.gd")
const Data=preload("res://scripts/data.gd")
var checks=0
var game
func _initialize(): call_deferred("run")
func check(ok:bool,message:String):
	if not ok: push_error("FAIL: "+message);quit(1);assert(ok,message)
	checks+=1;print("PASS: "+message)
func settle(): await process_frame;await process_frame
func touch(at:Vector2,index:int,down:bool=true):
	var event=InputEventScreenTouch.new();event.position=at;event.index=index;event.pressed=down;root.push_input(event,true)
func drag(at:Vector2,index:int):
	var event=InputEventScreenDrag.new();event.position=at;event.index=index;root.push_input(event,true)
func same_layout(a:Dictionary,b:Dictionary) -> bool:
	for id in b:
		for key in b[id]:
			if key=="position":
				for i in range(2):
					if not is_equal_approx(a[id][key][i],b[id][key][i]): return false
			elif b[id][key] is float:
				if not is_equal_approx(a[id][key],b[id][key]): return false
			elif a[id][key]!=b[id][key]: return false
	return true
func run():
	var model=Layout.new()
	for preset_name in Layout.PRESETS:
		check(model.apply_preset(preset_name),"Built-in preset loads: "+preset_name)
		for orientation in ["portrait","landscape"]:
			var area=Rect2(Vector2(8,8),Vector2(464,884) if orientation=="portrait" else Vector2(884,464))
			var unique=[];var okay=true
			for id in Layout.SIZES:
				var item=model.data.layouts[orientation][id]
				okay=okay and area.encloses(model.rect(id,area,orientation))
				if id in Layout.ASSIGNABLE: unique.append(item.action)
			check(okay,"Preset controls stay within bounds: "+preset_name+" "+orientation)
			check(unique.size()==10 and unique.all(func(a):return unique.count(a)==1),"Preset preserves unique assignments: "+preset_name+" "+orientation)
	model.data=model.defaults()
	check(model.reassign("attack","spell_1","portrait") and model.data.layouts.portrait.spell_1.action=="attack","Assignment swaps keep attack available")
	check(not model.reassign("pause","spell_1","portrait"),"Pause remains permanently assigned")
	var broken=model.data.duplicate(true);broken.layouts.portrait.attack.action="attack";broken.layouts.portrait.spell_1.action="attack"
	broken.layouts.portrait.spell_1.visible=false;broken.layouts.portrait.movement.visible=false;broken.layouts.portrait.attack.scale=NAN;broken.layouts.portrait.dodge.opacity=-5;broken.layouts.portrait.inventory.position=[INF,-10]
	model.data=model.sanitize(broken)
	var actions=[]
	for id in Layout.ASSIGNABLE: actions.append(model.data.layouts.portrait[id].action)
	check(actions.all(func(a):return actions.count(a)==1),"Malformed duplicate assignments are repaired")
	check(model.data.layouts.portrait.movement.visible and model.data.layouts.portrait.attack.scale==1,"Invalid sizes and hidden movement recover safely")
	check(model.data.layouts.portrait.dodge.opacity==.2 and model.data.layouts.portrait.inventory.position[1]==0,"Malformed opacity and coordinates clamp safely")
	check(model.sanitize(null).preset=="Classic RPG","Unreadable data restores a usable default")
	check(model.store_preset("Thumbs"),"A new named custom preset is created")
	check(not model.store_preset("Thumbs") and model.store_preset("Thumbs",true),"Overwriting requires an explicit overwrite operation")
	check(model.rename_preset("Thumbs","Combat hand") and model.data.preset=="Combat hand","Custom preset renaming retains selection")
	check(model.apply_preset("Classic RPG") and model.apply_preset("Combat hand"),"Custom preset loads without manual repositioning")
	check(not model.delete_preset("Classic RPG") and model.delete_preset("Combat hand"),"Only personal presets can be deleted")
	check(not model.store_preset("") and not model.store_preset("Classic RPG"),"Empty and reserved preset names are rejected")
	for i in range(12): check(model.store_preset("Layout %d" % i),"Personal layout slot %d saves" % i)
	check(not model.store_preset("Too many"),"Custom layout count is bounded")
	model.data=model.defaults();var safe=Rect2(Vector2(8,8),Vector2(464,884))
	model.data.layouts.portrait.dodge.position=model.data.layouts.portrait.attack.position.duplicate()
	check(not model.overlaps(safe,"portrait").is_empty(),"Intersecting controls are detected")
	check(model.fix_overlaps(safe,"portrait") and model.overlaps(safe,"portrait").is_empty(),"Auto-fix separates overlapping controls")
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(1080,2400)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
	game.start_character(Data.fresh("Warrior"));game.hero.auto=false;game.set_physics_process(false)
	var manager=game.hud.controls;var level=game.hero.level;game.save_game();var saved_character=FileAccess.get_file_as_string(Data.SAVE_PATH)
	game.hud.show_settings();check(game.hud.current_page=="settings","Settings is available inside the existing game")
	manager.open_editor();await settle();var editor=manager.editor
	check(not game.playing and manager.editing() and not game.hud.overlay.visible,"Editor shows the actual paused gameplay screen")
	var native=InputEventKey.new();native.keycode=KEY_I;native.physical_keycode=KEY_I;native.pressed=true;Input.parse_input_event(native)
	native.pressed=false;Input.parse_input_event(native);await settle()
	check(manager.editing() and not game.hud.overlay.visible,"Native gameplay shortcuts cannot open menus over Edit Mode")
	var attack=game.hud.attack_button;var old_position=manager.item("attack").position.duplicate();var center=attack.get_global_rect().get_center();var hp=game.hero.hp
	touch(center,3);drag(center+Vector2(-65,-125),3);touch(center+Vector2(-65,-125),3,false)
	check(manager.item("attack").position!=old_position and not game.attack_held and game.swing_time==0,"Real touch drag moves attack without firing gameplay")
	check(not game.playing and game.hero.hp==hp and game.hero.level==level,"Editing freezes combat and character simulation")
	var moved=manager.item("attack").position.duplicate();editor.undo_change()
	check(manager.item("attack").position==old_position,"Undo restores the complete previous layout")
	editor.redo_change();check(manager.item("attack").position==moved,"Redo restores a dragged control")
	editor.selected="attack";editor.minimize_tools();manager.apply()
	var before_size=attack.size;var corner=attack.get_global_rect().end-Vector2(3,3)
	touch(corner,2);drag(corner+Vector2(22,22),2);touch(corner+Vector2(22,22),2,false)
	check(attack.size.x>before_size.x and editor.tools_toggle.visible,"Corner dragging resizes the selected real control with tools minimized")
	editor.undo_change();check(attack.size==before_size,"Undo restores a corner resize")
	editor.cancel_edit();await settle()
	check(manager.item("attack").position==old_position and not FileAccess.file_exists(Layout.PATH),"Cancel discards the draft without writing control preferences")
	manager.open_editor();await settle();editor=manager.editor
	editor.remember();manager.item("attack").position=[.52,.6];manager.item("attack").scale=1.5;manager.item("attack").opacity=.35;manager.item("attack").skin="Blue runes";editor.changed()
	check(attack.size.is_equal_approx(Vector2(138,96)) and attack.get_global_rect().size==attack.size,"Resizing updates the real touchscreen hitbox")
	check(is_equal_approx(attack.self_modulate.a,.35)==false,"Edit outlines retain readable controls even with low gameplay opacity")
	check(manager.model.store_preset("My battle layout"),"Custom preset stores both orientations and appearance")
	editor.begin_preview();await settle()
	check(game.playing and editor.previewing and not manager.editing(),"Preview enables live gameplay without saving the layout")
	check(is_equal_approx(attack.self_modulate.a,.35) and not FileAccess.file_exists(Layout.PATH),"Preview uses selected opacity without a permanent write")
	var stick=game.hud.stick;var at=stick.get_global_rect().get_center()+Vector2(40,0);touch(at,1)
	check(game.move_vector.x>.7,"Movement is usable inside Preview")
	touch(at,1,false);editor.end_preview();await settle()
	check(not game.playing and manager.editing() and game.move_vector==Vector2.ZERO,"Returning to Edit releases preview input")
	var portrait=manager.model.data.layouts.portrait.duplicate(true)
	for dims in [Vector2i(2400,1080),Vector2i(1600,2560),Vector2i(2560,1600),Vector2i(720,1600)]:
		root.size=dims;game.adapt_screen();await settle();game.hud.layout()
		var within=true
		for node in manager.registry.values(): within=within and manager.safe_rect().encloses(node.get_global_rect())
		check(within,"All control hitboxes stay visible after rotation: "+str(dims))
		check(manager.model.data.layouts.portrait==portrait,"Rotation preserves portrait customization: "+str(dims))
	manager.test_safe=Rect2(Vector2(28,44),game.get_viewport_rect().size-Vector2(56,90));manager.apply()
	var safe_controls=true
	for node in manager.registry.values(): safe_controls=safe_controls and manager.test_safe.encloses(node.get_global_rect())
	check(safe_controls,"Simulated notch/navigation insets contain every hitbox")
	manager.test_safe=Rect2();manager.apply()
	editor.request_reset();check(editor.confirm.visible and manager.model.data.layouts.portrait==portrait,"Reset asks before changing a custom layout")
	editor.confirm.hide();editor.confirmation=Callable()
	editor.commit_save();await settle()
	check(FileAccess.file_exists(Layout.PATH) and not is_instance_valid(manager.editor),"Save persists preferences and exits editing")
	var reload=Layout.new();reload.load_settings()
	check(same_layout(reload.data.layouts.portrait,portrait) and reload.data.custom.has("My battle layout"),"Restart reloads positions, size, opacity, skin and custom presets")
	check(game.hero.level==level and FileAccess.get_file_as_string(Data.SAVE_PATH)==saved_character,"Control editing does not alter character save contents")
	reload.data.options.movement="dpad";check(reload.save_settings(),"Second preference save succeeds atomically")
	var corrupt=FileAccess.open(Layout.PATH,FileAccess.WRITE);corrupt.store_string("{broken");corrupt.close()
	var backup=Layout.new();backup.load_settings()
	check(backup.recovered and same_layout(backup.data.layouts.portrait,portrait),"Corrupted preferences recover from a separate settings backup")
	check(backup.save_settings(),"Recovered preferences can be saved again")
	var preserved=JSON.new();var error=preserved.parse(FileAccess.get_file_as_string(Layout.PATH+".bak"))
	check(error==OK and preserved.data is Dictionary,"Saving after recovery retains the valid settings backup")
	check(Data.read_save().level==level,"Settings recovery leaves gameplay saves loadable")
	print("%d CUSTOM CONTROL CHECKS PASSED" % checks);quit()
