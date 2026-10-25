extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var output=OS.get_environment("RUNEBOUND_VISUAL_OUTPUT")
class Creature extends Node2D:
	var art
	var enemy:Dictionary
	func _draw():art.draw(self,enemy,Vector2.ZERO,1,Vector2.RIGHT*500)
class Bestiary extends Node2D:
	var art=preload("res://scripts/enemy_visuals.gd").new()
	var font=ThemeDB.fallback_font
	func _ready():
		for i in range(art.KINDS.size()):
			var id=art.KINDS[i];var creature=Creature.new();creature.art=art
			creature.enemy={"type":id,"boss":id in ["root_warden","hollow_heart"],"flash":0.0,"slow":0.0}
			if id=="root_warden":creature.enemy.named="The Root Warden"
			if id=="hollow_heart":creature.enemy.chapter_boss=true
			creature.position=Vector2(105+i%7*178,285+int(i/7)*285);creature.scale=Vector2.ONE*(1.3 if creature.enemy.boss else 1.9);add_child(creature)
	func _draw():
		draw_rect(Rect2(0,0,1280,720),Color("101d25"))
		draw_string(font,Vector2(42,50),"RUNEBOUND  /  DREADWOOD",HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color("e2c68b"))
		draw_string(font,Vector2(42,78),"New in-game creature art · Every graphics quality",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("97b8b3"))
		for i in range(art.KINDS.size()):
			var id=art.KINDS[i];var at=Vector2(105+i%7*178,285+int(i/7)*285)
			draw_rect(Rect2(at-Vector2(77,165),Vector2(154,210)),Color("1a2c34"))
			draw_string(font,at+Vector2(-68,30),id.replace("_"," ").capitalize(),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("d4d5bd"))
func _initialize():call_deferred("run")
func capture(name:String):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
func run():
	DirAccess.make_dir_recursive_absolute(output);root.size=Vector2i(540,1200)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false);game.hero.auto=false;game.audio.enabled=false;game.audio.music.stop()
	game.hero.worldTime=180;game.enemies.clear();game.set_player_position(Vector2.ZERO);game.camera.position=Vector2.ZERO;game.camera.force_update_scroll()
	game.graphics.set_quality("Performance");game.world.refresh(true)
	for info in [["wolf",Vector2(-80,-80)],["archer",Vector2(110,-60)],["goblin",Vector2(15,-135)],["slime",Vector2(-110,60)]]:
		var e=game.create_enemy(info[1],2,info[0]);e.aggro=5;game.enemies.append(e)
	game.update_enemy_attack(game.enemies[1],.01);game.hud.toast_time=0;game.hud.update_hud();await capture("forest-performance-portrait")
	game.enter_dungeon();game.hero.dungeon.seed=12345;game.build_floor(true);game.enemies.clear()
	var at=game.cell_center(game.dungeon_map.start);game.set_player_position(at);game.camera.position=at;game.camera.force_update_scroll()
	var boss=game.create_enemy(at+Vector2(75,-25),7,"guardian",true);boss.named="The Hollow Heart";boss.chapter_boss=true;game.enemies.append(boss)
	game.update_enemy_attack(boss,.01);game.hud.toast_time=0;game.hud.update_hud();await capture("hollow-heart-performance-portrait")
	root.size=Vector2i(1200,540);await process_frame;game.adapt_screen();game.hud.layout();game.graphics.set_quality("Balanced");game.hud.update_hud();await capture("hollow-heart-balanced-landscape")
	game.queue_free();game=null;await process_frame;root.content_scale_size=Vector2i(1280,720);root.size=Vector2i(1280,720)
	var board=Bestiary.new();root.add_child(board);await capture("creature-preview");board.queue_free();await process_frame;quit()
