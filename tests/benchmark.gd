extends SceneTree
const Data=preload('res://scripts/data.gd')
func _initialize():
 call_deferred('run')
func run():
 Engine.max_fps=0
 var game=load('res://scenes/main.tscn').instantiate()
 root.add_child(game)
 await process_frame
 game.start_character(Data.fresh('Ranger'))
 Engine.max_fps=0
 game.playing=false
 if "profile_enabled" in game.world:game.world.profile_enabled=true
 game.hero.auto=false
 game.hero.hp=1e9
 game.enemies.clear()
 for i in range(38):
  var e=game.create_enemy(Vector2.from_angle(float(i)/38*TAU)*(140 if i<18 else 1200),3,'goblin')
  e.speed=0
  game.enemies.append(e)
 for i in range(250):
  game.world.queue_redraw()
  await process_frame
 var results={}
 if 'profile_draw_samples' in game.world:
  var samples=game.world.profile_draw_samples
  if samples.size()>10:
   var trimmed=samples.slice(10)
   trimmed.sort()
   var total=0.0
   for s in trimmed:total+=s
   results.draw_samples=trimmed.size()
   results.draw_mean_us=total/trimmed.size()
   results.draw_p95_us=trimmed[int(trimmed.size()*.95)]
 var start=Time.get_ticks_usec()
 for i in range(600):game.tick(1.0/60.0)
 results.tick_mean_us=float(Time.get_ticks_usec()-start)/600.0
 results.scenery_rebuilds=game.world.get('scenery_rebuilds')
 results.viewport=root.get_visible_rect().size
 print('BENCHMARK_JSON '+JSON.stringify(results))
 quit()
