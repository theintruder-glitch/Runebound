extends RefCounted
const SPOTS={
	"forest":{"name":"Willow Pool","pond":Vector2(340,320),"bank":Vector2(340,390),"fish":"Silver trout","color":"75b4c3"},
	"swamp":{"name":"Reedwater Pool","pond":Vector2(-1760,320),"bank":Vector2(-1760,390),"fish":"Marsh eel","color":"83ad8c"},
	"snow":{"name":"Iceglint Pool","pond":Vector2(400,-1680),"bank":Vector2(400,-1610),"fish":"Frost salmon","color":"a7def0"}
}
const SPECIES=["Silver trout","Marsh eel","Frost salmon","Starfin"]
const ROD_COST={"Wood":4,"Fiber":6,"Rope":1}
var game
var stage=""
var spot_id=""
var timer=0.0
var origin=Vector2.ZERO
func data() -> Dictionary: return game.hero.angler
func active() -> bool: return not stage.is_empty()
func reset() -> void:
	stage="";spot_id="";timer=0.0
func nearby() -> String:
	if game.hero.is_empty() or game.hero.dungeon!=null: return ""
	for id in SPOTS:
		if game.player_position().distance_to(SPOTS[id].bank)<65 and game.line_clear(game.player_position(),SPOTS[id].bank): return id
	return ""
func danger() -> bool:
	return game.enemies.any(func(e):return not e.dead and not e.get("neutral",false) and e.pos.distance_to(game.player_position())<260)
func craft_reason() -> String:
	if game.hero.is_empty() or game.hero.hp<=0: return "Continue a living character first"
	if data().rod: return "Rod already crafted"
	if game.hero.dungeon!=null or not game.build_recipe.is_empty(): return "Craft in the wilds without a building ghost"
	for name in ROD_COST:
		if game.survival.count(name)<ROD_COST[name]: return "Need 4 Wood, 6 Fiber and 1 Rope"
	return ""
func craft_rod() -> bool:
	var why=craft_reason()
	if not why.is_empty(): game.notify(why,3);return false
	for name in ROD_COST: game.survival.add(name,-ROD_COST[name])
	data().rod=true;game.sound("build");game.notify("Fishing rod crafted. Carry berries for bait.",4);game.save_game();return true
func cast_reason() -> String:
	if not game.playing or game.hero.is_empty() or game.hero.hp<=0: return "Resume your journey before casting"
	if not data().rod: return "Craft a fishing rod in Camp > Fishing"
	if nearby().is_empty(): return "Stand at a marked fishing bank"
	if not game.build_recipe.is_empty() or not game.spellbook.targeting.is_empty(): return "Finish or cancel placement before fishing"
	if game.dash_time>0 or game.is_walking: return "Stop moving before casting"
	if game.exploration.active() or game.forest.active() or danger(): return "Clear hostile enemies before fishing"
	if game.survival.count("Raw fish")>=99999: return "Make room for raw fish"
	if game.survival.count("Berries")<1: return "Carry a berry for bait"
	return ""
func cast_line() -> bool:
	if active(): return false
	var why=cast_reason()
	if not why.is_empty(): game.notify(why,3);return false
	spot_id=nearby();origin=game.player_position();stage="waiting";timer=randf_range(3.5,6.0)
	game.survival.add("Berries",-1);game.attack_held=false;game.desktop.clear_input()
	game.sound("gather");game.notify("Line cast. Wait for BITE, then interact to reel in.",4)
	game.save_game();game.update_interaction();return true
func cancel(message:String="Line packed away. Bait was used.") -> void:
	if not active(): return
	reset()
	if not message.is_empty(): game.notify(message,3)
func tick(dt:float) -> void:
	if not active() or not game.playing or dt<=0: return
	if game.hero.hp<=0 or game.hero.dungeon!=null or not game.build_recipe.is_empty() or nearby()!=spot_id or game.player_position().distance_to(origin)>8 or game.is_walking or game.dash_time>0 or danger():
		cancel("Fishing interrupted. Clear a safe bank and try again.");return
	timer-=dt
	if timer>0: return
	if stage=="waiting":
		stage="bite";timer=2.5;game.sound("reward");game.notify("BITE! Interact now to reel in.",2.5);game.update_interaction()
	else: cancel("The fish escaped. Cast again with a fresh berry.");game.update_interaction()
func reel() -> bool:
	if not active() or not game.playing: return false
	if stage!="bite": cancel("Too early! Wait for the BITE cue.");return false
	if nearby()!=spot_id or game.player_position().distance_to(origin)>8 or game.is_walking or game.dash_time>0 or game.hero.hp<=0 or danger(): cancel("Fishing interrupted.");return false
	if game.survival.count("Raw fish")>=99999: cancel("Raw fish stack full. Make room before casting again.");return false
	var species="Starfin" if randf()<.12 else SPOTS[spot_id].fish
	reset();game.survival.add("Raw fish",1);data().records[species]=mini(1000000,int(data().records.get(species,0))+1)
	game.sound("gather");game.notify("Caught "+species+" · +1 Raw fish. Cook it at a campfire.",4)
	if not data().rewarded and SPECIES.slice(0,3).all(func(name):return int(data().records.get(name,0))>0):
		data().rewarded=true;game.hero.gold+=150;game.hero.essence+=3
		game.notify("ANGLER'S JOURNEY COMPLETE · +150 gold and 3 essence",6)
	game.save_game();game.update_interaction();return true
func interaction() -> String:
	if stage=="bite": return "REEL IN!"
	if stage=="waiting": return "WAIT FOR BITE / CANCEL"
	return "FISH / CAST LINE" if not nearby().is_empty() else ""
func interact() -> void:
	if active(): reel()
	else: cast_line()
func objective() -> String:
	if active(): return "BITE! Interact to reel in · %.1fs" % maxf(0,timer) if stage=="bite" else "FISHING · Watch for BITE · Interact early to cancel"
	if not game.hero.exploration.target.is_empty() or not game.hero.contracts.target.is_empty(): return ""
	var target=data().target
	if SPOTS.has(target): return SPOTS[target].name+" · "+game.exploration.bearing(SPOTS[target].bank)
	return ""
func show_menu() -> void:
	var hud=game.hud
	hud.paragraph("Craft a rod, carry berries for bait and stand at a marked bank. Interact to cast. Wait for BITE, then interact again within 2.5 seconds. Moving, nearby hostiles or opening a menu ends the attempt; bait is spent when you cast.",14)
	if not data().rod:
		var body=hud.visual_panel("Fishing rod","HANDCRAFTED TOOL","fishing rod",Color("c9b780"))
		hud.text_in(body,"4 Wood, 6 Fiber, 1 Rope. Make rope under Camp > Craft > Parts. The rod is permanent and uses no gear slot.",14)
		var why=craft_reason()
		if not why.is_empty(): hud.text_in(body,why,12)
		hud.action(body,"Craft fishing rod",func():craft_rod();hud.show_character("fishing"),not why.is_empty())
	else: hud.paragraph("Rod ready · %d bait berries · %d Raw fish" % [game.survival.count("Berries"),game.survival.count("Raw fish")],15)
	hud.section("Angler's journal")
	for id in SPOTS:
		var region=id;var spot=SPOTS[id]
		var body=hud.visual_panel(spot.name,spot.fish+" · caught %d" % int(data().records.get(spot.fish,0)),"fish",Color(spot.color))
		hud.text_in(body,game.exploration.REGIONS[id].name+" · "+game.exploration.bearing(spot.bank),14)
		hud.action(body,"Track "+spot.name,func():data().target=region;game.hero.exploration.target="";game.hero.contracts.target="";game.save_game();hud.resume())
	hud.paragraph("Rare catch: Starfin · %d recorded. Every catch adds one Raw fish to your supplies." % int(data().records.get("Starfin",0)),13)
	hud.paragraph("Catch each of the three regional fish to earn 150 gold and 3 essence once. "+("Reward earned." if data().rewarded else "Journey in progress."),14)
	if not data().target.is_empty(): hud.action(hud.content,"Stop tracking fishing bank",func():data().target="";game.save_game();hud.show_character("fishing"))
	hud.action(hud.content,"Open camp cooking",func():hud.camp_page="Craft";hud.craft_filter="Food";hud.show_character("camp"))
	hud.action(hud.content,"Back to camp",func():hud.show_character("camp"))
func draw_pools(canvas:CanvasItem,bounds:Rect2) -> void:
	for id in SPOTS:
		var spot=SPOTS[id];var at:Vector2=spot.pond
		if not bounds.grow(100).has_point(at): continue
		canvas.draw_circle(at,55,Color("597567"));canvas.draw_circle(at,48,Color("214f66"))
		canvas.draw_arc(at,34,.2,2.6,24,Color(spot.color),2)
		canvas.draw_arc(at+Vector2(-6,6),19,3.3,5.9,20,Color(spot.color).darkened(.2),2)
		var bank:Vector2=spot.bank
		canvas.draw_rect(Rect2(bank-Vector2(16,8),Vector2(32,16)),Color("b99b71"))
		canvas.draw_string(ThemeDB.fallback_font,bank+Vector2(-40,28),"FISHING BANK",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("dfdfb4"))
func draw_line(canvas:CanvasItem) -> void:
	if not active(): return
	var pond:Vector2=SPOTS[spot_id].pond
	canvas.draw_line(game.player_position()+Vector2(6,-14),pond,Color("e9dfae"),1)
	canvas.draw_circle(pond,5 if stage=="bite" else 3,Color("f9c57b") if stage=="bite" else Color("cce7d6"))
