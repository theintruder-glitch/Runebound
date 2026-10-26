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
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;await process_frame
 for dims in [Vector2i(720,1280),Vector2i(1280,720)]:
  root.size=dims;game.adapt_screen();await process_frame
  game.start_character(Data.fresh("Mage"));game.set_physics_process(false);game.hero.auto=false;game.enemies.clear()
  for flag in ["chapter_boss","forge_boss","thornwatch_boss","realm_boss","cave_boss","beacon_boss"]:
   var e=game.create_enemy(game.player_position()+Vector2(0,80),5,"guardian",true);e.named="Test Keeper";e[flag]=true if flag!="realm_boss" else "frostspire";game.enemies=[e]
   e.hp=e.max_hp*.5;check(not game.boss_signs.phase_two(e),"Exact half health remains phase I: "+flag)
   e.hp=e.max_hp*.49;var hp=e.hp;var radius=e.strike_radius;var count=game.enemies.size();var effects=game.visuals.size()
   check(game.boss_signs.on_damage(e),"Crossing below half announces faster phase: "+flag)
   check(e.hp==hp and e.strike_radius==radius and game.enemies.size()==count,"Presentation does not alter damage, hit area or spawn budget")
   check(not game.boss_signs.on_damage(e) and game.visuals.size()==effects+1,"Phase alert produces one bounded effect, not repeated spam")
   game.hud._process(0)
   check(game.hud.boss_name.visible and "Test Keeper" in game.hud.boss_name.text and "PHASE II" in game.hud.boss_name.text,"Boss caption names keeper and phase")
   await process_frame
   check(game.hud.boss_bar.get_global_rect().encloses(game.hud.boss_name.get_global_rect()),"Caption stays inside enlarged health bar in both orientations")
   game.hud.show_pause();game.hud._process(0);check(not game.hud.boss_name.visible,"Menu hides encounter caption")
   e.erase("phase_announced");check(not game.boss_signs.on_damage(e),"Pause prevents a new phase alert")
   game.hud.resume();game.set_physics_process(false);e.dead=true;game.hud._process(0);check(not game.hud.boss_name.visible,"Dead bosses do not leave stale captions")
  game.enemies.clear()
  var ordinary=game.create_enemy(game.player_position()+Vector2(0,80),2,"guardian",true);ordinary.named="Ordinary Guardian";ordinary.hp=ordinary.max_hp*.4;game.enemies=[ordinary]
  check(not game.boss_signs.on_damage(ordinary),"Generic guardian does not falsely announce faster attacks")
  game.hud._process(0);check("Boss encounter" in game.hud.boss_name.text,"Generic boss health remains readable without a false phase claim")
  ordinary.pos+=Vector2(2000,0);game.hud._process(0);check(not game.hud.boss_name.visible,"Far-away outdoor boss is not advertised as current encounter")
  # Actual regional keeper behavior retains its warned attack timing and hit area.
  game.start_character(Data.fresh("Mage"));game.set_physics_process(false)
  game.set_player_position(game.landscape.realms.Catalog.ZONES.frostspire.gate);game.castle.enter_region("frostspire")
  game.hero.dungeon.floor=3;game.build_floor(true)
  var boss=game.enemies.filter(func(e):return e.has("realm_boss"))[0]
  game.set_player_position(boss.pos+Vector2(0,90));boss.cooldown=0;game.update_enemy_attack(boss,.016)
  var strike=boss.strike;var radius=boss.strike_radius;var windup=boss.windup
  game.hud._process(0);check("Frost King" in game.hud.boss_name.text and "Phase I" in game.hud.boss_name.text,"Real castle boss displays its actual identity")
  check(boss.strike==strike and boss.strike_radius==radius and boss.windup==windup,"HUD update does not move or shorten an existing warning")
  boss.hp=boss.max_hp*.49;game.hurt(boss,1,"magic",0)
  check(boss.get("phase_announced",false),"Real damage path triggers phase presentation")
  game.hud._process(0);check("PHASE II" in game.hud.boss_name.text,"Real keeper health transition appears in HUD")
 print("%d BOSS SIGN CHECKS; %d FAILURES" % [checks,failures]);quit(1 if failures else 0)
