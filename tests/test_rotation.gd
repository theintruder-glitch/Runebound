extends SceneTree
const Data=preload("res://scripts/data.gd")
var checks=0
func _initialize(): call_deferred("run")
func check(ok:bool,message:String):
 if not ok:
  push_error(message); quit(1); assert(ok,message)
 checks+=1; print("PASS: "+message)
func run():
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
 root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
 root.size=Vector2i(1080,2400)
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_character(Data.fresh("Warrior"))
 game.set_physics_process(false)
 for dims in [Vector2i(1080,2400),Vector2i(2400,1080),Vector2i(1280,720),Vector2i(720,1280)]:
  game.move_vector=Vector2.RIGHT
  game.attack_held=true
  root.size=dims
  game.adapt_screen()
  await process_frame
  await process_frame
  game.hud.layout()
  var view=game.get_viewport_rect().size
  check((view.x>view.y)==(dims.x>dims.y),"View follows orientation "+str(dims))
  check(root.content_scale_size==(Vector2i(900,480) if dims.x>dims.y else Vector2i(480,900)),"Landscape keeps a 480-unit base height "+str(dims))
  check(game.move_vector==Vector2.ZERO and not game.attack_held,"Rotation releases held touch actions "+str(dims))
  if dims.x>dims.y:
   check(game.hud.stick.position.x<view.x*.1 and game.hud.stick.get_global_rect()==game.hud.controls.model.rect("movement",game.hud.controls.safe_rect(),"landscape"),"Landscape joystick retains its saved relative left position "+str(dims))
  else:
   var bottom_spells=true
   for button in game.hud.spell_buttons.values():
    bottom_spells=bottom_spells and button.get_global_rect().end.y>view.y*.94 and button.get_global_rect().end.y<=view.y-8
   check(bottom_spells,"Portrait spells sit along the bottom edge "+str(dims))
   check(game.hud.attack_button.position.y>=view.y*.7,"Portrait combat row stays in the reachable lower screen "+str(dims))
  var controls=[game.hud.skill_button,game.hud.stick,game.hud.attack_button,game.hud.auto_button,game.hud.dash_button,game.hud.interaction]
  controls.append_array(game.hud.spell_buttons.values())
  var within=true
  var overlap=false
  for i in range(controls.size()):
   var rect=controls[i].get_global_rect()
   within=within and Rect2(Vector2.ZERO,view).encloses(rect)
   for j in range(i+1,controls.size()):
    overlap=overlap or rect.intersects(controls[j].get_global_rect())
  check(within,"All bottom controls fit on screen "+str(dims))
  check(not overlap,"Bottom controls do not overlap "+str(dims))
  check(game.hud.stick.size.x>=148 and game.hud.attack_button.size.x>=92,"Joystick and attack targets are larger "+str(dims))
  var touch=InputEventScreenTouch.new()
  touch.index=4; touch.pressed=true
  touch.position=game.hud.stick.get_global_rect().get_center()+Vector2(30,0)
  root.push_input(touch,true)
  check(game.move_vector.x>.5,"Joystick responds after rotation "+str(dims))
  touch.pressed=false; root.push_input(touch,true)
 game.begin_build("Wall")
 for dims in [Vector2i(1080,2400),Vector2i(2400,1080)]:
  root.size=dims; game.adapt_screen()
  await process_frame
  await process_frame
  game.hud.layout()
  var rect=game.hud.build_tools.get_global_rect()
  check(Rect2(Vector2.ZERO,game.get_viewport_rect().size).encloses(rect),"Build controls fit after rotation "+str(dims))
  check(not game.hud.controls.registry.build_rotate.get_global_rect().intersects(game.hud.interaction.get_global_rect()) and not game.hud.controls.registry.build_cancel.get_global_rect().intersects(game.hud.interaction.get_global_rect()),"Build controls leave PLACE accessible "+str(dims))
 game.cancel_build()
 check(game.hero.level==1,"Rotation preserves character state")
 print(str(checks)+" ROTATION CHECKS PASSED")
 quit()
