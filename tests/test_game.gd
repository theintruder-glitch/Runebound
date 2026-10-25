extends SceneTree

const Data = preload("res://scripts/data.gd")
var checks = 0

func check(condition: bool,label_value: String) -> void:
	if not condition:
		push_error("FAIL: "+label_value)
		quit(1)
		assert(condition,label_value)
	checks += 1
	print("PASS: "+label_value)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var fixture = OS.get_environment("RUNEBOUND_LEGACY_FIXTURE")
	if not fixture.is_empty():
		var imported = Data.migrate(JSON.parse_string(FileAccess.get_file_as_string(fixture)))
		check(not imported.is_empty() and imported.className=="Ranger" and imported.gold==456 and imported.level==6 and imported.kingdom.renown==350,"Actual legacy export JSON imports in Godot")
	var original = Data.fresh("Warrior")
	original.gold = 777
	original.level = 8
	original.opened.old_chest = true
	original.erase("engine")
	scene.start_character(original)
	scene.playing = false
	check(scene.hero.gold==777 and scene.hero.level==8 and scene.hero.opened.old_chest,"Character migration preserves progress")
	check(Data.migrate({"className":"Warrior","inventory":[]}).is_empty(),"Malformed character imports are rejected")
	scene.playing = true
	var move_touch = InputEventScreenTouch.new()
	move_touch.index = 0
	move_touch.pressed = true
	move_touch.position = scene.hud.stick.global_position+scene.hud.stick.size/2+Vector2(30,0)
	scene.hud.stick._input(move_touch)
	var spell_touch = InputEventScreenTouch.new()
	spell_touch.index = 1
	spell_touch.pressed = true
	spell_touch.position = scene.hud.spell_buttons.heal.get_global_rect().get_center()
	scene.hero.mp = Data.max_mp(scene.hero)
	var before_mana = scene.hero.mp
	scene.hud.spell_buttons.heal._input(spell_touch)
	check(scene.move_vector.x>.5 and scene.spell_cooldowns.heal>0 and scene.hero.mp==before_mana-25,"Separate touch fingers move and cast simultaneously")
	spell_touch.pressed = false
	scene.hud.spell_buttons.heal._input(spell_touch)
	move_touch.pressed = false
	scene.hud.stick._input(move_touch)
	check(scene.move_vector==Vector2.ZERO,"Releasing joystick touch stops movement")
	scene.playing = false
	check(Data.phase(0)=="Day" and Data.phase(360)=="Dusk" and Data.phase(420)=="Night" and Data.phase(570)=="Dawn" and Data.phase(600)=="Day","Day/night phase boundaries")
	check(is_equal_approx(Data.spawn_chance("Night")/Data.spawn_chance("Day"),5),"Night spawn attempts are five times as frequent")
	var counts = [0,0,0,0,0]
	var kinds = {}
	for i in range(20000):
		var item = Data.roll_loot(5)
		counts[item.rarity] += 1
		kinds[item.kind] = true
	var expected = [.60,.25,.10,.04,.01]
	for i in range(5):
		check(absf(counts[i]/20000.0-expected[i])<.025,"Weighted rarity "+Data.RARITIES[i].name)
	check(kinds.size()==8,"All eight equipment types drop")
	for i in range(100):
		check(Data.roll_loot(3,true).rarity>=2,"Boss loot Rare or better" if i==0 else "boss roll")
	for seed_value in range(1,121):
		var dungeon = Data.make_dungeon(seed_value)
		var tiles = 0
		for row in dungeon.grid:
			for cell in row:
				if cell:
					tiles += 1
		check(tiles==dungeon.floors.size() and dungeon.start!=dungeon.exit,"Dungeon seed %d connected with a distinct exit" % seed_value)
	check(Data.make_dungeon(42)==Data.make_dungeon(42),"Seeded dungeons reproduce saved layouts")
	check(Data.scaled_enemy(5,true).hp==Data.scaled_enemy(5).hp*4 and is_finite(Data.scaled_enemy(100000,true).hp),"Boss scaling and extreme floors stay finite")
	scene.hero.auto = false
	var amount = Data.damage(scene.hero,"melee")
	check(scene.build_building("Blacksmith") and Data.damage(scene.hero,"melee")>amount,"Blacksmith spends gold and increases damage")
	var gold = scene.hero.gold
	check(not scene.build_building("Blacksmith") and scene.hero.gold==gold,"Buildings cannot be purchased twice")
	scene.hero.gold = 1000
	check(scene.build_building("Tavern") and scene.build_building("Barracks"),"Tavern and Barracks can be built")
	scene.add_renown(700)
	check(Data.title(scene.hero.kingdom.renown)=="Endless King","Renown reaches Endless King")
	var weapon = scene.hero.inventory[0]
	var power = weapon.power
	scene.upgrade(weapon)
	check(weapon.power>power and weapon.upgrade==1,"Weapon upgrades apply")
	scene.hero.essence = 10
	check(scene.enchant_item(weapon) and weapon.enchant>0,"Weapon enchantments apply")
	var helmet = {"id":"test-helmet","kind":"helmet","power":40,"rarity":2,"level":3,"upgrade":0,"enchant":0,"name":"Test Helm"}
	scene.hero.inventory.append(helmet)
	var hp = Data.max_hp(scene.hero)
	scene.equip(helmet)
	check(Data.max_hp(scene.hero)==hp+24 and not scene.salvage(helmet),"Helmet adds health; equipped items cannot be salvaged")
	scene.hero.stats.melee = 40
	scene.hero.stats.magic = 30
	scene.hero.stats.bow = 60
	scene.hero.stats.bosses = 5
	scene.check_unlocks()
	check(scene.hero.unlocked.size()==3,"Three hidden class achievement conditions unlock")
	scene.enemies.clear()
	scene.shots.clear()
	scene.attack_cooldown = 0
	scene.playing = true
	var bow = Data.fresh("Ranger").inventory[0]
	scene.hero.inventory.append(bow)
	scene.equip(bow)
	var enemy = scene.create_enemy(scene.player_position()+Vector2(60,0),1,"goblin")
	enemy.hp = 10000.0
	enemy.max_hp = 10000.0
	enemy.speed = 0
	scene.enemies.append(enemy)
	check(scene.attack() and scene.shots.size()==1,"Bow launches an arrow")
	for i in range(15):
		scene.tick(.02)
	check(enemy.hp<10000,"Arrow collision damages the enemy")
	scene.playing = true
	scene.hero.mp = Data.max_mp(scene.hero)
	check(scene.cast("fire"),"Firebolt casts with a valid target")
	var mana = scene.hero.mp
	check(not scene.cast("fire") and scene.hero.mp==mana,"Spell cooldown prevents duplicate spending")
	scene.enemies.clear()
	scene.spell_cooldowns.fire = 0
	check(not scene.cast("fire") and scene.hero.mp==mana,"Missing Firebolt target spends no mana")
	scene.playing = false
	scene.hero.x = -212
	scene.hero.y = 535
	scene.enter_dungeon()
	check(scene.hero.dungeon.floor==1 and scene.walkable(scene.player_position(),10),"Dungeon entry creates a valid spawn")
	var total = scene.enemies.size()
	scene.spawn_enemy()
	check(scene.enemies.size()==total and not scene.advance_floor(),"Dungeon has no wilds spawns; descent locks until clear")
	var at = scene.move_position(scene.player_position(),Vector2(10000,0),10)
	check(scene.walkable(at,10) and at.x<10000,"Movement collides with dungeon walls")
	var killed = scene.enemies[0]
	scene.hurt(killed,1e9,"melee")
	var killed_id = killed.dungeon_id
	scene.save_game()
	var loaded = Data.read_save()
	scene.start_character(loaded)
	scene.playing = false
	check(not scene.enemies.any(func(e):return e.dungeon_id==killed_id),"Dungeon kills persist across save/load")
	while scene.hero.dungeon.floor<5:
		for e in scene.enemies.duplicate():
			scene.hurt(e,1e9,"magic")
		var renown = scene.hero.kingdom.renown
		scene.check_floor_clear()
		check(scene.hero.kingdom.renown==renown,"Floor reward cannot be repeated")
		check(scene.advance_floor(),"Cleared floor permits descent")
	check(scene.enemies.filter(func(e):return e.boss).size()==1,"Fifth floor has exactly one Dungeon Lord")
	scene.save_game()
	loaded = Data.read_save()
	check(loaded.dungeon.floor==5 and loaded.kingdom.buildings.size()==3,"Floor and buildings persist")
	scene.leave_dungeon()
	check(scene.hero.dungeon==null and scene.hero.x==-212 and scene.hero.y==535,"Dungeon exit restores wilds position")
	while scene.hero.inventory.size()<40:
		scene.hero.inventory.append(Data.roll_loot(1))
	var essence = scene.hero.essence
	scene.take_item(Data.roll_loot(1))
	check(scene.hero.inventory.size()==40 and scene.hero.essence>essence,"Full bag salvages overflow loot")
	scene.hero.gold = 100
	var level_value = scene.hero.level
	scene.defeated()
	check(scene.hero.gold==85 and scene.hero.level==level_value and scene.hero.inventory.size()==40 and not scene.playing,"Defeat preserves progression and removes 15% gold")
	# Backup fallback is tested using its own file, not the current character.
	var path = "user://test-character.json"
	check(Data.write_save(scene.hero,path) and Data.write_save(scene.hero,path),"Atomic save writes and backup succeed")
	var bad = FileAccess.open(path,FileAccess.WRITE)
	bad.store_string("broken")
	bad.close()
	check(not Data.read_save(path).is_empty(),"Corrupt primary save recovers from backup")
	print("ALL %d GODOT CHECKS PASSED" % checks)
	quit(0)
