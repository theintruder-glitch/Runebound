extends RefCounted
# Chapter II builds on the existing Emberforge trial; veteran trial wins count.
var game
var foes:Array=[]
var running=false
func data() -> Dictionary: return game.hero.forge_chapter
func point() -> Vector2: return game.exploration.REGIONS.caves.point
func stage() -> int:
	if not game.hero.chapter.claimed: return -1
	if not data().accepted: return 0
	if not game.hero.exploration.challenges.get("caves",false): return 1
	if not data().inspected: return 2
	if not data().cleared: return 3
	if not data().claimed: return 4
	return 5
func near() -> bool:
	return game.hero.dungeon==null and game.player_position().distance_to(point())<80 and game.line_clear(game.player_position(),point())
func active() -> bool: return running
func reset() -> void:
	for enemy in foes: game.enemies.erase(enemy)
	foes.clear();running=false
func tick(_dt:float) -> void:
	if not running: return
	if game.hero.dungeon!=null or game.hero.hp<=0 or game.player_position().distance_to(point())>550 or foes.any(func(e):return not e.dead and not game.enemies.has(e)):
		reset();game.notify("Ashen binding abandoned · return to Emberforge to retry.",4)
func track() -> void:
	game.hero.chapter.tracking=true;game.hero.exploration.target="";game.hero.contracts.target="";game.hero.angler.target=""
	game.save_game();game.hud.resume()
func objective() -> String:
	if stage()<0 or stage()==5: return ""
	if game.hero.dungeon!=null: return "ASH AND OATH · Leave dungeon via entrance stairs"
	if running: return "ASH AND OATH · Defeat the Keeper and its two embers · dodge warning circles"
	if stage() in [0,4]: return "ASH AND OATH · Speak with Mara · "+game.exploration.bearing(game.trader.POSITION)
	var task={1:"Complete sword + magic trial",2:"Read the forge inscription",3:"Break the ashen binding"}[stage()]
	return "ASH AND OATH · "+task+" · "+game.exploration.bearing(point())
func accept() -> bool:
	if stage()!=0 or not game.trader.near() or not game.line_clear(game.player_position(),game.trader.POSITION): return false
	data().accepted=true;game.hero.chapter.tracking=true;game.save_game();return true
func inspect_forge() -> bool:
	if stage()!=2 or not near() or game.exploration.active(): return false
	data().inspected=true
	game.notify("The inscription: 'A forge remembers every chain it made.' Two embers feed the last binding. Break them and silence the Ashbound Keeper.",8)
	game.save_game();return true
func begin() -> bool:
	if game.hero.hp<=0 or stage()!=3 or not near() or running or game.exploration.active() or game.forest.active() or not game.build_recipe.is_empty(): return false
	var positions:Array=[]
	for offset in [Vector2(0,-120),Vector2(-110,40),Vector2(110,40)]:
		var pos=point()+offset
		if not game.walkable(pos,24) or not game.line_clear(point(),pos):
			game.notify("Clear space around Emberforge before breaking the binding.",4);return false
		positions.append(pos)
	reset();running=true
	for i in range(3):
		var enemy=game.create_enemy(positions[i],maxi(3,game.hero.level),"guardian" if i==0 else "crystal_wisp",i==0)
		enemy.named="Ashbound Keeper" if i==0 else "Bound Ember"
		enemy.hp=float(300+game.hero.level*24) if i==0 else float(55+game.hero.level*8)
		enemy.max_hp=enemy.hp;enemy.contact_damage=12+game.hero.level if i==0 else 7+game.hero.level
		enemy.home=point();enemy.aggro=60;enemy.cooldown=1+i*.6
		enemy["forge_boss"]=i==0
		foes.append(enemy);game.enemies.append(enemy)
	game.notify("ASHEN BINDING · Two embers and one Keeper. Warning circles lock before striking. The Keeper attacks faster below half health.",8)
	game.save_game();return true
func on_kill(enemy:Dictionary) -> void:
	if not running or not foes.any(func(e):return is_same(e,enemy)) or foes.any(func(e):return not e.dead): return
	running=false;data().cleared=true
	game.notify("THE ASHEN BINDING BREAKS · Return to Mara. The forge remembers a second chain beneath Whisperfen.",8);game.save_game()
func claim() -> bool:
	if stage()!=4 or not game.trader.near() or not game.line_clear(game.player_position(),game.trader.POSITION): return false
	data().claimed=true;game.hero.gold+=350;game.hero.essence+=6;game.hero.points+=2
	game.notify("ASH AND OATH COMPLETE · +350 gold, +6 essence, +2 stat points",7);game.sound("reward");game.save_game();return true
func interaction() -> String:
	if not near() or game.exploration.active() or running or game.hero.exploration.pending.get("caves",false): return ""
	if stage()==2: return "READ FORGE INSCRIPTION"
	if stage()==3: return "BREAK ASHEN BINDING"
	return ""
func interact() -> void:
	if stage()==2: inspect_forge()
	elif stage()==3: begin()
func show_menu() -> void:
	var hud=game.hud
	hud.section("Chapter II · Ash and Oath")
	if stage()==0:
		hud.paragraph("Mara: The heart is free, but its chains were forged in Hollowdeep. Follow the eastern road to Emberforge. Prove that steel and spell can share one purpose, then read what the forge remembers.",14)
		hud.action(hud.content,"Ask Mara about Emberforge",func():accept();hud.show_character("chapter"),not game.trader.near())
	elif stage()==1:
		hud.paragraph("At Emberforge, discover the landmark, then complete its existing trial: hit the Forge Sentinel with a sword AND magic before defeating it. Your class need not change. A previously completed trial counts. Bring food, water and a usable spell; claim the regional relic separately at the landmark.",14)
	elif stage() in [2,3]:
		hud.paragraph("The Forge Sentinel's oath opens the old inscription. Two bound embers still feed an Ashbound Keeper. Clear all three to break the chain. Dodge locked warning circles; below half health the Keeper strikes faster. Stay within the forge clearing. Leaving, defeat or reloading abandons the encounter; you can retry without losing chapter progress.",14)
		if stage()==2: hud.action(hud.content,"Read forge inscription",func():inspect_forge();hud.show_character("chapter"),not near() or game.exploration.active())
		else: hud.action(hud.content,"Break ashen binding · 3 enemies",func():
			if begin(): hud.resume()
			else: hud.show_character("chapter"),not near() or running or game.exploration.active())
	elif stage()==4:
		hud.paragraph("Mara: These are no ordinary chains. Someone bound the forest, the forge… and something beneath Whisperfen. Take this for the road. The Veil Altar may hold the next answer.",14)
		hud.action(hud.content,"Claim chapter reward · 350 gold, 6 essence, 2 points",func():claim();hud.show_character("chapter"),not game.trader.near())
	else:
		hud.paragraph("CHAPTER II COMPLETE · The forge is free. The existing Whisperfen trial and Reaper path remain available at the Veil Altar.",14)
		hud.action(hud.content,"Next lead · track the Veil Altar",func():game.exploration.track("swamp"))
	if stage() in [1,2,3,4]: hud.action(hud.content,"Track Ash and Oath",track)
