extends SceneTree
const Data=preload("res://scripts/data.gd")
var checks=0
var game
func _initialize(): call_deferred("run")
func check(ok:bool,message:String):
	if not ok:
		push_error("FAIL: "+message);quit(1);assert(ok,message)
	checks+=1;print("PASS: "+message)
func structure(kind:String,pos:Vector2) -> Dictionary:
	return {"kind":kind,"x":pos.x,"y":pos.y,"rotation":0,"fuel":0.0,"open":false,"stash":{}}
func advance(seconds:float):
	game.hero.worldTime+=seconds;game.farming.tick(seconds)
func descendants(node:Node) -> Array:
	var out:Array=[]
	for child in node.get_children(): out.append(child);out.append_array(descendants(child))
	return out
func find_button(prefix:String) -> Button:
	for node in descendants(game.hud.content):
		if node is Button and node.text.begins_with(prefix): return node
	return null
func settle(): await process_frame;await process_frame
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size=Vector2i(1080,2400)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false)
	game.enemies.clear();game.hero.auto=false;game.spawn_timer=100000
	var farm=game.farming;var camp=game.survival
	check(farm.plots().is_empty(),"Existing and new characters do not gain free gardens")
	var old=Data.fresh("Ranger");old.survival.structures=[structure("Campfire",Vector2.ZERO)]
	check(not Data.migrate(old).is_empty() and old.survival.structures.size()==1,"Existing camp structures migrate without changes")
	old.survival.structures=[structure("Garden",Vector2.ZERO)]
	check(not Data.migrate(old).is_empty() and old.survival.structures[0].crop=="" and old.survival.structures[0].growth==0,"Garden save defaults are safe empty soil")
	check(not camp.craft("Garden"),"Garden construction requires materials")
	for material in ["Wood","Stone","Fiber","Berries","Herbs","Glowcap"]: camp.add(material,100)
	game.set_player_position(Vector2.ZERO);game.facing=Vector2.DOWN
	var wood=camp.count("Wood");var stone=camp.count("Stone");var fiber=camp.count("Fiber")
	game.begin_build("Garden");check(game.build_recipe=="Garden" and farm.plots().is_empty(),"Placement ghost spends no materials")
	game.interact()
	check(farm.plots().size()==1 and game.build_recipe=="","The normal PLACE action constructs a garden")
	check(camp.count("Wood")==wood-4 and camp.count("Stone")==stone-2 and camp.count("Fiber")==fiber-2,"Garden construction consumes the displayed costs exactly once")
	var plot=farm.plots()[0]
	check(farm.owns(plot) and not farm.owns(plot.duplicate()),"Crop actions require the actual stored plot, not a copied dictionary")
	check(not camp.blocked(camp.at(plot),12),"Garden plots never block walking")
	check(not camp.craft("Garden"),"Gardens cannot overlap existing structures")
	check(farm.nearest()==plot,"Nearby garden can be found from the world")
	# Camp menus can tend within 110 units, but the world prompt should only
	# take over close to the soil so nearby wild materials remain gatherable.
	camp.nodes=[{"id":"farm-input-test","kind":"Herbs","pos":Vector2.ZERO}]
	game.chest_near={};game.update_interaction()
	check(game.hud.interaction.text=="GATHER HERBS","A garden at menu range does not hide nearby wild resources")
	game.interact()
	check(camp.count("Herbs")>100 and plot.crop=="","The world gather action still works beside a garden")
	game.set_player_position(Vector2(0,64))
	game.update_interaction();check(game.hud.interaction.text=="TEND GARDEN","An empty garden has a clear world interaction")
	game.interact();check(game.hud.current_page=="farm" and not game.playing,"World interaction opens the paused garden menu")
	game.hud.resume()
	game.set_player_position(Vector2.ZERO)
	check(not farm.plant(plot,"Wood"),"Unknown crops cannot consume materials")
	check(not farm.plant(plot.duplicate(),"Berries"),"Copied plot cannot consume planting ingredients")
	game.set_player_position(Vector2(500,500));var berries=camp.count("Berries")
	check(not farm.plant(plot,"Berries") and camp.count("Berries")==berries,"Remote planting is refused without consuming ingredients")
	game.set_player_position(Vector2.ZERO)
	var wall=structure("Wall",Vector2(0,48));game.hero.survival.structures.append(wall)
	check(not farm.plant(plot,"Berries") and farm.nearest().is_empty(),"A closed wall prevents tending a plot through it")
	game.hero.survival.structures.erase(wall)
	game.hero.survival.materials.Berries=1
	check(not farm.plant(plot,"Berries"),"Planting requires two carried ingredients")
	var storage=structure("Storage",Vector2(80,0));storage.stash={"Berries":20};game.hero.survival.structures.append(storage)
	check(not farm.plant(plot,"Berries"),"Stored ingredients must be withdrawn before planting")
	game.hero.survival.structures.erase(storage);game.hero.survival.materials.Berries=100
	check(not farm.plant(plot,"Glowcap"),"Glowcap cultivation requires discovering the Veil Altar")
	check(farm.plant(plot,"Berries") and camp.count("Berries")==98,"Planting berries consumes exactly two and starts growth")
	check(plot.crop=="Berries" and plot.growth==0 and farm.stage(plot)==1,"A planted garden begins with visible seedlings")
	check(not farm.plant(plot,"Herbs") and not farm.harvest(plot),"Occupied and unripe crops cannot be overwritten or harvested")
	game.playing=true;game.tick(.4)
	check(is_equal_approx(plot.growth,.5),"The actual game tick grows spring crops at 125 percent")
	var revision=camp.revision
	advance(1)
	check(camp.revision==revision and farm.stage(plot)==1,"Substage growth does not invalidate retained scenery")
	advance(70.6)
	check(farm.stage(plot)==2 and camp.revision==revision+1,"Half-grown crops redraw once as larger plants")
	var growth=plot.growth;game.pause_game();game.set_physics_process(true);await create_timer(.12).timeout;game.set_physics_process(false)
	check(plot.growth==growth,"Menus pause crop growth through native physics callbacks")
	game.save_game();var saved=Data.read_save()
	check(saved.survival.structures[0].crop=="Berries" and is_equal_approx(saved.survival.structures[0].growth,growth),"Crop type and partial growth survive a disk save")
	game.start_character(saved);game.enemies.clear();plot=farm.plots()[0]
	check(is_equal_approx(plot.growth,growth),"Loading a character performs no offline catch-up")
	check(not farm.harvest(saved.survival.structures[0].duplicate()),"Stale saved plot copies cannot duplicate harvests")
	game.hero.worldTime=3600;advance(8)
	check(is_equal_approx(plot.growth,growth+6),"Winter crops continue growing at 75 percent")
	check(not camp.dismantle(plot),"Dismantling protects growing crops")
	game.set_player_position(Vector2(160,160));game.facing=Vector2.DOWN
	var crop_before=plot.crop;var growth_before=plot.growth
	game.begin_build("Garden",plot);game.build_rotation=1;game.interact()
	check(farm.plots().size()==1 and plot.rotation==1 and plot.x==160 and plot.y==256,"Garden moves and rotates through the existing building controls")
	check(plot.crop==crop_before and plot.growth==growth_before,"Moving a garden preserves its crop and growth")
	check(camp.count("Wood")==wood-4,"Moving a garden spends no new construction materials")
	var return_pos=game.player_position()
	game.set_player_position(Vector2(1900,0));advance(4)
	check(is_equal_approx(plot.growth,growth_before+3),"A distant outdoor garden grows while the hero explores caves")
	game.hero.dungeon={"floor":1};advance(4)
	check(is_equal_approx(plot.growth,growth_before+6),"Garden growth continues while the hero explores a dungeon")
	check(not farm.harvest(plot) and farm.nearest().is_empty(),"Underground menus cannot tend outdoor gardens")
	game.hero.dungeon=null;game.set_player_position(return_pos)
	berries=camp.count("Berries")
	check(farm.clear_crop(plot) and camp.count("Berries")==berries+2 and plot.crop=="" and plot.growth==0,"Clearing refunds only planting ingredients and resets growth")
	check(not farm.clear_crop(plot) and camp.count("Berries")==berries+2,"Clearing an empty plot cannot duplicate ingredients")
	game.hero.exploration.discovered.swamp=true
	for crop in ["Berries","Herbs","Glowcap"]:
		game.hero.worldTime=1200;var start=camp.count(crop)
		check(farm.plant(plot,crop),"Plant available crop: "+crop)
		advance(600)
		check(farm.ready(plot) and farm.stage(plot)==3 and farm.ready_count()==1,"Crop ripens and becomes visually ready: "+crop)
		check(plot.growth==farm.CROPS[crop].seconds,"Growth stops at the crop's mature duration: "+crop)
		game.save_game();var ripe_save=Data.read_save()
		check(farm.ready(ripe_save.survival.structures[0]),"A ripe crop survives save validation: "+crop)
		advance(4800)
		check(farm.ready(plot),"Ripe crops remain harvestable across a full year: "+crop)
		game.set_player_position(Vector2(900,900))
		check(not farm.harvest(plot),"Harvest requires returning to the plot: "+crop)
		game.set_player_position(return_pos)
		var before=camp.count(crop)
		game.hero.survival.materials[crop]=99999
		check(not farm.harvest(plot) and farm.ready(plot),"Full supplies preserve the pending crop: "+crop)
		game.hero.survival.materials[crop]=before
		var expected=6 if crop=="Berries" else 5
		check(farm.harvest(plot) and camp.count(crop)==start-2+expected,"Harvest gives the advertised ingredients exactly once: "+crop)
		check(plot.crop=="" and plot.growth==0 and not farm.harvest(plot),"Harvest empties a reusable plot without duplicate rewards: "+crop)
		var harvest_save=Data.read_save()
		check(harvest_save.survival.structures[0].crop=="" and harvest_save.survival.materials[crop]==camp.count(crop),"Harvest reward and emptied plot are saved together: "+crop)
	game.hero.worldTime=1199;farm.plant(plot,"Berries");advance(2)
	check(is_equal_approx(plot.growth,2.25),"Growth across a season boundary uses both seasonal rates")
	farm.clear_crop(plot);game.hero.worldTime=4799;farm.plant(plot,"Herbs");advance(2)
	check(is_equal_approx(plot.growth,2),"Winter-to-spring growth handles the annual boundary")
	game.hero.survival.materials.Herbs=99999
	check(not farm.clear_crop(plot) and plot.crop=="Herbs","A full bag prevents clearing without losing planted ingredients")
	game.hero.survival.materials.Herbs=100;farm.clear_crop(plot)
	game.set_player_position(Vector2(1800,0));game.facing=Vector2.DOWN
	check(camp.reason("Garden",false).contains("outdoor"),"Cave ground cannot receive new gardens")
	var original=game.hero.survival.structures.duplicate()
	game.hero.survival.structures=[]
	for i in range(12):
		var other=structure("Garden",Vector2(i*96,900));other.crop="";other.growth=0.0;game.hero.survival.structures.append(other)
	game.set_player_position(Vector2.ZERO)
	check(camp.reason("Garden",false).contains("12 plots") and not camp.craft("Garden"),"Garden construction is bounded to twelve plots")
	var capped=game.hero.survival.structures[0]
	game.begin_build("Garden",capped)
	check(camp.reason("Garden").is_empty(),"An existing garden can still be moved at the plot limit")
	game.cancel_build();game.hero.survival.structures=original
	game.set_player_position(return_pos)
	game.hero.survival.structures.append(structure("Campfire",return_pos+Vector2(40,0)));game.hero.survival.structures.back().fuel=90
	check(camp.craft("Warm tea") and camp.count("Warm tea")==1,"Garden ingredients feed the existing cooking recipes")
	game.set_player_position(game.trader.POSITION);var herbs=camp.count("Herbs");var gold=game.hero.gold
	check(game.trader.sell_supplies("Herbs",1) and camp.count("Herbs")==herbs-1 and game.hero.gold>gold,"Harvested ingredients can be sold through the existing trader")
	game.set_player_position(return_pos)
	for dims in [Vector2i(1080,2400),Vector2i(2400,1080)]:
		root.size=dims;game.adapt_screen();await settle()
		game.hud.show_character("farm");await settle()
		var plant=find_button("Plant Berries")
		check(plant!=null and not plant.disabled,"Planting is accessible in the garden menu "+str(dims))
		plant.pressed.emit();await settle()
		check(plot.crop=="Berries" and not game.playing,"Plant button updates the correct plot and keeps menus paused "+str(dims))
		check(find_button("Clear crop")!=null and find_button("Dismantle").disabled,"Growing plot UI offers safe clearing and protects dismantling "+str(dims))
		var within_bounds=true
		for node in descendants(game.hud.content):
			if node is Control and node.size.x>0:
				within_bounds=within_bounds and node.get_global_rect().end.x<=game.hud.scroll.get_global_rect().end.x+2
		check(within_bounds,"Garden menu stays within its horizontal bounds "+str(dims))
		find_button("Clear crop").pressed.emit();await settle()
		check(plot.crop=="","Clear button resets the correct plot "+str(dims))
	game.hero.worldTime=1200;farm.plant(plot,"Berries");advance(180)
	game.set_player_position(camp.at(plot)-Vector2(0,24))
	game.hud.resume();game.update_interaction()
	check(game.hud.interaction.text=="GARDEN / HARVEST","Ripe gardens advertise harvest from the world")
	game.interact();check(find_button("Harvest Berries")!=null and not find_button("Harvest Berries").disabled,"World garden interaction exposes the ready harvest")
	find_button("Harvest Berries").pressed.emit();check(plot.crop=="","Harvest button rewards and clears the selected plot")
	game.hud.resume();game.camera.position=camp.at(plot);game.world.profile_enabled=true
	for crop in ["Berries","Herbs","Glowcap"]:
		farm.plant(plot,crop)
		for seconds in [0.0,100.0,600.0]:
			advance(seconds);game.world.refresh(true);game.world.queue_redraw();await settle()
		check(game.world.profile_draw_samples.size()>0,"Native scenery draws crop stages: "+crop)
		farm.harvest(plot)
	var owned_wood=camp.count("Wood");var owned_stone=camp.count("Stone");var owned_fiber=camp.count("Fiber")
	check(camp.dismantle(plot) and farm.plots().is_empty(),"An empty garden dismantles through existing camp management")
	check(camp.count("Wood")==owned_wood+2 and camp.count("Stone")==owned_stone+1 and camp.count("Fiber")==owned_fiber+1,"Dismantling refunds the existing half-material rule")
	check(not farm.plant(plot,"Berries"),"A removed plot cannot be reused by a stale UI action")
	for malformed in ["crop","container","growth_type","negative","infinite","overflow","empty_growth","too_many"]:
		var bad=Data.fresh("Warrior");var garden=structure("Garden",Vector2.ZERO);garden.crop="Berries";garden.growth=1.0;bad.survival.structures=[garden]
		match malformed:
			"crop": garden.crop="Iron"
			"container": garden.crop=[]
			"growth_type": garden.growth="one"
			"negative": garden.growth=-1
			"infinite": garden.growth=INF
			"overflow": garden.growth=181
			"empty_growth": garden.crop=""
			"too_many":
				for i in range(12): bad.survival.structures.append(garden.duplicate())
		check(Data.migrate(bad).is_empty(),"Malformed crop save rejected: "+malformed)
	print(str(checks)+" FARMING CHECKS PASSED")
	quit()
