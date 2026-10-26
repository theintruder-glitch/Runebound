extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
func _initialize():call_deferred("run")
func settle():
 for i in range(6):await process_frame
 await RenderingServer.frame_post_draw
func veteran():
 var h=Data.fresh("Mage");h.chapter.accepted=true;h.chapter.clues={"watch":true,"cart":true,"grove":true};h.chapter.translated=true;h.chapter.cleared=true;h.chapter.claimed=true
 h.forge_chapter={"accepted":true,"inspected":true,"cleared":true,"claimed":true};h.exploration.challenges.caves=true;return h
func capture(name_value:String):
 await settle();root.get_texture().get_image().save_png("res://builds/mire-visuals/"+name_value+".png")
func run():
 DirAccess.make_dir_recursive_absolute("res://builds/mire-visuals")
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
 for dims in [Vector2i(600,1100),Vector2i(1152,648)]:
  root.size=dims;await settle();game.adapt_screen();game.hud.layout()
  game.start_character(veteran());game.set_physics_process(false);game.hero.auto=false;game.set_player_position(game.trader.POSITION);game.mire.accept()
  var prefix="portrait" if dims.x<dims.y else "landscape"
  game.hud.show_character("mire");await capture(prefix+"-journal")
  game.hud.resume();game.set_physics_process(false)
  for id in game.mire.CLUES:game.hero.mire_chapter.clues[id]=true
  game.hero.exploration.challenges.swamp=true;game.hero.opened["blackmire-cleared"]=true
  game.set_player_position(game.landscape.realms.Catalog.ZONES.blackmire.gate);game.castle.enter_region("blackmire");game.hero.dungeon.floor=2;game.build_floor(true)
  var p=game.cell_center(game.mire.archive_cell());game.set_player_position(p+Vector2(0,35));game.camera.position=game.player_position();game.camera.reset_smoothing();game.world.refresh(true);game.atlas.observe(true);game.update_interaction();game.hud.update_hud();game.hud._process(0);game.hud.toast_label.text=""
  await capture(prefix+"-testament")
  game.hud.show_character("map");await capture(prefix+"-atlas")
 game.queue_free();await process_frame;game=null;await process_frame
 print("MIRE CHAPTER VISUALS CAPTURED");quit()
