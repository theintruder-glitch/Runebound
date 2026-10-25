extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var checks=0
var failures=0
func _initialize(): call_deferred("run")
func check(ok:bool,message:String):
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error("FAIL: "+message)
func settle(): await process_frame;await process_frame
func touch(at:Vector2,index:int,down:bool=true):
	var event=InputEventScreenTouch.new();event.position=at;event.index=index;event.pressed=down
	root.push_input(event,true)
func drag(at:Vector2,index:int):
	var event=InputEventScreenDrag.new();event.position=at;event.index=index;event.relative=Vector2(10,0)
	root.push_input(event,true)
func screen(at:Vector2) -> Vector2: return game.get_canvas_transform()*at
func fresh_cast():
	game.spellbook.reset();game.spell_cooldowns.clear();game.hero.mp=Data.max_mp(game.hero);game.attack_cooldown=0;game.dash_cooldown=0;game.dash_time=0
	game.hero.survival.structures=[];game.enemies.clear();game.shots.clear();game.facing=Vector2.RIGHT;game.move_vector=Vector2.ZERO
	game.hud.resume();game.set_physics_process(false)
func enemy(at:Vector2,boss:bool=false) -> Dictionary:
	var e=game.create_enemy(at,1,"goblin",boss);e.hp=10000;e.max_hp=10000;e.speed=0;e.cooldown=999
	game.enemies.append(e);return e
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size=Vector2i(1080,2400)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
	var hero=Data.fresh("Mage");hero.level=12;hero.spells.known.meteor=1;hero.spells.known.blizzard=1;hero.spells.slots=["meteor","blizzard","heal"]
	game.start_character(hero);game.set_physics_process(false);game.hero.auto=false;game.enemies.clear();game.spawn_timer=999999
	game.set_player_position(Vector2.ZERO);game.camera.position=Vector2.ZERO;game.camera.force_update_scroll()
	check(not game.desktop.enabled,"Mobile combat suite uses the phone controls")
	var book=game.spellbook
	for dims in [Vector2i(1080,2400),Vector2i(2400,1080)]:
		root.size=dims;game.adapt_screen();await settle();game.hud.layout();fresh_cast()
		var mana=game.hero.mp
		var spell_button=game.hud.spell_buttons.fire
		touch(spell_button.get_global_rect().get_center(),1);await settle()
		check(book.targeting=="meteor" and book.zones.is_empty() and game.hero.mp==mana,"Touching Meteor previews without spending mana "+str(dims))
		check(book.aim_finger==-1,"The spell-button finger does not become a ground-aim finger")
		touch(spell_button.get_global_rect().get_center(),1,false)
		var controls=game.hud.spell_ui.aim_controls
		check(controls.is_visible_in_tree() and Rect2(Vector2.ZERO,game.get_viewport_rect().size).encloses(controls.get_global_rect()),"CAST / CANCEL fit the phone viewport "+str(dims))
		var overlaps=false
		for control in [game.hud.stick,game.hud.skill_button,game.hud.attack_button,game.hud.dash_button,game.hud.auto_button]: overlaps=overlaps or control.get_global_rect().intersects(controls.get_global_rect())
		check(not overlaps,"Aiming buttons leave movement and combat controls clear "+str(dims))
		var at=screen(Vector2(100,-90))
		touch(at,4);await settle()
		check(book.aim_finger==4 and book.target_point().distance_to(Vector2(100,-90))<1,"A world touch positions the actual spell circle")
		drag(screen(Vector2(-80,-80)),4);await settle()
		check(book.target_point().distance_to(Vector2(-80,-80))<1,"Dragging moves the circle in world coordinates")
		drag(screen(Vector2(80,-80)),5)
		check(book.target_point().distance_to(Vector2(-80,-80))<1,"A different finger cannot move the aim circle")
		touch(screen(Vector2(-80,-80)),4,false)
		check(book.aim_finger==-1 and book.target_point().distance_to(Vector2(-80,-80))<1,"Release retains the selected spot without casting")
		var stick_at=game.hud.stick.get_global_rect().get_center()+Vector2(38,0)
		touch(stick_at,0);await settle()
		check(game.move_vector.x>.5 and book.aim_finger==-1,"Joystick movement stays independent while choosing a spell")
		check(book.target_point().distance_to(Vector2(-80,-80))<1,"Joystick touches do not move the target circle")
		var target=book.target_point();var foe=enemy(target);var hp=foe.hp
		var cast_at=game.hud.spell_ui.cast_button.get_global_rect().get_center()
		touch(cast_at,2);await settle()
		check(book.targeting.is_empty() and book.zones.size()==1 and game.hero.mp==mana-32,"A second finger on CAST spends exactly one spell cost")
		check(book.zones[0].pos.distance_to(target)<1 and foe.hp==hp,"Confirmed Meteor waits at the chosen point before impact")
		check(game.move_vector.x>.5,"Confirming the spell does not release the movement finger")
		touch(cast_at,2,false);touch(stick_at,0,false)
		check(not book.confirm() and game.hero.mp==mana-32,"A stale confirmation cannot cast or spend twice")
		book.tick(.91);check(foe.hp<hp and foe.burn>0,"The selected Meteor actually lands and burns its target")
		fresh_cast();mana=game.hero.mp;book.request_slot(1);await settle()
		var cancel_at=game.hud.spell_ui.cancel_button.get_global_rect().get_center()
		touch(cancel_at,3);touch(cancel_at,3,false);await settle()
		check(book.targeting.is_empty() and game.hero.mp==mana and book.zones.is_empty(),"CANCEL leaves mana, cooldowns and damage untouched")
		fresh_cast();book.request_slot(1);await settle()
		touch(screen(Vector2(80,-60)),4);touch(game.hud.spell_ui.cast_button.get_global_rect().get_center(),4,false)
		check(book.aim_finger==-1 and book.targeting=="blizzard" and book.zones.is_empty(),"Releasing an aim finger over CAST does not accidentally cast")
		game.hero.survival.structures=[{"kind":"Wall","x":40.0,"y":-30.0,"rotation":1,"fuel":0.0,"open":false,"stash":{}}]
		await settle();mana=game.hero.mp
		check(not book.valid_ground(book.target_point()) and game.hud.spell_ui.cast_button.disabled,"A wall-blocked target visibly disables CAST")
		check(not book.confirm() and book.targeting=="blizzard" and game.hero.mp==mana,"Invalid ground retains preview and never spends mana")
		game.hero.survival.structures=[]
		book.handle_touch(make_touch(screen(Vector2(900,0)),7));check(book.target_point().distance_to(game.player_position())<=380.01,"Far target positions clamp to the spell's real range")
		book.cancel_target();book.request_slot(0);game.hud.back()
		check(book.targeting.is_empty() and game.playing,"Phone Back cancels aiming before pausing")
		book.request_slot(0);game.dash();check(book.targeting.is_empty() and game.dash_time>0,"Dodging cancels an uncommitted spell for free")
		fresh_cast();book.request_slot(0);touch(screen(Vector2(80,-80)),6);game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
		check(not game.playing and book.targeting.is_empty() and book.aim_finger==-1,"Focus loss clears preview and captured aim finger")
		fresh_cast();book.request_slot(0);game.adapt_screen();check(book.targeting.is_empty(),"Layout changes clear an unfinished spell preview")
	fresh_cast();game.hero.mode="survival";book.request_slot(0);game.move_vector=Vector2.RIGHT
	var before=game.player_position();var clock=game.hero.worldTime;var food=game.hero.needs.hunger
	game.tick(.1)
	check(game.player_position().x>before.x and game.hero.worldTime>clock and game.hero.needs.hunger<food,"Movement and survival time remain live while aiming")
	game.hero.mp=0;var mana=game.hero.mp;await settle()
	check(game.hud.spell_ui.cast_button.disabled and not book.confirm() and game.hero.mp==mana,"Losing mana during preview prevents spending or casting")
	check(book.targeting=="meteor","An unavailable confirmation keeps the selected spell visible")
	game.hero.mp=Data.max_mp(game.hero);book.request_slot(2)
	check(book.targeting.is_empty() and game.cast_time>0,"An instant heal cancels ground targeting and remains usable")
	fresh_cast();book.request_slot(0);await settle()
	touch(screen(Vector2(80,-80)),9)
	var canceled=InputEventScreenTouch.new();canceled.index=9;canceled.pressed=false;canceled.canceled=true;canceled.position=screen(Vector2(80,-80));root.push_input(canceled,true)
	check(book.aim_finger==-1 and book.zones.is_empty(),"A canceled Android touch releases aim without casting")
	game.hud.show_character("gear");check(book.targeting.is_empty() and not game.playing,"Opening equipment clears targeting before menu gestures")
	fresh_cast();game.hero=Data.fresh("Warrior");game.hero.auto=false;game.facing=Vector2.RIGHT;game.set_player_position(Vector2.ZERO)
	var front=enemy(Vector2(45,0));var behind=enemy(Vector2(-45,0));front.windup=.5
	check(game.attack() and front.hp<10000 and behind.hp==10000,"Phone melee hits the forward arc and leaves enemies behind untouched")
	check(front.stagger>0 and front.windup==0 and front.stagger_guard>.5,"A clean melee hit briefly staggers a normal foe and interrupts its windup")
	var saved_direction=game.swing_direction;game.facing=Vector2.UP;check(game.swing_direction==saved_direction,"Swing animation keeps its strike direction while movement turns")
	front.windup=.5;game.hurt(front,1,"melee");check(front.windup==.5,"Repeated immediate hits cannot permanently interrupt an enemy")
	game.tick(.2);check(front.stagger==0 and front.stagger_guard>0,"Hit recovery ends before the stagger guard expires")
	game.enemies.clear();var boss=enemy(Vector2(45,0),true);boss.windup=.5;game.hurt(boss,1,"melee")
	check(boss.get("stagger",0)==0 and boss.windup==.5,"Boss telegraphs resist basic-hit stagger")
	game.enemies.clear();var named=enemy(Vector2(45,0));named.named="Trial Warden";named.windup=.5;game.hurt(named,1,"melee")
	check(named.get("stagger",0)==0 and named.windup==.5,"Named trial enemies keep their challenge telegraphs")
	game.enemies.clear();var burn=enemy(Vector2(45,0));burn.windup=.5;game.hurt(burn,1,"melee",0,true)
	check(burn.get("stagger",0)==0 and burn.windup==.5,"Damage-over-time ticks cannot create melee stun locks")
	game.enemies.clear();game.attack_cooldown=0
	check(game.attack() and game.swing_time>0,"A missed phone attack still animates and uses its normal cooldown")
	check(not game.attack(),"Holding attack respects weapon cooldowns")
	game.attack_cooldown=0;game.playing=false;check(not game.attack(),"Paused controls cannot create attacks")
	game.playing=true;game.hero.auto=true;game.enemies=[game.create_enemy(Vector2(30,0),1,"deer")]
	check(not game.attack(true),"Automatic combat still leaves peaceful wildlife alone")
	game.hero=Data.fresh("Ranger");game.hero.auto=false;game.enemies.clear();game.facing=Vector2.LEFT;game.attack_cooldown=0
	check(game.attack() and game.shots.back().velocity.x<0,"A ranged miss fires in the character's facing direction")
	game.hero=Data.fresh("Mage");game.hero.auto=false;game.spell_cooldowns={"fire":0.0,"frost":0.0,"heal":0.0};game.hero.hp=20
	check(game.spellbook.request_slot(2) and game.cast_time>0,"Successful healing gets a visible casting reaction")
	game.tick(.4);check(game.cast_time==0,"Casting effects expire within their short animation window")
	check(not Data.migrate(JSON.parse_string(JSON.stringify(game.hero))).is_empty(),"Combat changes retain the shared character format")
	print("%d TOUCH COMBAT CHECKS; %d FAILURES" % [checks,failures]);quit(1 if failures else 0)
func make_touch(at:Vector2,index:int) -> InputEventScreenTouch:
	var event=InputEventScreenTouch.new();event.position=at;event.index=index;event.pressed=true;return event
