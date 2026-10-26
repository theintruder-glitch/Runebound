extends RefCounted

const Layout=preload("res://scripts/control_layout.gd")
const Editor=preload("res://scripts/control_editor.gd")
const Touch=preload("res://scripts/touch_action.gd")
var model=Layout.new()
var game
var hud
var registry:Dictionary={}
var editor
var connected=false
var styles:Dictionary={}
var test_safe=Rect2()

func setup() -> void:
	model.load_settings()
	bind("movement",hud.stick)
	for pair in [["attack",hud.attack_button],["dodge",hud.dash_button],["auto",hud.auto_button],["skill",hud.skill_button],["interact",hud.interaction],["inventory",hud.top.get_node("Gear")],["camp",hud.top.get_node("Realm")],["pause",hud.top.get_node("Pause")],["map",hud.top.get_node("Map")],["build_rotate",hud.build_tools.get_child(0)],["build_cancel",hud.build_tools.get_child(1)],["cast_confirm",hud.spell_ui.cast_button],["cast_cancel",hud.spell_ui.cancel_button]]: bind(pair[0],pair[1])
	for i in range(3): bind("spell_%d" % (i+1),hud.spell_buttons[["fire","frost","heal"][i]])
	connected=not Input.get_connected_joypads().is_empty()
	Input.joy_connection_changed.connect(joy_changed)
	apply()

func joy_changed(_device:int,_connected:bool) -> void:
	connected=not Input.get_connected_joypads().is_empty();release_all();update_visibility();focus_menu()

func bind(id:String,node:Control) -> void:
	registry[id]=node
	if node is Button:
		if node is Touch: node.game=game;node.slot_id=id
		node.button_down.connect(func():press_slot(id))
		node.button_up.connect(func():release_slot(id))

func orientation() -> String: return "landscape" if hud.get_viewport_rect().size.x>hud.get_viewport_rect().size.y else "portrait"

func safe_rect() -> Rect2:
	if test_safe.has_area(): return test_safe
	var view=hud.get_viewport_rect();var safe=view
	if OS.has_feature("android") and DisplayServer.get_name()!="headless":
		# DisplayServer returns physical screen pixels; the HUD's screen transform
		# includes Godot's stretch/letterbox scaling and window origin.
		var physical=DisplayServer.get_display_safe_area()
		if physical.has_area():
			var inverse=hud.get_screen_transform().affine_inverse()
			var a=inverse*Vector2(physical.position);var b=inverse*Vector2(physical.end)
			safe=view.intersection(Rect2(a,b-a))
	if not safe.has_area(): safe=view
	var inset=Vector2(8,8)
	return Rect2(safe.position+inset,(safe.size-inset*2).max(Vector2(64,64)))

func item(id:String) -> Dictionary: return model.data.layouts[orientation()][id]
func assignment(id:String) -> String: return item(id).action
func editing() -> bool: return is_instance_valid(editor) and not editor.previewing

func press_slot(id:String) -> void:
	if editing(): return
	var action=assignment(id)
	if model.data.options.haptics and OS.has_feature("android"): Input.vibrate_handheld(12)
	game.input_router.press(action,id)

func release_slot(id:String) -> void: game.input_router.release(assignment(id),id)

func release_all() -> void:
	game.input_router.reset_virtual()
	for node in registry.values():
		if node.has_method("reset"): node.reset()

func apply() -> void:
	if registry.is_empty(): return
	release_all()
	var touch_layout=not game.desktop.enabled or is_instance_valid(editor)
	if touch_layout:
		var safe=safe_rect();var orient=orientation()
		for id in registry:
			var node=registry[id];var rectangle=model.rect(id,safe,orient)
			if node is Button:
				node.clip_text=true;node.custom_minimum_size=Vector2.ZERO
				decorate(node,id)
			node.global_position=rectangle.position;node.size=rectangle.size
			if node is Button: node.add_theme_font_size_override("font_size",clampi(roundi(12*item(id).scale),8,20))
			node.self_modulate=Color(1,1,1,item(id).opacity if not editing() else maxf(.55,item(id).opacity))
		var options=model.data.options
		hud.stick.mode=options.movement;hud.stick.floating=options.floating;hud.stick.sensitivity=options.sensitivity;hud.stick.dead_zone=options.dead_zone;hud.stick.spacing=options.dpad_spacing
		hud.stick.accent=skin_color(item("movement").skin);hud.stick.queue_redraw()
	update_visibility();refresh_labels()
	if is_instance_valid(editor): editor.refresh()

func skin_color(value:String) -> Color:
	return {"Vyrnspire":Color("c9b986"),"Dark stone":Color("a5b1bd"),"Gold trim":Color("f4cf77"),"Purple magic":Color("cca6fa"),"Blue runes":Color("9bdcfb")}.get(value,Color("c9b986"))

func decorate(node:Button,id:String) -> void:
	var key=item(id).skin
	if not styles.has(key):
		var result={}
		for state in ["normal","hover","pressed","disabled","focus"]:
			var style=StyleBoxFlat.new();style.bg_color=Color("16202bee") if state!="pressed" else Color("3c3853")
			style.border_color=skin_color(key);style.set_border_width_all(1);style.set_corner_radius_all(10);style.set_content_margin_all(4)
			style.shadow_color=Color(0,0,0,.55);style.shadow_size=2
			if key in ["Purple magic","Blue runes"]: style.shadow_color=Color(skin_color(key),.22);style.shadow_size=5
			result[state]=style
		styles[key]=result
	for state in styles[key]: node.add_theme_stylebox_override(state,styles[key][state])

func update_visibility() -> void:
	if registry.is_empty(): return
	var edit=editing();var hidden=connected and model.data.options.hide_on_gamepad and not edit
	var mobile=not game.desktop.enabled or is_instance_valid(editor)
	for id in registry:
		var node=registry[id];var wanted=true
		if mobile:
			wanted=item(id).visible
			if id=="interact": wanted=wanted and not hud.interaction.text.is_empty()
			elif id.begins_with("build_"): wanted=wanted and not game.build_recipe.is_empty()
			elif id.begins_with("cast_"): wanted=wanted and not game.spellbook.targeting.is_empty()
		elif id in ["movement","map"]: wanted=false
		if hidden and id!="pause": wanted=false
		if edit: wanted=true
		node.visible=wanted
		if node is Touch: node.input_enabled=not edit
		elif node is Button: node.mouse_filter=Control.MOUSE_FILTER_IGNORE if edit else Control.MOUSE_FILTER_PASS
		hud.stick.input_enabled=not edit
	if edit:
		hud.build_tools.show();hud.spell_ui.aim_controls.show()

func refresh_labels() -> void:
	if registry.is_empty(): return
	for id in Layout.ASSIGNABLE:
		var node=registry[id];var action=assignment(id)
		if action!=id:
			if action.begins_with("spell_") and not game.hero.is_empty():
				var spell=game.hero.spells.slots[int(action.right(1))-1];var info=game.spellbook.BOOK[spell]
				node.text=info.short+"\n%d MP" % info.cost;node.disabled=not game.spellbook.can_cast(spell)
			else:
				node.text=Layout.LABELS[action].to_upper();node.disabled=false
		if editing(): node.disabled=false

func over_button(at:Vector2) -> bool:
	for id in registry:
		if id!="movement" and registry[id].is_visible_in_tree() and registry[id].get_global_rect().has_point(at): return true
	return false

func save() -> bool:
	var okay=model.save_settings()
	if not okay: game.notify("Could not save controls. Your previous layout is kept on disk.",5)
	return okay

func open_editor() -> void:
	if is_instance_valid(editor): return
	game.pause_game();hud.overlay.hide();hud.top.show();hud.buttons.show()
	editor=Editor.new();editor.manager=self;hud.add_child(editor)
	apply()

func show_settings() -> void:
	game.pause_game();hud.current_page="controls";hud.clear_content("Controls",false)
	hud.paragraph("YOUR HANDS. YOUR LAYOUT.",18,Color("edd7a0"))
	hud.action(hud.content,"Customize Layout",open_editor)
	hud.paragraph("Drag every control, resize it, and save separate portrait and landscape positions. Optional actions remain available from the pause and character menus.",13)
	var options=model.data.options
	hud.section("Movement")
	for mode in ["joystick","dpad"]:
		var chosen=mode
		hud.action(hud.content,("Virtual Joystick" if mode=="joystick" else "Directional D-Pad")+(" · selected" if options.movement==mode else ""),func():options.movement=chosen;save();apply();show_settings(),options.movement==mode)
	preference_toggle("Floating joystick", "floating")
	preference_number("Joystick sensitivity","sensitivity",.5,2,.05)
	preference_number("Joystick dead zone","dead_zone",0,.4,.01)
	preference_number("D-Pad spacing","dpad_spacing",0,.3,.01)
	hud.section("Layouts")
	hud.paragraph("Current: "+model.data.preset+" · "+orientation().capitalize(),14)
	var choices=OptionButton.new();choices.custom_minimum_size.y=44
	for value in Layout.PRESETS+model.data.custom.keys(): choices.add_item(value)
	choices.select(maxi(0,(Layout.PRESETS+model.data.custom.keys()).find(model.data.preset)))
	choices.item_selected.connect(func(index):model.apply_preset(choices.get_item_text(index));save();apply();show_settings())
	hud.content.add_child(choices)
	hud.paragraph("Save, rename, overwrite or delete up to 12 custom arrangements inside Customize Layout → Presets. Combat and Exploration are quick starting presets; custom names can describe any play style.",12)
	preference_toggle("Hide touch controls with gamepad","hide_on_gamepad")
	preference_toggle("Haptic button feedback","haptics")
	hud.paragraph("Keyboard: WASD / arrows · Space attack · Shift dodge · E use · 1–3 spells. Gamepad: left stick / D-pad move · A attack · B dodge · X use / confirm spell · Y class skill · shoulders / left trigger spells · right stick aim · Start menu.",12)
	hud.action(hud.content,"Back to Settings",hud.show_settings)

func preference_toggle(title:String,key:String) -> void:
	hud.action(hud.content,title+": "+("ON" if model.data.options[key] else "OFF"),func():model.data.options[key]=not model.data.options[key];save();apply();show_settings())

func preference_number(title:String,key:String,minimum:float,maximum:float,step:float) -> void:
	var row=HBoxContainer.new();hud.content.add_child(row)
	var label=hud.label(row,title,13);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var field=SpinBox.new();field.min_value=minimum;field.max_value=maximum;field.step=step;field.value=model.data.options[key];field.custom_minimum_size=Vector2(122,44)
	field.value_changed.connect(func(value):model.data.options[key]=value;save();apply())
	row.add_child(field)

func shutdown() -> void:
	if Input.joy_connection_changed.is_connected(joy_changed): Input.joy_connection_changed.disconnect(joy_changed)

func focus_menu() -> void:
	if not connected or not hud.overlay.visible: return
	var first:BaseButton=null
	var pending=[hud.overlay]
	while not pending.is_empty():
		var node=pending.pop_front()
		if node is BaseButton:
			node.focus_mode=Control.FOCUS_ALL
			if first==null and hud.content.is_ancestor_of(node) and node.is_visible_in_tree() and not node.disabled: first=node
		pending.append_array(node.get_children())
	if first!=null: first.grab_focus()

func action_ready(id:String) -> bool:
	if game.hero.is_empty() or not game.playing: return false
	var action=assignment(id)
	if action.begins_with("spell_"):
		return game.spellbook.can_cast(game.hero.spells.slots[int(action.right(1))-1])
	if action=="skill":
		return game.abilities.cooldown<=0 and game.hero.mp>=game.abilities.SKILLS[game.hero.className].cost and game.build_recipe.is_empty()
	if action=="cast_confirm":
		return not game.spellbook.targeting.is_empty() and game.spellbook.can_cast(game.spellbook.targeting) and game.spellbook.valid_ground(game.spellbook.target_point())
	return false
