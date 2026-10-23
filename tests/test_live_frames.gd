extends SceneTree
const Data=preload("res://scripts/data.gd")
var checks=0
func _initialize():
 call_deferred("run")
func check(value: bool,message: String):
 if not value:
  push_error("FAIL: "+message)
  quit(1)
  assert(value,message)
 checks+=1
 print("PASS: "+message)
func run():
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
 root.size=Vector2i(1688,900) if "landscape" in OS.get_cmdline_user_args() else Vector2i(480,900)
 await process_frame
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_character(Data.fresh("Warrior"))
 game.hero.auto=false
 game.world.profile_enabled=true
 check(game.world.is_processing(),"World receives engine frame callbacks automatically")
 check(game.is_physics_processing(),"Movement receives real physics callbacks")
 var stick=game.hud.stick
 for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
  game.set_player_position(Vector2.ZERO)
  game.camera.position=Vector2.ZERO
  game.camera.force_update_scroll()
  game.enemies.clear()
  game.spawn_timer=1000
  game.world.profile_hero_positions.clear()
  var before=game.world.clock
  var touch=InputEventScreenTouch.new()
  touch.index=2
  touch.pressed=true
  touch.position=stick.get_global_rect().get_center()
  root.push_input(touch,true)
  var drag=InputEventScreenDrag.new()
  drag.index=2
  drag.position=touch.position+direction*stick.size.x*.33
  root.push_input(drag,true)
  # No direct tick(), _process(), _draw(), or queue_redraw() calls. The
  # actual engine loop must update both simulation and drawing continuously.
  var max_camera_step=0.0
  var max_hero_step=0.0
  var old_camera=game.camera.position
  var old_hero=game.player_position()
  for frame in range(70):
   await process_frame
   max_camera_step=maxf(max_camera_step,game.camera.position.distance_to(old_camera))
   max_hero_step=maxf(max_hero_step,game.player_position().distance_to(old_hero))
   old_camera=game.camera.position
   old_hero=game.player_position()
  var draws=game.world.profile_hero_positions
  check(draws.size()>=60,"Hero drawing runs on successive live frames "+str(direction))
  var advancing=0
  for i in range(1,draws.size()):
   if (draws[i]-draws[i-1]).dot(direction)>.01: advancing+=1
  check(advancing>=draws.size()-3,"Drawn hero position advances continuously with held joystick "+str(direction))
  check(game.world.clock-before>1,"Walking animation clock advances in the real loop "+str(direction))
  check(max_camera_step<=max_hero_step+.01,"Camera never jumps farther than the character walked "+str(direction))
  touch.pressed=false
  root.push_input(touch,true)
  var stopped=game.player_position()
  for frame in range(4): await process_frame
  check(game.player_position().is_equal_approx(stopped),"Releasing live touch stops immediately "+str(direction))
 game.pause_game()
 var paused_clock=game.world.clock
 for frame in range(3): await process_frame
 check(game.world.clock==paused_clock,"Pause stops animation")
 print(str(checks)+" LIVE FRAME CHECKS PASSED at "+str(root.size))
 quit()
