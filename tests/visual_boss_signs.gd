extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
func _initialize():call_deferred("run")
func capture(name_value:String):
 game.hud.update_hud();game.hud._process(0);game.hud.toast_label.text=""
 for i in range(6):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/boss-visuals/"+name_value+".png")
func run():
 DirAccess.make_dir_recursive_absolute("res://builds/boss-visuals")
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;await process_frame
 for dims in [Vector2i(600,1100),Vector2i(1152,648)]:
  root.size=dims;await process_frame;game.adapt_screen();game.hud.layout()
  game.start_character(Data.fresh("Mage"));game.set_physics_process(false);game.hero.auto=false
  game.set_player_position(game.landscape.realms.Catalog.ZONES.frostspire.gate);game.castle.enter_region("frostspire");game.hero.dungeon.floor=3;game.build_floor(true)
  var boss=game.enemies.filter(func(e):return e.has("realm_boss"))[0]
  game.set_player_position(boss.pos+Vector2(0,120));game.camera.position=game.player_position();game.camera.reset_smoothing();game.world.refresh(true)
  boss.cooldown=0;game.update_enemy_attack(boss,.016)
  var prefix="portrait" if dims.x<dims.y else "landscape"
  await capture(prefix+"-frost-king")
  boss.hp=boss.max_hp*.4;boss.windup=0;boss.cooldown=0;game.update_enemy_attack(boss,.016);game.boss_signs.on_damage(boss)
  await capture(prefix+"-phase-two")
  game.start_character(Data.fresh("Mage"));game.set_physics_process(false);game.hero.auto=false;game.enemies.clear()
  var id="beacon-emerald"
  for key in ["read","step-0","step-1","step-2","solved"]:game.beacons.mark(id,key)
  game.set_player_position(game.beacons.SITES[id].point);game.beacons.begin(id)
  game.camera.position=game.player_position();game.camera.reset_smoothing();game.world.refresh(true)
  await capture(prefix+"-watchers")
 game.queue_free();await process_frame;game=null;await process_frame
 print("BOSS SIGN VISUALS CAPTURED");quit()
