extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
	checks+=1
	if ok:print("PASS: "+message)
	else:failures+=1;push_error("FAIL: "+message)
func structure(kind:String,at:Vector2,fuel:float=90) -> Dictionary:
	return {"kind":kind,"x":at.x,"y":at.y,"rotation":1,"fuel":fuel,"open":false,"stash":{}}
func reset():
	game.hero.dungeon=null;game.hero.survival.materials={};game.hero.survival.structures=[];game.survival.moving={};game.enemies.clear();game.build_recipe=""
	game.set_player_position(Vector2.ZERO);game.hud.resume();game.set_physics_process(false)
func button(title:String) -> Button:
	for node in game.hud.content.find_children("*","Button",true,false):
		if node.text==title:return node
	return null
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;await process_frame
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false);game.hero.auto=false
	var camp=game.survival
	reset();camp.add("Wood",30)
	check(camp.batch_limit("Plank")==15,"Maximum parts batch is limited by real carried ingredients")
	check(camp.craft_batch("Plank",5) and camp.count("Wood")==20 and camp.count("Plank")==5,"Five planks spend ten wood and produce exactly five parts")
	var before=game.hero.duplicate(true)
	check(not camp.craft_batch("Plank",11) and game.hero==before,"An unaffordable batch produces and spends nothing")
	check(camp.batch_reason("Plank",11).contains("2 more Wood"),"Batch shortage reports the full requested ingredient deficit")
	for amount in [-1,0,100,999999]:
		check(not camp.craft_batch("Plank",amount) and game.hero==before,"Invalid quantity is rejected without state changes: "+str(amount))
	check(not camp.craft_batch("invented",1) and game.hero==before,"Unknown recipes spend nothing")
	check(not camp.craft_batch("Workbench",2) and not camp.craft_batch("Iron sword",2),"Buildings and gear retain their single-item rules")
	reset();camp.add("Reeds",15)
	check(camp.craft_batch("Reed rope",5) and camp.count("Rope")==5 and camp.count("Reeds")==0 and not game.hero.survival.materials.has("Reed rope"),"Aliased recipes produce the actual Rope material")
	reset();camp.add("Wood",500);camp.add("Plank",99997)
	check(camp.batch_limit("Plank")==2,"Maximum respects remaining output stack capacity")
	before=game.hero.duplicate(true);check(not camp.craft_batch("Plank",3) and game.hero==before,"Output overflow cannot consume ingredients")
	check(camp.craft_batch("Plank",2) and camp.count("Plank")==99999 and camp.count("Wood")==496,"Exact remaining capacity is filled without discarding materials")
	reset();camp.add("Wood",1000);check(camp.batch_limit("Plank")==99,"One batch is bounded to ninety-nine items")
	reset();camp.add("Berries",30);game.hero.survival.structures=[structure("Campfire",Vector2(70,0))]
	game.hero.hp=40;game.hero.mp=20;game.hero.mode="survival";game.hero.needs.hunger=12;game.hero.needs.water=18
	var hp=game.hero.hp;var mana=game.hero.mp;var needs=game.hero.needs.duplicate(true);var clock=game.hero.worldTime
	check(camp.craft_batch("Roasted berries",5) and camp.count("Berries")==15 and camp.count("Roasted berries")==5,"Batch cooking produces food with exact ingredient costs")
	check(game.hero.hp==hp and game.hero.mp==mana and game.hero.needs==needs and game.hero.worldTime==clock,"Cooking does not eat food, heal, refill needs or advance the paused clock")
	check(game.hero.journey.cooked,"Batch cooking preserves the tutorial cooking milestone")
	var loaded=Data.read_save();check(loaded.survival.materials["Roasted berries"]==5 and loaded.survival.materials.Berries==15,"Batch outputs and paid costs persist through actual save reload")
	check(camp.eat("Roasted berries") and camp.count("Roasted berries")==4 and game.hero.hp>hp and game.hero.needs.hunger>12,"Cooked batch food works with the existing eat/Survival system")
	game.hero.survival.structures.append(structure("Wall",Vector2(35,0)))
	for recipe in ["Roasted berries","Warm tea","Roasted meat","Herbal stew","Grilled fish","Fisher stew"]:
		for material in camp.RECIPES[recipe].cost:camp.add(material,20)
		before=game.hero.duplicate(true)
		check(camp.reason(recipe).contains("wall") and not camp.craft(recipe) and not camp.craft_batch(recipe,2) and game.hero==before,"Walls block single and batch cooking: "+recipe)
	reset();game.hero.survival.structures=[structure("Campfire",Vector2(20,0),0),structure("Campfire",Vector2(80,0),90)];camp.add("Berries",6)
	check(camp.craft_batch("Roasted berries",2),"A closer unlit fire does not hide a reachable lit fire")
	reset();game.hero.survival.structures=[structure("Campfire",Vector2(70,0)),structure("Wall",Vector2(35,0)),structure("Campfire",Vector2(-70,0))];camp.add("Berries",6)
	check(camp.craft_batch("Roasted berries",2),"A blocked fire does not hide a second reachable fire")
	reset();game.hero.survival.structures=[structure("Campfire",Vector2(70,0),0)];camp.add("Berries",6);before=game.hero.duplicate(true)
	check(not camp.craft_batch("Roasted berries",2) and game.hero==before,"An extinguished fire cannot cook or charge ingredients")
	reset();game.hero.survival.structures=[structure("Workbench",Vector2(70,0)),structure("Wall",Vector2(35,0))];camp.add("Iron",20);camp.add("Wood",20);before=game.hero.duplicate(true)
	check(camp.reason("Iron sword").contains("wall") and not camp.craft("Iron sword") and game.hero==before,"Workbench crafting requires a reachable station")
	game.hero.survival.structures.append(structure("Workbench",Vector2(-70,0)))
	check(camp.craft("Iron sword") and game.hero.inventory.back().name=="Iron sword","A second reachable bench retains real single-item gear crafting")
	reset();camp.moving=structure("Wall",Vector2(100,0));camp.add("Wood",20);before=game.hero.duplicate(true)
	check(camp.reason("Plank").contains("placement") and camp.batch_limit("Plank")==0 and not camp.craft("Plank") and not camp.craft_batch("Plank",5) and game.hero==before,"Moving a structure cannot bypass costs for single or batch parts")
	reset();game.hero.exploration.discovered.swamp=false;camp.add("Glowcap",30);camp.add("Herbs",30);game.hero.survival.structures=[structure("Campfire",Vector2(70,0))]
	check(camp.batch_limit("Bog remedy")==0 and not camp.craft_batch("Bog remedy",2),"Regional batch recipes require their existing discovery")
	game.hero.exploration.discovered.swamp=true;check(camp.craft_batch("Bog remedy",2) and camp.count("Bog remedy")==2,"Discovered regional food can be cooked in a real batch")
	reset();camp.add("Wood",20);var snapshot=JSON.stringify(game.hero)
	game.hud.show_craft_batch("Plank",5)
	check(JSON.stringify(game.hero)==snapshot and not game.playing,"Opening the batch preview pauses and spends nothing")
	button("Back to crafting").pressed.emit();check(JSON.stringify(game.hero)==snapshot,"Leaving the preview does not spend ingredients")
	for dims in [Vector2i(1080,2400),Vector2i(2400,1080)]:
		root.size=dims;game.adapt_screen();await process_frame;await process_frame;game.hud.layout()
		reset();camp.add("Wood",20);game.hud.show_craft_batch("Plank",5);await process_frame;await process_frame
		button("+").pressed.emit();var stepped=button("Make 6 · Plank")!=null;button("−").pressed.emit()
		check(stepped and button("Make 5 · Plank")!=null and camp.count("Wood")==20,"Plus/minus selects exact quantities without spending")
		check(button("Make 5 · Plank")!=null and not button("Make 5 · Plank").disabled,"Batch confirmation is available in "+str(dims))
		check(game.hud.content.get_global_rect().size.x<=game.hud.scroll.get_global_rect().size.x+1,"Batch controls fit the native scrolling menu in "+str(dims))
		button("Make 5 · Plank").pressed.emit();check(camp.count("Plank")==5 and camp.count("Wood")==10,"Native UI confirmation crafts the shown quantity")
		button("10").pressed.emit();check(button("Make 10 · Plank").disabled,"An unaffordable preset disables confirmation")
		button("Use maximum available · 5").pressed.emit();check(not button("Make 5 · Plank").disabled,"Maximum selects the actually affordable remaining quantity")
		# Simulate ingredients changing after preview: execution must revalidate.
		camp.add("Wood",-10);snapshot=JSON.stringify(game.hero);button("Make 5 · Plank").pressed.emit()
		check(JSON.stringify(game.hero)==snapshot,"A stale UI confirmation cannot overspend changed ingredients")
	print("%d CRAFTING BATCH CHECKS; %d FAILURES" % [checks,failures]);game.queue_free();await process_frame;quit(1 if failures else 0)
