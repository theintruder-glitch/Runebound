extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var output=OS.get_environment("RUNEBOUND_VISUAL_OUTPUT")
func _initialize():call_deferred("run")
func capture(name:String):
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output.path_join(name+".png"))
func find_setting(node:Node):
 for child in node.get_children():
  if child is Button and child.text.begins_with("Enemy crowds:"):return child
  var found=find_setting(child)
  if found!=null:return found
 return null
func run():
 DirAccess.make_dir_recursive_absolute(output);root.size=Vector2i(540,1200)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.audio.enabled=false;game.audio.music.stop();game.start_character(Data.fresh("Warrior"));game.set_physics_process(false)
 for dims in [Vector2i(540,1200),Vector2i(1200,540)]:
  root.size=dims;game.adapt_screen();game.hud.layout();game.hud.show_pause();await process_frame;await process_frame
  var setting=find_setting(game.hud.content)
  if setting!=null:game.hud.scroll.ensure_control_visible(setting)
  await capture("crowd-setting-"+("portrait" if dims.x<dims.y else "landscape"))
 game.queue_free();await process_frame;await process_frame;quit()
