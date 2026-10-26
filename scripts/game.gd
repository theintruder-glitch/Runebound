extends Node2D

const Data = preload("res://scripts/data.gd")
const InputRouter=preload("res://scripts/input_router.gd")
var input_router
const TacticsScript=preload("res://scripts/enemy_tactics.gd")
var tactics
const ChapterScript=preload("res://scripts/chapter.gd")
var chapter
const ForgeScript=preload("res://scripts/forge_chapter.gd")
var forge
const LandscapeScript=preload("res://scripts/kingdom_landscape.gd")
const CastleScript=preload("res://scripts/castle.gd")
var landscape
var castle
const WorldScript = preload("res://scripts/world.gd")
const HUDScript = preload("res://scripts/hud.gd")
const TILE = 48.0
const DesktopScript=preload("res://scripts/desktop.gd")
var desktop
const ExpeditionScript=preload("res://scripts/expedition.gd")
var expedition
const KitScript=preload("res://scripts/survival_kit.gd")
var kit
const FishingScript=preload("res://scripts/fishing.gd")
var fishing
const SpellbookScript=preload("res://scripts/spellbook.gd")
const GraphicsScript=preload("res://scripts/graphics.gd")
var spellbook
var graphics
const SurvivalScript = preload("res://scripts/survival.gd")
var survival
const FarmingScript=preload("res://scripts/farming.gd")
var farming
const WeatherScript=preload("res://scripts/weather.gd")
var weather
const ContractsScript=preload("res://scripts/contracts.gd")
var contracts
const TraderScript=preload("res://scripts/trader.gd")
var trader
const ForestScript=preload("res://scripts/forest.gd")
const AudioScript=preload("res://scripts/game_audio.gd")
var forest
const ExplorationScript=preload("res://scripts/exploration.gd")
const AbilitiesScript=preload("res://scripts/abilities.gd")
var exploration
var abilities
var audio
var build_recipe=""
var build_rotation=0
var swing_time=0.0
var swing_duration=.24
var swing_direction=Vector2.DOWN
var cast_time=0.0
var cast_color=Color.WHITE
var hero: Dictionary = {}
var enemies: Array = []
var shots: Array = []
var effects: Array = []
var visuals:Array=[]
var dash_trail=0.0
var chests: Array = []
var dungeon_map: Dictionary = {}
var astar: AStarGrid2D
var playing = false
var move_vector = Vector2.ZERO
var facing = Vector2.DOWN
var attack_held = false
var attack_cooldown = 0.0
var dash_cooldown = 0.0
var dash_time = 0.0
var spell_cooldowns = {"fire":0.0,"frost":0.0,"heal":0.0}
var spawn_timer = 1.0
var save_timer = 0.0
var hud_timer = 0.0
var chunk_key = Vector2i(999999,999999)
var chest_near: Dictionary = {}
var world
var hud
var camera: Camera2D
var saved: Dictionary = {}
var low_power = true
var reduced_crowds = true
var is_walking = false
var screen_landscape = false

func _ready() -> void:
	get_window().title="VYRNSPIRE"
	input_router=InputRouter.new();input_router.game=self;add_child(input_router)
	tactics=TacticsScript.new();tactics.game=self
	chapter=ChapterScript.new();chapter.game=self
	forge=ForgeScript.new();forge.game=self
	landscape=LandscapeScript.new();landscape.game=self
	castle=CastleScript.new();castle.game=self
	desktop=DesktopScript.new()
	desktop.game=self
	desktop.initialize()
	kit=KitScript.new();kit.game=self
	fishing=FishingScript.new();fishing.game=self
	expedition=ExpeditionScript.new();expedition.game=self
	spellbook=SpellbookScript.new();spellbook.game=self
	exploration=ExplorationScript.new()
	exploration.game=self
	abilities=AbilitiesScript.new()
	abilities.game=self
	forest=ForestScript.new()
	forest.game=self
	audio=AudioScript.new()
	add_child(audio)
	survival = SurvivalScript.new()
	survival.game = self
	survival.load_pickup_settings()
	farming=FarmingScript.new()
	farming.game=self
	trader=TraderScript.new()
	trader.game=self
	contracts=ContractsScript.new()
	contracts.game=self
	weather=WeatherScript.new()
	weather.game=self
	weather.load_settings()
	load_performance_settings()
	world = $World
	world.game = self
	graphics=GraphicsScript.new();graphics.game=self;add_child(graphics)
	camera = $Camera2D
	get_window().size_changed.connect(adapt_screen)
	adapt_screen()
	hud = HUDScript.new()
	hud.game = self
	$Interface.add_child(hud)
	saved = Data.read_save()
	hud.show_title(not saved.is_empty())
	get_tree().auto_accept_quit = false

func start_character(character: Dictionary) -> void:
	hero = Data.migrate(character)
	if hero.is_empty():
		return
	clear_scene()
	trader.refresh()
	contracts.survey_timer=0
	weather.last_season=""
	weather.tick()
	forest.boss={}
	build_recipe=""
	# Repair invalid collision/precision positions before generating nearby chunks.
	var recovered_position=false
	if hero.dungeon==null:
		var restored=safe_wilds_position(player_position())
		recovered_position=restored!=player_position()
		set_player_position(restored)
	survival.refresh(true)
	playing = true
	hero.hp = clampf(hero.hp,1,Data.max_hp(hero))
	hero.mp = clampf(hero.mp,0,Data.max_mp(hero))
	if hero.dungeon!=null:
		build_floor(false)
	else:
		dungeon_map = {}
		set_player_position(safe_wilds_position(player_position()))
		populate_chests(true)
		for i in range(3):
			spawn_enemy()
	camera.position = player_position()
	camera.reset_smoothing()
	world.refresh(true)
	hud.resume()
	notify("Recovered a blocked or unplayable saved position. Your character progress is intact." if recovered_position else "Walk near marked resources to collect them. Auto pickup can be changed in Pause.",6)
	save_game()

func player_position() -> Vector2:
	return Vector2(hero.get("x",0),hero.get("y",0))

func set_player_position(at: Vector2) -> void:
	hero.x = at.x
	hero.y = at.y

func clear_scene() -> void:
	if input_router!=null: input_router.reset_virtual()
	if forge!=null: forge.reset()
	if fishing!=null: fishing.reset()
	if desktop!=null: desktop.clear_input();desktop.pointer_seen=false
	build_recipe=""
	build_rotation=0
	if abilities!=null: abilities.reset()
	if spellbook!=null: spellbook.reset()
	if survival!=null:
		survival.moving={}
		survival.pickup_timer=0.0
	enemies.clear()
	shots.clear()
	effects.clear()
	visuals.clear()
	dash_trail=0
	chests.clear()
	chest_near = {}
	chunk_key = Vector2i(999999,999999)
	attack_cooldown = 0
	swing_time=0;cast_time=0
	dash_time = 0
	dash_cooldown = 0
	spell_cooldowns = {"fire":0.0,"frost":0.0,"heal":0.0}
	spawn_timer = 1
	move_vector = Vector2.ZERO
	is_walking = false
	attack_held = false

func pause_game() -> void:
	if fishing!=null: fishing.cancel("Line packed away while paused. Bait was used.")
	if desktop!=null: desktop.clear_input()
	playing = false
	if input_router!=null: input_router.reset_virtual()
	if spellbook!=null: spellbook.cancel_target()
	move_vector = Vector2.ZERO
	is_walking = false
	attack_held = false
	if hud!=null:
		hud.reset_stick()
	save_game()

func save_game() -> bool:
	if hero.is_empty():
		return true
	var success = Data.write_save(hero)
	if not success:
		notify("Could not save. Check available device storage.",6)
	return success

func notify(text_value: String,duration: float=3) -> void:
	if hud!=null:
		hud.toast(text_value,duration)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]:
		if playing and hud!=null:
			hud.show_pause()
	elif what==NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit()
	elif what==NOTIFICATION_WM_GO_BACK_REQUEST and hud!=null:
		hud.back()

func _unhandled_key_input(event: InputEvent) -> void:
	if input_router.handle_event(event): get_viewport().set_input_as_handled()

func _input(event:InputEvent) -> void:
	if spellbook!=null: spellbook.release_touch(event)
	if desktop!=null and desktop.enabled: desktop.release_input(event)

func _unhandled_input(event:InputEvent) -> void:
	if not event is InputEventKey and input_router.handle_event(event):
		get_viewport().set_input_as_handled();return
	if spellbook!=null and spellbook.handle_touch(event):
		get_viewport().set_input_as_handled();return
	if desktop!=null: desktop.handle_input(event)

func _physics_process(dt: float) -> void:
	if not playing or hero.is_empty():
		return
	tick(dt)

func tick(dt: float) -> void:
	swing_time=maxf(0,swing_time-dt)
	cast_time=maxf(0,cast_time-dt)
	forest.reset_if_abandoned()
	exploration.tick(dt)
	forge.tick(dt)
	abilities.tick(dt)
	contracts.tick(dt)
	hero.worldTime += dt
	weather.tick()
	survival.tick(dt)
	farming.tick(dt)
	spellbook.tick(dt)
	var movement = input_router.movement()
	is_walking = movement.length()>.1 or dash_time>0
	var speed = 147 if hero.className=="Rogue" else 142 if hero.className=="Ranger" else 130
	speed*=expedition.speed_factor()
	if abilities.stealth>0: speed*=1.25
	var at = player_position()
	if dash_time>0:
		at = move_position(at,facing*490*dt,10)
		dash_time -= dt
		dash_trail-=dt
		if dash_trail<=0:
			visual_fx("dash",at,18,Color("a4dfcf"),.24)
			dash_trail=.045
	else:
		at = move_position(at,movement*speed*dt,10)
		if movement.length()>.1:
			facing = movement.normalized()
	set_player_position(at)
	fishing.tick(dt)
	survival.pickup_tick(dt)
	update_edge_camera(at)
	desktop.update_aim()
	input_router.update_aim()
	if hero.dungeon==null:
		hero.bestDistance = maxf(hero.bestDistance,at.length())
	attack_cooldown = maxf(0,attack_cooldown-dt)
	dash_cooldown = maxf(0,dash_cooldown-dt)
	for key in spell_cooldowns:
		spell_cooldowns[key] = maxf(0,spell_cooldowns[key]-dt)
	hero.mp = minf(Data.max_mp(hero),hero.mp+dt*(4+hero.int*.07+(1.5 if Data.has_building(hero,"Tavern") else 0)))
	var manual=attack_held or input_router.is_virtual_held("attack") or desktop.mouse_attack or Input.is_action_pressed("attack")
	if (hero.auto or manual) and spellbook.targeting.is_empty():
		attack(not manual)
	spawn_timer -= dt
	if spawn_timer<=0 and hero.dungeon==null:
		spawn_enemy()
		spawn_timer = roaming_spawn_interval()
	tactics.prepare()
	var in_combat = false
	for enemy in enemies.duplicate():
		if enemy.dead:
			continue
		if enemy.pos.distance_squared_to(at)>640000 and enemy.aggro<=0 and enemy.burn<=0:
			continue
		enemy.cooldown -= dt
		enemy.flash = maxf(0,enemy.flash-dt)
		enemy["stagger"]=maxf(0,enemy.get("stagger",0.0)-dt)
		enemy["stagger_guard"]=maxf(0,enemy.get("stagger_guard",0.0)-dt)
		enemy["attack_pose"]=maxf(0,enemy.get("attack_pose",0.0)-dt)
		enemy.slow = maxf(0,enemy.slow-dt)
		enemy.aggro = maxf(0,enemy.aggro-dt)
		if enemy.burn>0:
			enemy.burn -= dt
			enemy.burn_tick -= dt
			if enemy.burn_tick<=0:
				enemy.burn_tick = .7
				hurt(enemy,enemy.burn_damage,enemy.burn_kind,0,true)
		if enemy.dead:
			continue
		var distance = enemy.pos.distance_to(at)
		var direction = Vector2.ZERO
		if hero.dungeon==null:
			direction = tactics.wilds_direction(enemy,dt)
			in_combat = in_combat or enemy.aggro>0
		elif distance<330 or enemy.aggro>0:
			in_combat = true
			direction = dungeon_direction(enemy,dt)
		if hero.dungeon!=null: direction=tactics.direction(enemy,direction)
		if enemy.stagger>0: direction=Vector2.ZERO
		enemy["motion"]=direction
		if (distance>enemy.radius+12 or enemy.get("neutral",false) or tactics.ranged(enemy)) and enemy.get("windup",0.0)<=0:
			enemy.pos = move_position(enemy.pos,direction*enemy.speed*(.4 if enemy.slow>0 else 1)*dt,enemy.radius)
		update_enemy_attack(enemy,dt)
	if not in_combat and not expedition.deprived():
		hero.hp = minf(Data.max_hp(hero),hero.hp+dt*Data.max_hp(hero)*(.018 if Data.has_building(hero,"Tavern") else .009))
		var comfort=weather.recovery_rate()
		hero.hp=minf(Data.max_hp(hero),hero.hp+comfort.x*dt)
		hero.mp=minf(Data.max_mp(hero),hero.mp+comfort.y*dt)
	if hero.className=="Cleric" and not expedition.deprived():
		hero.hp = minf(Data.max_hp(hero),hero.hp+dt*1.2)
	for shot in shots:
		shot.life -= dt
		var previous = shot.pos
		shot.pos += shot.velocity*dt
		if not line_clear(previous,shot.pos):
			shot.life = 0
			continue
		for enemy in enemies:
			if not enemy.dead and Geometry2D.get_closest_point_to_segment(enemy.pos,previous,shot.pos).distance_to(enemy.pos)<enemy.radius+5:
				hurt(enemy,shot.damage,"magic" if shot.kind=="fire" else shot.kind,shot.enchant)
				if shot.kind=="fire": visual_fx("fire",shot.pos,30,Color("f5b179"),.35)
				shot.life = 0
				break
	shots = shots.filter(func(s): return s.life>0)
	enemies = enemies.filter(func(e): return not e.dead and (hero.dungeon!=null or protected_encounter_enemy(e) or e.aggro>0 or e.burn>0 or e.pos.distance_squared_to(at)<810000))
	for visual in visuals: visual.life-=dt
	visuals=visuals.filter(func(v):return v.life>0)
	for effect in effects:
		effect.life -= dt
		effect.pos += effect.velocity*dt
	effects = effects.filter(func(e): return e.life>0)
	var effect_limit = 80 if low_power else 160
	if effects.size()>effect_limit:
		effects = effects.slice(effects.size()-effect_limit)
	expedition.tick(dt)
	chapter.tick(dt)
	castle.tick(dt)
	if hero.hp<=0:
		defeated()
		return
	hud_timer += dt
	save_timer += dt
	if hud_timer>.25:
		hud_timer = 0
		populate_chests()
		world.refresh()
		chest_near = {}
		for chest in chests:
			if not hero.opened.has(chest.id) and chest.pos.distance_to(at)<65:
				chest_near = chest
		update_interaction()
		hud.update_hud()
	if save_timer>8:
		save_timer = 0
		save_game()

func update_edge_camera(at: Vector2) -> void:
	# Keep space for visible character movement, then scroll continuously by
	# only the amount walked past the boundary. Never jump by a screenful.
	var view = get_viewport_rect().size
	var relative = at-camera.position
	var side = maxf(60,view.x*.5-40)
	var top = -view.y*.5+minf(170,view.y*.22)
	var bottom = view.y*.5-minf(210,view.y*.25)
	var scroll = relative-Vector2(clampf(relative.x,-side,side),clampf(relative.y,top,bottom))
	if scroll!=Vector2.ZERO:
		camera.position += scroll
		camera.force_update_scroll()
		world.refresh()

func roaming_limit() -> int: return 6 if reduced_crowds else 12

func protected_encounter_enemy(enemy:Dictionary) -> bool:
	return enemy.has("named") or enemy.has("trial") or enemy.has("dungeon_id") or enemy.get("chapter_boss",false) or enemy.get("forge_boss",false)

func roaming_spawn_interval() -> float:
	var base=randf_range(5,8) if reduced_crowds else randf_range(3,5)
	return clampf(base/minf(1.3,1+hero.level*.01)*(.1/Data.spawn_chance(Data.phase(hero.worldTime))),3.0 if reduced_crowds else 2.0,10.0)

func nearby_hostiles() -> int:
	var count=0
	for enemy in enemies:
		if not enemy.dead and not enemy.get("neutral",false) and enemy.pos.distance_squared_to(player_position())<102400: count+=1
	return count

func spawn_enemy(boss_force: bool=false) -> Dictionary:
	if hero.dungeon!=null or forest.active() or exploration.active() or forge.active() or enemies.size()>=roaming_limit():
		return {}
	if not boss_force and nearby_hostiles()>=(3 if reduced_crowds else 5): return {}
	var boss = boss_force or randf()<.035
	var level_value = maxi(1,int(hero.level*.65+player_position().length()/1900+randf_range(0,2)))
	var at = player_position()+Vector2.from_angle(randf()*TAU)*randf_range(290,570)
	var kind = "guardian" if boss else exploration.spawn_kind(exploration.region_at(at))
	if not walkable(at,12): return {}
	var enemy = create_enemy(at,level_value,kind,boss)
	enemies.append(enemy)
	if kind in ["wolf","frost_wolf"]:
		var pack=randi_range(1,2147483640)
		enemy.pack=pack
		for i in range(2):
			if enemies.size()>=roaming_limit(): break
			var spot=at+Vector2.from_angle(i*TAU/3)*42
			if not walkable(spot,12): continue
			var ally=create_enemy(spot,level_value,kind)
			ally.pack=pack; ally["pack_slot"]=i+1; enemies.append(ally)
	return enemy

func create_enemy(at: Vector2,level_value: int,kind: String,boss: bool=false) -> Dictionary:
	var hp = (24+level_value*11)*(6 if boss else 1)
	return {"pos":at,"home":at,"returning":false,"level":level_value,"type":kind,"boss":boss,"hp":float(hp),"max_hp":float(hp),"radius":22.0 if boss else 11.0,"speed":(100 if kind=="deer" else 92 if kind in ["wolf","frost_wolf"] else 38 if kind in ["slime","bog_toad"] else 65 if kind in ["wisp","crystal_wisp"] else 50)+level_value*.7,"contact_damage":(5+level_value*2)*(1.8 if boss else 1),"reward_gold":(4+level_value*2)*(12 if boss else 1),"cooldown":0.0,"slow":0.0,"flash":0.0,"aggro":0.0,"wander":randf()*TAU,"wander_time":2.0,"burn":0.0,"burn_tick":0.0,"burn_damage":0.0,"burn_kind":"magic","dead":false,"path_timer":0.0,"neutral":kind=="deer","pack":0,"goal":at,"windup":0.0,"strike":at,"strike_radius":38.0}

func closest(range_value: float,from: Vector2,excluded: Dictionary={},hostile_only:bool=false) -> Dictionary:
	var best: Dictionary = {}
	var distance = range_value
	for enemy in enemies:
		if (hostile_only and enemy.get("neutral",false)) or enemy.dead or (not excluded.is_empty() and is_same(enemy,excluded)):
			continue
		var value = from.distance_to(enemy.pos)
		if value<distance and line_clear(from,enemy.pos):
			distance = value
			best = enemy
	return best

func attack(auto_only:bool=false) -> bool:
	if fishing.active():
		if auto_only: return false
		fishing.cancel()
	if not playing or hero.is_empty() or attack_cooldown>0 or survival.sheltered() or not spellbook.targeting.is_empty() or not build_recipe.is_empty():
		return false
	if desktop.enabled and desktop.mouse_aim and not auto_only: return desktop.manual_attack()
	var weapon = Data.equipped(hero,"weapon")
	var kind = "bow" if weapon.get("kind")=="bow" else "magic" if weapon.get("kind")=="staff" else "melee"
	var target = closest(72 if kind=="melee" else 430,player_position(),{},auto_only)
	if auto_only and (target.is_empty() or (hero.dungeon==null and target.aggro<=0)): return false
	var direction=facing
	if not target.is_empty() and (auto_only or kind!="melee" or facing.dot(player_position().direction_to(target.pos))>.25): direction=player_position().direction_to(target.pos)
	return directional_attack(direction,auto_only)

func start_swing(direction:Vector2,duration:float=.24) -> void:
	swing_direction=direction.normalized() if direction.length_squared()>.01 else Vector2.DOWN
	swing_duration=duration;swing_time=duration

func cast_feedback(color:Color) -> void:
	cast_time=.35;cast_color=color

func directional_attack(direction:Vector2,auto_only:bool=false) -> bool:
	if not playing or hero.is_empty() or attack_cooldown>0 or survival.sheltered() or not spellbook.targeting.is_empty() or not build_recipe.is_empty(): return false
	direction=direction.normalized() if direction.length_squared()>.01 else Vector2.DOWN
	var weapon=Data.equipped(hero,"weapon")
	var kind="bow" if weapon.get("kind")=="bow" else "magic" if weapon.get("kind")=="staff" else "melee"
	abilities.stealth=0;start_swing(direction);sound("attack")
	attack_cooldown=.65 if kind=="bow" else .72 if kind=="magic" else .52
	if dash_time<=0: facing=direction
	if kind=="melee":
		for enemy in enemies.duplicate():
			var delta=enemy.pos-player_position()
			if not enemy.dead and (not auto_only or not enemy.get("neutral",false)) and delta.length()<72 and (delta.length()<12 or delta.normalized().dot(direction)>.25) and line_clear(player_position(),enemy.pos):
				hurt(enemy,Data.damage(hero,kind),kind,int(weapon.get("enchant",0)))
		burst(player_position()+direction*32,Color("fff0c8"),8)
	else:
		desktop.shoot(direction,kind,Data.damage(hero,kind),int(weapon.get("enchant",0)))
	return true

func shoot(target: Dictionary,kind: String,amount: float,enchant: int=0) -> void:
	shots.append({"pos":player_position()+Vector2(0,-4),"velocity":player_position().direction_to(target.pos)*(390 if kind=="bow" else 310),"kind":kind,"damage":amount,"enchant":enchant,"life":1.7})

func hurt(enemy: Dictionary,amount: float,kind: String,enchant: int=0,no_chain: bool=false) -> void:
	if enemy.dead:
		return
	var critical = randf()<minf(.6,.06+hero.dex*.006+(.25 if hero.className=="Rogue" else 0))
	if critical:
		amount *= 3 if hero.className=="Reaper" else 1.8
	amount = maxf(1,round(amount))
	sound("hit")
	visual_fx("impact",enemy.pos+Vector2(0,-12),18,Color("f1ddb3") if kind=="melee" else Color("e6c59e") if kind=="bow" else Color("f0ac80") if enchant==1 else Color("c6b2ef"),.22)
	exploration.on_hit(enemy,kind)
	enemy.hp -= amount
	exploration.pack_alert(enemy)
	enemy.aggro = 6
	enemy.flash = .12
	if kind=="melee" and not no_chain and not enemy.get("boss",false) and not enemy.has("named") and enemy.get("stagger_guard",0.0)<=0:
		enemy["stagger"]=.14;enemy["stagger_guard"]=.9
		enemy["recoil_direction"]=player_position().direction_to(enemy.pos)
		enemy.windup=0;enemy.cooldown=maxf(.4,enemy.get("cooldown",0.0))
	floating(enemy.pos+Vector2(-10,-enemy.radius-7),str(int(amount))+("!" if critical else ""),Color("ffdf87") if critical else Color("f8e8c8"))
	if enchant==4 or hero.className=="Reaper":
		hero.hp = minf(Data.max_hp(hero),hero.hp+maxf(1,amount*.07))
	if kind=="melee" and hero.className=="Spellblade":
		hero.mp = minf(Data.max_mp(hero),hero.mp+2)
	if enchant==1:
		enemy.burn = 3
		enemy.burn_tick = .7
		enemy.burn_damage = amount*.16
		enemy.burn_kind = kind
	elif enchant==2:
		enemy.slow = 2.5
	elif enchant==3 and not no_chain:
		var other = closest(155,enemy.pos,enemy)
		if not other.is_empty():
			var lightning=visual_fx("storm",enemy.pos,155,Color("cdbbff"),.2)
			lightning["end"]=other.pos
			hurt(other,amount*.4,kind,0,true)
	if kind=="bow" and hero.className=="Arcane Archer" and not no_chain:
		var other = closest(80,enemy.pos,enemy)
		if not other.is_empty():
			hurt(other,amount*.3,kind,0,true)
		burst(enemy.pos,Color("8de8e3"),6)
	if enemy.hp<=0:
		kill_enemy(enemy,kind)

func kill_enemy(enemy: Dictionary,kind: String) -> void:
	if enemy.dead:
		return
	enemy.dead = true
	forest.defeated(enemy)
	exploration.on_kill(enemy)
	forge.on_kill(enemy)
	castle.defeated(enemy)
	contracts.on_kill(enemy)
	if enemy.get("neutral",false):
		survival.add("Raw meat",2); survival.add("Hide",1)
	hero.kills += 1
	hero.stats["melee" if kind=="melee" else "bow" if kind=="bow" else "magic"] += 1
	if enemy.boss:
		hero.stats.bosses += 1
	hero.gold += enemy.reward_gold
	add_renown(25 if enemy.boss else 2)
	grant_xp(int((8+enemy.level*3)*(7 if enemy.boss else 1)))
	if enemy.boss or randf()<.1:
		take_item(Data.roll_loot(enemy.level,enemy.boss))
	if enemy.boss or randf()<.14:
		hero.hp = minf(Data.max_hp(hero),hero.hp+Data.max_hp(hero)*.2)
		hero.mp = minf(Data.max_mp(hero),hero.mp+12)
	if hero.dungeon!=null and enemy.has("dungeon_id"):
		if not enemy.dungeon_id in hero.dungeon.cleared:
			hero.dungeon.cleared.append(enemy.dungeon_id)
		check_floor_clear()
	burst(enemy.pos,Color("e9cd85") if enemy.boss else Color("98c48e"),12)

func grant_xp(amount: int) -> void:
	hero.xp += amount
	while hero.xp>=Data.needed_xp(hero):
		hero.xp -= Data.needed_xp(hero)
		hero.level += 1
		hero.points += 3
		hero.hp = Data.max_hp(hero)
		hero.mp = Data.max_mp(hero)
		notify("LEVEL %d · +3 stat points. Health and mana restored." % hero.level,4)
	check_unlocks()

func check_unlocks() -> void:
	var goals = {"Spellblade":hero.stats.melee>=40 and hero.stats.magic>=30,"Arcane Archer":hero.stats.bow>=60 and hero.stats.magic>=20,"Reaper":hero.stats.bosses>=5}
	for name_value in goals:
		if goals[name_value] and not name_value in hero.unlocked:
			hero.unlocked.append(name_value)
			notify("HIDDEN CLASS DISCOVERED: "+name_value+". Open Paths.",6)

func add_renown(amount: int) -> void:
	var before = Data.title(hero.kingdom.renown)
	hero.kingdom.renown += amount
	if before!=Data.title(hero.kingdom.renown):
		notify("Your title is now "+Data.title(hero.kingdom.renown)+"!",4)

func cast(spell:String) -> bool:
	return spellbook.cast(spell,spellbook.target_point())

func cast_legacy(spell: String) -> bool:
	if not playing or float(spell_cooldowns.get(spell,0.0))>0 or (spell!="heal" and survival.sheltered()):
		return false
	var cost = {"fire":12,"frost":20,"heal":25}[spell]
	if hero.mp<cost:
		notify("Not enough mana. Mana recovers over time.",2)
		return false
	var target = closest(470,player_position())
	var mouse_fire=spell=="fire" and desktop.enabled and desktop.mouse_aim
	if spell=="fire" and target.is_empty() and not mouse_fire:
		notify("No enemy in Firebolt range.",2)
		return false
	sound("spell")
	cast_feedback(Color({"fire":"ffb077","frost":"9edff4","heal":"aedfb6"}[spell]))
	if spell!="heal": abilities.stealth=0
	hero.mp -= cost
	spell_cooldowns[spell] = {"fire":1.3,"frost":5.5,"heal":9.0}[spell]
	if spell=="fire":
		if mouse_fire: desktop.shoot(desktop.aim_direction(),"fire",Data.damage(hero,"magic")*1.7,1)
		else: shoot(target,"fire",Data.damage(hero,"magic")*1.7,1)
	elif spell=="frost":
		visual_fx("frost",player_position(),175,Color("a6e5f4"),.55)
		for enemy in enemies.duplicate():
			if not enemy.dead and enemy.pos.distance_to(player_position())<175 and line_clear(player_position(),enemy.pos):
				hurt(enemy,Data.damage(hero,"magic")*1.5,"magic",2)
		burst(player_position(),Color("9bddfa"),40)
	else:
		visual_fx("heal",player_position(),40,Color("bce7b7"),.65)
		hero.hp = minf(Data.max_hp(hero),hero.hp+Data.max_hp(hero)*(.55 if hero.className=="Cleric" else .33))
		burst(player_position(),Color("b2efb9"),25)
	return true

func dash() -> void:
	if not playing or dash_cooldown>0:
		return
	fishing.cancel()
	spellbook.cancel_target()
	if exploration.active(): exploration.dodged=true
	dash_cooldown = 2.4 if hero.className=="Rogue" else 3.8
	dash_time = .23
	var direction=input_router.movement()
	if direction.length()>.1: facing=direction.normalized()

func take_item(item: Dictionary) -> void:
	if hero.inventory.size()>=40:
		hero.essence += item.rarity+1
		notify("Bag full: new loot salvaged into essence.",3)
	else:
		hero.inventory.append(item)
		notify(Data.RARITIES[int(item.rarity)].name+" "+item.name,3)

func populate_chests(force: bool=false) -> void:
	if hero.dungeon!=null:
		return
	var center = Vector2i(floori(hero.x/640.0),floori(hero.y/640.0))
	if center==chunk_key and not force:
		return
	chunk_key = center
	chests.clear()
	if absi(center.x)<4 and absi(center.y)<4:
		chests.append({"id":"wayfarer-cache","pos":Vector2(100,120),"level":1})
	for x in range(center.x-2,center.x+3):
		for y in range(center.y-2,center.y+3):
			var id = "g:%d,%d:0" % [x,y]
			var spot=Vector2(x*640+100+WorldScript.tile_hash(x,y,8)*440,y*640+100+WorldScript.tile_hash(x,y,13)*440)
			if exploration.cave_wall(spot): spot+=Vector2(72,72)
			if not walkable(spot,10):continue
			if not exploration.cave_wall(spot): chests.append({"id":id,"pos":spot,"level":maxi(1,int(Vector2(x,y).length()*.55+hero.level*.65))})

func open_chest() -> bool:
	if chest_near.is_empty() or hero.opened.has(chest_near.id) or chest_near.pos.distance_to(player_position())>70:
		return false
	var chest = chest_near
	hero.opened[chest.id] = true
	hero.stats.chests += 1
	hero.gold += randi_range(20,40)+chest.level*7
	hero.essence += randi_range(1,2)
	add_renown(8)
	take_item(Data.roll_loot(chest.level))
	hero.hp = minf(Data.max_hp(hero),hero.hp+Data.max_hp(hero)*.15)
	chest_near = {}
	save_game()
	return true

func build_building(name_value: String) -> bool:
	if not Data.BUILDINGS.has(name_value) or Data.has_building(hero,name_value) or hero.gold<Data.BUILDINGS[name_value].cost:
		return false
	hero.gold -= Data.BUILDINGS[name_value].cost
	hero.kingdom.buildings.append(name_value)
	save_game()
	return true

func equip(item: Dictionary) -> void:
	var slot = "weapon" if item.kind in ["sword","bow","staff"] else item.kind
	hero.equipped[slot] = item.id
	hero.hp = minf(hero.hp,Data.max_hp(hero))
	hero.mp = minf(hero.mp,Data.max_mp(hero))
	save_game()

func upgrade(item: Dictionary) -> bool:
	var cost = Data.upgrade_cost(hero,item)
	if hero.gold<cost:
		return false
	hero.gold -= cost
	item.upgrade += 1
	item.power += maxi(2,int(round(item.power*.12)))
	save_game()
	return true

func enchant_item(item: Dictionary) -> bool:
	if hero.essence<3 or not item.kind in ["sword","bow","staff"]:
		return false
	hero.essence -= 3
	var choices = [1,2,3,4]
	choices.erase(int(item.enchant))
	item.enchant = choices.pick_random()
	save_game()
	return true

func salvage(item: Dictionary) -> bool:
	if item.id in hero.equipped.values():
		return false
	hero.essence += item.rarity+1
	hero.gold += maxi(3,item.level*2)
	hero.inventory.erase(item)
	save_game()
	return true

func enter_dungeon(story:bool=false) -> void:
	if hero.dungeon!=null:
		return
	if story and (chapter.stage()!=3 or player_position().distance_to(exploration.RUINS)>=80): return
	hero.journey.dungeon_entered=true
	hero.dungeon = {"floor":1,"seed":randi_range(1,2147483640),"run":str(Time.get_ticks_usec()),"cleared":[],"rewarded":false,"returnX":hero.x,"returnY":hero.y}
	hero.dungeon["story"]=story
	build_floor(true)
	save_game()
	if story: notify("THE HOLLOW ROOT · Three floors. Purple runes warn before striking. Seek the Hollow Heart.",7);return
	notify("SURVIVAL EXPEDITION · Five floors. Defeat the final lord and return home." if expedition.enabled() else "ENDLESS DUNGEON · Defeat enemies to unlock the gold stairs.",5)

func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell)*TILE+Vector2.ONE*TILE/2

func build_floor(reset_position: bool=true) -> void:
	clear_scene()
	var dungeon = hero.dungeon
	dungeon_map = castle.layout() if castle.active() else Data.make_dungeon(int(dungeon.seed))
	astar = AStarGrid2D.new()
	astar.region = Rect2i(0,0,dungeon_map.size,dungeon_map.size)
	astar.cell_size = Vector2(TILE,TILE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for y in range(dungeon_map.size):
		for x in range(dungeon_map.size):
			astar.set_point_solid(Vector2i(x,y),not dungeon_map.grid[y][x])
	if reset_position or not walkable(player_position(),10):
		set_player_position(cell_center(dungeon_map.start))
	hero.highestFloor = maxi(hero.highestFloor,dungeon.floor)
	if castle.active():
		castle.setup();camera.position=player_position();camera.reset_smoothing();world.refresh(true);check_floor_clear();return
	var places = dungeon_map.floors.filter(func(c):return Vector2(c).distance_to(Vector2(dungeon_map.start))>2.2 and c!=dungeon_map.exit)
	var rng = RandomNumberGenerator.new()
	rng.seed = int(dungeon.seed)^0x1234abcd
	for i in range(places.size()-1,0,-1):
		var j = rng.randi_range(0,i)
		var value = places[i]
		places[i] = places[j]
		places[j] = value
	var positions = places.slice(0,mini(14,5+int(dungeon.floor*.7)))
	if int(dungeon.floor)%5==0:
		positions.append(dungeon_map.exit)
	for i in range(positions.size()):
		var id = "%d:%d" % [dungeon.floor,i]
		if id in dungeon.cleared:
			continue
		var boss = positions[i]==dungeon_map.exit
		var enemy = create_enemy(cell_center(positions[i]),dungeon.floor,"guardian" if boss else ["goblin","skeleton","slime"][i%3],boss)
		var stats = Data.scaled_enemy(dungeon.floor,boss)
		enemy.hp = stats.hp
		enemy.max_hp = stats.hp
		enemy.contact_damage = stats.dmg
		enemy.reward_gold = stats.gold
		enemy.dungeon_id = id
		enemies.append(enemy)
	for i in range(mini(3,places.size())):
		chests.append({"id":"gd:%s:%d:%d" % [dungeon.run,dungeon.floor,i],"pos":cell_center(places[places.size()-1-i]),"level":dungeon.floor})
	chapter.floor_setup()
	camera.position = player_position()
	camera.reset_smoothing()
	world.refresh(true)
	check_floor_clear()

func floor_clear() -> bool:
	if castle.active():return castle.required_clear()
	return not enemies.any(func(e):return not e.dead)

func check_floor_clear() -> bool:
	if hero.dungeon==null or not floor_clear():
		return false
	if castle.active() and castle.has("floor-reward"):hero.dungeon.rewarded=true
	if not hero.dungeon.rewarded:
		if castle.active():hero.opened[castle.token("floor-reward")]=true
		chapter.floor_cleared()
		hero.dungeon.rewarded = true
		hero.floorsCleared += 1
		contracts.advance("delve")
		hero.journey.first_floor=true
		forest.check_opening_reward()
		add_renown(15+mini(100,hero.dungeon.floor*2))
		hero.gold += 10+hero.dungeon.floor*5
		if chapter.story_run() and hero.dungeon.floor==3:
			notify("THE HOLLOW ROOT COMPLETE · Gold stairs return you to Mara.",6)
		elif expedition.enabled() and hero.dungeon.floor>=5:
			hero.needs.ruins=true
			notify("EXPEDITION COMPLETE · Use the gold stairs to return home.",5)
		elif castle.caves.active():notify("EXPEDITION CLEARED · Search the optional vault or take the gold stairs outside.",5)
		elif castle.active():notify("CASTLE LEVEL CLEARED · Explore the optional rooms or take the gold stairs.",5)
		else: notify("FLOOR CLEARED · Find the gold staircase to descend.",5)
		save_game()
	return true

func advance_floor() -> bool:
	if castle.active():return castle.advance()
	if hero.dungeon==null or not floor_clear():
		return false
	if (chapter.story_run() and hero.dungeon.floor>=3) or (expedition.enabled() and hero.dungeon.floor>=5):
		leave_dungeon();return true
	hero.dungeon.floor += 1
	hero.dungeon.seed = posmod(int(hero.dungeon.seed)*1664525+1013904223,2147483647)
	hero.dungeon.cleared = []
	hero.dungeon.rewarded = false
	build_floor(true)
	save_game()
	notify("FLOOR %d%s" % [hero.dungeon.floor," · A Dungeon Lord awaits." if int(hero.dungeon.floor)%5==0 else ""],4)
	return true

func leave_dungeon() -> void:
	if hero.dungeon==null:
		return
	var at = Vector2(hero.dungeon.returnX,hero.dungeon.returnY)
	hero.dungeon = null
	dungeon_map = {}
	clear_scene()
	set_player_position(at)
	populate_chests(true)
	world.refresh(true)
	camera.position = at
	camera.reset_smoothing()
	save_game()

func walkable(at: Vector2,radius: float=0) -> bool:
	if hero.dungeon==null or dungeon_map.is_empty():
		for offset in [Vector2(-radius,-radius),Vector2(radius,-radius),Vector2(-radius,radius),Vector2(radius,radius)]:
			if landscape.solid(at+offset):return false
			if exploration.cave_wall(at+offset): return false
		return not survival.blocked(at,radius)
	for offset in [Vector2(-radius,-radius),Vector2(radius,-radius),Vector2(-radius,radius),Vector2(radius,radius)]:
		var cell = Vector2i(floori((at.x+offset.x)/TILE),floori((at.y+offset.y)/TILE))
		if cell.x<0 or cell.y<0 or cell.x>=dungeon_map.size or cell.y>=dungeon_map.size or not dungeon_map.grid[cell.y][cell.x]:
			return false
	return true

func move_position(at: Vector2,delta: Vector2,radius: float) -> Vector2:
	var steps = maxi(1,ceili(maxf(absf(delta.x),absf(delta.y))/8.0))
	for i in range(steps):
		if walkable(at+Vector2(delta.x/steps,0),radius):
			at.x += delta.x/steps
		if walkable(at+Vector2(0,delta.y/steps),radius):
			at.y += delta.y/steps
	return at

func line_clear(a: Vector2,b: Vector2) -> bool:
	if hero.dungeon==null and hero.survival.structures.is_empty() and exploration.region_at(a)!="caves" and exploration.region_at(b)!="caves" and not landscape.intersects_authored(a,b):
		return true
	var steps = maxi(1,ceili(a.distance_to(b)/8.0))
	for i in range(steps+1):
		if not walkable(a.lerp(b,float(i)/steps)):
			return false
	return true

func dungeon_direction(enemy: Dictionary,dt: float) -> Vector2:
	enemy.path_timer -= dt
	var cell = Vector2i(floori(enemy.pos.x/TILE),floori(enemy.pos.y/TILE))
	var target_cell = Vector2i(floori(hero.x/TILE),floori(hero.y/TILE))
	if cell==target_cell:
		return enemy.pos.direction_to(player_position())
	if enemy.path_timer<=0 or enemy.pos.distance_to(enemy.goal)<4:
		enemy.path_timer = .35
		var path = astar.get_id_path(cell,target_cell)
		if path.size()>1:
			enemy.goal = cell_center(path[1])
	var center = cell_center(cell)
	var goal = enemy.goal
	if (absf(goal.x-center.x)>1 and absf(enemy.pos.y-center.y)>3) or (absf(goal.y-center.y)>1 and absf(enemy.pos.x-center.x)>3):
		goal = center
	return enemy.pos.direction_to(goal)

func update_interaction() -> void:
	var label_value = "OPEN CHEST" if not chest_near.is_empty() else ""
	if hero.dungeon==null and label_value.is_empty():
		var node = survival.nearest_node()
		if not node.is_empty(): label_value="GATHER "+node.kind.to_upper()
		elif not survival.near("Campfire").is_empty(): label_value="CAMPFIRE / COOK"
		elif survival.sheltered(): label_value="SHELTER / CRAFT"

	if hero.dungeon!=null:
		if player_position().distance_to(cell_center(dungeon_map.start))<38:
			label_value = "STAIRS · PREVIOUS CASTLE LEVEL" if castle.active() and hero.dungeon.floor>1 else "LEAVE DUNGEON"
		elif player_position().distance_to(cell_center(dungeon_map.exit))<38:
			label_value = ("RETURN HOME · EXPEDITION COMPLETE" if (chapter.story_run() and hero.dungeon.floor>=3) or (expedition.enabled() and hero.dungeon.floor>=5) else "DESCEND · FLOOR %d" % (hero.dungeon.floor+1)) if floor_clear() else "STAIRS LOCKED"
			if castle.active() and floor_clear():label_value="RETURN OUTSIDE · EXPEDITION CLEARED" if castle.caves.active() else "RETURN OUTSIDE · KEEP RECLAIMED" if hero.dungeon.floor==3 else "STAIRS · NEXT CASTLE LEVEL"
	if hero.dungeon==null:
		var door=survival.near("Door",65)
		if not door.is_empty(): label_value="CLOSE DOOR" if door.open else "OPEN DOOR"
		var garden=farming.nearest(48)
		if not garden.is_empty(): label_value="GARDEN / HARVEST" if farming.ready(garden) else "TEND GARDEN"
		if not forest.interaction().is_empty(): label_value=forest.interaction()
		if not exploration.interaction().is_empty(): label_value=exploration.interaction()
	if expedition.enabled() and expedition.near_spring(): label_value="SPRING / REFILL FLASK"
	if contracts.near_board(): label_value="QUEST BOARD"
	if trader.near(): label_value="TRADE WITH MARA"
	if not fishing.interaction().is_empty(): label_value=fishing.interaction()
	if not chapter.interaction().is_empty(): label_value=chapter.interaction()
	if not forge.interaction().is_empty(): label_value=forge.interaction()
	if not landscape.feature_near().is_empty():label_value=landscape.feature_near()
	if not castle.interaction().is_empty():label_value=castle.interaction()
	if not build_recipe.is_empty(): label_value="PLACE "+build_recipe.to_upper()
	hud.set_interaction(label_value)

func interact() -> void:
	if not playing:
		return
	if not spellbook.targeting.is_empty(): return
	if not build_recipe.is_empty():
		if survival.craft(build_recipe): cancel_build()
		return
	if not castle.interaction().is_empty():castle.use_feature();return
	if not landscape.feature_near().is_empty():landscape.interact();return
	if not forge.interaction().is_empty(): forge.interact();return
	if not chapter.interaction().is_empty(): chapter.interact();return
	if not fishing.interaction().is_empty():
		fishing.interact();return
	if expedition.enabled() and expedition.near_spring():
		expedition.drink(true);notify("Fresh water · thirst restored and flask filled",3);return
	if trader.near():
		hud.show_character("trader");return
	if contracts.near_board():
		hud.show_character("quests");return
	if not exploration.interaction().is_empty():
		exploration.interact(); return
	if not forest.interaction().is_empty():
		forest.interact(); return
	if not farming.nearest(48).is_empty():
		hud.show_character("farm");return
	var door=survival.near("Door",65)
	if not door.is_empty():
		survival.toggle_door(door); return
	if hero.dungeon!=null:
		if player_position().distance_to(cell_center(dungeon_map.start))<38:
			if castle.active():castle.retreat()
			else:leave_dungeon()
			return
		if player_position().distance_to(cell_center(dungeon_map.exit))<38:
			if not advance_floor():
				notify("Defeat all enemies to unlock the stairs.",3)
			return
	if not chest_near.is_empty():
		open_chest()
	elif not survival.nearest_node().is_empty():
		survival.gather()
	elif not survival.near("Campfire").is_empty() or survival.sheltered():
		hud.show_character("camp")
	update_interaction()

func defeated() -> void:
	if castle.checkpoint_defeat():return
	hero.deaths += 1
	expedition.reset_after_defeat()
	var loss = int(hero.gold*.15)
	hero.gold -= loss
	hero.dungeon = null
	dungeon_map = {}
	clear_scene()
	set_player_position(safe_wilds_position(Vector2(hero.respawn.x,hero.respawn.y)))
	cancel_build()
	hero.hp = Data.max_hp(hero)
	hero.mp = Data.max_mp(hero)
	populate_chests(true)
	world.refresh(true)
	camera.position = player_position()
	camera.reset_smoothing()
	hud.show_pause("You fell. %d gold lost. Your levels, gear, and discoveries are safe." % loss)

func floating(at: Vector2,text_value: String,color: Color) -> void:
	if at.distance_squared_to(player_position())>360000:
		return
	effects.append({"pos":at,"text":text_value,"color":color,"velocity":Vector2(0,-22),"life":1.0})

func burst(at: Vector2,color: Color,count: int) -> void:
	count = mini(count,8 if low_power else 20)
	for i in range(count):
		effects.append({"pos":at,"color":color,"velocity":Vector2.from_angle(randf()*TAU)*randf_range(20,110),"life":randf_range(.25,.7)})

func load_performance_settings() -> void:
	var config = ConfigFile.new()
	reduced_crowds=true
	low_power=not desktop.enabled
	if config.load("user://performance.cfg")==OK:
		low_power = bool(config.get_value("display","low_power",true))
		var crowd_value=config.get_value("display","reduced_crowds",true)
		reduced_crowds=crowd_value if crowd_value is bool else true
	if desktop.enabled and "--safe-mode" in OS.get_cmdline_user_args():
		low_power=true;weather.particles_enabled=false
	Engine.max_fps = 30 if low_power else 60

func set_low_power(enabled: bool) -> void:
	low_power = enabled
	Engine.max_fps = 30 if low_power else 60
	var config = ConfigFile.new()
	config.load("user://performance.cfg")
	config.set_value("display","low_power",low_power)
	config.save("user://performance.cfg")
	if world!=null:
		world.queue_redraw()

func set_reduced_crowds(enabled:bool) -> void:
	reduced_crowds=enabled
	var config=ConfigFile.new();config.load("user://performance.cfg")
	config.set_value("display","reduced_crowds",enabled);config.save("user://performance.cfg")
	# Only recycle distant, idle ambient enemies. Active fights and quest foes stay.
	if enabled and not hero.is_empty() and hero.dungeon==null:
		enemies=enemies.filter(func(e):return protected_encounter_enemy(e) or e.aggro>0 or e.burn>0 or e.get("windup",0.0)>0 or e.pos.distance_squared_to(player_position())<422500)
	spawn_timer=maxf(spawn_timer,3.0)

func adapt_screen() -> void:
	var window=get_window()
	var landscape=window.size.x>window.size.y
	var base=desktop.VIEWS[desktop.view_name] if desktop!=null and desktop.enabled else Vector2i(900,480) if landscape else Vector2i(480,900)
	if window.content_scale_size!=base:
		window.content_scale_size=base
	if hud!=null:
		hud.reset_stick()
		attack_held=false
	if spellbook!=null: spellbook.cancel_target()
	if landscape!=screen_landscape and not hero.is_empty():
		camera.position=player_position()
		camera.force_update_scroll()
		world.refresh(true)
	screen_landscape=landscape

func sound(cue:String) -> void:
	if audio!=null: audio.play_cue(cue)
func begin_build(recipe:String,move_source:Dictionary={}) -> void:
	fishing.cancel()
	spellbook.cancel_target()
	survival.moving=move_source
	build_recipe=recipe
	build_rotation=int(move_source.get("rotation",0))
	hud.resume()
	notify("Move to position the ghost. Rotate it, then tap PLACE. Cancel spends nothing.",5)
func cancel_build() -> void:
	build_recipe=""
	survival.moving={}
	if hud!=null: hud.build_tools.visible=false
func update_enemy_attack(enemy:Dictionary,dt:float) -> void:
	if not playing or dt<=0 or enemy.dead or enemy.get("neutral",false): return
	if enemy.get("stagger",0.0)>0: return
	if abilities.stealth>0 or survival.sheltered() or enemy.get("returning",false):
		enemy.windup=0
		return
	var pos=player_position()
	var named=enemy.has("named")
	if enemy.get("windup",0.0)>0:
		if not tactics.attack_reachable(enemy,pos):
			enemy.windup=0;enemy.cooldown=maxf(.3,enemy.cooldown)
			return
		enemy.windup=maxf(0,enemy.windup-dt)
		if enemy.windup==0:
			enemy["attack_pose"]=.18
			burst(enemy.strike,Color("f29875"),12)
			if pos.distance_to(enemy.strike)<enemy.strike_radius+9 and dash_time<=0 and not survival.sheltered() and line_clear(enemy.pos,pos):
				var mitigation=Data.power(hero,"armor")*.045+Data.power(hero,"shield")*.18+Data.power(hero,"helmet")*.1
				var amount=maxf(1,floor(enemy.contact_damage*(.9 if Data.has_building(hero,"Barracks") else 1)-mitigation))
				visual_fx("impact",pos+Vector2(0,-8),28,Color("e8a49a"),.25)
				if spellbook.ward_time>0: amount*=.4
				hero.hp-=amount
				floating(pos+Vector2(-12,-30),"-"+str(int(amount)),Color("ff9895"))
				sound("hurt")
			enemy.cooldown=1.5 if named else 1.0
		return
	if enemy.cooldown>0 or survival.sheltered() or enemy.get("returning",false): return
	var distance=enemy.pos.distance_to(pos)
	var ranged=enemy.type in ["wisp","skeleton","crystal_wisp","archer","ice_archer"]
	if distance<(230 if named else 210 if ranged else enemy.radius+35) and line_clear(enemy.pos,pos):
		enemy.windup=1.1 if named else .85 if ranged else .65
		enemy.strike=pos if named or ranged else enemy.pos+enemy.pos.direction_to(pos)*22
		enemy.strike_radius=(95.0 if enemy.hp<enemy.max_hp*.5 else 72.0) if named else 30.0 if ranged else 38.0
		if enemy.get("chapter_boss",false):
			enemy.windup=.8 if enemy.hp<enemy.max_hp*.5 else 1.2
			enemy.strike_radius=100.0 if enemy.hp<enemy.max_hp*.5 else 55.0
		if enemy.get("forge_boss",false):
			enemy.windup=.85 if enemy.hp<enemy.max_hp*.5 else 1.3
			enemy.strike_radius=82.0 if enemy.hp<enemy.max_hp*.5 else 58.0
		if enemy.get("thornwatch_boss",false):
			enemy["thorn_pattern"]=enemy.get("thorn_pattern",0)+1
			enemy.windup=.85 if enemy.hp<enemy.max_hp*.5 else 1.35
			enemy.strike_radius=110.0 if enemy.thorn_pattern%2==0 else 55.0
			if enemy.thorn_pattern%2==0:enemy.strike=enemy.pos
		if enemy.has("realm_boss"):castle.regional.prepare_attack(enemy)
		if enemy.get("cave_boss",false):castle.caves.prepare_attack(enemy)
		enemy["windup_max"]=enemy.windup
		enemy.aggro=maxf(enemy.aggro,2)

func movement_precision_ok(at:Vector2) -> bool:
	return at.is_finite() and (at+Vector2(.5,0)).x!=at.x and (at+Vector2(0,.5)).y!=at.y

func safe_wilds_position(at:Vector2) -> Vector2:
	# Single-precision world coordinates can swallow movement at extreme values.
	if not movement_precision_ok(at): at=Vector2.ZERO
	if walkable(at,12): return at
	for ring in range(1,49):
		for direction in [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2(1,1),Vector2(-1,1),Vector2(1,-1),Vector2(-1,-1)]:
			var candidate=at+direction*48*ring
			if walkable(candidate,12): return candidate
	return Vector2(at.x,0) if exploration.region_at(at)=="caves" else Vector2.ZERO

func recover_stuck_character() -> bool:
	if hero.is_empty() or hero.dungeon!=null or hero.hp<=0: return false
	# Explicit emergency action: keep the character, camp, rewards and needs intact.
	cancel_build();clear_scene()
	set_player_position(safe_wilds_position(Vector2.ZERO))
	exploration.tick(0)
	survival.refresh(true);populate_chests(true)
	camera.position=player_position();camera.reset_smoothing();camera.force_update_scroll()
	world.refresh(true);hud.reset_stick()
	# Stay paused so an injured/freezing character can review supplies before resuming.
	hud.show_pause("Position recovered · Back at the original camp. Gear and progress kept. Check supplies, then Resume journey.")
	return true

func visual_fx(kind:String,at:Vector2,radius:float,color:Color,duration:float=.4) -> Dictionary:
	var effect={"kind":kind,"pos":at,"radius":radius,"color":color,"life":duration,"duration":duration}
	visuals.append(effect)
	var limit=24 if low_power else 48
	if visuals.size()>limit: visuals=visuals.slice(visuals.size()-limit)
	return effect
