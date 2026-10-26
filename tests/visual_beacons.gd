extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
func _initialize():call_deferred("run")
func settle():
 for i in range(6):await process_frame
 await RenderingServer.frame_post_draw
func capture(name_value:String):
 await settle();root.get_texture().get_image().save_png("res://builds/beacon-visuals/"+name_value+".png")
func run():
 DirAccess.make_dir_recursive_absolute("res://builds/beacon-visuals")
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
 for orientation in [Vector2i(600,1100),Vector2i(1152,648)]:
  root.size=orientation;await settle();game.adapt_screen();game.hud.layout()
  for id in game.beacons.SITES:
   game.start_character(Data.fresh("Mage"));game.set_physics_process(false);game.hero.auto=false;game.enemies.clear()
   var b=game.beacons;var info=b.SITES[id];b.mark(id,"read")
   for key in info.order:
    game.set_player_position(info.point+b.OFFSETS[key]);b.align(id,key)
   game.hero.exploration.target=id;game.set_player_position(info.point+Vector2(0,65));game.camera.position=game.player_position();game.camera.reset_smoothing();game.world.refresh(true);game.hud.update_hud();game.update_interaction();game.hud.toast_label.text=""
   await capture(("portrait-" if orientation.x<orientation.y else "landscape-")+id)
   b=null
  game.hud.show_character("beacons");await capture("journal-"+("portrait" if orientation.x<orientation.y else "landscape"))
 game.queue_free();await process_frame;game=null;await process_frame
 print("BEACON VISUALS CAPTURED");quit()
