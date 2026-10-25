extends Control

const Data = preload("res://scripts/data.gd")
const JoystickScript = preload("res://scripts/joystick.gd")
const TouchActionScript = preload("res://scripts/touch_action.gd")
const CardScript=preload("res://scripts/ui_card.gd")
const IconScript=preload("res://scripts/ui_icon.gd")
const MapScript=preload("res://scripts/world_map.gd")
var gear_filter="All"
var gear_selected=""
var camp_page="Build"
var quest_page="Posted"
var trader_page="Buy"
var trader_filter="Supplies"
var trader_selected=""
var craft_filter="Gear"
var map_selection="forest"
var map_widget
var map_detail:Label
var game
var top: Control
var buttons: Control
var shade: ColorRect
var heading: Label
var subheading: Label
var wealth: Label
var movement_status: Label
var hp: ProgressBar
var mp: ProgressBar
var xp: ProgressBar
var hp_label: Label
var mp_label: Label
var toast_label: Label
var toast_time = 0.0
var shade_phase = ""
var stick
var skill_button: Button
var attack_button: Button
var auto_button: Button
var dash_button: Button
var spell_buttons: Dictionary = {}
var build_tools: HBoxContainer
var objective_label: Label
var boss_bar: ProgressBar
var interaction: Button
var overlay: ColorRect
var panel: PanelContainer
var content: VBoxContainer
var scroll: ScrollContainer
var tabs: HBoxContainer
var panel_title: Label
var current_page = "title"
var new_character_pending = false
var import_dialog: FileDialog
var export_dialog:FileDialog
var desktop_hint:Label
var advanced
var spell_ui
const SpellUI=preload("res://scripts/spell_ui.gd")
const SurvivalUI=preload("res://scripts/survival_ui.gd")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme_value = Theme.new()
	theme_value.default_font_size = 17 if game.desktop.enabled else 15
	for name_value in ["normal","hover","pressed","disabled","focus"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("203c3c") if name_value!="pressed" else Color("396253")
		style.border_color = Color("52756988")
		style.set_border_width_all(1)
		style.set_corner_radius_all(10)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 11
		style.content_margin_bottom = 11
		theme_value.set_stylebox(name_value,"Button",style)
	theme = theme_value
	shade = ColorRect.new()
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	top = Control.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	heading = label(top,"",17,Color("e2e9da"))
	subheading = label(top,"",12,Color("adbfad"))
	wealth = label(top,"",12,Color("e4d9ad"))
	movement_status = label(top,"",11,Color("c4d6c1"))
	hp = make_bar(top,Color("d27477"))
	mp = make_bar(top,Color("7b9fda"))
	xp = make_bar(top,Color("d8c17d"))
	hp_label = label(hp,"",11,Color.WHITE)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mp_label = label(mp,"",11,Color.WHITE)
	mp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gear = action(top,"Gear",func():show_character("gear"))
	gear.name = "Gear"
	var realm = action(top,"Camp",func():show_character("camp"))
	realm.name = "Realm"
	var pause = action(top,"II",show_pause)
	pause.name = "Pause"
	buttons = Control.new()
	buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(buttons)
	stick = JoystickScript.new()
	stick.game = game
	buttons.add_child(stick)
	attack_button = action(buttons,"ATTACK",func():pass)
	attack_button.button_down.connect(func():game.attack_held=true;game.attack())
	attack_button.button_up.connect(func():game.attack_held=false)
	attack_button.add_theme_font_size_override("font_size",14)
	auto_button = action(buttons,"AUTO ON",func():game.hero.auto=not game.hero.auto;update_hud();game.save_game())
	auto_button.add_theme_font_size_override("font_size",12)
	skill_button=action(buttons,"CLASS SKILL",func():game.abilities.use())
	skill_button.add_theme_font_size_override("font_size",11)
	dash_button = action(buttons,"DASH",func():game.dash())
	dash_button.add_theme_font_size_override("font_size",13)
	for name_value in ["fire","frost","heal"]:
		var spell = name_value
		spell_buttons[spell] = action(buttons,{"fire":"FIRE\n12 MP","frost":"FROST\n20 MP","heal":"HEAL\n25 MP"}[spell],func():game.spellbook.request_slot(["fire","frost","heal"].find(spell)))
		spell_buttons[spell].add_theme_font_size_override("font_size",11)
		spell_buttons[spell].add_theme_color_override("font_color",{"fire":Color("ffc38f"),"frost":Color("a4dcf4"),"heal":Color("b4e8b5")}[spell])
	interaction = action(buttons,"OPEN CHEST",func():game.interact())
	interaction.visible = false
	build_tools=HBoxContainer.new()
	buttons.add_child(build_tools)
	action(build_tools,"ROTATE",func():game.build_rotation=(game.build_rotation+1)%4)
	action(build_tools,"CANCEL",func():game.cancel_build())
	build_tools.visible=false
	objective_label=label(top,"",13,Color("eddaa8"))
	objective_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	boss_bar=make_bar(top,Color("d58c6d"))
	boss_bar.visible=false
	toast_label = label(self,"",15,Color("f1dfa9"))
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay = ColorRect.new()
	overlay.color = Color("08191af5")
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	panel = PanelContainer.new()
	overlay.add_child(panel)
	var box = StyleBoxFlat.new()
	box.bg_color = Color("102529")
	box.border_color = Color("486858")
	box.set_border_width_all(1)
	box.set_corner_radius_all(18)
	box.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel",box)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	panel.add_child(column)
	var head = HBoxContainer.new()
	column.add_child(head)
	panel_title = label(head,"VYRNSPIRE",25,Color("efe5c6"))
	panel_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action(head,"X",back)
	tabs = HBoxContainer.new()
	column.add_child(tabs)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 12
	column.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",10)
	scroll.add_child(content)
	import_dialog = FileDialog.new()
	import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	import_dialog.access = FileDialog.ACCESS_FILESYSTEM
	import_dialog.filters = PackedStringArray(["*.json;VYRNSPIRE save;application/json,text/plain,application/octet-stream"])
	import_dialog.use_native_dialog = true
	import_dialog.file_selected.connect(import_save)
	add_child(import_dialog)
	export_dialog=FileDialog.new()
	export_dialog.file_mode=FileDialog.FILE_MODE_SAVE_FILE
	export_dialog.access=FileDialog.ACCESS_FILESYSTEM
	export_dialog.filters=PackedStringArray(["*.json;VYRNSPIRE character;application/json"])
	export_dialog.use_native_dialog=true
	export_dialog.current_file="VYRNSPIRE-Character.json"
	export_dialog.file_selected.connect(export_save)
	add_child(export_dialog)
	desktop_hint=label(buttons,"WASD move · E use · V survival supplies · C camp · I gear · M map · F11 fullscreen",12,Color("bbcbb1"))
	desktop_hint.mouse_filter=Control.MOUSE_FILTER_IGNORE
	desktop_hint.visible=game.desktop.enabled
	advanced=SurvivalUI.new();advanced.game=game;advanced.hud=self;advanced.setup()
	spell_ui=SpellUI.new();spell_ui.game=game;spell_ui.hud=self;spell_ui.setup()
	get_viewport().size_changed.connect(layout)
	layout()

func label(parent: Node,text_value: String,font_size: int=15,color: Color=Color("b7cbbd")) -> Label:
	var result = Label.new()
	result.text = text_value
	result.add_theme_font_size_override("font_size",font_size)
	result.add_theme_color_override("font_color",color)
	parent.add_child(result)
	return result

func action(parent: Node,text_value: String,callback: Callable,disabled: bool=false,touch_action:bool=false) -> Button:
	var result = TouchActionScript.new() if (parent==buttons or touch_action) and buttons!=null and not game.desktop.enabled else Button.new()
	# Let native touch drags reach the enclosing ScrollContainer. It cancels
	# pending button taps when a swipe starts, and provides inertial scrolling.
	if not result is TouchActionScript:
		result.mouse_filter = Control.MOUSE_FILTER_PASS
	result.text = text_value
	result.disabled = disabled
	result.focus_mode = Control.FOCUS_NONE
	result.pressed.connect(callback)
	parent.add_child(result)
	return result

func make_bar(parent: Node,color: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.show_percentage = false
	var background = StyleBoxFlat.new()
	background.bg_color = Color("0b181e")
	background.set_corner_radius_all(4)
	var fill = StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background",background)
	bar.add_theme_stylebox_override("fill",fill)
	parent.add_child(bar)
	return bar

func layout() -> void:
	if advanced!=null: advanced.layout()
	if spell_ui!=null: spell_ui.layout()
	if game.desktop.enabled:
		layout_desktop();return
	var view = get_viewport_rect().size
	reset_stick()
	game.attack_held=false
	top.size = view
	buttons.size = view
	heading.position = Vector2(17,15)
	subheading.position = Vector2(17,39)
	wealth.position = Vector2(17,119)
	movement_status.position = Vector2(17,138)
	var width = minf(300,view.x*.65)
	hp.position = Vector2(17,65)
	hp.size = Vector2(width,18)
	mp.position = Vector2(17,88)
	mp.size = Vector2(width,18)
	xp.position = Vector2(17,111)
	xp.size = Vector2(width,4)
	top.get_node("Realm").position = Vector2(view.x-182,14)
	top.get_node("Gear").position = Vector2(view.x-108,14)
	top.get_node("Pause").position = Vector2(view.x-45,14)
	var landscape = view.x>view.y
	stick.position = Vector2(184 if landscape else 24,view.y-180)
	stick.size = Vector2(148,148)
	skill_button.position=Vector2(208 if landscape else 24,view.y-252)
	skill_button.size=Vector2(96,56)
	attack_button.position = Vector2(view.x-184,view.y-118)
	attack_button.size = Vector2(92,92)
	auto_button.position = Vector2(view.x-254,view.y-98)
	auto_button.size = Vector2(62,64)
	dash_button.position = Vector2(view.x-82,view.y-108)
	dash_button.size = Vector2(70,76)
	for i in range(3):
		var spell = ["fire","frost","heal"][i]
		spell_buttons[spell].position = Vector2(view.x-252+i*80,view.y-200)
		spell_buttons[spell].size = Vector2(72,72)
		spell_buttons[spell].add_theme_font_size_override("font_size",12)
	if not landscape:
		# Keep spells at the bottom, with a compact combat row above them.
		attack_button.position.y=view.y-158
		attack_button.size.y=64
		auto_button.position.y=view.y-150
		auto_button.size.y=56
		dash_button.position.y=view.y-158
		dash_button.size.y=64
		for spell in spell_buttons.values():
			spell.position.y=view.y-84
			spell.size.y=64
	interaction.position = Vector2(view.x/2-112,view.y-70 if landscape else view.y-265)
	interaction.size = Vector2(224,52)
	if landscape:
		heading.position = Vector2(17,10)
		subheading.position = Vector2(17,32)
		hp.position = Vector2(17,55)
		hp.size = Vector2(210,17)
		mp.position = Vector2(239,55)
		mp.size = Vector2(180,17)
		xp.position = Vector2(17,77)
		xp.size = Vector2(402,4)
		wealth.position = Vector2(440,53)
		movement_status.position = Vector2(440,73)
	build_tools.position=Vector2(view.x/2-112,view.y-128 if landscape else view.y-325)
	build_tools.size=Vector2(224,46)
	objective_label.position=Vector2(17,98 if landscape else 162)
	objective_label.size=Vector2(view.x-34,42)
	boss_bar.position=Vector2(view.x/2-140,142 if landscape else 210)
	boss_bar.size=Vector2(280,12)
	toast_label.position = Vector2(25,view.y*.36)
	toast_label.size = Vector2(view.x-50,90)
	panel.position = Vector2(maxf(14,(view.x-660)/2),20)
	panel.size = Vector2(minf(view.x-28,660),view.y-40)
	queue_redraw()

func layout_desktop() -> void:
	var view=get_viewport_rect().size
	reset_stick();game.attack_held=false;game.desktop.clear_input()
	top.size=view;buttons.size=view;stick.hide()
	heading.position=Vector2(22,16);subheading.position=Vector2(22,42)
	subheading.clip_text=true;subheading.size=Vector2(maxf(200,view.x-550),20)
	hp.position=Vector2(22,72);hp.size=Vector2(240,18)
	mp.position=Vector2(274,72);mp.size=Vector2(180,18)
	xp.position=Vector2(22,96);xp.size=Vector2(432,4)
	wealth.position=Vector2(22,108);movement_status.position=Vector2(22,130)
	top.get_node("Realm").position=Vector2(view.x-262,16);top.get_node("Realm").size=Vector2(92,44)
	top.get_node("Gear").position=Vector2(view.x-158,16);top.get_node("Gear").size=Vector2(80,44)
	top.get_node("Pause").position=Vector2(view.x-66,16);top.get_node("Pause").size=Vector2(44,44)
	var hotbar=[attack_button,dash_button,spell_buttons.fire,spell_buttons.frost,spell_buttons.heal,skill_button,auto_button]
	var widths=[104,96,112,112,112,120,72]
	var x=view.x/2-388
	for i in range(hotbar.size()):
		for state in ["normal","hover","pressed","disabled","focus"]:
			var style=theme.get_stylebox(state,"Button").duplicate()
			style.set_content_margin_all(6);hotbar[i].add_theme_stylebox_override(state,style)
		hotbar[i].position=Vector2(x,view.y-82);hotbar[i].size=Vector2(widths[i],62)
		hotbar[i].add_theme_font_size_override("font_size",12)
		x+=widths[i]+8
	interaction.position=Vector2(view.x/2-150,view.y-170);interaction.size=Vector2(300,48)
	build_tools.position=Vector2(view.x/2-150,view.y-225);build_tools.size=Vector2(300,42)
	build_tools.get_child(0).text="[R] ROTATE";build_tools.get_child(1).text="[Esc] CANCEL"
	desktop_hint.position=Vector2(22,view.y-110);desktop_hint.size=Vector2(view.x-44,22)
	desktop_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	objective_label.position=Vector2(22,160);objective_label.size=Vector2(view.x-330,54)
	boss_bar.position=Vector2(view.x/2-150,204);boss_bar.size=Vector2(300,12)
	toast_label.position=Vector2(40,view.y*.36);toast_label.size=Vector2(view.x-80,90)
	panel.position=Vector2(maxf(18,(view.x-860)/2),20);panel.size=Vector2(minf(view.x-36,860),view.y-40)
	queue_redraw()

func _process(dt: float) -> void:
	toast_time -= dt
	toast_label.visible = toast_time>0 and not overlay.visible
	if not game.hero.is_empty():
		build_tools.visible=not game.build_recipe.is_empty()
		if not game.build_recipe.is_empty():
			var problem=game.survival.reason(game.build_recipe)
			interaction.disabled=not problem.is_empty()
			objective_label.text="BUILD "+game.build_recipe+" · "+(problem if not problem.is_empty() else "Green ghost: tap PLACE")
		else:
			interaction.disabled=false
			objective_label.text=game.forest.objective()
		boss_bar.visible=game.forest.active()
		if boss_bar.visible:
			boss_bar.max_value=game.forest.boss.max_hp
			boss_bar.value=game.forest.boss.hp
			objective_label.text="ROOT WARDEN · Dodge red circles · %d HP" % int(game.forest.boss.hp)
		if game.exploration.active():
			objective_label.text="TRIAL · "+game.exploration.REGIONS[game.exploration.trial]["class"]+" · "+{"caves":"Sword + magic","swamp":"Defeat shades + DASH","snow":"Bow + DASH"}[game.exploration.trial]
			var trial_foes=game.exploration.foes.filter(func(e):return not e.dead)
			boss_bar.visible=true
			boss_bar.max_value=0; boss_bar.value=0
			for enemy in trial_foes:
				boss_bar.max_value+=enemy.max_hp
				boss_bar.value+=enemy.hp
		if game.expedition.enabled() and not game.forest.active() and not game.exploration.active() and game.build_recipe.is_empty():
			objective_label.text="SURVIVAL · "+("Chapter complete · your home awaits" if game.hero.needs.won else "Build a home · harvest food · survive 5 days · clear the 5-floor ruins")
		if not game.fishing.objective().is_empty() and game.build_recipe.is_empty() and not game.forest.active() and not game.exploration.active(): objective_label.text=game.fishing.objective()
		if game.build_recipe.is_empty() and game.hero.exploration.target.is_empty() and game.hero.contracts.target.is_empty() and game.hero.angler.target.is_empty() and not game.chapter.objective().is_empty(): objective_label.text=game.chapter.objective()
		if game.forge.active():
			objective_label.text=game.forge.objective();boss_bar.visible=true;boss_bar.max_value=0;boss_bar.value=0
			for enemy in game.forge.foes:
				boss_bar.max_value+=enemy.max_hp
				if not enemy.dead: boss_bar.value+=enemy.hp
		if not game.spellbook.targeting.is_empty(): objective_label.text="PLACE "+game.spellbook.BOOK[game.spellbook.targeting].name.to_upper()+" · "+game.spellbook.placement_hint()
		if not game.spellbook.targeting.is_empty(): interaction.disabled=true
		spell_ui.update_targeting()
		var phase = Data.phase(game.hero.worldTime) if game.hero.dungeon==null else "Dungeon"
		if phase!=shade_phase:
			shade_phase = phase
			shade.visible = phase in ["Night","Dusk"] and not game.desktop.enabled
			shade.color = Color("07183355") if phase=="Night" else Color("6b405b22")

func toast(text_value: String,duration: float=3) -> void:
	toast_label.text = text_value
	toast_time = duration

func set_interaction(text_value: String) -> void:
	interaction.text = ("[E] " if game.desktop.enabled and not text_value.is_empty() else "")+text_value
	interaction.visible = not text_value.is_empty()

func reset_stick() -> void:
	if stick!=null:
		stick.reset()
	if buttons!=null:
		var touch_controls=buttons.get_children()
		if spell_ui!=null and spell_ui.aim_controls!=null: touch_controls.append_array(spell_ui.aim_controls.get_children())
		for child in touch_controls:
			if child.get_script()==TouchActionScript:
				child.reset()

func blocks_world_pointer(at:Vector2) -> bool:
	if overlay.visible: return true
	for child in top.get_children()+buttons.get_children():
		if (child is BaseButton or child in [build_tools,stick,spell_ui.aim_controls]) and child.is_visible_in_tree() and child.get_global_rect().has_point(at): return true
	return false

func update_hud() -> void:
	if game.hero.is_empty():
		return
	var h = game.hero
	heading.text = "%s · LV %d" % [h.className.to_upper(),h.level]
	heading.add_theme_font_size_override("font_size",14 if h.className.length()<12 else 12)
	subheading.text = (("Survival Ruins · %d / 5" if game.expedition.enabled() else "Endless Dungeon · Floor %d") % h.dungeon.floor if h.dungeon!=null else game.exploration.REGIONS[game.exploration.region_at(game.player_position())].name)+" · "+game.weather.season()+" · "+game.weather.sky()+" · "+Data.phase(h.worldTime)
	if game.chapter.story_run(): subheading.text="The Hollow Root · %s · %d / 3" % [game.chapter.FLOORS[h.dungeon.floor-1],h.dungeon.floor]
	hp.max_value = Data.max_hp(h)
	hp.value = h.hp
	mp.max_value = Data.max_mp(h)
	mp.value = h.mp
	xp.max_value = Data.needed_xp(h)
	xp.value = h.xp
	hp_label.text = "%d / %d HP" % [ceil(h.hp),Data.max_hp(h)]
	mp_label.text = "%d / %d MANA" % [h.mp,Data.max_mp(h)]
	wealth.text = "%d gold · %d essence · %d kills · %d FPS" % [h.gold,h.essence,h.kills,Engine.get_frames_per_second()]
	movement_status.text = ("Sheltered · recovering" if game.survival.sheltered() else game.weather.comfort())+" · %dm from camp" % int(game.player_position().length()/10)
	var skill=game.abilities.SKILLS[h.className]
	skill_button.text=("%.1fs" % game.abilities.cooldown) if game.abilities.cooldown>.1 else skill.name+"\n%d MP" % skill.cost
	skill_button.disabled=game.abilities.cooldown>.1 or h.mp<skill.cost or not game.build_recipe.is_empty()
	auto_button.text = "AUTO\nON" if h.auto else "AUTO\nOFF"
	dash_button.text = "%.1fs" % game.dash_cooldown if game.dash_cooldown>.1 else "DASH"
	if game.desktop.enabled:
		attack_button.text="[LMB] ATTACK\nSpace"
		dash_button.text="[Shift] DASH\n"+("%.1fs" % game.dash_cooldown if game.dash_cooldown>.1 else "Right click")
		skill_button.text="[Q] "+skill.name+"\n"+("%.1fs" % game.abilities.cooldown if game.abilities.cooldown>.1 else "%d MP" % skill.cost)
		auto_button.text="[T] AUTO\n"+("ON" if h.auto else "OFF")
	advanced.update()
	spell_ui.update()
	if h.dungeon!=null:
		queue_redraw()

func clear_content(title_value: String,show_tabs: bool=true) -> void:
	panel_title.text = title_value
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	for child in tabs.get_children():
		tabs.remove_child(child)
		child.queue_free()
	tabs.visible = show_tabs
	if show_tabs:
		for pair in [["gear","Gear"],["stats","Stats"],["classes","Paths"],["realm","Realm"],["camp","Camp"]]:
			var tab_name = pair[0]
			var b = action(tabs,pair[1],func():show_character(tab_name))
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.add_theme_font_size_override("font_size",12)
			b.add_theme_constant_override("outline_size",0)
			b.add_theme_stylebox_override("normal",theme.get_stylebox("normal","Button"))
	scroll.scroll_vertical = 0
	overlay.show()
	buttons.hide()

func paragraph(text_value: String,font_size: int=14,color: Color=Color("aec4b8")) -> Label:
	var result = label(content,text_value,font_size,color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result

func section(text_value: String) -> void:
	paragraph(text_value.to_upper(),12,Color("e1d0a3"))

func show_title(has_save: bool) -> void:
	current_page = "title"
	top.hide()
	buttons.hide()
	clear_content("VYRNSPIRE",false)
	paragraph("FORGE YOUR LEGEND",13,Color("89d7b0"))
	paragraph("Build your home beneath the trees. Follow the call of an ancient shrine. Face the Root Warden and awaken your hidden power.",21,Color("ece2c4"))
	paragraph("Survival chapter · Classic adventure · Offline\nVersion "+str(ProjectSettings.get_setting("application/config/version")),13)
	if has_save:
		action(content,"Continue journey",func():game.start_character(Data.read_save()))
	action(content,"Begin a new journey",func():advanced.show_modes(true))
	action(content,"Import a character save",choose_import)
	if game.desktop.enabled: action(content,"Laptop settings and controls",show_desktop_settings)
	paragraph("This Godot edition has its own save. To bring a character from v0.2, use the included Save Transfer update and export your character first.",12)

func resume() -> void:
	new_character_pending = false
	current_page = "game"
	overlay.hide()
	top.show()
	buttons.show()
	game.playing = true
	reset_stick()
	update_hud()

func show_pause(message: String="") -> void:
	if game.hero.is_empty():
		return
	game.pause_game()
	current_page = "pause"
	clear_content("A moment of rest",false)
	if not message.is_empty():
		paragraph(message,17,Color("e5bd8d"))
	paragraph("Version "+str(ProjectSettings.get_setting("application/config/version")),12)
	paragraph(game.weather.summary(),13)
	paragraph("Level %d %s · %d kills · %d chests" % [game.hero.level,game.hero.className,game.hero.kills,game.hero.stats.chests])
	action(content,"Resume journey",resume)
	action(content,"Spellbook · equip slots 1 / 2 / 3",func():show_character("spells"))
	action(content,"Game mode · "+("Survival" if game.expedition.enabled() else "Classic adventure"),func():advanced.show_modes())
	if game.expedition.enabled(): action(content,"Survival gauges and supplies",func():show_character("needs"))
	paragraph("%d FPS · %d enemies · %d MB engine memory" % [Engine.get_frames_per_second(),game.enemies.size(),Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0],12)
	action(content,"Enemy crowds: "+("Reduced · recommended" if game.reduced_crowds else "Standard"),func():game.set_reduced_crowds(not game.reduced_crowds);show_pause())
	action(content,"Low power: "+("ON · 30 FPS" if game.low_power else "OFF · 60 FPS"),func():game.set_low_power(not game.low_power);show_pause())
	action(content,"Auto pickup: "+("ON" if game.survival.auto_pickup else "OFF"),func():game.survival.set_auto_pickup(not game.survival.auto_pickup);show_pause())
	action(content,"Graphics · "+game.graphics.quality,show_graphics_settings)
	action(content,"Weather effects: "+("ON" if game.weather.particles_enabled else "OFF"),func():game.weather.toggle_particles();show_pause())
	action(content,"Sound and music: "+("ON" if game.audio.enabled else "OFF"),func():game.audio.toggle();show_pause())
	if game.desktop.enabled:
		action(content,"Laptop settings and controls",show_desktop_settings)
	else:
		action(content,"Landscape view",func():DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE);resume())
		action(content,"Portrait view",func():DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_PORTRAIT);resume())
		action(content,"Auto-rotate view",func():DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR);resume())
	action(content,"Trader Mara",func():show_character("trader"))
	action(content,"Quest board and active jobs",func():show_character("quests"))
	action(content,"World map",func():show_character("map"))
	action(content,"Recover stuck character",show_position_recovery)
	action(content,"Equipment and character",func():show_character("gear"))
	action(content,"Realm and dungeons",func():show_character("realm"))
	action(content,"Copy save to clipboard",func():DisplayServer.clipboard_set(JSON.stringify(game.hero));toast("Save copied. Paste it into a text file to back it up.",5))
	action(content,"Export character save",choose_export)
	action(content,"Save and title screen",func():game.save_game();show_title(true))

func show_position_recovery() -> void:
	game.pause_game();current_page="recovery";clear_content("Recover position",false)
	var at=game.player_position()
	paragraph("Position: %.0f, %.0f · %s" % [at.x,at.y,game.exploration.REGIONS[game.exploration.region_at(at)].name],14)
	paragraph("If movement is stuck, return to the original Mossveil camp. Your levels, gear, gold, camp and quest progress are kept. Health, mana and survival supplies are not refilled. An active wilds trial is abandoned.",15)
	if game.hero.dungeon!=null: paragraph("Inside a dungeon, use the entrance stairs to leave. Position recovery is available in the wilds.",14)
	action(content,"Return to original camp · keep my character",func():game.recover_stuck_character(),game.hero.dungeon!=null or game.hero.hp<=0)
	action(content,"Cancel · stay here",show_pause)

func back() -> void:
	if game.playing and not game.spellbook.targeting.is_empty():
		game.spellbook.cancel_target();return
	if current_page=="title":
		return
	if game.hero.is_empty() and current_page=="laptop":
		show_title(not Data.read_save().is_empty());return
	if new_character_pending:
		new_character_pending = false
		show_title(not Data.read_save().is_empty())
	elif overlay.visible:
		resume()
	else:
		show_pause()

func show_character(tab_value: String="gear") -> void:
	game.pause_game()
	current_page = tab_value
	clear_content({"gear":"Equipment","stats":"Character","classes":"Paths of power","realm":"Your realm","guide":"Field guide","camp":"Your camp","map":"World map","quests":"Quest board","trader":"Mara’s camp market","farm":"Your garden plots","needs":"Survival supplies","spells":"Your spellbook","spellshop":"Arcane tomes","kit":"Survival kit","chapter":"Story journal","fishing":"Fishing and catches"}[tab_value],tab_value not in ["map","quests","trader","farm","needs","spells","spellshop","kit","fishing","chapter"])
	match tab_value:
		"gear": show_gear()
		"stats": show_stats()
		"classes": show_classes(false)
		"realm": show_realm()
		"guide": show_guide()
		"camp": show_camp()
		"map": show_map()
		"quests": show_quests()
		"trader": show_trader()
		"farm": show_farm()
		"needs": advanced.show_needs()
		"kit": game.kit.show_menu()
		"fishing": game.fishing.show_menu()
		"chapter": game.chapter.show_menu()
		"spells": spell_ui.show_spells()
		"spellshop": spell_ui.show_shop()

func show_classes(choosing: bool) -> void:
	if choosing:
		game.pause_game()
		new_character_pending = true
		current_page = "choose"
		clear_content("Choose your class",false)
		if not Data.read_save().is_empty():
			paragraph("Choosing a class replaces your Godot character save. Close to keep your current journey.",14,Color("efba8b"))
	for name_value in Data.CLASSES:
		var class_value = name_value
		var definition = Data.CLASSES[class_value]
		var available = not definition.has("goal") or (not game.hero.is_empty() and class_value in game.hero.unlocked)
		section(class_value if available else "??? Hidden class")
		paragraph(definition.desc if available else definition.goal)
		if available: paragraph(game.abilities.SKILLS[class_value].name+": "+game.abilities.SKILLS[class_value].desc,12)
		if available:
			var current = not choosing and game.hero.className==class_value
			action(content,"Choose "+class_value if choosing else "Current class" if current else "Become "+class_value,func():
				if choosing:
					game.start_character(advanced.fresh_character(class_value))
				else:
					game.hero.className = class_value
					game.hero.hp = minf(game.hero.hp,Data.max_hp(game.hero))
					game.hero.mp = minf(game.hero.mp,Data.max_mp(game.hero))
					game.save_game()
					show_character("classes"),current)

func show_gear() -> void:
	var h=game.hero
	paragraph("%d gold · %d essence · %d / 40 items" % [h.gold,h.essence,h.inventory.size()],16,Color("ebd392"))
	var filters=HBoxContainer.new();content.add_child(filters)
	for choice in ["All","Weapons","Armor","Trinkets"]:
		var selected=choice
		action(filters,choice,func():gear_filter=selected;show_character("gear"),choice==gear_filter)
	var items=h.inventory.filter(func(item):return gear_filter=="All" or (gear_filter=="Weapons" and item.kind in ["sword","bow","staff"]) or (gear_filter=="Armor" and item.kind in ["armor","helmet","shield"]) or (gear_filter=="Trinkets" and item.kind in ["ring","charm"]))
	items.sort_custom(func(left,right):return int(left.id in h.equipped.values())>int(right.id in h.equipped.values()) if (left.id in h.equipped.values())!=(right.id in h.equipped.values()) else left.rarity>right.rarity)
	var selected_item:Dictionary={}
	for item in items:
		if item.id==gear_selected: selected_item=item
	if selected_item.is_empty() and not items.is_empty(): selected_item=items[0];gear_selected=selected_item.id
	if not selected_item.is_empty():
		var item=selected_item
		var equipped=item.id in h.equipped.values()
		var color=Color(Data.RARITIES[int(item.rarity)].color)
		var body=visual_panel(item.name+(" +%d" % item.upgrade if item.upgrade>0 else ""),Data.RARITIES[int(item.rarity)].name+" · "+item.kind.to_upper(),item.kind,color)
		text_in(body,"Level %d · Power %d%s" % [item.level,item.power," · EQUIPPED" if equipped else ""],14)
		var slot="weapon" if item.kind in ["sword","bow","staff"] else item.kind
		var current=Data.equipped(h,slot)
		if not equipped and not current.is_empty():
			var delta=int(item.power-current.power)
			text_in(body,"Power versus equipped %s: %+d" % [slot,delta],13,Color("a4dbb4") if delta>=0 else Color("e4aaa2"))
		if item.enchant>0: text_in(body,"Enchantment: "+Data.ENCHANTS[int(item.enchant)],13,color)
		var row=HBoxContainer.new();body.add_child(row)
		action(row,"Equipped" if equipped else "Equip",func():game.equip(item);show_character("gear"),equipped)
		action(row,"Upgrade %dg" % Data.upgrade_cost(h,item),func():game.upgrade(item);show_character("gear"),h.gold<Data.upgrade_cost(h,item))
		if item.kind in ["sword","bow","staff"]: action(body,"Enchant · 3 essence",func():game.enchant_item(item);show_character("gear"),h.essence<3)
		if not equipped: action(body,"Salvage · +%d essence" % (item.rarity+1),func():game.salvage(item);show_character("gear"))
	section("Select an item · gold dot means equipped")
	if items.is_empty(): paragraph("No items in this category.")
	var grid=GridContainer.new();grid.columns=4 if get_viewport_rect().size.x<700 else 6;content.add_child(grid)
	for value in items:
		var item=value
		var card=CardScript.new()
		card.caption=item.name;card.subtitle="PWR %d" % item.power;card.kind=item.kind
		card.tint=Color(Data.RARITIES[int(item.rarity)].color);card.marked=item.id in h.equipped.values();card.chosen=item.id==gear_selected
		card.tooltip_text=item.name+" · "+Data.RARITIES[int(item.rarity)].name
		card.pressed.connect(func():gear_selected=item.id;show_character("gear"))
		grid.add_child(card)

func show_stats() -> void:
	var h = game.hero
	paragraph("Level %d %s · %d unspent points" % [h.level,h.className,h.points],18,Color("e7d8b5"))
	paragraph("%d / %d experience · %d maximum HP · %d maximum mana" % [h.xp,Data.needed_xp(h),Data.max_hp(h),Data.max_mp(h)])
	for pair in [["str","Strength","More sword damage"],["int","Intelligence","More magic damage and mana"],["dex","Dexterity","More bow damage and critical chance"],["vit","Vitality","+12 maximum health"]]:
		var key = pair[0]
		section("%s · %d" % [pair[1],h[key]])
		paragraph(pair[2])
		action(content,"Add point",func():
			if h.points>0:
				h.points -= 1
				h[key] += 1
				if key=="vit":
					h.hp += 12
				game.save_game()
				show_character("stats"),h.points<1)
	section("Journey record")
	paragraph("%d melee · %d bow · %d magic kills\n%d bosses · %d chests · %d defeats" % [h.stats.melee,h.stats.bow,h.stats.magic,h.stats.bosses,h.stats.chests,h.deaths])

func show_realm() -> void:
	var h = game.hero
	paragraph(Data.title(h.kingdom.renown)+" of the Wilds",22,Color("eddaaa"))
	paragraph("%d renown · %d gold\nTitles advance every 100 renown. Kills, chests, bosses, and cleared dungeon floors increase renown." % [h.kingdom.renown,h.gold])
	for name_value in Data.BUILDINGS:
		var building = name_value
		section(building)
		paragraph(Data.BUILDINGS[building].desc)
		action(content,"Built" if Data.has_building(h,building) else "Build · %d gold" % Data.BUILDINGS[building].cost,func():game.build_building(building);show_character("realm"),Data.has_building(h,building) or h.gold<Data.BUILDINGS[building].cost)
	section("The endless dungeon")
	paragraph("Deepest floor %d · %d floors cleared. Explore connected random floors with treasure and enemies. Every fifth floor contains a Dungeon Lord. Defeat all enemies to unlock the gold staircase." % [h.highestFloor,h.floorsCleared])
	if h.dungeon==null:
		action(content,"Enter dungeon · Floor 1",func():game.enter_dungeon();resume())
	else:
		action(content,"Leave dungeon · Return to the wilds",func():game.leave_dungeon();resume())
	paragraph("Leaving ends this expedition. Closing the app preserves the current floor. The green minimap dot is you; gold marks the way down.",12)

func show_guide() -> void:
	for pair in [
		["Auto pickup","Walk within 65 units of wild materials to collect them automatically. Pause > Auto pickup switches it on or off. Walls and closed doors block collection; full stacks leave resources waiting. Enemy rewards already enter your inventory. Open chests and harvest gardens manually."],
		["Movement and combat","WASD or arrows move. Aim with the mouse and hold left click or Space to attack. T toggles automatic combat. Shift or right click dodges. Every class can use swords, bows, staves and magic; arrows are unlimited." if game.desktop.enabled else "Drag the left thumbstick. Auto attack targets nearby enemies; toggle AUTO off to use ATTACK manually. Every class can use swords, bows, staves, and magic. Arrows are unlimited. DASH briefly protects you."],
		["Magic","Firebolt costs 12 mana and follows your mouse aim, even without a target. Frost Nova costs 20 and damages and slows nearby enemies. Heal costs 25. Use 1 / 2 / 3 or click the hotbar. Mana recovers automatically." if game.desktop.enabled and game.desktop.mouse_aim else "Firebolt costs 12 mana and needs a target. Frost Nova costs 20 and damages and slows nearby enemies. Heal costs 25. Mana recovers automatically. Cooldown seconds appear on spell buttons."],
		["Treasure","Approach a chest and tap OPEN CHEST. Loot appears directly in your bag. The bag holds 40 items; excess loot becomes essence. Equip, upgrade, enchant, and salvage from Gear."],
		["Rarity and enchantments","Common 60%, Uncommon 25%, Rare 10%, Epic 4%, Legendary 1%. Boss drops guarantee Rare or better. Ember burns; Frost slows; Storm chains lightning; Leech restores health."],
		["Classes and levels","Each level grants 3 stat points and restores health and mana. Hidden classes unlock through accomplishments shown in Paths. Classes can be switched freely while keeping your level and gear."],
		["Weather and seasons","Spring, Summer, Autumn and Winter last two game days each. Camp → Journal explains gathering bonuses. A roof or shelter keeps precipitation off you; adding a lit campfire gives bonus recovery outside combat. Cook Warm tea for a portable mana recovery bonus. Pause can turn weather effects off."],
		["Trading with Mara","Mara runs a stall northeast of the original camp. Camp → Trader Mara lets you review or track her. Visit to buy supplies, Rare enchanted weapons, armor or an Epic relic; sell spare gear and materials for gold. Equipped items are protected. Buyback keeps the last eight sold equipment pieces at the sale payout plus 10% (minimum 1 gold). Stock refreshes each active game day and keeps a fixed equipment level for that day. Six completed jobs earn 10% off; eighteen earn 15%."],
		["Frontier jobs","A quest board stands northwest of the starting camp. Open Camp → Quest board and active jobs. Accept up to three jobs nearby, track a job from anywhere, and return to turn it in. Deliveries consume carried supplies; kills and floor clears count after acceptance. Jobs repost after ten minutes of active play. Every third turn-in gives Rare enchanted gear; every ninth gives Epic instead. Keep a bag slot free for that bonus."],
		["World and kingdom","The wilds have random continuous spawns and no waves. A day lasts 10 minutes of active play. Night spawn attempts are five times as frequent. Realm manages buildings, renown titles, and optional dungeon entry."],
		["Dungeons","Walk around seeded connected floors, defeat enemies, collect chests, and descend using the gold stairs. Every fifth floor has a Dungeon Lord. Walls block movement and projectiles. The entrance staircase returns to your previous wilds position."],
		["Defeat and saves","Defeat costs 15% gold and returns you to your chosen bed, or the origin if none is set. Levels, gear, buildings, and discoveries remain. The game saves every 8 seconds and when paused. Local saves have a backup. Clearing app data removes them. Menus pause combat."],
		["Save transfer","The Godot edition installs separately from v0.2. Use the supplied Save Transfer update on your old app to export a JSON save, then Import a character save on this edition's title screen. Old dungeon expeditions return to the wilds; character progression carries over."],
		["Keyboard","WASD or arrows: move. Space: attack. E: interact. 1/2/3: spells. Q: class skill. M: map. Shift: dash. I: gear. Escape: pause."]]:
		section(pair[0])
		paragraph(pair[1])
	section("Engine and credits")
	paragraph("Built with Godot Engine, available under the MIT license. Engine license: https://godotengine.org/license/ . Engine and third-party notices are bundled in the project and APK.",12)

func choose_import() -> void:
	import_dialog.popup_centered_ratio(.85)

func choose_export() -> void:
	if game.hero.is_empty(): return
	game.save_game()
	export_dialog.current_file="VYRNSPIRE-Character.json"
	export_dialog.popup_centered_ratio(.85)

func export_save(path:String) -> bool:
	if game.hero.is_empty() or path.is_empty(): return false
	var file=FileAccess.open(path,FileAccess.WRITE)
	if file==null:
		paragraph("Could not export there. Choose a writable folder such as Downloads.",15,Color("efad98"));return false
	file.store_string(JSON.stringify(game.hero));file.flush()
	var success=file.get_error()==OK
	file.close()
	paragraph("Character exported. Move the JSON to your other device, then choose Import a character save on its title screen." if success else "Export failed. Choose a writable folder and try again.",14,Color("c9dfa9") if success else Color("efad98"))
	return success

func show_graphics_settings() -> void:
	game.pause_game();current_page="graphics";clear_content("Graphics",false)
	paragraph("The new creature and environment art is included in every quality. Performance keeps lights off. Balanced adds ambient lighting and a few soft lights. Rich adds denser ground detail and atmosphere.",15)
	paragraph("Low power caps lighting at two lights and keeps the existing 30 FPS limit. Start with Performance on your phone, then try Balanced. Save progress before a long playtest.",14)
	for value in game.graphics.LEVELS:
		var choice=value
		action(content,choice+(" · selected" if game.graphics.quality==choice else ""),func():game.graphics.set_quality(choice);show_graphics_settings(),game.graphics.quality==choice)
	action(content,"Back to pause",show_pause)

func show_desktop_settings() -> void:
	game.pause_game();current_page="laptop";clear_content("Laptop settings",false)
	paragraph("WASD / arrows: move · Mouse: aim · Left click / Space: attack · Right click / Shift: dodge · E: use / place · R: rotate · Esc: cancel building or pause",15)
	paragraph("1 / 2 / 3: equipped spells · B: spellbook · V: survival · Q: class skill · T: auto combat · C: camp · I: gear · M: map · F11: fullscreen",15)
	paragraph("Mouse aim gives directional sword swings, arrows and firebolts. Auto combat still targets nearby alerted enemies. Disable mouse aim for the original assisted targeting.",13)
	action(content,"Mouse aim: "+("ON" if game.desktop.mouse_aim else "OFF · assisted targeting"),func():game.desktop.toggle_aim();show_desktop_settings())
	action(content,"Fullscreen: "+("ON" if game.desktop.fullscreen else "OFF"),func():game.desktop.toggle_fullscreen();show_desktop_settings())
	section("Graphics quality")
	paragraph("Balanced adds day/night lighting, campfire and spell lights, detailed ground and fireflies. Rich adds more lights and detail. Performance turns lighting effects off.",13)
	for value in game.graphics.LEVELS:
		var choice=value
		action(content,choice+(" · selected" if game.graphics.quality==choice else ""),func():game.graphics.set_quality(choice);show_desktop_settings(),game.graphics.quality==choice)
	section("World view")
	paragraph("Close makes characters larger. Balanced shows more of the world. Wide shows the most and uses more rendering work.",13)
	for name_value in game.desktop.VIEWS:
		var selected=name_value
		action(content,selected+(" · selected" if selected==game.desktop.view_name else ""),func():game.desktop.set_view(selected);show_desktop_settings(),selected==game.desktop.view_name)
	action(content,"Enemy crowds: "+("Reduced · recommended" if game.reduced_crowds else "Standard"),func():game.set_reduced_crowds(not game.reduced_crowds);show_desktop_settings())
	action(content,"Frame cap: "+("30 FPS · battery saver" if game.low_power else "60 FPS"),func():game.set_low_power(not game.low_power);show_desktop_settings())
	action(content,"Weather effects: "+("ON" if game.weather.particles_enabled else "OFF"),func():game.weather.toggle_particles();show_desktop_settings())
	paragraph("To continue your phone character, update the phone app, use Pause → Export character save, move that JSON to the laptop, then Import a character save here. Saves are local; transferring does not automatically sync later progress.",13)
	if not game.hero.is_empty(): action(content,"Export character save",choose_export)
	action(content,"Back",func():show_title(not Data.read_save().is_empty()) if game.hero.is_empty() else show_pause())

func import_save(path: String) -> void:
	var parser = JSON.new()
	var error = parser.parse(FileAccess.get_file_as_string(path))
	var data = parser.data if error==OK else null
	if not data is Dictionary:
		paragraph("That file is not a valid VYRNSPIRE save.",15,Color("efad98"))
		return
	var converted = Data.migrate(data)
	if converted.is_empty():
		paragraph("That file is not a supported VYRNSPIRE character.",15,Color("efad98"))
		return
	game.start_character(converted)
	toast("Character imported. Your Godot journey is ready.",5)

func _draw() -> void:
	if game==null or game.hero.is_empty() or game.hero.dungeon==null or overlay==null or overlay.visible:
		return
	var map = game.dungeon_map
	var origin = Vector2(17,size.y-350)
	var scale_value = 4.0
	draw_rect(Rect2(origin-Vector2(6,6),Vector2(map.size*scale_value+12,map.size*scale_value+31)),Color("0b1b28dd"))
	for cell in map.floors:
		draw_rect(Rect2(origin+Vector2(cell)*scale_value,Vector2.ONE*3),Color("7b9793"))
	draw_circle(origin+Vector2(map.exit)*scale_value+Vector2.ONE*2,3,Color("e5c97d"))
	draw_circle(origin+game.player_position()/game.TILE*scale_value,3,Color("99e9b6"))
	var count = game.enemies.filter(func(e):return not e.dead).size()
	draw_string(ThemeDB.fallback_font,origin+Vector2(0,map.size*scale_value+19),"%d enemies left" % count,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("d0d9c5"))

func show_camp() -> void:
	var camp=game.survival
	action(content,"Story journal · Chapters I–II",func():show_character("chapter"))
	action(content,"Fishing · rod and catch journal",func():show_character("fishing"))
	action(content,"Survival kit · craft and manage",func():show_character("kit"))
	if game.expedition.enabled(): action(content,"Food, water and sleep",func():show_character("needs"))
	paragraph(game.forest.objective(),15,Color("eddaaa"))
	action(content,"Garden plots · %d ready" % game.farming.ready_count(),func():show_character("farm"))
	action(content,"Trader Mara",func():show_character("trader"))
	action(content,"Quest board and active jobs",func():show_character("quests"))
	action(content,"World map and tracking",func():show_character("map"))
	var pages=HBoxContainer.new();content.add_child(pages)
	for name_value in ["Build","Craft","Supplies","Journal"]:
		var page=name_value
		action(pages,page,func():camp_page=page;show_character("camp"),camp_page==page)
	var nearby=camp.nearest_structure()
	if not nearby.is_empty():
		var body=visual_panel("Nearby "+nearby.kind,"Manage your camp",nearby.kind,Color("c8b590"))
		var row=HBoxContainer.new();body.add_child(row)
		action(row,"Move",func():game.begin_build(nearby.kind,nearby))
		action(row,"Dismantle",func():camp.dismantle(nearby);show_character("camp"))
		text_in(body,"Dismantling returns half the materials. Empty storage first.",11)
		if nearby.kind=="Garden":
			text_in(body,game.farming.status(nearby),13)
			action(body,"Plant, harvest or clear this garden",func():show_character("farm"))
		if nearby.kind=="Bed": action(body,"Rest and set return point",func():camp.rest(nearby);show_character("camp"))
		if nearby.kind=="Door": action(body,"Open / close",func():camp.toggle_door(nearby);show_character("camp"))
		if nearby.kind=="Storage":
			var stored=PackedStringArray()
			for material in nearby.get("stash",{}): stored.append("%s: %d" % [material,nearby.stash[material]])
			text_in(body,"Stored: "+("Empty" if stored.is_empty() else " · ".join(stored)),12)
			action(body,"Choose supplies to store or take",func():show_storage(nearby))
			action(body,"Deposit carried materials",func():camp.transfer(nearby,true);show_character("camp"))
			action(body,"Withdraw stored materials",func():camp.transfer(nearby,false);show_character("camp"))
	match camp_page:
		"Build":
			paragraph("Place a ghost, move to position it, then rotate and confirm. Make planks and rope under Craft → Parts.",13)
			for recipe in camp.RECIPES:
				if recipe in camp.STRUCTURES: recipe_card(recipe)
		"Craft":
			var filters=HBoxContainer.new();content.add_child(filters)
			for name_value in ["Gear","Food","Parts"]:
				var choice=name_value
				action(filters,choice,func():craft_filter=choice;show_character("camp"),choice==craft_filter)
			for recipe in camp.RECIPES:
				if recipe in camp.STRUCTURES: continue
				var is_food=recipe in camp.FOODS
				var is_gear=camp.RECIPES[recipe].station=="bench"
				if (craft_filter=="Food" and is_food) or (craft_filter=="Gear" and is_gear) or (craft_filter=="Parts" and not is_food and not is_gear): recipe_card(recipe)
		"Supplies":
			var grid=GridContainer.new();grid.columns=4 if get_viewport_rect().size.x<700 else 6;content.add_child(grid)
			for material in camp.MATERIALS:
				if camp.count(material)<1: continue
				var card=CardScript.new();card.caption=material;card.subtitle="× %d" % camp.count(material);card.kind=material;card.mouse_filter=Control.MOUSE_FILTER_IGNORE;grid.add_child(card)
			if grid.get_child_count()==0: paragraph("Your supplies bag is empty. Approach a labeled resource and tap GATHER.")
			for food in camp.FOODS:
				var selected=food
				if camp.count(food)>0: action(content,"Eat "+food+" · %d owned" % camp.count(food),func():camp.eat(selected);show_character("camp"))
		"Journal":
			var calendar=visual_panel("Turning Seasons",game.weather.summary(),"map",Color("b7dbbe"))
			text_in(calendar,"A day lasts 10 minutes of active play; each season lasts two days. Menus and time away pause the calendar. Weather changes every two minutes and varies by region.",13)
			text_in(calendar,"This season: +1 per harvest of "+", ".join(game.weather.GATHER_BONUS[game.weather.season()])+". All other materials keep their normal yield.",13)
			text_in(calendar,"Roof or shelter + lit fire: +1 HP and +2 mana per second outside combat. Fire alone or warm tea: +1 mana per second. Bonuses do not stack. Classic has no exposure damage. Survival has temperature damage and thirst or exhaustion penalties.",13)
			action(content,"Resume opening guide",func():game.hero.contracts.target="";game.hero.exploration.target="";game.save_game();resume())
			for key in game.exploration.REGIONS:
				var region=key;var info=game.exploration.REGIONS[region];var journal=game.hero.exploration
				var status="Trial complete" if journal.challenges.get(region,false) or (region=="forest" and game.hero.journey.warden) else "Landmark discovered" if journal.discovered.get(region,false) else "Region visited" if journal.visited.get(region,false) else "Undiscovered"
				var body=visual_panel(info.name,status+" · "+game.exploration.bearing(info.point),"map",Color("add5bf"))
				text_in(body,"Unique material: "+info.material+". "+game.exploration.instructions(region),13)
				action(body,"Track "+info.landmark,func():game.hero.contracts.target="";game.hero.exploration.target=region;game.save_game();resume())
			action(content,"Realm and dungeons",func():show_character("realm"))
			action(content,"Field guide",func():show_character("guide"))
	var fire=camp.near("Campfire")
	if not fire.is_empty():
		section("Nearby fire · %d seconds of fuel" % int(fire.fuel))
		action(content,"Add 1 Wood · +90 seconds",func():camp.fuel_fire();show_character("camp"),camp.count("Wood")<1 or fire.fuel>510)
	action(content,"Return to the wilds",resume)

func show_farm() -> void:
	var farm=game.farming
	var gardens=farm.plots()
	paragraph("%d / %d plots · %d ready · %s" % [gardens.size(),farm.MAX_PLOTS,farm.ready_count(),game.weather.season()],15,Color("d8dfa5"))
	paragraph("Plant ingredients from carried supplies, then adventure while they grow. Spring: 25% faster. Winter: 25% slower. Menus and time away pause growth. Ripe crops stay ready.",13)
	var build_reason=game.survival.reason("Garden",false)
	action(content,"Place a Garden · 4 Wood, 2 Stone, 2 Fiber",func():game.begin_build("Garden"),not build_reason.is_empty())
	if not build_reason.is_empty(): paragraph(build_reason,12)
	action(content,"Back to camp",func():show_character("camp"))
	if gardens.is_empty():
		var body=visual_panel("Start a kitchen garden","Build on outdoor ground","Garden",Color("bdd29a"))
		text_in(body,"Gather Wood, Stone and Fiber, then place a garden. Walk close to plant 2 Berries for 6, or 2 Herbs for 5. Discover the Veil Altar to grow Glowcap. Garden plots do not block movement.",13)
	for i in range(gardens.size()):
		var plot=gardens[i]
		var close=farm.nearby(plot)
		var body=visual_panel("Garden %d · %s" % [i+1,"Nearby" if close else game.exploration.bearing(game.survival.at(plot))],farm.status(plot),plot.get("crop","") if not plot.get("crop","").is_empty() else "Garden",Color("c5dfa5") if farm.ready(plot) else Color("a1c49b"))
		if plot.get("crop","").is_empty():
			for crop_name in farm.CROPS:
				var crop=crop_name;var info=farm.CROPS[crop]
				var why=farm.plant_reason(plot,crop)
				text_in(body,"%s: plant %d → harvest %d · about %ds now" % [crop,info.cost,info.yield,ceili(info.seconds/farm.rate())],12)
				action(body,"Plant "+crop+" · %d carried" % game.survival.count(crop),func():farm.plant(plot,crop);show_character("farm"),not why.is_empty())
				if not why.is_empty(): text_in(body,why,11)
		else:
			var why=farm.harvest_reason(plot)
			action(body,"Harvest "+plot.crop,func():farm.harvest(plot);show_character("farm"),not why.is_empty())
			if not why.is_empty(): text_in(body,why,12)
			if not farm.ready(plot):
				text_in(body,"Clearing returns the planting ingredients and resets growth.",11)
				action(body,"Clear crop · recover %d %s" % [farm.CROPS[plot.crop].cost,plot.crop],func():farm.clear_crop(plot);show_character("farm"),not farm.clear_reason(plot).is_empty())
		var row=HBoxContainer.new();body.add_child(row)
		action(row,"Move plot",func():game.begin_build("Garden",plot),not close)
		action(row,"Dismantle",func():game.survival.dismantle(plot);show_character("farm"),not close or not plot.get("crop","").is_empty())
		if not plot.get("crop","").is_empty(): text_in(body,"Moving keeps this crop. Harvest or clear it before dismantling.",11)
	action(content,"Return to the wilds",resume)

func show_storage(chest:Dictionary) -> void:
	game.pause_game();current_page="storage";clear_content("Camp storage",false)
	var why=game.survival.storage_reason(chest)
	if not why.is_empty(): paragraph(why,15)
	else:
		paragraph("Choose a supply to store or take. You keep control of food, building materials and ingredients; nothing moves until you press a transfer button.",14)
		var found=false
		for material in game.survival.MATERIALS:
			var carried=game.survival.count(material);var stored=int(chest.stash.get(material,0))
			if carried==0 and stored==0: continue
			found=true
			var selected=material
			action(content,"%s · carry %d / stored %d" % [selected,carried,stored],func():show_storage_item(chest,selected))
		if not found: paragraph("Both your supplies and this chest are empty.",14)
	action(content,"Back to camp",func():show_character("camp"))

func show_storage_item(chest:Dictionary,material:String,quantity:int=1) -> void:
	game.pause_game();current_page="storage_item";clear_content(material+" · Storage",false)
	var camp=game.survival;var why=camp.storage_reason(chest)
	if not why.is_empty():
		paragraph(why,15);action(content,"Back to camp",func():show_character("camp"));return
	paragraph("Carried: %d · In this chest: %d" % [camp.count(material),int(chest.stash.get(material,0))],16)
	paragraph("Transfer quantity: %d" % quantity,15)
	var row=HBoxContainer.new();content.add_child(row)
	for amount in [1,5,10]:
		var chosen=amount
		action(row,str(chosen),func():show_storage_item(chest,material,chosen),quantity==chosen)
	action(content,"Store %d %s" % [quantity,material],func():camp.transfer_item(chest,material,quantity,true);show_storage_item(chest,material,quantity),camp.transfer_amount(chest,material,true)<quantity)
	action(content,"Take %d %s" % [quantity,material],func():camp.transfer_item(chest,material,quantity,false);show_storage_item(chest,material,quantity),camp.transfer_amount(chest,material,false)<quantity)
	var deposit=camp.transfer_amount(chest,material,true);var withdraw=camp.transfer_amount(chest,material,false)
	action(content,"Store maximum · %d" % deposit,func():camp.transfer_item(chest,material,deposit,true);show_storage_item(chest,material,quantity),deposit<=0)
	action(content,"Take maximum · %d" % withdraw,func():camp.transfer_item(chest,material,withdraw,false);show_storage_item(chest,material,quantity),withdraw<=0)
	paragraph("Transfers respect each stack's 99,999 limit. Ingredients stay in the chest until you take them; crafting uses carried supplies.",13)
	action(content,"Back to chest",func():show_storage(chest))

func recipe_card(recipe:String) -> void:
	var camp=game.survival
	if game.expedition.enabled(): action(content,"Food, water and sleep",func():show_character("needs"))
	var definition=camp.RECIPES[recipe]
	var why=camp.reason(recipe,false)
	var kind=definition.get("kind",recipe)
	var body=visual_panel(recipe,"Ready" if why.is_empty() else why,kind,Color("a4d8b1") if why.is_empty() else Color("acb7b3"))
	text_in(body,definition.desc,13)
	text_in(body,camp.cost_text(recipe),12)
	action(body,("Place " if recipe in camp.STRUCTURES else "Make ")+recipe,func():
		if recipe in camp.STRUCTURES: game.begin_build(recipe)
		else: camp.craft(recipe);show_character("camp"),not why.is_empty())
	if camp.batchable(recipe): action(body,"Choose quantity · "+recipe,func():show_craft_batch(recipe))

func show_craft_batch(recipe:String,quantity:int=1) -> void:
	var camp=game.survival
	if not camp.batchable(recipe): return
	game.pause_game();current_page="craft_batch";clear_content("Make "+recipe,false)
	paragraph(camp.RECIPES[recipe].desc,14)
	paragraph("Batch quantity: %d · Can make now: %d (limit 99)" % [quantity,camp.batch_limit(recipe)],15)
	var row=HBoxContainer.new();content.add_child(row)
	action(row,"−",func():show_craft_batch(recipe,quantity-1),quantity<=1)
	for amount in [1,5,10]:
		var chosen=amount
		action(row,str(chosen),func():show_craft_batch(recipe,chosen),quantity==chosen)
	action(row,"+",func():show_craft_batch(recipe,quantity+1),quantity>=99)
	var maximum=camp.batch_limit(recipe)
	action(content,"Use maximum available · %d" % maximum,func():show_craft_batch(recipe,maximum),maximum<1 or maximum==quantity)
	paragraph(camp.batch_cost(recipe,quantity),14)
	var why=camp.batch_reason(recipe,quantity)
	if not why.is_empty(): paragraph(why,14,Color("efb392"))
	paragraph("Only carried ingredients are used. Crafting does not eat the food or refill survival gauges. Nothing is spent until you confirm the full batch.",13)
	action(content,"Make %d · %s" % [quantity,recipe],func():camp.craft_batch(recipe,quantity);show_craft_batch(recipe,quantity),not why.is_empty())
	action(content,"Back to crafting",func():camp_page="Craft";show_character("camp"))

func visual_panel(title:String,subtitle:String,kind:String,tint:Color) -> VBoxContainer:
	var frame=PanelContainer.new()
	frame.mouse_filter=Control.MOUSE_FILTER_PASS
	var style=StyleBoxFlat.new();style.bg_color=Color("172f33");style.border_color=tint.darkened(.45);style.set_border_width_all(1);style.set_corner_radius_all(12);style.set_content_margin_all(12)
	frame.add_theme_stylebox_override("panel",style);content.add_child(frame)
	var body=VBoxContainer.new();body.add_theme_constant_override("separation",7);frame.add_child(body)
	var header=HBoxContainer.new();body.add_child(header)
	var icon=IconScript.new();icon.kind=kind;icon.tint=tint;header.add_child(icon)
	var words=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(words)
	text_in(words,title,17,tint);text_in(words,subtitle,12)
	return body

func text_in(parent:Node,value:String,font_size:int=14,color:Color=Color("b8ccc0")) -> Label:
	var result=label(parent,value,font_size,color);result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;result.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return result

func show_map() -> void:
	if not game.hero.exploration.target.is_empty(): map_selection=game.hero.exploration.target
	var landscape=get_viewport_rect().size.x>get_viewport_rect().size.y
	var layout_box=HBoxContainer.new() if landscape else VBoxContainer.new();content.add_child(layout_box)
	map_widget=MapScript.new();map_widget.game=game;map_widget.selected=map_selection
	map_widget.local_view=not map_widget.OVERVIEW.has_point(map_widget.position_in_wilds())
	map_widget.custom_minimum_size.y=260 if landscape else 330
	layout_box.add_child(map_widget)
	var details=VBoxContainer.new();details.custom_minimum_size.x=180 if landscape else 0;details.size_flags_horizontal=Control.SIZE_FILL;layout_box.add_child(details)
	map_detail=text_in(details,map_description(map_selection),14,Color("e5d4a8"))
	map_widget.marker_selected.connect(func(id):map_selection=id;map_detail.text=map_description(id))
	action(details,"Track selected",func():game.hero.contracts.target="";game.hero.exploration.target=map_widget.selected;game.save_game();resume())
	action(details,"World overview",func():map_widget.local_view=false;map_widget.queue_redraw())
	action(details,"Around me",func():map_widget.local_view=true;map_widget.queue_redraw())
	action(details,"Resume journey",resume)
	paragraph("Map opens around you beyond the central regions. Around me centers your location; World overview includes you and home. In a dungeon the arrow marks your wilds entrance.",12)
	paragraph("White arrow: you · Gold squares: your camp
Gold rings: completed · Gray markers: undiscovered
Tap a marker, then Track selected.",11)

func map_description(id:String) -> String:
	if id=="trader": return "Mara’s camp market · "+game.exploration.bearing(game.trader.POSITION)
	if id=="home": return "Home / return point · "+game.exploration.bearing(Vector2(game.hero.respawn.x,game.hero.respawn.y))
	if id=="ruins": return "Mossveil Ruins · "+game.exploration.bearing(game.exploration.RUINS)
	return game.exploration.REGIONS[id].landmark+" · "+game.exploration.bearing(game.exploration.REGIONS[id].point)

func show_quests() -> void:
	var board=game.contracts
	action(content,"Story journal · Chapters I–II",func():show_character("chapter"))
	paragraph("Frontier noticeboard",19,Color("eddaaa"))
	paragraph("%d/3 active · %d completed · Board: %s" % [board.data().active.size(),board.data().completed,"in the wilds" if game.hero.dungeon!=null else game.exploration.bearing(board.BOARD)],13)
	if not board.near_board(): paragraph("Accept and turn in at the wooden board northwest of the starting camp. Review and track jobs from anywhere.",13)
	action(content,"Track quest board",func():board.track("board"))
	var remaining=3-posmod(int(board.data().completed),3)
	paragraph("Enchanted gear in %d turn-in%s. Every third completion: Rare; every ninth: Epic. Leave a slot in Gear for the bonus." % [remaining,"" if remaining==1 else "s"],13,Color("c8b8e5"))
	if not board.data().target.is_empty(): action(content,"Stop job tracking",func():board.data().target="";game.save_game();show_character("quests"))
	var pages=HBoxContainer.new();content.add_child(pages)
	for title_value in ["Active","Posted"]:
		var page=title_value
		action(pages,page,func():quest_page=page;show_character("quests"),quest_page==page)
	if quest_page=="Active":
		section("Active jobs")
		if board.data().active.is_empty(): paragraph("No active jobs. Supplies and rations are good first jobs.",13)
		for id_value in board.data().active:
			var id=id_value
			var job=board.JOBS[id]
			var body=visual_panel(job.name,"READY TO TURN IN" if board.ready(id) else board.progress_text(id),job.icon,Color("a7d4ad") if board.ready(id) else Color("c7b691"))
			text_in(body,job.desc,13)
			if board.ready(id): text_in(body,board.progress_text(id),12)
			if id=="survey":
				for region in ["caves","swamp","snow"]:
					text_in(body,("✓ " if board.data().active[id].visited.get(region,false) else "○ ")+game.exploration.REGIONS[region].landmark,12)
			text_in(body,board.reward_text(id),13)
			var why=board.claim_reason(id)
			if not why.is_empty(): text_in(body,why,12)
			action(body,"Turn in "+job.name,func():board.claim(id);show_character("quests"),not why.is_empty())
			action(body,"Track "+job.name,func():board.track(id))
			action(body,"Abandon "+job.name,func():board.abandon(id);show_character("quests"))
	else:
		section("Posted jobs")
		for id_value in board.JOBS:
			var id=id_value
			if board.active(id): continue
			var job=board.JOBS[id]
			var why=board.accept_reason(id)
			var body=visual_panel(job.name,"Available" if why.is_empty() else why,job.icon,Color("b5c8ab"))
			text_in(body,job.desc,13)
			if job.kind=="delivery": text_in(body,"Carried supplies: "+board.progress_text(id)+". Items are consumed only on turn-in.",12)
			text_in(body,board.reward_text(id),13)
			action(body,"Accept "+job.name,func():board.accept(id);quest_page="Active";show_character("quests"),not why.is_empty())
	paragraph("Progress counts only while a job is accepted. Survey jobs require new visits. Abandoning resets that job's progress and keeps your supplies. Completed jobs repost after 10 minutes of active play; menus and time away pause this timer.",12)
	action(content,"Back to camp",func():show_character("camp"))
	action(content,"Resume journey",resume)

func show_trader() -> void:
	var market=game.trader
	action(content,"Speak with Mara · The Hollow Root",func():show_character("chapter"))
	action(content,"Arcane tomes · buy and upgrade spells",func():show_character("spellshop"))
	market.refresh()
	paragraph("%d gold · %s" % [game.hero.gold,market.relation()],13)
	paragraph("Stock level %d · Restocks in %ds of active play" % [market.data().level,market.restock_in()],12)
	if not market.near():
		paragraph("Visit Mara northeast of the original camp to buy or sell. You can browse from anywhere.",13)
		action(content,"Track Mara",func():market.track())
	var pages=HBoxContainer.new();content.add_child(pages)
	for name_value in ["Buy","Sell","Buyback"]:
		var page=name_value
		action(pages,page,func():trader_page=page;show_character("trader"),page==trader_page)
	if trader_page=="Buy":
		var filters=HBoxContainer.new();content.add_child(filters)
		for name_value in ["Supplies","Gear"]:
			var choice=name_value
			action(filters,choice,func():trader_filter=choice;show_character("trader"),choice==trader_filter)
		for listing in market.offers():
			if (trader_filter=="Gear")!=(listing.type=="gear"): continue
			var key=listing.key
			var kind=listing.item.kind if listing.type=="gear" else listing.name
			var tint=Color(Data.RARITIES[listing.item.rarity].color) if listing.type=="gear" else Color("bdcfad")
			var body=visual_panel(listing.name,"%d gold · %d left today" % [listing.price,market.stock(key)],kind,tint)
			if listing.type=="gear":
				text_in(body,"%s · Level %d · Power %d" % [Data.RARITIES[listing.item.rarity].name,listing.item.level,listing.item.power],13)
				var equipped=Data.equipped(game.hero,"armor" if listing.item.kind=="armor" else "weapon")
				if not equipped.is_empty(): text_in(body,"Power versus equipped: %+d" % int(listing.item.power-equipped.power),12)
				if listing.item.enchant>0: text_in(body,Data.ENCHANTS[listing.item.enchant]+" enchanted",13,tint)
			else: text_in(body,"Bundle: %d %s · Carrying %d" % [listing.amount,listing.name,game.survival.count(listing.name)],13)
			var why=market.buy_reason(key)
			if not why.is_empty(): text_in(body,why,12)
			action(body,"Buy %s · %dg" % [listing.name,listing.price],func():market.buy(key);show_character("trader"),not why.is_empty())
	elif trader_page=="Sell":
		var filters=HBoxContainer.new();content.add_child(filters)
		for name_value in ["Supplies","Gear"]:
			var choice=name_value
			action(filters,choice,func():trader_filter=choice;show_character("trader"),choice==trader_filter)
		if trader_filter=="Gear":
			paragraph("Equipped items are protected. Sold equipment goes to Buyback (last 8 pieces).",13)
			var items=game.hero.inventory.filter(func(item):return item.id not in game.hero.equipped.values())
			if not items.any(func(item):return item.id==trader_selected): trader_selected=items[0].id if not items.is_empty() else ""
			if items.is_empty(): paragraph("No spare equipment to sell.")
			for item in items:
				if item.id!=trader_selected: continue
				var id=item.id
				var body=visual_panel(item.name,"%s · Power %d · +%d gold" % [Data.RARITIES[int(item.rarity)].name,item.power,market.gear_value(item)],item.kind,Color(Data.RARITIES[int(item.rarity)].color))
				text_in(body,"Level %d · Upgrade +%d · %s" % [item.level,item.upgrade,Data.ENCHANTS[int(item.enchant)]],12)
				var why=market.sell_reason(id)
				if not why.is_empty(): text_in(body,why,12)
				action(body,"Sell selected · %dg" % market.gear_value(item),func():market.sell_gear(id);show_character("trader"),not why.is_empty())
			var grid=GridContainer.new();grid.columns=4 if get_viewport_rect().size.x<700 else 6;content.add_child(grid)
			for item in items:
				var id=item.id
				var card=CardScript.new();card.caption=item.name;card.subtitle="%dg" % market.gear_value(item);card.kind=item.kind;card.tint=Color(Data.RARITIES[int(item.rarity)].color);card.chosen=id==trader_selected
				card.pressed.connect(func():trader_selected=id;show_character("trader"));grid.add_child(card)
		else:
			paragraph("Materials and food are sold from carried supplies. Supplies are not kept in Buyback.",13)
			var shown=0
			for name_value in market.SELL_RATES:
				var material=name_value;var owned=game.survival.count(material)
				if owned<1: continue
				shown+=1
				var body=visual_panel(material,"%d carried · %dg each" % [owned,market.SELL_RATES[material]],material,Color("b9caaa"))
				var row=HBoxContainer.new();body.add_child(row)
				for amount in [1,10]:
					var quantity=amount
					action(row,"Sell %d" % quantity,func():market.sell_supplies(material,quantity);show_character("trader"),not market.near() or owned<quantity)
				action(row,"Sell all",func():market.sell_supplies(material,owned);show_character("trader"),not market.near())
			if shown==0: paragraph("No carried supplies to sell.")
	else:
		paragraph("The last 8 sold equipment pieces stay here across days and saves. Recovery costs the sale payout +10%, at least 1 extra gold. Older pieces leave when a ninth item is sold.",13)
		if market.data().buyback.is_empty(): paragraph("No equipment waiting in Buyback.")
		for entry in market.data().buyback:
			var id=entry.item.id
			var body=visual_panel(entry.item.name,"%s · Power %d" % [Data.RARITIES[int(entry.item.rarity)].name,entry.item.power],entry.item.kind,Color(Data.RARITIES[int(entry.item.rarity)].color))
			text_in(body,"Level %d · Upgrade +%d · %s" % [entry.item.level,entry.item.upgrade,Data.ENCHANTS[int(entry.item.enchant)]],12)
			var why=market.buyback_reason(id)
			if not why.is_empty(): text_in(body,why,12)
			action(body,"Buy back · %dg" % market.buyback_price(entry),func():market.buyback(id);show_character("trader"),not why.is_empty())
	action(content,"Back to camp",func():show_character("camp"))
	action(content,"Resume journey",resume)
