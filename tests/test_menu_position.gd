extends SceneTree
const Data=preload("res://scripts/data.gd")
var checks=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 if not ok:push_error(message);quit(1);assert(ok,message)
 checks+=1;print("PASS: "+message)
func settle():
 for i in range(4):await process_frame
func buttons(node:Node) -> Array:
 var result=[]
 for child in node.get_children():
  if child is Button:result.append(child)
  result.append_array(buttons(child))
 return result
func run():
 root.size=Vector2i(480,900)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
 game.start_character(Data.fresh("Mage"));game.set_physics_process(false);game.hero.points=30
 var hud=game.hud
 for dims in [Vector2i(480,900),Vector2i(900,480)]:
  root.size=dims;game.adapt_screen();await settle();hud.show_character("stats");hud.panel.size.y=450;await settle()
  for repeat in range(3):
   hud.scroll.scroll_vertical=200;await settle();var before=hud.scroll.scroll_vertical
   var points=game.hero.points
   var choices=buttons(hud.content).filter(func(b):return b.text=="Add point")
   choices[2].pressed.emit();await settle()
   check(game.hero.points==points-1,"Stat point is applied once")
   check(abs(hud.scroll.scroll_vertical-before)<=1 and before>0,"Repeated stat upgrade retains scroll position "+str(dims))
  hud.scroll.scroll_vertical=150;await settle();var refresh_position=hud.scroll.scroll_vertical
  hud.show_character("stats");await settle();check(hud.scroll.scroll_vertical==refresh_position,"Direct same-page refresh also retains position without a button callback")
  hud.show_character("gear");await settle();check(hud.scroll.scroll_vertical==0,"Opening a different page starts at the top")
  hud.show_pause();await settle();hud.scroll.scroll_vertical=180;await settle();var old=hud.scroll.scroll_vertical
  var toggle=buttons(hud.content).filter(func(b):return b.text.begins_with("Auto pickup:"))[0]
  toggle.pressed.emit();await settle();check(abs(hud.scroll.scroll_vertical-old)<=1,"Pause-menu setting refresh retains position")
  game.hud.controls.connected=true;hud.show_character("stats");hud.panel.size.y=450;await settle();hud.scroll.scroll_vertical=180;await settle();old=hud.scroll.scroll_vertical
  var point_button=buttons(hud.content).filter(func(b):return b.text=="Add point")[2]
  point_button.grab_focus();point_button.pressed.emit();await settle()
  check(abs(hud.scroll.scroll_vertical-old)<=1,"Controller menu focus cannot jump to the first button on refresh")
  check(root.gui_get_focus_owner()!=null and root.gui_get_focus_owner().text=="Add point","Controller focus stays on the refreshed upgrade action")
  hud.controls.connected=false
 print("%d MENU POSITION CHECKS PASSED" % checks);quit()
