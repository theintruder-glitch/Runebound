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
	check(fire.disabled and fire.cooldown_fraction==1,"Touch spell immediately displays its recovery state")
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
	game.hud.resume()
	game.move_vector=Vector2.RIGHT
	game.dash_cooldown=0
	game.visuals.clear()
	touch(11,game.hud.dash_button.get_global_rect().get_center())
	touch(11,Vector2.ZERO,false)
	check(game.dash_time>0 and game.dash_cooldown==3.8,"Touch dodge retains its existing timing")
	check(game.visuals.size()==1 and game.visuals[0].kind=="dodge" and game.visuals[0].direction==Vector2.RIGHT,"Dodge immediately shows its movement direction")
	check(game.hud.dash_button.text.begins_with("DASH") and game.hud.dash_button.disabled,"Recovering dodge keeps its name and disables repeat taps")
	check(game.hud.dash_button.cooldown_fraction==1,"Dodge recovery bar starts empty")
	var effects=game.visuals.size()
	touch(12,game.hud.dash_button.get_global_rect().get_center())
	touch(12,Vector2.ZERO,false)
	check(game.visuals.size()==effects and game.dash_cooldown==3.8,"Cooldown tap cannot restart dodge or add a false cue")
	game.dash_cooldown=1.9
	game.hud.update_hud()
	check(is_equal_approx(game.hud.dash_button.cooldown_fraction,.5),"Dodge bar tracks remaining recovery")
	for key in ["fire","frost","heal"]:
		game.spell_cooldowns[key]=game.SPELL_RECOVERY[key]*.5
	game.abilities.cooldown=7
	game.hud.update_hud()
	for key in ["fire","frost","heal"]:
		var button=game.hud.spell_buttons[key]
		check(button.text.begins_with(key.to_upper()) and button.disabled and is_equal_approx(button.cooldown_fraction,.5),"Spell name and recovery remain readable: "+key)
	check(game.hud.skill_button.text.begins_with("METEOR") and is_equal_approx(game.hud.skill_button.cooldown_fraction,.5),"Class skill keeps its identity while recovering")
	game.spell_cooldowns.fire=.05
	game.hud.update_hud()
	check(game.hud.spell_buttons.fire.disabled,"Final cooldown fraction cannot advertise an unusable spell")
	game.spell_cooldowns.fire=0
	game.hero.mp=0
	game.hud.update_hud()
	check(game.hud.spell_buttons.fire.disabled and game.hud.spell_buttons.fire.text=="FIRE\n12 MP" and game.hud.spell_buttons.fire.cooldown_fraction==0,"Low mana shows cost without a false cooldown bar")
	game.hero.mp=Data.max_mp(game.hero)
	game.hud.update_hud()
	check(not game.hud.spell_buttons.fire.disabled,"Recovered spell becomes available with sufficient mana")
	game.world.profile_enabled=true
	game.world.queue_redraw()
	await process_frame
	await process_frame
	check(game.world.profile_draw_samples.size()>0,"Dodge cue runs through the actual world draw callback")
	game.set_low_power(true)
	for i in range(40):
		game.dash_cooldown=0
		game.dash()
	check(game.visuals.size()==24,"Repeated dodge cues respect the low-power effect budget")
	game.clear_scene()
	check(game.visuals.is_empty(),"Scene changes remove dodge cues")
	print(str(checks)+" MOBILE CONTROL CHECKS PASSED")
	quit()
