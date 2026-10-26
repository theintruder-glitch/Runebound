extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
func _initialize():call_deferred("run")
func settle():
 for i in range(6):await process_frame
 await RenderingServer.frame_post_draw
func capture(name_value:String,p:Vector2):
 game.set_player_position(p);game.camera.position=p;game.camera.reset_smoothing();game.world.refresh(true);game.hud.update_hud();game.update_interaction()
 await settle();root.get_texture().get_image().save_png("res://builds/cave-visuals/"+name_value+".png")
func run():
 DirAccess.make_dir_recursive_absolute("res://builds/cave-visuals")
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
 for orientation in [Vector2i(600,1100),Vector2i(1152,648)]:
  root.size=orientation;await settle();game.adapt_screen();game.hud.layout()
  for id in game.castle.caves.SITES:
   game.start_character(Data.fresh("Mage"));game.set_physics_process(false);game.hero.auto=false
   game.set_player_position(game.castle.caves.SITES[id].point);game.castle.caves.enter(id)
   var prefix=("portrait-" if orientation.x<orientation.y else "landscape-")+id
   var p=game.cell_center(game.castle.caves.rooms()[1][0].get_center())+Vector2(0,80)
   await capture(prefix+"-interior",p)
   game.set_player_position(game.cell_center(game.castle.features().mechanism.cell));game.castle.use_feature()
   p=game.cell_center(game.castle.caves.rooms()[4][0].get_center())+Vector2(-40,55)
   await capture(prefix+"-vault",p)
 print("SIDE CAVE VISUALS CAPTURED");quit()
