extends RefCounted

const RECIPES={
	"waterskin":{"name":"Large waterskin","cost":{"Hide":4,"Rope":2},"bench":true,"icon":"waterskin","description":"Carry six flask drinks instead of three. Refill at the spring after crafting; no free water is added."},
	"cloak":{"name":"Trail cloak","cost":{"Hide":6,"Fiber":8},"bench":true,"icon":"cloak","description":"Raises cold exposure targets by 25 warmth, up to comfortable. Adds 12 warmth in hot weather. Take it off in summer sun."},
	"bedroll":{"name":"Travel bedroll","cost":{"Hide":3,"Fiber":6,"Rope":1},"bench":false,"icon":"bedroll","description":"Rest outdoors away from hostiles: +45 rest, up to 80. Costs 12 food and 16 water. Wait two active minutes between uses. Does not heal or move your return point."}
}
const REST_COOLDOWN=120.0
var game
func data() -> Dictionary: return game.hero.kit
func owns(id:String) -> bool: return not game.hero.is_empty() and bool(data().get(id,false))
func capacity() -> int: return 6 if owns("waterskin") else 3
func wearing_cloak() -> bool: return owns("cloak") and data().cloak_worn
func craft_reason(id:String) -> String:
	if not RECIPES.has(id): return "Unknown kit recipe"
	if game.hero.is_empty() or game.hero.hp<=0: return "Continue a living character first"
	if owns(id): return "Already crafted"
	if game.hero.dungeon!=null: return "Craft your kit in the wilds"
	if not game.build_recipe.is_empty(): return "Finish or cancel building placement first"
	if RECIPES[id].bench:
		var bench=game.survival.near("Workbench")
		if bench.is_empty() or not game.line_clear(game.player_position(),game.survival.at(bench)): return "Stand near a reachable workbench"
	for material in RECIPES[id].cost:
		if game.survival.count(material)<RECIPES[id].cost[material]: return "Gather more materials"
	return ""
func craft(id:String) -> bool:
	var reason=craft_reason(id)
	if not reason.is_empty(): game.notify(reason,3);return false
	for material in RECIPES[id].cost: game.survival.add(material,-RECIPES[id].cost[material])
	data()[id]=true
	if id=="cloak": data().cloak_worn=true
	game.sound("build");game.notify("Crafted "+RECIPES[id].name,3)
	game.save_game();game.hud.update_hud();return true
func toggle_cloak() -> bool:
	if not owns("cloak"): return false
	data().cloak_worn=not data().cloak_worn
	game.save_game();game.hud.update_hud();return true
func exposure(target:float) -> float:
	if not wearing_cloak(): return target
	if target<50: return minf(50,target+25)
	return minf(100,target+12) if target>50 else target
func rest_reason() -> String:
	if not game.expedition.enabled(): return "Bedroll rest is available in Survival mode"
	if not owns("bedroll"): return "Craft a travel bedroll first"
	if game.hero.hp<=0: return "You cannot rest while defeated"
	if game.hero.dungeon!=null or game.exploration.region_at(game.player_position())=="caves": return "Find an outdoor campsite"
	if not game.build_recipe.is_empty(): return "Finish or cancel building placement first"
	if game.exploration.active(): return "Finish or leave the active trial first"
	if game.hero.needs.sleep>=80: return "Use a proper bed for rest above 80"
	if data().rest_until>game.hero.worldTime: return "Ready in %d active seconds" % ceili(data().rest_until-game.hero.worldTime)
	if game.hero.needs.hunger<12 or game.hero.needs.water<16: return "Need at least 12 food and 16 water"
	if game.hero.needs.temperature<20 or game.hero.needs.temperature>80: return "Get warm or cool down before resting"
	for enemy in game.enemies:
		if not enemy.dead and not enemy.get("neutral",false) and enemy.pos.distance_to(game.player_position())<260: return "Hostile enemies are too close to rest"
	return ""
func rest() -> bool:
	var reason=rest_reason()
	if not reason.is_empty(): game.notify(reason,3);return false
	var needs=game.hero.needs
	needs.sleep=minf(80,needs.sleep+45);needs.hunger-=12;needs.water-=16
	data().rest_until=game.hero.worldTime+REST_COOLDOWN
	game.sound("cook");game.notify("Rested on your bedroll. A proper bed restores full rest.",4)
	game.save_game();game.hud.update_hud();return true
func show_menu() -> void:
	var hud=game.hud
	hud.paragraph("Made once, carried with your character. Kit does not use equipment bag slots. Your armor and weapons stay equipped.",14)
	if not game.expedition.enabled(): hud.paragraph("Craft now if you like; water, warmth and rest benefits apply in Survival mode.",13)
	for key in RECIPES:
		var id=key;var recipe=RECIPES[id];var owned=owns(id)
		var body=hud.visual_panel(recipe.name,"CRAFTED" if owned else "CRAFTABLE KIT",recipe.icon,Color("c8b590"))
		hud.text_in(body,recipe.description,14)
		if not owned:
			var costs=PackedStringArray()
			for material in recipe.cost: costs.append("%d %s (%d carried)" % [recipe.cost[material],material,game.survival.count(material)])
			hud.text_in(body,", ".join(costs),13)
			var reason=craft_reason(id)
			hud.text_in(body,("Workbench required. " if recipe.bench else "Handcrafted. ")+reason,12)
			hud.action(body,"Craft "+recipe.name,func():craft(id);hud.show_character("kit"),not reason.is_empty())
		elif id=="waterskin": hud.text_in(body,"Flask: %d / %d drinks. Refill at the spring." % [game.hero.needs.flask,capacity()],14)
		elif id=="cloak": hud.action(body,"Take off cloak" if wearing_cloak() else "Wear cloak",func():toggle_cloak();hud.show_character("kit"))
		elif id=="bedroll":
			var reason=rest_reason()
			if not reason.is_empty(): hud.text_in(body,reason,13)
			hud.action(body,"Rest on bedroll · +45 (max 80)",func():rest();hud.show_character("kit"),not reason.is_empty())
	hud.action(hud.content,"Food, water and sleep",func():hud.show_character("needs"))
	hud.action(hud.content,"Back to camp",func():hud.show_character("camp"))
