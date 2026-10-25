extends SceneTree
const Data=preload("res://scripts/data.gd")
const Catalog=preload("res://scripts/realm_catalog.gd")
var game
func _initialize():call_deferred("run")
func measure(label:String):
 var samples=[];game.hero.vit=1000;game.hero.hp=Data.max_hp(game.hero);game.set_physics_process(false);game.hero.auto=false;game.spawn_timer=999999;game.save_timer=0
 for i in range(330):
  game.hero.hp=Data.max_hp(game.hero);var start=Time.get_ticks_usec();game.tick(1.0/60)
  if i>=30:samples.append((Time.get_ticks_usec()-start)/1000.0)
 samples.sort();var total=0.0
 for value in samples:total+=value
 print(JSON.stringify({"scenario":label,"frames":samples.size(),"enemies":game.enemies.size(),"mean_ms":total/samples.size(),"p95_ms":samples[285],"scope":"headless desktop CPU simulation; excludes renderer, Android hardware, GPU and heat"}))
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;await process_frame
 for id in Catalog.ZONES:
  game.start_character(Data.fresh("Warrior"));game.set_physics_process(false);game.enemies.clear()
  game.set_player_position(Catalog.ZONES[id].trail[2])
  for i in range(6):game.enemies.append(game.create_enemy(game.player_position()+Vector2.from_angle(i*TAU/6)*60,8,"frost_wolf" if id=="frostspire" else "bog_toad" if id=="blackmire" else "guardian"))
  measure(id+" / six ambient enemies")
  game.set_player_position(Catalog.ZONES[id].gate);game.castle.enter_region(id);measure(id+" / gatehouse and all guards")
  game.hero.dungeon.floor=3;game.build_floor(true);game.set_player_position(game.cell_center(game.castle.rooms(3)[1][0].get_center())+Vector2(0,75));measure(id+" / final boss and guards")
 game.queue_free();await process_frame;await process_frame;quit()
