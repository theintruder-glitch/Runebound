extends RefCounted
const Data=preload("res://scripts/data.gd")
const BOARD=Vector2(-128,-48)
const JOBS={
	"supplies":{"name":"A roof over Mossveil","kind":"delivery","items":{"Wood":18,"Stone":8},"goal":1,"gold":45,"xp":40,"essence":1,"icon":"Wood","desc":"Deliver carried building supplies to keep the frontier camps standing."},
	"rations":{"name":"Food for the trail","kind":"delivery","items":{"Roasted berries":3},"goal":1,"gold":40,"xp":45,"essence":1,"icon":"Roasted berries","desc":"Cook or bring three portions of roasted berries. Deliver them at the board."},
	"wolves":{"name":"Wolves on the road","kind":"hunt","goal":6,"gold":75,"xp":70,"essence":2,"icon":"sword","desc":"Defeat six wolves or frost wolves after accepting. Wildlife is not a target."},
	"archers":{"name":"Break the ambush","kind":"hunt","goal":4,"gold":70,"xp":65,"essence":2,"icon":"bow","desc":"Defeat four archers or ice archers after accepting. Skeletons do not count."},
	"survey":{"name":"Beyond the green border","kind":"survey","goal":3,"gold":100,"xp":90,"essence":3,"icon":"map","desc":"After accepting, revisit Emberforge, the Veil Altar, and Winter Oath. Approach within 90 units of each landmark."},
	"delve":{"name":"Light in the deep","kind":"dungeon","goal":2,"gold":90,"xp":85,"essence":3,"icon":"staff","desc":"Clear two new dungeon floors after accepting. Already rewarded floors do not count."}
}
var game
var survey_timer=0.0
func data() -> Dictionary: return game.hero.contracts
func near_board() -> bool: return game.hero.dungeon==null and game.player_position().distance_to(BOARD)<=120
func active(id:String) -> bool: return data().active.has(id)
func cooldown(id:String) -> float: return maxf(0,float(data().cooldowns.get(id,0))-game.hero.worldTime)
func accept_reason(id:String) -> String:
	if not JOBS.has(id): return "Unknown job"
	if active(id): return "Already accepted"
	if not near_board(): return "Return to the quest board near the starting camp"
	if data().active.size()>=3: return "Finish or abandon a job first (3 active maximum)"
	if cooldown(id)>0: return "Reposts in %ds of active play" % ceili(cooldown(id))
	return ""
func accept(id:String) -> bool:
	var why=accept_reason(id)
	if not why.is_empty(): game.notify(why,3);return false
	data().active[id]={"level":clampi(int(game.hero.level),1,1000),"progress":0,"visited":{}}
	track(id,false)
	game.notify("Accepted: "+JOBS[id].name,3);game.save_game()
	return true
func ready(id:String) -> bool:
	if not active(id): return false
	if JOBS[id].kind=="delivery":
		for material in JOBS[id].items:
			if game.survival.count(material)<JOBS[id].items[material]: return false
		return true
	return data().active[id].progress>=JOBS[id].goal
func progress_text(id:String) -> String:
	if JOBS[id].kind=="delivery":
		var parts=PackedStringArray()
		for material in JOBS[id].items:
			parts.append("%s %d/%d" % [material,mini(game.survival.count(material),JOBS[id].items[material]),JOBS[id].items[material]])
		return " · ".join(parts)
	if not active(id): return "0/%d" % JOBS[id].goal
	return "%d/%d" % [data().active[id].progress,JOBS[id].goal]
func rewards(id:String) -> Dictionary:
	var level=data().active[id].level if active(id) else clampi(int(game.hero.level),1,1000)
	return {"gold":JOBS[id].gold+level*5,"xp":JOBS[id].xp+level*6,"essence":JOBS[id].essence}
func reward_text(id:String) -> String:
	var r=rewards(id)
	return "%d gold · %d XP · %d essence" % [r.gold,r.xp,r.essence]
func next_gear() -> bool: return (int(data().completed)+1)%3==0
func claim_reason(id:String) -> String:
	if not active(id): return "Accept this job first"
	if not ready(id): return "Objectives incomplete"
	if not near_board(): return "Return to the quest board to turn in"
	if next_gear() and game.hero.inventory.size()>=40: return "Make room in Gear for the enchanted completion bonus"
	return ""
func claim(id:String) -> bool:
	var why=claim_reason(id)
	if not why.is_empty(): game.notify(why,4);return false
	var r=rewards(id)
	var level=int(data().active[id].level)
	if JOBS[id].kind=="delivery":
		for material in JOBS[id].items: game.survival.add(material,-JOBS[id].items[material])
	# Commit the one-shot state before granting rewards or running level-up hooks.
	data().active.erase(id)
	data().completed+=1
	data().cooldowns[id]=game.hero.worldTime+600
	if data().target==id: data().target=""
	game.hero.gold+=r.gold;game.hero.essence+=r.essence
	game.grant_xp(r.xp);game.add_renown(10)
	if int(data().completed)%3==0:
		var rarity=3 if int(data().completed)%9==0 else 2
		var kind=Data.equipped(game.hero,"weapon").get("kind","sword")
		if kind not in ["sword","bow","staff"]: kind="sword"
		var item={"id":"contract-%d-%d" % [Time.get_ticks_usec(),randi()],"kind":kind,"name":"Wayfarer "+str(kind).capitalize(),"level":level,"rarity":rarity,"power":int((5+level*2)*Data.RARITIES[rarity].mult),"upgrade":0,"enchant":randi_range(1,4)}
		game.hero.inventory.append(item)
	game.sound("reward");game.notify("JOB COMPLETE · "+reward_text_from(r)+(" · Enchanted gear added!" if int(data().completed)%3==0 else ""),6)
	game.save_game();game.hud.update_hud();return true
func reward_text_from(r:Dictionary) -> String: return "+%d gold, +%d XP, +%d essence" % [r.gold,r.xp,r.essence]
func abandon(id:String) -> bool:
	if not active(id): return false
	data().active.erase(id)
	if data().target==id: data().target=""
	game.save_game();game.notify("Job abandoned. Carried supplies were kept.",3);return true
func track(id:String,resume:bool=true) -> void:
	if id!="board" and not active(id): return
	data().target=id;game.hero.exploration.target=""
	game.save_game()
	if resume: game.hud.resume()
func advance(id:String) -> void:
	if not active(id) or ready(id): return
	data().active[id].progress=mini(JOBS[id].goal,data().active[id].progress+1)
	if ready(id): game.notify("Job ready: "+JOBS[id].name+" · Return to the quest board.",5)
func on_kill(enemy:Dictionary) -> void:
	if enemy.get("neutral",false): return
	if enemy.type in ["wolf","frost_wolf"]: advance("wolves")
	if enemy.type in ["archer","ice_archer"]: advance("archers")
func tick(dt:float) -> void:
	survey_timer-=dt
	if survey_timer>0: return
	survey_timer=.5
	if game.hero.dungeon!=null or not active("survey") or ready("survey"): return
	var entry=data().active.survey
	for region in ["caves","swamp","snow"]:
		if not entry.visited.get(region,false) and game.player_position().distance_to(game.exploration.REGIONS[region].point)<90:
			entry.visited[region]=true;advance("survey");game.save_game()
func objective() -> String:
	var id=data().target
	if game.hero.dungeon!=null and (id=="board" or ready(id)): return "Quest board · Leave dungeon via entrance stairs"
	if game.hero.dungeon!=null and id=="survey" and active(id): return "Survey route · Leave dungeon via entrance stairs"
	if id=="board": return "Quest board · "+game.exploration.bearing(BOARD)
	if not active(id): return ""
	if ready(id): return "Turn in: "+JOBS[id].name+" · "+game.exploration.bearing(BOARD)
	if id=="survey":
		for region in ["caves","swamp","snow"]:
			if not data().active[id].visited.get(region,false): return "Survey "+game.exploration.REGIONS[region].landmark+" · "+game.exploration.bearing(game.exploration.REGIONS[region].point)
	if id=="delve": return "Dungeon job · "+progress_text(id)+(" floors · Clear this floor" if game.hero.dungeon!=null else " floors · "+game.exploration.bearing(game.exploration.RUINS))
	return JOBS[id].name+" · "+progress_text(id)
