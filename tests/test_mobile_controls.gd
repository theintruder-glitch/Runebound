extends SceneTree
const Data = preload("res://scripts/data.gd")
var checks = 0
var game

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error("FAIL: "+message)
		quit(1)
		assert(ok,message)
	checks+=1
	print("PASS: "+message)

func touch(index: int, at: Vector2, down: bool=true, canceled: bool=false) -> void:
	var event = InputEventScreenTouch.new()
	event.index=index;event.position=at;event.pressed=down;event.canceled=canceled
	root.push_input(event,true)

func drag(index: int, at: Vector2) -> void:
	var event = InputEventScreenDrag.new()
	event.index=index;event.position=at
	root.push_input(event,true)

func run() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.size=Vector2i(1688,900) if "landscape" in OS.get_cmdline_user_args() else Vector2i(480,900)
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_character(Data.fresh("Mage"))
	game.set_physics_process(false)
	game.hero.auto=false
	game.enemies=[game.create_enemy(game.player_position()+Vector2(60,0),1,"goblin")]
	game.enemies[0].hp=10000;game.enemies[0].max_hp=10000
	game.hero.mp=Data.max_mp(game.hero)
	var stick=game.hud.stick
	var center=stick.get_global_rect().get_center()
	touch(1,center+Vector2(2,0))
	check(game.move_vector==Vector2.ZERO,"Thumb jitter at center does not cause drift")
	drag(1,center+Vector2(stick.size.x,0))
	check(game.move_vector.is_equal_approx(Vector2.RIGHT),"A held thumb immediately reaches full movement")
	touch(9,center)
	drag(9,center+Vector2(-stick.size.x,0))
	check(game.move_vector==Vector2.RIGHT,"A second finger cannot steal joystick ownership")
	var attack=game.hud.attack_button
	var attack_at=attack.get_global_rect().get_center()
	touch(2,attack_at)
	check(game.attack_held and attack.self_modulate!=Color.WHITE,"Attack has immediate held-state visual feedback")
	check(game.move_vector==Vector2.RIGHT,"Attacking leaves the moving thumb active")
	var fire=game.hud.spell_buttons.fire
	var fire_at=fire.get_global_rect().get_center()
	var mana=game.hero.mp
	touch(3,fire_at)
	check(game.hero.mp==mana-12 and game.spell_cooldowns.fire>0,"A third finger casts Firebolt exactly once")
	check(game.attack_held and game.move_vector==Vector2.RIGHT,"Spell casting preserves held attack and movement")
	# Android emits a mouse event for the same touch; it must not cast twice.
	game.spell_cooldowns.fire=0
	var mouse=InputEventMouseButton.new()
	mouse.device=-1;mouse.position=fire_at;mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=true
	root.push_input(mouse,true)
	check(game.hero.mp==mana-12,"An emulated mouse press cannot duplicate a spell")
	touch(3,Vector2.ZERO,false)
	touch(2,Vector2.ZERO,false,true)
	check(not game.attack_held and attack.self_modulate==Color.WHITE,"Canceled attack releases gameplay and visual state outside the button")
	check(game.move_vector==Vector2.RIGHT,"Canceling attack does not release the movement thumb")
	touch(1,Vector2.ZERO,false,true)
	check(game.move_vector==Vector2.ZERO and stick.finger==-1,"Canceled joystick touch stops immediately")
	touch(4,attack_at)
	attack.hide()
	check(not game.attack_held and attack.finger==-1 and attack.self_modulate==Color.WHITE,"Hiding an action releases its held input")
	attack.show()
	touch(5,center+Vector2(stick.size.x,0))
	stick.hide()
	check(game.move_vector==Vector2.ZERO and stick.finger==-1,"Hiding the joystick clears movement")
	stick.show()
	touch(6,center+Vector2(stick.size.x,0))
	touch(7,attack_at)
	game.hud.show_pause()
	check(not game.playing and not game.attack_held and game.move_vector==Vector2.ZERO,"Pause safely releases simultaneous combat inputs")
	check(attack.finger==-1 and stick.finger==-1 and attack.self_modulate==Color.WHITE,"Pause clears touch ownership and pressed visuals")
	game.hud.resume()
	touch(8,attack_at)
	game.adapt_screen()
	check(not game.attack_held and attack.finger==-1 and attack.self_modulate==Color.WHITE,"Rotation resets action ownership and pressed visuals")
	touch(8,Vector2.ZERO,false)
	touch(10,attack_at)
	game.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not game.playing and not game.attack_held and attack.finger==-1,"App focus loss cannot leave attack held on resume")
	check(Data.read_save().className=="Mage","Lifecycle input resets preserve the existing character save")
	print(str(checks)+" MOBILE CONTROL CHECKS PASSED")
	quit()
