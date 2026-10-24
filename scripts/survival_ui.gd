extends RefCounted
var hud
var game
var selected_mode="survival"
var needs_panel:PanelContainer
var gauges={}
var status:Label
var mode_button:Button
func setup() -> void:
	mode_button=hud.action(hud.top,"[V] Survival",func():hud.show_character("needs"));mode_button.name="Survival"
	mode_button.visible=game.desktop.enabled
	needs_panel=PanelContainer.new();needs_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.top.add_child(needs_panel)
	var style=StyleBoxFlat.new();style.bg_color=Color("111f2bed");style.border_color=Color("7f927a88");style.set_border_width_all(1);style.set_corner_radius_all(10);style.set_content_margin_all(10);needs_panel.add_theme_stylebox_override("panel",style)
	var column=VBoxContainer.new();column.mouse_filter=Control.MOUSE_FILTER_IGNORE;needs_panel.add_child(column)
	for entry in [["hunger","FOOD","dbb472"],["water","WATER","85c9ef"],["sleep","REST","b7a1df"]]:
		var row=HBoxContainer.new();row.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(row)
		var name_label=hud.label(row,entry[1],11,Color(entry[2]));name_label.custom_minimum_size.x=54;name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var bar=hud.make_bar(row,Color(entry[2]));bar.custom_minimum_size=Vector2(138,12);bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var number=hud.label(row,"100",11);number.custom_minimum_size.x=30;number.mouse_filter=Control.MOUSE_FILTER_IGNORE
		gauges[entry[0]]={"bar":bar,"number":number}
	status=hud.label(column,"Comfortable",11,Color("b9dac6"));status.mouse_filter=Control.MOUSE_FILTER_IGNORE
func layout() -> void:
	var view=hud.get_viewport_rect().size
	mode_button.position=Vector2(view.x-390,16);mode_button.size=Vector2(118,44)
	var compact=not game.desktop.enabled and view.x>view.y
	needs_panel.position=Vector2(view.x-284,82) if game.desktop.enabled else Vector2(17,158 if compact else 232)
	for key in gauges:
		gauges[key].bar.custom_minimum_size.x=72 if compact else 138
		gauges[key].number.custom_minimum_size.x=26 if compact else 30
	needs_panel.size=Vector2(188 if compact else 262,108)
func update() -> void:
	needs_panel.visible=game.expedition.enabled()
	if needs_panel.visible:
		for key in gauges:
			gauges[key].bar.value=game.hero.needs[key];gauges[key].number.text=str(ceili(game.hero.needs[key]))
		status.text=("COLD" if game.hero.needs.temperature<20 else "HOT" if game.hero.needs.temperature>80 else "WET" if game.hero.needs.wetness>=60 else "MILD")+" · Flask %d/%d" % [game.hero.needs.flask,game.kit.capacity()]
func show_modes(new_game:bool=false) -> void:
	game.pause_game();hud.current_page="modes";hud.clear_content("Choose how you play",false)
	if not new_game: hud.paragraph("Change the rules for your current character. Your gear, camp and discoveries stay with you. Survival gauges are preserved when switching back.",14)
	for id in ["survival","classic"]:
		var mode=id
		hud.section("Survival · A home in the wilds" if id=="survival" else "Classic adventure")
		hud.paragraph("Food, water, sleep, cold and heat matter. Build a home, harvest food, survive five days and finish a five-floor expedition. Completion rewards 500 gold and 8 essence; you may keep playing." if id=="survival" else "Explore freely, build and learn magic. No hunger or thirst; the endless dungeon is optional.",15)
		var disabled=not new_game and (game.hero.mode==id or game.hero.dungeon!=null)
		hud.action(hud.content,("New " if new_game else "Play ")+("Survival" if id=="survival" else "Classic adventure"),func():
			if new_game: selected_mode=mode;hud.show_classes(true)
			else: game.expedition.switch_mode(mode);hud.resume(),disabled)
	if not new_game and game.hero.dungeon!=null: hud.paragraph("Return to the wilds before changing modes.")
	hud.action(hud.content,"Back",func():hud.show_title(not game.Data.read_save().is_empty()) if new_game else hud.show_pause())
func fresh_character(cls:String) -> Dictionary:
	var character=game.Data.fresh(cls);character.mode=selected_mode
	if selected_mode=="survival": character.survival.materials={"Berries":6,"Roasted meat":2}
	return character
func show_needs() -> void:
	var exp=game.expedition
	if not exp.enabled():
		hud.paragraph("Classic adventure has no hunger, thirst or sleep drain. Select Survival for those rules.",16)
		hud.action(hud.content,"Choose game mode",func():show_modes());return
	hud.paragraph(exp.condition(),18,Color("e4d5a7"));var n=exp.data()
	hud.paragraph("Food %d / 100 · Water %d / 100 · Rest %d / 100\nBody warmth %d / 100 · 50 is comfortable" % [n.hunger,n.water,n.sleep,n.temperature],15)
	hud.paragraph("Wetness %d / 100. Rain and snow soak clothing and make cold exposure worse. Roofs and shelters keep rain off and let clothing dry; a reachable lit fire dries it faster. Warm tea helps warmth. Empty food or water and extreme temperatures hurt. Low water or rest slows movement. Needs pause in menus and while away." % n.wetness,13)
	hud.section("Water")
	hud.action(hud.content,"Drink flask · %d / %d charges · +45 water" % [n.flask,game.kit.capacity()],func():exp.drink();hud.show_character("needs"),n.flask<=0 or n.water>=100)
	hud.action(hud.content,"Drink and refill at the spring",func():exp.drink(true);hud.show_character("needs"),not exp.near_spring())
	hud.paragraph("The marked spring is 16m east and 5m north of the original camp. Stand beside it and interact. Your flask holds %d drinks; craft a large waterskin to carry six." % game.kit.capacity(),13)
	hud.section("Carried food")
	for name_value in exp.FOOD:
		var food=name_value;var amount=game.survival.count(food)
		if amount>0: hud.action(hud.content,"Eat %s · %d carried · +%d food" % [food,amount,exp.FOOD[food]],func():exp.eat(food);hud.show_character("needs"),n.hunger>=100)
	hud.action(hud.content,"Survival kit · craft and manage",func():hud.show_character("kit"))
	hud.section("Sleep")
	var bed=game.survival.near("Bed",110)
	hud.action(hud.content,"Rest at nearby bed · -6 food / -8 water",func():game.survival.rest(bed);hud.show_character("needs"),bed.is_empty())
	hud.paragraph("Craft a bed and keep enemies away. Rest restores sleep and sets your return point. Rest does not skip the world clock.",13)
	hud.section("A home in the wilds · "+("complete" if n.won else "chapter objectives"))
	var done=exp.objectives();var objectives=["Survive five active days · %d / 3000 seconds" % mini(3000,int(n.elapsed)),"Build a shelter and a bed","Harvest a planted garden","Clear floor five of a Survival expedition"]
	for i in range(4): hud.paragraph(("✓ " if done[i] else "○ ")+objectives[i],14)
	hud.paragraph("Defeat starts a new five-day survival attempt. Built structures, harvest and expedition goals stay completed. There is no permanent death.",12)
	hud.action(hud.content,"Open camp crafting",func():hud.show_character("camp"))
	hud.action(hud.content,"Resume survival",hud.resume)
