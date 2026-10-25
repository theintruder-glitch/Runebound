extends SceneTree
const Data=preload("res://scripts/data.gd")
const Catalog=preload("res://scripts/realm_catalog.gd")
var game
var output=OS.get_environment("RUNEBOUND_VISUAL_OUTPUT")
func _initialize():call_deferred("run")
func capture(name:String):
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output.path_join(name+".png"))
func view(p:Vector2):
 game.set_player_position(p);game.camera.position=p;game.camera.reset_smoothing();game.world.refresh(true);game.hud.update_hud();game.update_interaction();game.hud.toast_time=0;game.hud.toast_label.text=""
func run():
 DirAccess.make_dir_recursive_absolute(output);root.size=Vector2i(1200,720)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.audio.enabled=false;game.audio.music.stop()
 for id in Catalog.ZONES:
  game.start_character(Data.fresh("Warrior"));game.set_physics_process(false);game.hero.auto=false;game.enemies.clear();game.spawn_timer=999999
  game.graphics.set_quality("Balanced");game.hero.worldTime=120
  var info=Catalog.ZONES[id]
  view(info.gate);game.camera.position=info.gate-Vector2(0,230);game.world.refresh(true);await capture(id+"-exterior")
  root.size=Vector2i(540,1200);game.adapt_screen();game.hud.layout();view(info.gate);game.camera.position=info.gate-Vector2(0,230);game.world.refresh(true);await capture(id+"-portrait")
  root.size=Vector2i(1200,720);game.adapt_screen();game.hud.layout();view(Vector2(280,-2204) if id=="frostspire" else Vector2(game.landscape.realms.river_x(180),180) if id=="blackmire" else Vector2(2400,430));await capture(id+"-bridge");view(info.gate);game.castle.enter_region(id)
  view(game.cell_center(game.castle.rooms(1)[4][0].get_center()));await capture(id+"-hall")
  game.hero.dungeon.floor=2;game.build_floor(true);view(game.cell_center(game.castle.rooms(2)[4][0].get_center()));await capture(id+"-crypt")
  game.hero.dungeon.floor=3;game.build_floor(true)
  var boss=game.enemies.filter(func(e):return e.has("realm_boss"))[0]
  view(boss.pos+Vector2(0,80));boss.cooldown=0;boss.windup=0;game.update_enemy_attack(boss,.016);await capture(id+"-boss")
 game.queue_free();await process_frame;await process_frame;quit()
