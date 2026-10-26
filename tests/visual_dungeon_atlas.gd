extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
func _initialize():call_deferred("run")
func settle():
 for i in range(6):await process_frame
 await RenderingServer.frame_post_draw
func capture(name_value:String):
 await settle();root.get_texture().get_image().save_png("res://builds/atlas-visuals/"+name_value+".png")
func run():
 DirAccess.make_dir_recursive_absolute("res://builds/atlas-visuals")
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
 for dims in [Vector2i(600,1100),Vector2i(1152,648)]:
  root.size=dims;await settle();game.adapt_screen();game.hud.layout()
  for id in ["thornwatch","frostspire","frost-cave"]:
   game.start_character(Data.fresh("Mage"));game.set_physics_process(false);game.hero.auto=false
   if id=="thornwatch":game.set_player_position(game.landscape.KEEP);game.castle.enter()
   elif id=="frost-cave":game.set_player_position(game.castle.caves.SITES[id].point);game.castle.caves.enter(id)
   else:game.set_player_position(game.landscape.realms.Catalog.ZONES[id].gate);game.castle.enter_region(id)
   var target:Vector2i=game.castle.features()["mechanism" if id=="frost-cave" else "key"].cell
   var path=game.astar.get_id_path(game.dungeon_map.start,target)
   for cell in path:game.set_player_position(game.cell_center(cell));game.atlas.observe()
   game.hud.show_character("map");await capture(("portrait-" if dims.x<dims.y else "landscape-")+id)
 game.queue_free();await process_frame;game=null;await process_frame
 print("DUNGEON ATLAS VISUALS CAPTURED");quit()
