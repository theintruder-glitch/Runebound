extends SceneTree
var checks=0
func check(value:bool, msg:String):
	if not value: push_error("FAIL: "+msg);quit(1);assert(value)
	checks+=1;print("PASS: "+msg)
func touch_at(at:Vector2,id:int,pressed:bool,canceled:bool=false):
	var e=InputEventScreenTouch.new();e.position=at;e.index=id;e.pressed=pressed;e.canceled=canceled;root.push_input(e,true)
func drag_at(at:Vector2,relative:Vector2,id:int):
	var e=InputEventScreenDrag.new();e.position=at;e.relative=relative;e.index=id;root.push_input(e,true)
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(960,540)
	var game=load("res://main.tscn").instantiate();root.add_child(game)
	for i in range(90):await physics_frame
	check(game.player.is_on_floor(),"Player lands on the 3D terrain")
	check(absf(game.terrain_height(0,0)-game.terrain_height(20,10))>.1,"Terrain has varied elevation")
	var start=game.player.global_position
	touch_at(Vector2(100,430),1,true);drag_at(Vector2(100,370),Vector2(0,-60),1)
	check(game.touch.move_id==1 and game.touch.direction.y<-.9,"Movement finger is captured")
	touch_at(Vector2(700,300),2,true);drag_at(Vector2(740,300),Vector2(40,0),2)
	check(game.touch.look_id==2 and game.touch.move_id==1,"Camera and movement fingers are independent")
	var old_yaw=game.yaw
	for i in range(30):await physics_frame
	check(game.player.global_position.distance_to(start)>.5,"Character walks on terrain")
	check(absf(game.yaw-old_yaw)>.1,"Camera rotates from a look drag")
	touch_at(Vector2(700,300),2,false);check(game.touch.move_id==1 and game.touch.direction.length()>.5,"Releasing camera leaves movement held")
	touch_at(Vector2(100,370),1,false,true);check(game.touch.move_id==-1 and game.touch.direction==Vector2.ZERO,"Cancelled movement stops cleanly")
	game.touch.reset();check(game.touch.look_id==-1 and game.touch.direction==Vector2.ZERO,"Reset clears all touch ownership")
	print("%d 3D PREVIEW CHECKS PASSED" % checks);game.queue_free();quit(0)
