extends RefCounted
const Data=preload("res://scripts/data.gd")
const SHRINE=Vector2(760,-520)
var game
var boss:Dictionary={}
func state() -> Dictionary: return game.hero.journey
func has_structure(kind:String) -> bool:
 for s in game.hero.survival.structures:
  if s.kind==kind: return true
 return false
func step() -> int:
 if not state().wood and game.survival.count("Wood")<6: return 0
 if not has_structure("Campfire"): return 1
 if not state().cooked: return 2
 if not has_structure("Shelter"): return 3
 if not state().dungeon_entered: return 4
 if not state().first_floor: return 5
 if not state().warden: return 6
 if not state().reward: return 7
 return 8
func objective() -> String:
 if not game.contracts.objective().is_empty(): return game.contracts.objective()
 if not game.hero.exploration.target.is_empty(): return game.exploration.objective()
 if not game.chapter.objective().is_empty(): return game.chapter.objective()
 match step():
  0: return "Gather 6 Wood · Approach a labeled woodpile"
  1: return "Build a Campfire · Open Camp"
  2: return "Cook berries · Stand by a lit fire"
  3: return "Build a Shelter · Make 6 Planks and 2 Rope"
  4: return "Find Mossveil Ruins · "+game.exploration.bearing(game.exploration.RUINS)
  5: return "Clear your first dungeon floor · +50 gold and +2 essence"
  6: return "Seek the Elder Shrine · "+bearing()
  7: return "Claim your shrine reward"
 return game.exploration.objective()
func check_opening_reward() -> bool:
 if not state().first_floor or state().opening_reward: return false
 state().opening_reward=true; game.hero.gold+=50; game.hero.essence+=2
 game.notify("FIRST EXPEDITION COMPLETE · +50 gold, +2 essence. The Elder Shrine awaits.",6)
 game.sound("reward"); return true
func bearing() -> String:
 var delta=SHRINE-game.player_position()
 var direction="E" if delta.x>0 else "W"
 if absf(delta.x)<absf(delta.y)*.45: direction=""
 if absf(delta.y)>absf(delta.x)*.45: direction=("N" if delta.y<0 else "S")+direction
 return "%s · %dm" % [direction,int(delta.length()/10)]
func active() -> bool:
 return not boss.is_empty() and not boss.dead and game.enemies.has(boss)
func interaction() -> String:
 if game.hero.dungeon!=null: return ""
 if game.player_position().distance_to(game.exploration.RUINS)<80: return "MOSSVEIL RUINS · CHOOSE EXPEDITION" if game.chapter.stage()==3 else "ENTER MOSSVEIL RUINS"
 if game.player_position().distance_to(SHRINE)>80: return ""
 if state().warden: return "CLAIM SHRINE REWARD" if not state().reward else "ELDER SHRINE · RESTORED"
 if active(): return ""
 return "AWAKEN THE ROOT WARDEN"
func interact() -> void:
 if game.player_position().distance_to(game.exploration.RUINS)<80:
  if game.chapter.stage()==3: game.hud.show_character("chapter");return
  game.enter_dungeon(); return
 if state().warden:
  claim_reward(); return
 if active(): return
 boss=game.create_enemy(SHRINE+Vector2(0,-100),maxi(2,game.hero.level),"guardian",true)
 boss["named"]="The Root Warden"
 boss.hp=float(260+game.hero.level*38); boss.max_hp=boss.hp
 boss.contact_damage=16+game.hero.level*2
 boss.aggro=60; boss.home=SHRINE
 game.enemies.append(boss)
 game.notify("ROOT WARDEN · Leave the red circle before it strikes. DASH can evade the hit.",6)
 game.sound("spell")
func defeated(enemy:Dictionary) -> void:
 if enemy.get("named","")!="The Root Warden" or state().warden: return
 state().warden=true
 if not "Arcane Archer" in game.hero.unlocked: game.hero.unlocked.append("Arcane Archer")
 game.notify("FOREST RESTORED · Arcane Archer unlocked! Return to the shrine for your enchanted weapon.",7)
 game.survival.revision+=1
 game.sound("reward")
 game.save_game()
func claim_reward() -> bool:
 if not state().warden or state().reward: return false
 if game.hero.inventory.size()>=40:
  game.notify("Make room in Gear, then claim your shrine reward.",4); return false
 var kind=Data.equipped(game.hero,"weapon").get("kind","sword")
 if kind not in ["sword","bow","staff"]: kind="sword"
 game.hero.inventory.append({"id":"elder-shrine-oath","kind":kind,"name":{"sword":"Verdant Oath","bow":"Elderwood Promise","staff":"Heartroot Staff"}[kind],"level":game.hero.level,"rarity":3,"power":int((9+game.hero.level*3)*3),"upgrade":0,"enchant":4})
 state().reward=true
 game.notify("Epic Leech-enchanted weapon added to Gear.",5)
 game.sound("reward"); game.save_game()
 return true
func reset_if_abandoned() -> void:
 if active() and (game.hero.dungeon!=null or game.player_position().distance_to(SHRINE)>550):
  game.enemies.erase(boss); boss={}
  game.notify("The Warden returns to the shrine. Approach it to try again.",3)
