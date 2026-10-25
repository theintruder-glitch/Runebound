extends SceneTree
const Data=preload("res://scripts/data.gd")
const Visuals=preload("res://scripts/enemy_visuals.gd")
var checks=0
var failures=0
var game
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
	checks+=1
	if ok:print("PASS: "+message)
	else:failures+=1;push_error("FAIL: "+message)
func run():
	root.size=Vector2i(1080,2400)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;await process_frame
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false);game.hero.auto=false;game.enemies.clear()
	var art=game.world.enemy_visuals
	check(art.textures.size()==13,"All 13 creature designs load in the actual game renderer")
	var image=Visuals.ATLAS.get_image()
	check(image.get_size()==Vector2i(640,480),"Creature atlas remains under 1.3 MB uncompressed RGBA")
	for id in art.KINDS:
		var texture=art.textures[id];var region=texture.region
		var visible=0;var transparent=0
		for x in range(int(region.position.x),int(region.end.x),4):
			for y in range(int(region.position.y),int(region.end.y),4):
				if image.get_pixel(x,y).a>.1:visible+=1
				else:transparent+=1
		check(visible>60 and transparent>100 and texture.filter_clip,id+" has visible artwork, a transparent margin and clipped atlas sampling")
		var e=game.create_enemy(Vector2.ZERO,3,id);game.enemies.append(e)
		check(art.kind(e)==id or id in ["root_warden","hollow_heart"],id+" selects its own art instead of sharing another creature")
	var boss=game.create_enemy(Vector2.ZERO,5,"guardian",true);boss.named="The Root Warden"
	check(art.kind(boss)=="root_warden","The Root Warden uses the thorned wood-and-heart design")
	boss.chapter_boss=true;check(art.kind(boss)=="hollow_heart","The Hollow Heart has its own corrupted-heart design")
	check(art.bounds(boss,Vector2.ZERO).size.x==96 and art.bounds(game.enemies[0],Vector2.ZERO).size.x==64,"Boss silhouettes are larger than ordinary creatures")
	for id in ["tree","rock","chest","chest_open"]:
		check(game.world.textures[id].region.size==Vector2(128,192),id+" uses the detailed environment atlas")
	check(game.world.textures.tree.atlas.get_size()==Vector2(512,192),"Environment texture budget stays below 0.4 MB RGBA")
	var before=JSON.stringify(game.hero)
	for dims in [Vector2i(1080,2400),Vector2i(2400,1080)]:
		root.size=dims;game.adapt_screen();await process_frame;await process_frame
		game.hud.layout();game.hud.show_graphics_settings();await process_frame
		check(not game.playing and game.hud.current_page=="graphics","Graphics menu pauses safely in "+str(dims))
		check(game.hud.content.get_global_rect().size.x<=game.hud.scroll.get_global_rect().size.x+1,"Graphics controls fit the native scroll area in "+str(dims))
		for value in game.graphics.LEVELS:
			game.graphics.set_quality(value);game.graphics._process(0)
			check(game.graphics.enhanced()==(value!="Performance"),value+" is available on mobile in "+str(dims))
			if value=="Performance":check(game.graphics.lights.all(func(light):return not light.enabled),"Performance disables real lights while retaining all new enemy art")
			else:check(game.graphics.lights.filter(func(light):return light.enabled).size()<=2,"Battery saver bounds the soft-light pool")
			game.world.queue_redraw();game.world.scenery.queue_redraw();await process_frame;await process_frame
			check(game.world.enemy_visuals.textures.size()==13,"All creature designs remain loaded at "+value)
	game.graphics.set_quality("Balanced")
	var clone=game.GraphicsScript.new();clone.game=game;game.add_child(clone)
	check(clone.quality=="Balanced","A phone user's selected quality persists across graphics initialization")
	clone.queue_free();game.graphics.set_quality("Performance")
	var config=ConfigFile.new();config.load("user://graphics.cfg");check(config.get_value("graphics","quality","")=="Performance","Performance selection is persisted separately from the character")
	check(JSON.stringify(game.hero)==before and not Data.migrate(JSON.parse_string(before)).is_empty(),"Graphics changes preserve character JSON, progression and save compatibility")
	game.enter_dungeon();game.enemies.clear();game.world.refresh(true);game.world.queue_redraw();await process_frame;await process_frame
	check(game.world.terrain.get_used_cells().size()==game.dungeon_map.size*game.dungeon_map.size,"New floor/wall art retains every dungeon collision tile")
	print("%d DREADWOOD CHECKS; %d FAILURES" % [checks,failures]);game.queue_free();await process_frame;quit(1 if failures else 0)
