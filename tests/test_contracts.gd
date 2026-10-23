extends SceneTree
const Data=preload("res://scripts/data.gd")
var checks=0
func _initialize(): call_deferred("run")
func check(ok:bool,message:String):
	if not ok:
		push_error("FAIL: "+message);quit(1);assert(ok,message)
	checks+=1;print("PASS: "+message)
func descendants(node:Node) -> Array:
	var out:Array=[]
	for child in node.get_children(): out.append(child);out.append_array(descendants(child))
	return out
func button(node:Node,title:String) -> Button:
	for item in descendants(node):
		if item is Button and item.text==title: return item
	return null
func run():
	root.size=Vector2i(1080,2400)
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false)
	game.enemies.clear();game.hero.auto=false;game.spawn_timer=100000
	var jobs=game.contracts;var camp=game.survival
	check(jobs.JOBS.size()==6 and jobs.data().active.is_empty(),"Six posted jobs and no automatic acceptance")
	var legacy=Data.fresh("Mage");legacy.erase("contracts")
	check(Data.migrate(legacy).contracts.completed==0,"Existing characters gain an empty job journal")
	game.set_player_position(Vector2(500,500))
	check(not jobs.accept("supplies"),"Jobs cannot be accepted away from the board")
	jobs.track("board",false)
	check(game.forest.objective().begins_with("Quest board"),"Board tracking gives a live world bearing")
	game.set_player_position(jobs.BOARD);game.update_interaction()
	check(game.hud.interaction.text=="QUEST BOARD","Nearby board appears on the interaction button")
	game.playing=true;game.interact();await process_frame;await process_frame
	check(game.hud.current_page=="quests" and not game.playing,"World interaction opens a paused job menu")
	var accept=button(game.hud.content,"Accept A roof over Mossveil")
	check(accept!=null and not accept.disabled,"Posted job has a usable acceptance button")
	accept.pressed.emit()
	check(jobs.active("supplies") and jobs.data().target=="supplies","UI accepts and tracks a job")
	check(game.hud.quest_page=="Active" and button(game.hud.content,"Accept Wolves on the road")==null,"Accepting switches to a compact active-job view")
	check(not jobs.accept("supplies") and jobs.data().active.size()==1,"Duplicate acceptance is rejected")
	check(not jobs.ready("supplies") and not jobs.claim("supplies"),"Incomplete job cannot grant rewards")
	camp.add("Wood",18);camp.add("Stone",8)
	check(jobs.ready("supplies"),"Carried delivery materials satisfy the job")
	camp.add("Wood",-1)
	check(not jobs.ready("supplies"),"Spending required supplies makes delivery incomplete again")
	camp.add("Wood",1)
	game.hero.survival.structures=[{"kind":"Storage","x":jobs.BOARD.x,"y":jobs.BOARD.y,"fuel":0,"rotation":0,"open":false,"stash":{}}]
	var storage=game.hero.survival.structures[0]
	camp.transfer(storage,true)
	check(not jobs.ready("supplies"),"Materials in storage are not silently consumed by deliveries")
	camp.transfer(storage,false);game.hero.survival.structures=[]
	game.set_player_position(Vector2(1000,1000))
	var gold=game.hero.gold;var wood=camp.count("Wood")
	check(not jobs.claim("supplies") and game.hero.gold==gold and camp.count("Wood")==wood,"Remote turn-in changes neither supplies nor rewards")
	game.set_player_position(jobs.BOARD)
	var reward=jobs.rewards("supplies");var xp=game.hero.xp;var essence=game.hero.essence
	check(jobs.claim("supplies"),"Ready delivery can be turned in at the board")
	check(camp.count("Wood")==0 and camp.count("Stone")==0,"Turn-in consumes the exact requested materials")
	check(game.hero.gold==gold+reward.gold and game.hero.essence==essence+reward.essence,"Job awards its previewed gold and essence")
	check(game.hero.xp==xp+reward.xp or game.hero.level>1,"Job awards XP through normal leveling")
	gold=game.hero.gold
	check(not jobs.claim("supplies") and game.hero.gold==gold,"Claiming the same job twice cannot duplicate rewards")
	check(not jobs.accept("supplies") and jobs.cooldown("supplies")==600,"Completed job repost waits one active game day")
	game.pause_game();var remaining=jobs.cooldown("supplies")
	game.set_physics_process(true);await create_timer(.12).timeout;game.set_physics_process(false)
	check(jobs.cooldown("supplies")==remaining,"Repost timers pause in menus")
	game.hero.worldTime+=600
	check(jobs.accept("supplies"),"Completed jobs can be repeated after their cooldown")
	check(jobs.accept("wolves") and jobs.accept("archers"),"Three jobs can be active together")
	check(not jobs.accept("survey") and jobs.data().active.size()==3,"Active job cap is enforced")
	var foe=game.create_enemy(jobs.BOARD+Vector2(50,0),1,"wolf")
	game.kill_enemy(foe,"melee")
	check(jobs.data().active.wolves.progress==1,"Actual enemy defeat advances a matching bounty")
	game.kill_enemy(foe,"melee")
	check(jobs.data().active.wolves.progress==1,"An enemy can credit a bounty only once")
	for type in ["deer","goblin","skeleton"]: game.kill_enemy(game.create_enemy(jobs.BOARD,1,type),"melee")
	check(jobs.data().active.wolves.progress==1 and jobs.data().active.archers.progress==0,"Wildlife and unrelated enemies do not credit bounties")
	game.kill_enemy(game.create_enemy(jobs.BOARD,1,"frost_wolf"),"melee")
	check(jobs.data().active.wolves.progress==2,"Frost wolves count toward the wolf bounty")
	for type in ["archer","ice_archer"]: game.kill_enemy(game.create_enemy(jobs.BOARD,1,type),"bow")
	check(jobs.data().active.archers.progress==2,"Both archer variants count toward the ambush bounty")
	game.save_game();var loaded=Data.read_save()
	check(loaded.contracts.active.wolves.progress==2 and loaded.contracts.active.archers.progress==2,"Accepted bounties and progress survive save/reload")
	jobs.abandon("supplies")
	check(not jobs.active("supplies") and jobs.active("wolves"),"Abandoning affects only the selected job")
	check(jobs.accept("survey"),"Abandoning frees a job slot")
	game.hero.exploration.discovered={"caves":true,"swamp":true,"snow":true}
	check(jobs.data().active.survey.progress==0,"Past discoveries do not instantly complete a new survey")
	for region in ["caves","swamp","snow"]:
		game.set_player_position(game.exploration.REGIONS[region].point)
		jobs.tick(1);var count=jobs.data().active.survey.progress;jobs.tick(1)
		check(jobs.data().active.survey.progress==count,"Survey credits a landmark only once: "+region)
	check(jobs.ready("survey"),"Revisiting all three landmarks completes the survey")
	jobs.track("survey",false)
	check(game.forest.objective().begins_with("Turn in:"),"Completed tracked jobs direct the player back to the board")
	game.set_player_position(jobs.BOARD);check(jobs.claim("survey"),"Survey grants rewards on returning to the board")
	check(jobs.data().completed==2,"Completion count advances once per claimed job")
	check(jobs.accept("delve"),"Dungeon job can be accepted at the board")
	game.enter_dungeon()
	check(not jobs.near_board(),"Dungeon coordinates cannot impersonate a nearby world board")
	jobs.track("board",false)
	check(jobs.objective().contains("Leave dungeon"),"Board tracking guides dungeon players to the exit")
	jobs.track("delve",false)
	for enemy in game.enemies.duplicate(): game.kill_enemy(enemy,"melee")
	check(game.check_floor_clear() and jobs.data().active.delve.progress==1,"New floor reward credits the dungeon contract")
	game.check_floor_clear();game.build_floor(false)
	check(jobs.data().active.delve.progress==1,"Reloading or rechecking a rewarded floor cannot duplicate credit")
	game.advance_floor()
	for enemy in game.enemies.duplicate(): game.kill_enemy(enemy,"melee")
	game.check_floor_clear()
	check(jobs.ready("delve"),"Two distinct cleared floors complete the dungeon job")
	game.leave_dungeon();game.set_player_position(jobs.BOARD)
	var starter=game.hero.inventory[0].duplicate()
	game.hero.inventory.clear()
	for i in range(40):
		var item=starter.duplicate();item.id="full-"+str(i);game.hero.inventory.append(item)
	gold=game.hero.gold
	check(not jobs.claim("delve") and game.hero.gold==gold and jobs.active("delve"),"Full bags preserve the pending enchanted milestone reward")
	game.hero.inventory.pop_back();var size=game.hero.inventory.size()
	check(jobs.claim("delve") and game.hero.inventory.size()==size+1,"Third completion adds an enchanted gear bonus")
	var bonus=game.hero.inventory[-1]
	check(bonus.rarity==2 and bonus.enchant>0 and bonus.kind in ["sword","bow","staff"],"Third completion guarantees a Rare enchanted weapon")
	game.save_game();loaded=Data.read_save()
	check(loaded.contracts.completed==3 and not loaded.contracts.active.has("delve"),"Claim and milestone state survive saving")
	game.hero.inventory=[starter];jobs.data().active.clear();jobs.data().completed=8
	game.hero.worldTime+=600;game.set_player_position(jobs.BOARD)
	jobs.accept("rations");camp.add("Roasted berries",3)
	check(jobs.claim("rations") and game.hero.inventory[-1].rarity==3,"Every ninth completion upgrades the enchanted bonus to Epic")
	check(camp.count("Roasted berries")==0,"Food delivery consumes the carried meals")
	jobs.data().active.clear();jobs.data().completed=0
	game.hero.worldTime+=600;check(jobs.accept("wolves"),"Repeat bounty can be accepted after cooldown and abandonment")
	check(jobs.data().active.wolves.progress==0,"New acceptance starts with fresh bounty progress")
	jobs.track("wolves",false);game.hud.show_character("map");await process_frame;await process_frame
	button(game.hud.content,"Track selected").pressed.emit()
	check(jobs.data().target.is_empty() and not game.hero.exploration.target.is_empty(),"Map tracking cleanly replaces job tracking")
	jobs.track("wolves",false)
	check(game.hero.exploration.target.is_empty(),"Tracking a job clears competing map objectives")
	for dims in [Vector2i(1080,2400),Vector2i(2400,1080)]:
		root.size=dims;game.adapt_screen();await process_frame;await process_frame
		game.hud.show_character("quests");await process_frame;await process_frame
		var bounds=game.hud.scroll.get_global_rect();var fits=true
		for control in descendants(game.hud.content):
			if control is Button:
				var rect=control.get_global_rect();fits=fits and rect.position.x>=bounds.position.x-.5 and rect.end.x<=bounds.end.x+.5
		check(fits,"Quest actions have no horizontal overflow "+str(dims))
		var tracking=button(game.hud.content,"Track Wolves on the road")
		check(tracking!=null,"Active quest exposes tracking in both orientations "+str(dims))
		tracking.pressed.emit()
		check(game.playing and not game.hud.overlay.visible,"Tracking returns to gameplay "+str(dims))
	game.save_game();loaded=Data.read_save()
	check(loaded.contracts.target=="wolves","Tracked job survives save/reload")
	for malformed in ["container","limit","unknown","progress","visited","completed","cooldown"]:
		var bad=Data.fresh("Warrior")
		match malformed:
			"container": bad.contracts=[]
			"limit":
				for id in ["wolves","archers","survey","delve"]: bad.contracts.active[id]={"level":1,"progress":0,"visited":{}}
			"unknown": bad.contracts.active.fake={"level":1,"progress":0,"visited":{}}
			"progress": bad.contracts.active.wolves={"level":1,"progress":999,"visited":{}}
			"visited": bad.contracts.active.survey={"level":1,"progress":0,"visited":{"fake":true}}
			"completed": bad.contracts.completed=-1
			"cooldown": bad.contracts.cooldowns.wolves="bad"
		check(Data.migrate(bad).is_empty(),"Malformed job save rejected: "+malformed)
	game.set_player_position(jobs.BOARD-Vector2(0,96));game.facing=Vector2.DOWN
	for material in camp.MATERIALS: camp.add(material,30)
	check(camp.reason("Wall").contains("quest board"),"New construction preserves access to the board")
	print(str(checks)+" CONTRACT CHECKS PASSED")
	quit()
