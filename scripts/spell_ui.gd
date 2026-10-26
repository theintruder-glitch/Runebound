extends RefCounted
var hud
var game
var button:Button
var aim_controls:Control
var cast_button:Button
var cancel_button:Button
func setup() -> void:
	button=hud.action(hud.top,"[B] Spells",func():hud.show_character("spells"));button.visible=game.desktop.enabled
	aim_controls=Control.new();hud.buttons.add_child(aim_controls)
	cast_button=hud.action(aim_controls,"CAST",func():pass,false,true)
	cancel_button=hud.action(aim_controls,"CANCEL",func():pass,false,true)
	for control in [cast_button,cancel_button]: control.custom_minimum_size=Vector2(108,52)
	cast_button.position=Vector2.ZERO;cast_button.size=Vector2(108,52)
	cancel_button.position=Vector2(116,0);cancel_button.size=Vector2(108,52)
	aim_controls.hide()
func layout() -> void:
	button.position=Vector2(hud.get_viewport_rect().size.x-508,16);button.size=Vector2(108,44)
	var view=hud.get_viewport_rect().size
	aim_controls.position=Vector2(view.x/2-112,view.y-128 if view.x>view.y else view.y-325)
	aim_controls.size=Vector2(224,52)
func update_targeting() -> void:
	var book=game.spellbook
	aim_controls.visible=game.playing and not game.desktop.enabled and not book.targeting.is_empty()
	if aim_controls.visible:
		cast_button.disabled=not book.can_cast(book.targeting) or not book.valid_ground(book.target_point())
func update() -> void:
	for i in range(3):
		var b=hud.spell_buttons[["fire","frost","heal"][i]]
		var id=game.hero.spells.slots[i];var info=game.spellbook.BOOK[id];var cd=float(game.spell_cooldowns.get(id,0))
		b.text=("[%d] " % (i+1) if game.desktop.enabled else "")+info.short+"\n"+("%.1fs" % cd if cd>.1 else "%d MP" % info.cost)
		b.tooltip_text=info.name+" · "+info.desc;b.disabled=cd>.1 or game.hero.mp<info.cost or not game.build_recipe.is_empty()
		b.add_theme_color_override("font_color",Color(info.color))
		if game.desktop.enabled:
			for state in ["normal","hover","pressed"]:
				var style=hud.theme.get_stylebox(state,"Button").duplicate();style.set_content_margin_all(5)
				style.bg_color=Color("1c2c40") if state=="normal" else Color("354459");style.border_color=Color(info.color);style.border_width_bottom=3
				b.add_theme_stylebox_override(state,style)
func show_spells() -> void:
	var book=game.spellbook;var names=[]
	for i in range(3): names.append("[%d] %s" % [i+1,book.BOOK[game.hero.spells.slots[i]].name])
	hud.paragraph("  ·  ".join(names),17,Color("e8e4d5"))
	hud.paragraph("Assign learned spells below. Assigning a spell already on your bar swaps those slots. Meteor / Blizzard: select the spell, then "+book.placement_hint()+". The preview costs no mana; the fight keeps moving while you aim.",13)
	hud.action(hud.content,"Buy spells and upgrades from Mara",func():hud.show_character("spellshop"))
	for name_value in book.BOOK:
		var id=name_value
		if not book.known(id): continue
		var info=book.BOOK[id];var body=hud.visual_panel(info.name,"Rank %d · %d MP · %.1fs cooldown" % [book.rank(id),info.cost,info.cooldown],"staff",Color(info.color))
		hud.text_in(body,info.desc,13);var row=HBoxContainer.new();body.add_child(row)
		for i in range(3):
			var slot=i
			hud.action(row,"Slot %d%s" % [i+1," · equipped" if game.hero.spells.slots[i]==id else ""],func():book.assign(id,slot);hud.show_character("spells"),game.hero.spells.slots[i]==id)
	hud.action(hud.content,"Resume journey",hud.resume)
func show_shop() -> void:
	var book=game.spellbook
	hud.paragraph("MARA'S ARCANE TOMES · %d gold" % game.hero.gold,17,Color("ecd69e"))
	hud.paragraph("Learn permanent spells. Extra ranks add 25% damage per rank; Astral Ward gains 2 seconds per rank. Equip learned spells in your spellbook.",13)
	if not game.trader.near(): hud.action(hud.content,"Track Mara on the map",func():game.trader.track())
	for name_value in book.BOOK:
		var id=name_value;var info=book.BOOK[id]
		if info.price==0: continue
		var why=book.buy_reason(id);var body=hud.visual_panel(info.name,"Level %d · Rank %d / 3 · %d MP" % [info.level+book.rank(id)*2,book.rank(id),info.cost],"staff",Color(info.color))
		hud.text_in(body,info.desc,13)
		if not why.is_empty(): hud.text_in(body,why,12)
		hud.action(body,("Learn" if book.rank(id)==0 else "Upgrade")+" · %dg" % book.price(id),func():book.buy(id);hud.show_character("spellshop"),not why.is_empty())
	hud.action(hud.content,"Equip learned spells",func():hud.show_character("spells"))
	hud.action(hud.content,"Back to Mara's market",func():hud.show_character("trader"))
