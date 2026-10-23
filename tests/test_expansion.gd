extends SceneTree
const Data=preload("res://scripts/data.gd")
var checks=0
func _initialize(): call_deferred("run")
func check(ok:bool,message:String):
 if not ok:
  push_error("FAIL: "+message); quit(1); assert(ok,message)
 checks+=1; print("PASS: "+message)
func run():
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
 root.size=Vector2i(480,900)
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_character(Data.fresh("Warrior"))
 game.set_physics_process(false); game.hero.auto=false; game.enemies.clear()
 var explore=game.exploration; var camp=game.survival
 for id in explore.REGIONS:
  var point:Vector2=explore.REGIONS[id].point
  check(explore.region_at(point)==id,"Landmark belongs to its region: "+id)
  game.set_player_position(point); game.camera.position=point
  explore.tick(.1); camp.refresh(true); game.world.refresh(true)
  check(game.hero.exploration.visited.get(id,false),"Visiting a region is recorded: "+id)
  check(camp.nodes.any(func(n):return n.kind==explore.REGIONS[id].material),"Region provides its unique material: "+id)
  check(game.walkable(point,10),"Regional landmark clearing is walkable: "+id)
  if id!="forest":
   var gold=game.hero.gold
   explore.interact()
   check(game.hero.exploration.discovered.get(id,false) and game.hero.gold==gold+30,"Discovering a landmark awards a one-time reward: "+id)
  game.world.queue_redraw(); await process_frame
 check(explore.cave_wall(Vector2(1921,625)),"Caves contain actual solid walls")
 game.set_player_position(Vector2(1921,625))
 check(not game.walkable(game.player_position(),5),"Cave walls block movement")
 check(game.walkable(game.safe_wilds_position(game.player_position()),12),"An older save inside a new cave wall can recover nearby")
 check(not explore.cave_wall(Vector2(1921,0)),"Main cave corridor remains connected")
 for key in camp.MATERIALS: camp.add(key,100)
 game.set_player_position(Vector2(300,0));game.facing=Vector2.DOWN
 check(camp.craft("Workbench"),"A crafting station can be placed")
 for recipe in ["Resin blade","Crystal staff","Frost bow","Leather vest"]:
  var size=game.hero.inventory.size()
  check(camp.craft(recipe) and game.hero.inventory.size()==size+1,"Discovered regional recipe makes usable equipment: "+recipe)
 check(game.hero.inventory[-1].kind=="armor","Leather recipe creates armor, not a sword")
 var rope=camp.count("Rope")
 check(camp.craft("Reed rope") and camp.count("Rope")==rope+1,"Swamp reeds weave into usable rope")
 game.set_player_position(Vector2.ZERO)
 var wolf=game.create_enemy(Vector2(100,0),1,"wolf")
 var ally=game.create_enemy(Vector2(150,50),1,"wolf")
 wolf.pack=42; ally.pack=42; ally["pack_slot"]=1
 game.enemies=[wolf,ally]
 camp.enemy_direction(wolf,.1)
 check(wolf.aggro>0 and ally.aggro>0,"One wolf alerts its pack")
 check(camp.enemy_direction(wolf,.1)!=camp.enemy_direction(ally,.1),"Pack members choose different approach directions")
 var deer=game.create_enemy(Vector2(50,0),1,"deer")
 check(camp.enemy_direction(deer,.1).x>0,"Wildlife flees away from the player")
 var hp=game.hero.hp
 game.update_enemy_attack(deer,1)
 check(game.hero.hp==hp and deer.windup==0,"Wildlife never initiates an attack")
 game.enemies=[deer]
 check(not game.attack(true),"Automatic combat leaves wildlife alone")
 game.kill_enemy(deer,"melee")
 check(camp.count("Raw meat")>=2 and camp.count("Hide")>=1,"Hunting provides cooking and crafting materials")
 var archer=game.create_enemy(Vector2(80,0),1,"archer")
 archer.aggro=2
 check(camp.enemy_direction(archer,.1).x>0,"Archer retreats when the player gets close")
 archer.pos=Vector2(150,0)
 check(camp.enemy_direction(archer,.1)==Vector2.ZERO,"Archer holds a firing distance")
 for id in ["caves","swamp","snow"]:
  game.enemies.clear(); game.set_player_position(explore.REGIONS[id].point)
  explore.begin_trial(id)
  check(explore.active(),"Regional trial starts: "+id)
  for foe in explore.foes:
   foe.max_hp=10000; foe.hp=10000
  if id=="caves":
   game.hurt(explore.foes[0],1,"melee"); game.hurt(explore.foes[0],1,"magic")
  elif id=="snow": game.hurt(explore.foes[0],1,"bow")
  game.dash_cooldown=0; game.playing=true; game.dash()
  for foe in explore.foes.duplicate(): game.kill_enemy(foe,"magic")
  check(game.hero.exploration.challenges.get(id,false) and explore.REGIONS[id]["class"] in game.hero.unlocked,"Adventure requirements unlock the hidden class: "+id)
  var size=game.hero.inventory.size()
  check(explore.claim(id) and game.hero.inventory.size()==size+1,"Trial grants its regional relic: "+id)
  check(not explore.claim(id),"Regional relic cannot be claimed twice: "+id)
 check(not game.hero.journey.warden,"Regional trials cannot accidentally complete the Root Warden quest")
 game.enemies.clear(); explore.begin_trial("caves")
 game.kill_enemy(explore.foes[0],"melee")
 # Completed flags from the first trial remain, but the failed replay gives no extra relic.
 check(not game.hero.exploration.pending.get("caves",false),"Missing combo requirement grants no extra trial reward")
 game.enemies.clear(); explore.trial=""
 game.set_player_position(Vector2.ZERO); game.hero.survival.structures.clear()
 for cls in Data.CLASSES:
  game.hero.className=cls; game.hero.mp=Data.max_mp(game.hero); game.hero.hp=50
  game.abilities.reset(); game.shots.clear(); game.spell_cooldowns.fire=0
  var enemy=game.create_enemy(Vector2(60,0),1,"goblin"); enemy.hp=10000;enemy.max_hp=10000
  game.enemies=[enemy]; game.playing=true; game.dash_time=0
  var mana=game.hero.mp
  check(game.abilities.use(),"Class exclusive ability activates: "+cls)
  check(game.abilities.cooldown>0 and game.hero.mp<mana,"Ability spends mana and starts cooldown: "+cls)
  check(not game.abilities.use(),"Ability cooldown prevents repeat use: "+cls)
  if cls=="Rogue":
   check(game.abilities.stealth>0 and camp.enemy_direction(enemy,.1).x>=0,"Vanish makes enemies lose the Rogue")
   enemy.windup=1; game.update_enemy_attack(enemy,.1)
   check(enemy.windup==0,"Vanish cancels a pending enemy strike instead of freezing its warning")
  elif cls=="Cleric":
   game.abilities.tick(1)
   check(game.hero.hp>50 and enemy.hp<10000,"Sanctuary heals and damages within its zone")
  elif cls in ["Ranger","Arcane Archer"]: check(game.shots.size()==(3 if cls=="Ranger" else 5),"Volley fires the class-specific number of arrows: "+cls)
  else: check(enemy.hp<10000,"Class attack affects nearby enemies: "+cls)
  game.hud.update_hud(); game.world.queue_redraw(); await process_frame
 # Exercise actual draw callbacks for every new enemy type and all four biomes.
 game.abilities.reset(); game.hero.className="Warrior"; game.hero.auto=false
 for id in explore.REGIONS:
  var point:Vector2=explore.REGIONS[id].point
  game.set_player_position(point);game.camera.position=point;game.camera.force_update_scroll()
  game.enemies.clear()
  var index=0
  for kind in ["wolf","frost_wolf","deer","archer","ice_archer","crystal_wisp","bog_toad"]:
   var enemy=game.create_enemy(point+Vector2(index*30-90,40),1,kind); enemy["motion"]=Vector2.RIGHT
   game.enemies.append(enemy);index+=1
  camp.refresh(true);game.world.refresh(true)
  for frame in range(3): await process_frame
  check(game.world.terrain_cells.size()>0,"Live drawing and terrain remain active in region: "+id)
 game.enemies.clear(); game.playing=false
 game.hero.journey.first_floor=true; game.hero.journey.opening_reward=false
 var gold=game.hero.gold
 check(game.forest.check_opening_reward() and game.hero.gold==gold+50,"First dungeon expedition grants a clear reward")
 check(not game.forest.check_opening_reward(),"Opening reward is never repeated")
 game.save_game()
 var saved=Data.read_save()
 check(saved.exploration.challenges.size()==3 and saved.journey.opening_reward,"Exploration, trials, and opening rewards survive saving")
 var old=Data.fresh("Mage");old.erase("exploration")
 check(not Data.migrate(old).is_empty() and old.exploration.visited.forest,"Older saves receive exploration defaults")
 game.hud.show_character("camp"); await process_frame
 check(game.hud.overlay.visible,"Regional journal and crafting menu opens")
 print(str(checks)+" EXPANSION CHECKS PASSED")
 quit()
