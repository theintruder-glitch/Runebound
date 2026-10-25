extends SceneTree
const Data=preload("res://scripts/data.gd")
const Catalog=preload("res://scripts/realm_catalog.gd")
var game
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func reached(target:Vector2i) -> bool:return not game.astar.get_id_path(game.dungeon_map.start,target).is_empty()
func visit(id:String) -> bool:
 game.set_player_position(game.cell_center(game.castle.features()[id].cell));return game.castle.use_feature()
func restore():
 var saved=Data.migrate(JSON.parse_string(JSON.stringify(game.hero)))
 check(not saved.is_empty(),"Actual JSON save migration accepts regional castle state")
 if not saved.is_empty():game.start_character(saved);game.set_physics_process(false);game.spawn_timer=999999
func clear_guards():
 for e in game.enemies.duplicate():
  if not e.dead:game.kill_enemy(e,"melee")
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;await process_frame
 var signatures={}
 for id in Catalog.ZONES:
  game.start_character(Data.fresh("Warrior"));game.set_physics_process(false);game.spawn_timer=999999
  var info=Catalog.ZONES[id]
  var route_ok=true
  for i in range(info.trail.size()-1):
   var a:Vector2=info.trail[i];var b:Vector2=info.trail[i+1]
   var steps=ceili(a.distance_to(b)/6)
   for step in range(steps+1):
    var p=a.lerp(b,float(step)/steps)
    if not game.walkable(p,12):route_ok=false;print("Blocked authored route: ",id," ",p)
   var traveled=game.move_position(a,b-a,12)
   check(traveled.distance_to(b)<1,"Full-radius forward movement across "+id+" segment "+str(i))
   check(game.move_position(b,a-b,12).distance_to(a)<1,"Full-radius return across "+id+" segment "+str(i))
  check(route_ok,"Every sample of "+id+" approach has collision clearance")
  game.set_player_position(Vector2.ZERO)
  check(not game.castle.enter_region(id),"Remote entry cannot bypass the real "+id+" entrance")
  game.set_player_position(info.gate);check(game.castle.enter_region(id),"Real outdoor entrance loads "+id)
  check(game.enemies.size()<=5 and game.castle.active(),"Only the active floor and five guards are loaded")
  check(not game.castle.enter_region(id),"Double entry cannot erase regional progress")
  check(reached(game.castle.features().key.cell) and reached(game.castle.features().seal.cell),"Key and mechanism are reachable before the upper gate opens")
  check(not reached(game.dungeon_map.exit),"Upper gate cannot be bypassed")
  check(visit("key"),"Armory key can be collected")
  restore();check(game.castle.has("key") and not game.castle.has("seal"),"Partial key progress survives reload")
  check(not reached(game.dungeon_map.exit),"One key alone does not open the upper gate")
  check(visit("seal") and reached(game.dungeon_map.exit),"Regional mechanism updates real collision and pathfinding")
  var floor_signature=JSON.stringify(game.dungeon_map.grid)
  check(not signatures.has(floor_signature),"Castle floor plan is structurally distinct: "+id);signatures[floor_signature]=true
  for room in game.castle.rooms(1):check(reached(room[0].get_center()),"Floor-one room is connected: "+room[1])
  check(not visit("vault"),"Living optional guard blocks its treasure")
  clear_guards();var gold=game.hero.gold
  check(visit("vault") and game.hero.gold==gold+130,"Optional guard unlocks exactly one treasure reward")
  check(not visit("vault") and game.hero.gold==gold+130,"Same vault cannot pay twice")
  check(game.castle.advance() and game.hero.dungeon.floor==2,"Gold stairs unload floor one and load floor two")
  var regional=game.castle.regional
  check(not reached(regional.rooms(2)[5][0].get_center()),"Puzzle vault is physically sealed before switches")
  for index in range(5):check(reached(regional.rooms(2)[index][0].get_center()),"Mandatory floor-two room is reachable: "+str(index))
  check(visit("checkpoint"),"Checkpoint binds on floor two")
  var dead_id=game.enemies[0].castle_index;game.kill_enemy(game.enemies[0],"melee")
  check(game.castle.retreat() and game.hero.dungeon.floor==1,"Entrance stair returns to previous floor")
  check(game.player_position()==game.cell_center(game.dungeon_map.exit),"Return stairs arrive at the matching doorway")
  check(game.castle.advance() and game.hero.dungeon.floor==2,"Cleared previous floor can be revisited without a reset")
  check(not game.enemies.any(func(e):return e.castle_index==dead_id),"Backtracking retains defeated regional guards")
  check(visit("archive"),"Archive reveals the real regional puzzle order")
  var wrong="rune-a" if info.order[0]!="rune-a" else "rune-b"
  check(not visit(wrong) and not game.castle.has(wrong),"Wrong rune order resets without opening the vault")
  check(visit(info.order[0]),"First correct rune activates")
  restore();check(game.castle.has(info.order[0]),"Partial puzzle survives JSON save/reload")
  check(visit(info.order[1]) and visit(info.order[2]) and game.castle.has("puzzle"),"Regional rune sequence opens the secret passage")
  check(reached(regional.rooms(2)[5][0].get_center()),"Solved puzzle changes the sealed room's actual collision")
  gold=game.hero.gold;check(visit("puzzle-vault") and game.hero.gold==gold+130,"Puzzle treasure pays once")
  check(not visit("puzzle-vault"),"Puzzle treasure cannot be farmed by repeated input")
  var cell=regional.traps()[0];game.set_player_position(game.cell_center(cell));var hp=game.hero.hp
  game.castle.trap_clock=2.4;game.castle.tick(.2);check(game.hero.hp==hp,"Trap warning is harmless")
  game.castle.tick(1.3);check(game.hero.hp<hp,"Trap strikes after its visible warning")
  hp=game.hero.hp;game.dash_time=.2;game.castle.trap_clock=3.7;game.castle.tick(.2)
  check(game.hero.hp==hp,"Dash avoids regional trap damage")
  game.dash_time=0;game.hud.show_pause();var clock=game.castle.trap_clock;game.castle.tick(2)
  check(game.castle.trap_clock==clock,"Menus pause regional traps")
  game.hud.resume();game.set_physics_process(false);game.hero.hp=0;game.defeated()
  check(game.hero.dungeon.floor==2 and game.hero.hp>0 and not game.playing,"Bound checkpoint restores the current run and pauses")
  restore();check(game.castle.has("puzzle") and game.castle.has("puzzle-vault"),"Checkpoint reload retains secret rooms and claimed rewards")
  game.hud.resume();game.set_physics_process(false);clear_guards();check(game.castle.advance(),"Cleared crypt stairs reach the boss floor")
  for room in game.castle.rooms(3):check(reached(room[0].get_center()),"Royal-floor room connects: "+room[1])
  check(not visit("relic"),"Legendary reward requires the current boss defeat")
  var boss=game.enemies.filter(func(e):return e.has("realm_boss"))[0]
  var patterns={}
  game.set_player_position(boss.pos+Vector2(0,90))
  for i in range(3):
   boss.cooldown=0;boss.windup=0;game.update_enemy_attack(boss,.016);patterns[boss.castle_attack]=true
   check(boss.windup>1 and boss.strike_radius>=45,"Boss attack warns before striking: "+boss.castle_attack)
  check(patterns.size()==3,"Each regional boss has three distinct attack patterns")
  boss.hp=boss.max_hp*.4;boss.windup=0;boss.cooldown=0;game.update_enemy_attack(boss,.016)
  check(boss.windup<1,"Wounded boss enters its faster attack phase")
  game.hud._process(0);check(game.hud.boss_bar.visible,"Regional boss displays a real health bar")
  clear_guards()
  while game.hero.inventory.size()<40:game.hero.inventory.append(game.hero.inventory[0].duplicate(true))
  check(not visit("relic"),"Full gear bag preserves the unclaimed legendary reward")
  game.hero.inventory.pop_back();check(visit("relic"),"Legendary reward can be collected after making room")
  check(game.hero.inventory[-1].name==info.relic,"Castle awards its unique named equipment")
  check(game.hero.spells.known.has(info.spell) and game.survival.count(info.core)>=3,"Castle grants its exclusive spell and forging material")
  game.hero.mp=1000;game.spell_cooldowns.clear();game.hud.resume();game.set_physics_process(false)
  check(game.spellbook.cast(info.spell),"Boss-earned spell casts through the real mana/cooldown path")
  check(game.hero.mp==1000-game.spellbook.BOOK[info.spell].cost and game.spell_cooldowns[info.spell]>0,"Exclusive spell spends its mana and starts cooldown")
  game.hero.mp=Data.max_mp(game.hero)
  restore();check(game.hero.dungeon.castle==id and game.hero.opened.get(id+"-relic",false),"Boss relic and castle identity survive save migration")
  game.set_player_position(game.cell_center(game.dungeon_map.exit));game.interact()
  check(game.hero.dungeon==null and game.player_position()==info.gate,"Final exit returns to the exact outdoor gate")
  game.castle.enter_region(id);game.set_player_position(game.cell_center(game.dungeon_map.start));game.interact()
  check(game.hero.dungeon==null and game.player_position()==info.gate,"Entrance exit always provides a safe retreat")
 # Landmark collision and character identity remain backward compatible.
 game.start_character(Data.fresh("Warrior"));game.set_physics_process(false)
 for site in game.landscape.realms.SITES.values():
  check(game.walkable(site.point,12),"Outdoor discovery has a usable interaction point: "+site.name)
 var highland=Catalog.ZONES.stormbreak.gate;game.set_player_position(highland)
 check(game.exploration.outdoor_highlands(highland) and game.weather.sky()!="Underground","Highland weather runs outdoors rather than treating the whole region as a cave")
 game.set_player_position(game.exploration.REGIONS.caves.point)
 check(game.weather.sky()=="Underground","Original Emberforge cavern retains shelter and weather behavior")
 print("%d KINGDOM CHECKS; %d FAILURES" % [checks,failures]);quit(1 if failures else 0)
