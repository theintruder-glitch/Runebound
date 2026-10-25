extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var checks=0
var failures=0
func _initialize(): call_deferred("run")
func check(ok:bool,message:String):
 checks+=1
 if ok: print("PASS: "+message)
 else: failures+=1;push_error("FAIL: "+message)
func settle(): await process_frame;await process_frame
func veteran() -> Dictionary:
 var h=Data.fresh("Warrior")
 h.chapter={"accepted":true,"clues":{"watch":true,"cart":true,"grove":true},"translated":true,"cleared":true,"claimed":true,"tracking":false,"return_until":0.0}
 return h
func button_with(node:Node,text:String):
 for child in node.get_children():
  if child is Button and child.text.begins_with(text): return child
  var found=button_with(child,text)
  if found!=null: return found
 return null
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
 var h=Data.fresh("Warrior");h.erase("forge_chapter");h.gold=612
 var old=Data.migrate(h)
 check(not old.is_empty() and old.gold==612 and not old.forge_chapter.accepted,"Legacy saves retain progress and get an unstarted second chapter")
 for key in ["accepted","inspected","cleared","claimed"]:
  var bad=old.duplicate(true);bad.forge_chapter[key]=null
  check(Data.migrate(bad).is_empty(),"Invalid chapter field rejected: "+key)
 var bad=old.duplicate(true);bad.forge_chapter.accepted=true
 check(Data.migrate(bad).is_empty(),"Chapter II cannot precede Chapter I")
 game.start_character(old);game.set_physics_process(false);game.enemies.clear()
 var story=game.forge
 game.set_player_position(game.trader.POSITION)
 check(story.stage()==-1 and not story.accept(),"Mara gates Chapter II behind the Hollow Root reward")
 game.start_character(veteran());game.set_physics_process(false);game.enemies.clear();game.spawn_timer=99999
 check(story.stage()==0 and not story.accept(),"Chapter II starts at Mara, not remotely")
 game.set_player_position(game.trader.POSITION)
 check(story.accept() and story.stage()==1,"Mara accepts Ash and Oath")
 check(not story.accept(),"Acceptance cannot reset progress")
 check(not story.inspect_forge() and not story.begin() and not story.claim(),"Trial, location and chapter order gate all steps")
 game.exploration.track("caves")
 check(game.hero.exploration.target=="caves","Chapter's regional tracking helper works")
 game.exploration.track("unknown")
 check(game.hero.exploration.target=="caves","Invalid tracking leaves the existing target intact")
 story.track()
 check(game.hero.exploration.target.is_empty() and game.chapter.objective().contains("sword + magic"),"Story tracking produces the current chapter objective")
 game.set_player_position(story.point())
 game.exploration.interact() # Discover the real landmark before its trial.
 game.exploration.interact()
 var sentinel=game.exploration.foes[0]
 game.exploration.on_hit(sentinel,"melee");game.exploration.on_hit(sentinel,"magic");game.kill_enemy(sentinel,"magic")
 check(story.stage()==2 and game.hero.exploration.pending.caves,"Real sword and magic trial advances the chapter without consuming its relic")
 check(story.inspect_forge() and story.stage()==3,"Physical forge inscription advances the chapter")
 check(not story.inspect_forge(),"Inscription cannot be collected twice")
 var restored=Data.migrate(JSON.parse_string(JSON.stringify(game.hero)))
 check(not restored.is_empty() and restored.forge_chapter.inspected,"New chapter progress survives actual JSON migration")
 bad=restored.duplicate(true);bad.exploration.challenges.caves=false
 check(Data.migrate(bad).is_empty(),"Forged inscription progress without the trial is rejected")
 check(story.interaction().is_empty() and game.exploration.interaction()=="CLAIM TRIAL RELIC","Earned trial relic keeps its world interaction priority")
 game.exploration.claim("caves")
 game.enemies.clear()
 check(story.interaction()=="BREAK ASHEN BINDING" and story.begin(),"Forge interaction starts the ashen binding")
 check(story.foes.size()==3 and story.active(),"Encounter contains one Keeper and two embers")
 check(not story.begin(),"Repeated input cannot duplicate an encounter")
 check(not game.chapter.recall_reason().is_empty(),"Hearthcall cannot escape the active encounter")
 var count=game.enemies.size();game.exploration.begin_trial("caves")
 check(game.enemies.size()==count and game.exploration.interaction().is_empty(),"Regional trials cannot overlap the story fight")
 var boss=story.foes[0];game.set_player_position(boss.pos+Vector2(10,0));boss.cooldown=0;game.playing=true
 game.update_enemy_attack(boss,.01);var windup=boss.windup;var radius=boss.strike_radius
 boss.windup=0;boss.cooldown=0;boss.hp=boss.max_hp*.4;game.update_enemy_attack(boss,.01)
 check(boss.windup<windup and boss.strike_radius>radius,"Keeper's second phase changes real attack timing and radius")
 game.pause_game();var clock=boss.windup;game.update_enemy_attack(boss,4)
 check(boss.windup==clock,"Menus freeze Keeper attacks")
 game.hud.resume();game.set_player_position(story.point()+Vector2(560,0));story.tick(.1)
 check(not story.active() and story.stage()==3 and not game.enemies.has(boss),"Leaving the clearing abandons foes and preserves retry progress")
 game.set_player_position(story.point());check(story.begin(),"Abandoned encounters can be retried")
 restored=Data.migrate(JSON.parse_string(JSON.stringify(game.hero)));game.start_character(restored);game.set_physics_process(false);game.enemies.clear()
 check(not story.active() and story.stage()==3,"Reload abandons transient combat without granting completion")
 game.set_player_position(story.point());story.begin();game.enemies.erase(story.foes[1]);story.tick(.1)
 check(not story.active() and not story.data().cleared,"Missing foes cannot softlock or falsely complete the encounter")
 game.set_player_position(story.point());story.begin();game.kill_enemy(story.foes[0],"melee")
 check(not story.data().cleared,"Killing the Keeper alone leaves two embers to defeat")
 for e in story.foes.duplicate(): game.kill_enemy(e,"magic")
 check(not story.active() and story.stage()==4,"Defeating all actual enemies breaks the binding")
 check(not story.claim(),"Completion reward requires returning to Mara")
 game.set_player_position(game.trader.POSITION);var gold=game.hero.gold;var essence=game.hero.essence;var points=game.hero.points
 check(story.claim() and game.hero.gold==gold+350 and game.hero.essence==essence+6 and game.hero.points==points+2,"Mara pays the precise chapter reward")
 check(not story.claim() and game.hero.gold==gold+350,"Chapter reward cannot be collected twice")
 restored=Data.migrate(JSON.parse_string(JSON.stringify(game.hero)));game.start_character(restored);game.set_physics_process(false)
 check(story.stage()==5 and story.objective().is_empty(),"Completed chapter remains completed after reload")
 var prior=veteran();prior.exploration.challenges.caves=true
 game.start_character(prior);game.set_physics_process(false);game.set_player_position(game.trader.POSITION);story.accept()
 check(story.stage()==2,"Veteran Emberforge wins count without repeating the trial")
 game.set_player_position(story.point());story.inspect_forge();game.enemies.clear()
 game.hero.hp=0
 check(not story.begin(),"A defeated character cannot start an encounter")
 game.hero.hp=100
 game.hero.survival.structures.append({"kind":"Wall","x":story.point().x,"y":story.point().y-120,"rotation":0,"fuel":0.0,"open":false,"stash":{}})
 check(not story.begin() and not story.active() and story.foes.is_empty(),"Obstructed encounter space spawns nothing and keeps the chapter retryable")
 game.hero.survival.structures.clear()
 for dims in [Vector2i(1080,2400),Vector2i(2400,1080)]:
  root.size=dims;game.adapt_screen();await settle();game.hud.show_character("chapter");await settle()
  check(not game.playing and game.hud.content.size.x<=game.hud.scroll.size.x+1,"Story journal fits and pauses in "+str(dims))
  var launch=button_with(game.hud.content,"Break ashen binding")
  check(launch!=null and not launch.disabled,"Encounter launch is accessible in "+str(dims))
  if launch!=null: launch.pressed.emit()
  check(story.active() and game.playing,"Native journal launch starts combat and resumes play in "+str(dims))
  var before=game.enemies.size();game.spawn_enemy()
  check(game.enemies.size()==before,"Ambient spawns respect the active story encounter")
  game.hero.hp=0;story.tick(.1)
  check(not story.active() and story.stage()==3,"Defeat abandons the encounter without granting completion")
  game.hero.hp=100
 game.hero.exploration.challenges.caves=true;story.data().inspected=true
 game.set_player_position(story.point());story.begin()
 for e in story.foes.duplicate(): game.kill_enemy(e,"melee")
 game.set_player_position(game.trader.POSITION)
 while game.hero.inventory.size()<40: game.hero.inventory.append(game.hero.inventory[0].duplicate(true))
 check(story.claim(),"Chapter currency rewards remain claimable with a full gear bag")
 print("%d FORGE CHAPTER CHECKS; %d FAILURES" % [checks,failures]);quit(1 if failures else 0)
