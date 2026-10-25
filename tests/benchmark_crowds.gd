extends SceneTree
const Data=preload("res://scripts/data.gd")
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.start_character(Data.fresh("Warrior"));game.set_physics_process(false)
 game.set_player_position(Vector2(2050,0));game.hero.hp=1e9;game.spawn_timer=1e9
 var report={"kind":"synthetic headless CPU; not phone FPS","samples":600}
 for count in [6,24]:
  seed(5917);game.enemies.clear();game.hero.auto=true;game.hero.hp=1e9
  for i in range(count):
   var e=game.create_enemy(game.player_position()+Vector2.from_angle(i*TAU/count)*150,3,"archer")
   e.speed=0;e.aggro=1e9;e.cooldown=1e9;game.enemies.append(e)
  for i in range(60):game.tick(1.0/60)
  var start=Time.get_ticks_usec()
  for i in range(600):game.tick(1.0/60)
  report[str(count)+"_enemies_tick_mean_us"]=float(Time.get_ticks_usec()-start)/600
 print("CROWD_BENCHMARK "+JSON.stringify(report));quit()
