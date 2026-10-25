extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 checks+=1
 if ok: print("PASS: "+message)
 else: failures+=1;push_error("FAIL: "+message)
func reset():
 game.hero.dungeon=null;game.hero.survival.structures=[];game.enemies.clear();game.shots.clear();game.visuals.clear();game.effects.clear()
 game.hero.auto=false;game.hero.hp=100;game.spawn_timer=99999;game.set_player_position(Vector2.ZERO);game.hud.resume();game.set_physics_process(false)
func enemy(at:Vector2,kind:String="goblin") -> Dictionary:
 var e=game.create_enemy(at,1,kind);e.cooldown=999;game.enemies.append(e);return e
func button_with(node:Node,text:String):
 for child in node.get_children():
  if child is Button and child.text.begins_with(text):return child
  var found=button_with(child,text)
  if found!=null:return found
 return null
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;await process_frame
 game.start_character(Data.fresh("Warrior"));game.set_physics_process(false)
 check(game.reduced_crowds and game.roaming_limit()==6,"Existing installations default to six roaming enemies")
 var passed=true;var wolves=false
 for region in [Vector2.ZERO,Vector2(2050,0),Vector2(-2050,0),Vector2(0,-2050)]:
  for sample in range(20):
   reset();game.set_player_position(region);seed(sample)
   for i in range(80):game.spawn_enemy()
   passed=passed and game.enemies.size()<=6
   wolves=wolves or game.enemies.any(func(e):return e.get("pack",0)>0)
 check(passed,"Hundreds of spawn attempts in all four regions respect six-enemy cap")
 check(wolves,"Wolf packs remain available within the cap")
 game.set_low_power(false);check(game.roaming_limit()==6,"60 FPS cannot raise roaming density")
 game.set_reduced_crowds(false);check(game.roaming_limit()==12,"Standard crowd option is bounded at twelve")
 reset()
 for i in range(100):game.spawn_enemy()
 check(game.enemies.size()<=12,"Standard pack spawning cannot overshoot twelve")
 game.set_reduced_crowds(true);reset()
 for i in range(3):enemy(Vector2(100+i*20,0))
 var before=game.enemies.size()
 check(game.spawn_enemy().is_empty() and game.enemies.size()==before,"Three nearby hostiles stop ambient reinforcements")
 reset()
 for i in range(3):enemy(Vector2(100+i*20,0),"deer")
 check(game.nearby_hostiles()==0,"Wildlife does not count as a hostile fight")
 var slowest=0.0;var fastest=999.0
 for clock in [0.0,170.0,400.0,590.0]:
  game.hero.worldTime=clock
  for level in [1,100,1000]:
   game.hero.level=level
   for i in range(10):
    var interval=game.roaming_spawn_interval();slowest=maxf(slowest,interval);fastest=minf(fastest,interval)
 check(fastest>=3 and slowest<=10,"Night and high levels retain bounded reinforcement intervals")
 game.hero.level=1;reset()
 var idle=enemy(Vector2(1000,0));var active=enemy(Vector2(1000,20));active.aggro=4
 var burning=enemy(Vector2(1000,40));burning.burn=3
 var named=enemy(Vector2(1100,0));named.named="Quest foe"
 var warning=enemy(Vector2(1000,60));warning.windup=.5
 var nearby=enemy(Vector2(200,0))
 game.set_reduced_crowds(true)
 check(not game.enemies.has(idle),"Reduced crowds recycle distant idle ambient foes")
 check(game.enemies.has(active) and game.enemies.has(burning) and game.enemies.has(warning),"Changing density preserves aggro, burning and windup enemies")
 check(game.enemies.has(named) and game.enemies.has(nearby),"Changing density preserves named foes and nearby actors")
 check(game.hero.kills==0,"Recycling grants no kills or rewards")
 reset();named=enemy(Vector2(1200,0));named.named="Quest foe";idle=enemy(Vector2(1000,0));active=enemy(Vector2(250,20));active.aggro=3
 game.tick(.01)
 check(game.enemies.has(named) and game.enemies.has(active) and not game.enemies.has(idle),"Regular cleanup keeps protected/active encounters and removes far idle reserves")
 reset();game.enter_dungeon();game.enemies.clear();idle=enemy(Vector2(1600,0));game.set_reduced_crowds(true)
 check(game.enemies.has(idle),"Density changes cannot delete dungeon objectives")
 game.leave_dungeon();reset()
 var e=enemy(Vector2(180,0));e.aggro=4
 game.tick(1.0/60);var x=e.pos.x;var wait=e.think_wait;game.tick(1.0/60)
 check(e.pos.x<x and e.think_wait<wait,"Movement continues every physics frame while ordinary steering is reused")
 var unchanged=e.think_player;game.set_player_position(Vector2(0,40));game.tick(1.0/60)
 check(e.think_player!=unchanged and e.think_player==game.player_position(),"Player displacement refreshes steering immediately")
 e.burn=1;e.burn_tick=.001;e.burn_damage=5;e.burn_kind="magic";var hp=e.hp;game.tick(.01)
 check(e.hp==hp-5,"Damage-over-time continues at full rate between steering decisions")
 reset();e=enemy(Vector2(50,0));e.aggro=4;e.windup=.3;e.strike=game.player_position();e.strike_radius=38;e.windup_max=.3
 game.tick(.02);check(is_equal_approx(e.windup,.28),"Attack warning timing remains per frame")
 game.pause_game();var timer=e.windup;game.update_enemy_attack(e,.1)
 check(e.windup==timer,"Menus freeze warnings under reduced crowds")
 reset();e=enemy(Vector2(180,0));e.named="Quest foe";e.aggro=3;game.tick(.01)
 check(not e.has("think_wait"),"Named quest AI stays at full update rate")
 reset();e=enemy(Vector2(180,0));e.trial="caves";e.aggro=3;game.tick(.01)
 check(not e.has("think_wait"),"Regional trial AI stays at full update rate")
 reset();var far=enemy(Vector2(500,0));var near=enemy(Vector2(50,0));var neutral=enemy(Vector2(10,0),"deer")
 check(is_same(game.closest(100,Vector2.ZERO,{},true),near),"Range-first targeting still picks nearest visible hostile")
 check(game.closest(100,Vector2.ZERO,near,true).is_empty(),"Target exclusions and range gates remain valid")
 reset();var blocked=enemy(Vector2(30,0));var visible=enemy(Vector2(0,60))
 game.hero.survival.structures.append({"kind":"Wall","x":16.0,"y":0.0,"rotation":1,"fuel":0.0,"open":false,"stash":{}})
 check(is_same(game.closest(100,Vector2.ZERO),visible),"A nearer wall-blocked target cannot hide a reachable target")
 game.set_reduced_crowds(false);game.set_low_power(true);game.load_performance_settings()
 check(not game.reduced_crowds and game.low_power,"Frame-cap changes preserve saved crowd preference")
 game.set_reduced_crowds(true);game.set_low_power(false);game.load_performance_settings()
 check(game.reduced_crowds and not game.low_power,"Crowd changes preserve saved frame-cap preference")
 for dims in [Vector2i(1080,2400),Vector2i(2400,1080)]:
  root.size=dims;game.adapt_screen();await process_frame;game.hud.show_pause();await process_frame
  var button=button_with(game.hud.content,"Enemy crowds:")
  check(button!=null,"Crowd setting is exposed in "+str(dims))
  var selected=game.reduced_crowds
  if button!=null:button.pressed.emit()
  check(game.reduced_crowds!=selected and not game.playing,"Native crowd action applies while remaining paused in "+str(dims))
 print("%d CROWD RELIEF CHECKS; %d FAILURES" % [checks,failures]);quit(1 if failures else 0)
