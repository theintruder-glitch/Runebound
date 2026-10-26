extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func veteran() -> Dictionary:
 var h=Data.fresh("Mage");h.chapter.accepted=true;h.chapter.clues={"watch":true,"cart":true,"grove":true};h.chapter.translated=true;h.chapter.cleared=true;h.chapter.claimed=true
 h.forge_chapter={"accepted":true,"inspected":true,"cleared":true,"claimed":true};h.exploration.challenges.caves=true
 return h
func restore():
 var saved=Data.migrate(JSON.parse_string(JSON.stringify(game.hero)))
 check(not saved.is_empty(),"Chapter III survives real JSON migration")
 if not saved.is_empty():game.start_character(saved);game.set_physics_process(false);game.spawn_timer=999999
func button(parent:Node,prefix:String) -> Button:
 if parent is Button and parent.text.begins_with(prefix):return parent
 for child in parent.get_children():
  var found=button(child,prefix)
  if found!=null:return found
 return null
func settle():
 for i in range(4):await process_frame
func touch_interact(p:Vector2):
 game.hud.resume();game.set_physics_process(false);game.set_player_position(p);game.update_interaction()
 var event=InputEventScreenTouch.new();event.index=7;event.pressed=true;event.position=game.hud.interaction.get_global_rect().get_center();root.push_input(event,true)
 event.pressed=false;root.push_input(event,true);await process_frame
func clear_guards():
 for e in game.enemies.duplicate():
  if not e.dead:game.kill_enemy(e,"magic")
func use_feature(id:String):
 game.set_player_position(game.cell_center(game.castle.features()[id].cell));game.castle.use_feature()
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
 for dims in [Vector2i(720,1280),Vector2i(1280,720)]:
  root.size=dims;game.adapt_screen();await settle()
  game.start_character(Data.fresh("Mage"));game.set_physics_process(false);game.set_player_position(game.trader.POSITION)
  check(game.mire.stage()==-1 and not game.mire.accept(),"Chapter III waits for both earlier chapter rewards")
  var old=veteran();old.erase("mire_chapter");game.start_character(old);game.set_physics_process(false);game.enemies.clear()
  check(game.mire.stage()==0 and game.hero.inventory.size()==1,"Old characters gain an unstarted chapter without losing gear")
  check(not game.mire.accept(),"Cannot accept remotely")
  game.set_player_position(game.trader.POSITION);check(game.mire.accept() and game.mire.stage()==1,"Mara starts The Drowned Oath")
  check(not game.mire.accept() and not game.mire.claim() and not game.mire.recover(),"Repeated or out-of-order actions grant nothing")
  game.mire.track(false);check(game.hero.chapter.tracking and game.hero.exploration.target.is_empty(),"Story tracker clears competing navigation targets")
  check("Sunken Watch" in game.chapter.objective(),"Chapter objective points to the first missing clue")
  for id in game.mire.CLUES:
   var p:Vector2=game.landscape.realms.SITES[id].point
   check(game.walkable(p,12),"Chapter clue uses an existing accessible world site")
   await touch_interact(p)
   check(game.hero.mire_chapter.clues.has(id),"Actual mobile input reads the clue: "+id)
   check(not game.mire.investigate(id),"Read clue cannot repeat")
   check(not game.hero.opened.get(id,false),"Reading lore does not silently consume normal cache supplies")
   restore()
  check(game.mire.stage()==2,"Two records lead to the Veil Altar trial")
  game.set_player_position(game.exploration.REGIONS.swamp.point);game.enemies.clear();game.exploration.interact();game.exploration.interact()
  check(game.exploration.active(),"Existing swamp trial starts normally")
  game.exploration.dodged=true;clear_guards()
  check(game.mire.stage()==3 and game.hero.exploration.pending.swamp,"Real completed trial advances story and preserves its pending relic")
  game.set_player_position(game.landscape.realms.Catalog.ZONES.blackmire.gate)
  check(game.castle.enter_region("blackmire"),"Real Blackmire gate starts the existing castle")
  use_feature("key");use_feature("seal");clear_guards();check(game.castle.advance() and game.hero.dungeon.floor==2,"Existing locks and floor guards retain their progression")
  var archive=game.castle.features().archive.cell;game.set_player_position(game.cell_center(archive))
  check(not game.mire.recover(),"Archive testament stays protected until Abomination is defeated")
  use_feature("archive");use_feature("checkpoint");clear_guards();check(game.castle.advance() and game.hero.dungeon.floor==3,"Castle archive, checkpoint and third floor remain functional")
  var count=game.enemies.size();clear_guards()
  check(game.mire.stage()==4 and game.hero.opened.get("blackmire-cleared",false),"Actual castle boss defeat advances Chapter III")
  check(count<=5,"Chapter introduces no extra enemies over the castle budget")
  game.hud._process(0);check("Backtrack" in game.hud.objective_label.text,"Story HUD points back to level-two archive")
  check(game.castle.retreat() and game.hero.dungeon.floor==2,"Actual stairs return from boss arena to archive floor")
  game.set_player_position(game.cell_center(archive));game.atlas.observe(true)
  check(game.atlas.destinations().has("story:testament"),"Discovered testament appears in Dungeon Atlas after boss defeat")
  check(game.castle.has("archive"),"Previously read castle rune clue stays read")
  var gold=game.hero.gold;var essence=game.hero.essence;await touch_interact(game.cell_center(archive))
  check(game.hero.mire_chapter.testament and game.mire.stage()==5,"Actual touch recovers the quest record from the used archive")
  check(game.hero.gold==gold and game.hero.essence==essence,"Recovering the record cannot duplicate archive loot")
  check(not game.atlas.destinations().has("story:testament") and not game.mire.recover(),"Recovered record cannot be collected twice or leave a stale quest marker")
  restore();check(game.hero.mire_chapter.testament,"Record persists across closing and continuing the castle")
  game.hero.hp=0;game.defeated();check(game.hero.dungeon.floor==2 and game.hero.mire_chapter.testament,"Checkpoint defeat preserves the recovered quest record")
  game.hud.resume();game.set_physics_process(false)
  check(not game.mire.claim(),"Chapter payment still requires returning to Mara")
  game.leave_dungeon();game.set_player_position(game.trader.POSITION)
  while game.hero.inventory.size()<40:game.hero.inventory.append(game.hero.inventory[0].duplicate(true))
  gold=game.hero.gold;essence=game.hero.essence;var points=game.hero.points
  check(game.mire.claim() and game.hero.gold==gold+450 and game.hero.essence==essence+8 and game.hero.points==points+3,"Full Gear bag cannot block exact currency/stat reward")
  check(not game.mire.claim() and game.hero.gold==gold+450,"Mara cannot pay twice")
  restore();check(game.mire.stage()==6 and game.mire.objective().is_empty(),"Completed third chapter remains completed after reload")
  # The permanent benefit changes only positive swamp weather wetness.
  game.hero.mode="survival";game.hero.worldTime=480;game.hero.survival.structures.clear();game.set_player_position(Vector2(-1900,600));game.hero.needs.wetness=10
  game.hero.mire_chapter.claimed=false;var hp=game.hero.hp;game.expedition.tick(1);var normal=game.hero.needs.wetness-10
  game.hero.mire_chapter.claimed=true;game.hero.needs.wetness=10;game.expedition.tick(1);var protected_delta=game.hero.needs.wetness-10
  check(normal>0 and absf(protected_delta-normal*.6)<.001,"Mirewarden oath reduces actual swamp precipitation buildup by exactly 40 percent")
  game.set_player_position(Vector2(0,0));check(game.mire.weather_multiplier()==1,"Other regions keep normal weather exposure")
  game.set_player_position(Vector2(-1900,600));game.hero.worldTime=360;game.hero.needs.wetness=10;game.expedition.tick(1)
  check(game.hero.needs.wetness<10,"Oath does not slow normal drying in clear weather")
  game.hero.mode="classic";var needs=game.hero.needs.duplicate(true);game.expedition.tick(1);check(game.hero.needs==needs,"Classic mode still has no Survival drain")
  game.hud.show_character("mire");await settle();check(button(game.hud.content,"Next lead · track Frostspire")!=null,"Completed journal provides a real next-region tracking action")
  button(game.hud.content,"Next lead · track Frostspire").pressed.emit();check(game.hero.exploration.target=="frostspire","Next lead routes through existing world navigation")
 # Veteran discoveries and victories are honored on acceptance.
 var prior=veteran();prior.opened["mire-watch"]=true;prior.opened["mire-grove"]=true;prior.opened["blackmire-cleared"]=true;prior.exploration.challenges.swamp=true
 game.start_character(prior);game.set_physics_process(false);game.set_player_position(game.trader.POSITION);game.mire.accept()
 check(game.mire.stage()==4,"Veteran caches, trial and boss victories count without repeating those wins")
 for bad in [{"accepted":"yes","clues":{},"testament":false,"claimed":false},{"accepted":true,"clues":{"fake":true},"testament":false,"claimed":false},{"accepted":true,"clues":{},"testament":true,"claimed":false},{"accepted":true,"clues":{},"testament":false,"claimed":true}]:
  var invalid=veteran();invalid.mire_chapter=bad;check(Data.migrate(invalid).is_empty(),"Malformed chapter progression rejected")
 print("%d MIRE CHAPTER CHECKS; %d FAILURES" % [checks,failures]);quit(1 if failures else 0)
