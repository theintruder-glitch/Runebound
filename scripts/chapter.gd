extends RefCounted
const Data=preload("res://scripts/data.gd")
const FLOORS=["Buried Gate","Rootworks","Heart Chamber"]
const CLUES={
 "watch":{"name":"Silent Watch","point":Vector2(-520,-350),"text":"A scout's journal: the roots pulse toward the ruins. The forest is feeding something underground."},
 "cart":{"name":"Broken Caravan","point":Vector2(850,180),"text":"Mara's missing caravan carried a cracked rune. Its inscription says: a heart divided can still be healed."},
 "grove":{"name":"Ashen Grove","point":Vector2(-420,620),"text":"Beneath the ash, a living seed glows. The corruption began below Mossveil; the Elder Shrine is not its source."}
}
var game
var trap_clock=0.0
var traps:Array=[]
func data() -> Dictionary: return game.hero.chapter
func story_run() -> bool: return game.hero.dungeon!=null and game.hero.dungeon.get("story",false)
func stage() -> int:
	if not data().accepted: return 0
	if data().clues.size()<3: return 1
	if not data().translated: return 2
	if not data().cleared: return 3
	if not data().claimed: return 4
	return 5
func track() -> void:
	data().tracking=true;game.hero.exploration.target="";game.hero.contracts.target="";game.hero.angler.target=""
	game.save_game();game.hud.resume()
func objective() -> String:
	if not data().tracking or stage()==5: return ""
	var lead="THE HOLLOW ROOT · "
	if stage() in [0,2,4]: return lead+"Speak with Mara · "+game.exploration.bearing(game.trader.POSITION)
	if stage()==1:
		for id in CLUES:
			if not data().clues.has(id): return lead+CLUES[id].name+" · "+game.exploration.bearing(CLUES[id].point)
	return lead+("Floor %d/3 · Clear the roots; gold stairs lead onward" % game.hero.dungeon.floor if story_run() else "Enter the story expedition · "+game.exploration.bearing(game.exploration.RUINS))
func accept() -> bool:
	if not game.trader.near() or stage()!=0: return false
	data().accepted=true;data().tracking=true
	game.save_game();game.hud.update_hud();return true
func translate() -> bool:
	if not game.trader.near() or stage()!=2: return false
	data().translated=true;game.hero.gold+=40;game.grant_xp(45)
	game.save_game();return true
func nearby_clue() -> String:
	if game.hero.dungeon!=null or stage()!=1: return ""
	for id in CLUES:
		if not data().clues.has(id) and game.player_position().distance_to(CLUES[id].point)<70 and game.line_clear(game.player_position(),CLUES[id].point): return id
	return ""
func investigate(id:String) -> bool:
	if nearby_clue()!=id or id.is_empty(): return false
	data().clues[id]=true;game.grant_xp(25);game.notify(CLUES[id].text,8);game.sound("reward");game.save_game();return true
func begin() -> bool:
	if stage()!=3 or game.hero.dungeon!=null or game.player_position().distance_to(game.exploration.RUINS)>=80: return false
	game.enter_dungeon(true);return true
func floor_setup() -> void:
	traps.clear();trap_clock=0
	if not story_run(): return
	var cells=game.dungeon_map.floors.filter(func(c):return c!=game.dungeon_map.start and c!=game.dungeon_map.exit and Vector2(c).distance_to(Vector2(game.dungeon_map.start))>3)
	for i in range(mini(2,cells.size())): traps.append(game.cell_center(cells[int(cells.size()*(i+1)/3.0)]))
	if game.hero.dungeon.floor==3:
		var id="3:heart"
		if id not in game.hero.dungeon.cleared:
			var boss=game.create_enemy(game.cell_center(game.dungeon_map.exit),maxi(3,game.hero.level),"guardian",true)
			boss.named="The Hollow Heart";boss.chapter_boss=true;boss.dungeon_id=id
			boss.hp=float(300+game.hero.level*24);boss.max_hp=boss.hp;boss.contact_damage=14+game.hero.level;boss.reward_gold=45
			game.enemies.append(boss)
func floor_cleared() -> void:
	if story_run() and game.hero.dungeon.floor==3 and not data().cleared:
		data().cleared=true;game.notify("THE HOLLOW ROOT IS SILENT · Return to Mara for Hearthcall.",7)
func claim() -> bool:
	if not game.trader.near() or stage()!=4: return false
	data().claimed=true;data().tracking=false;game.hero.gold+=250;game.hero.essence+=5;game.hero.points+=2
	game.notify("CHAPTER COMPLETE · Hearthcall unlocked · +250 gold, +5 essence, +2 stat points",8)
	game.sound("reward");game.save_game();return true
func recall_reason() -> String:
	if not data().claimed: return "Complete The Hollow Root first"
	if game.hero.hp<=0 or game.hero.dungeon!=null or game.exploration.active(): return "Return from the expedition or trial first"
	if not game.build_recipe.is_empty(): return "Finish building placement first"
	if data().return_until>game.hero.worldTime: return "Ready in %ds of active play" % ceili(data().return_until-game.hero.worldTime)
	for e in game.enemies:
		if not e.dead and not e.get("neutral",false) and e.pos.distance_to(game.player_position())<260: return "Move away from hostile enemies"
	return ""
func recall() -> bool:
	if not recall_reason().is_empty(): return false
	var home=game.safe_wilds_position(Vector2(game.hero.respawn.x,game.hero.respawn.y))
	game.fishing.cancel();game.spellbook.cancel_target();game.hud.reset_stick();game.attack_held=false
	game.set_player_position(home);game.camera.position=home;game.camera.reset_smoothing()
	game.survival.refresh(true);game.populate_chests(true);game.world.refresh(true)
	data().return_until=game.hero.worldTime+120;game.save_game();game.notify("Hearthcall · Returned to your camp. No healing or free supplies.",4);return true
func cache_position() -> Vector2:
	var cells=game.dungeon_map.floors
	return game.cell_center(cells[maxi(0,cells.size()-2)])
func cache_key() -> String: return "hollow-cache:%s:%d" % [game.hero.dungeon.run,game.hero.dungeon.floor]
func cache_near() -> bool:
	return story_run() and not game.hero.opened.has(cache_key()) and game.player_position().distance_to(cache_position())<42 and game.line_clear(game.player_position(),cache_position())
func interaction() -> String:
	if cache_near(): return "OPEN RUNIC CACHE"
	var clue=nearby_clue()
	if not clue.is_empty(): return "INVESTIGATE "+CLUES[clue].name.to_upper()
	return ""
func interact() -> void:
	if cache_near():
		game.hero.opened[cache_key()]=true;game.hero.gold+=20;game.hero.mp=minf(Data.max_mp(game.hero),game.hero.mp+20)
		game.notify("Runic cache · +20 gold, +20 mana",4);game.sound("reward");game.save_game()
	else: investigate(nearby_clue())
func tick(dt:float) -> void:
	if not story_run() or not game.playing or dt<=0: return
	var previous=floori(trap_clock/2.8);trap_clock+=dt
	if floori(trap_clock/2.8)==previous: return
	for pos in traps:
		game.visual_fx("frost",pos,27,Color("c19bea"),.4)
		if game.player_position().distance_to(pos)<28 and game.dash_time<=0:
			game.hero.hp-=maxf(3,Data.max_hp(game.hero)*.04);game.floating(pos,"ROOT SNARE",Color("e3b2e8"))
func draw(canvas:CanvasItem) -> void:
	if story_run():
		for pos in traps:
			var warning=fposmod(trap_clock,2.8)>1.8
			canvas.draw_circle(pos,27,Color("bd82dc44") if warning else Color("795e8e22"))
			canvas.draw_arc(pos,27,0,TAU,20,Color("e1b0ff") if warning else Color("866a9e"),2)
		if not game.hero.opened.has(cache_key()):
			var pos=cache_position();canvas.draw_rect(Rect2(pos-Vector2(13,13),Vector2(26,26)),Color("ba9ae8"),false,3)
			canvas.draw_string(ThemeDB.fallback_font,pos+Vector2(-40,-20),"RUNIC CACHE",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("dcc5fa"))
		return
	if game.hero.dungeon!=null: return
	for id in CLUES:
		var pos=CLUES[id].point;var found=data().clues.has(id)
		canvas.draw_line(pos+Vector2(-25,13),pos+Vector2(25,-13),Color("80614c"),6)
		canvas.draw_line(pos+Vector2(-24,-13),pos+Vector2(24,13),Color("80614c"),6)
		canvas.draw_circle(pos,8,Color("99bba2") if found else Color("e4cc91"))
		canvas.draw_string(ThemeDB.fallback_font,pos+Vector2(-52,-30),CLUES[id].name.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("ddcca8"))
func show_menu() -> void:
	var hud=game.hud
	hud.section("Chapter I · The Hollow Root")
	hud.paragraph("Mara: Three camps have gone quiet. Roots crawl toward the ruins, and the forest's heartbeat is getting louder. Find out what happened before another caravan disappears.",14)
	if stage()==0:
		hud.action(hud.content,"Ask Mara about the missing camps",func():accept();hud.show_character("chapter"),not game.trader.near())
	elif stage()==1:
		for id in CLUES:
			hud.paragraph(("✓ " if data().clues.has(id) else "○ ")+CLUES[id].name+" · "+game.exploration.bearing(CLUES[id].point),14)
			if data().clues.has(id): hud.paragraph(CLUES[id].text,13)
	elif stage()==2:
		hud.paragraph("Mara: The scout, the broken rune, the living seed… this is a binding. Someone chained a heart beneath Mossveil. Take the seed below and break that chain.",14)
		hud.action(hud.content,"Let Mara translate the rune · +40 gold",func():translate();hud.show_character("chapter"),not game.trader.near())
	elif stage()==3:
		hud.paragraph("Enter the story expedition beside Mossveil Ruins. Three floors: the Buried Gate, the Rootworks, and the Heart Chamber. Purple runes warn before they strike; optional runic caches restore mana. The Hollow Heart's attacks grow wider below half health. Clear the final chamber, then return to Mara.",14)
		hud.action(hud.content,"Enter The Hollow Root · 3 floors",func():begin();hud.resume(),game.hero.dungeon!=null or game.player_position().distance_to(game.exploration.RUINS)>=80)
		hud.action(hud.content,"Enter regular expedition",func():game.enter_dungeon();hud.resume(),game.hero.dungeon!=null or game.player_position().distance_to(game.exploration.RUINS)>=80)
	elif stage()==4:
		hud.paragraph("Mara: You brought its heartbeat back to the forest. Keep this seed; wherever your home stands, it will remember the way. Beyond the eastern caves, other bindings still wait.",14)
		hud.action(hud.content,"Claim Hearthcall · +250 gold, 5 essence, 2 points",func():claim();hud.show_character("chapter"),not game.trader.near())
	else:
		hud.paragraph("CHAPTER COMPLETE · Hearthcall returns you to your bed's return point, or the original camp. It requires a safe wilds location and recharges over 120 seconds of active play. It does not heal, refill needs or skip time.",14)
		var why=recall_reason()
		if not why.is_empty(): hud.paragraph(why,13)
		hud.action(hud.content,"Hearthcall · return to camp",func():recall();hud.resume(),not why.is_empty())
		hud.action(hud.content,"Next lead · track the Emberforge",func():game.exploration.track("caves"))
	if stage()<5: hud.action(hud.content,"Track chapter objective",track)
	hud.action(hud.content,"Back to camp",func():hud.show_character("camp"))
