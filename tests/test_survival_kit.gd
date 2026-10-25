extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var checks=0
var failures=0
func _initialize(): call_deferred("run")
func check(ok:bool,message:String):
	checks+=1
	if not ok: failures+=1;push_error("FAIL: "+message)
	else: print("PASS: "+message)
func structure(kind:String,pos:Vector2=Vector2.ZERO) -> Dictionary:
	return {"kind":kind,"x":pos.x,"y":pos.y,"rotation":0,"open":false,"fuel":0.0,"stash":{}}
func descendants(node:Node) -> Array:
	var nodes=[]
	for child in node.get_children(): nodes.append(child);nodes.append_array(descendants(child))
	return nodes
func settle(): await process_frame;await process_frame
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
	var old=Data.fresh("Warrior");old.erase("kit")
	var character=Data.migrate(old)
	check(character.kit.waterskin==false and character.kit.bedroll==false and character.kit.cloak==false,"Existing saves receive an empty kit without free items")
	for key in ["waterskin","cloak","bedroll","cloak_worn"]:
		var invalid=character.duplicate(true);invalid.kit[key]=1
		check(Data.migrate(invalid).is_empty(),"Kit ownership rejects non-boolean "+key)
	for value in [-1,INF,NAN,"bad",null,character.worldTime+121]:
		var invalid=character.duplicate(true);invalid.kit.rest_until=value
		check(Data.migrate(invalid).is_empty(),"Malformed bedroll cooldown is rejected")
	var invalid=character.duplicate(true);invalid.kit.cloak_worn=true
	check(Data.migrate(invalid).is_empty(),"An unowned cloak cannot be worn in imported saves")
	invalid=character.duplicate(true);invalid.needs.flask=6
	check(Data.migrate(invalid).is_empty(),"Six drinks require owning the waterskin")
	game.start_character(character);game.set_physics_process(false);game.enemies.clear();game.hero.auto=false;game.spawn_timer=100000
	var kit=game.kit;var camp=game.survival;var exp=game.expedition
	check(kit.capacity()==3 and not kit.craft("unknown"),"Default flask remains three drinks and unknown recipes are refused")
	check(not kit.craft("bedroll"),"Missing materials cannot create kit items")
	for material in ["Hide","Rope","Fiber"]: camp.add(material,100)
	check(not kit.craft("waterskin") and camp.count("Hide")==100,"Waterskin requires a workbench without spending ingredients")
	game.hero.survival.structures=[structure("Workbench",Vector2(60,0)),structure("Wall",Vector2(30,0))]
	check(not kit.craft("waterskin"),"A wall prevents reaching the workbench")
	game.hero.survival.structures=[structure("Workbench",Vector2(60,0))]
	var bag=game.hero.inventory.duplicate(true);var weapon=game.hero.equipped.duplicate(true)
	game.hero.needs.flask=1
	check(kit.craft("waterskin") and kit.capacity()==6,"Crafting a waterskin doubles capacity")
	check(camp.count("Hide")==96 and camp.count("Rope")==98,"Waterskin spends the exact carried costs")
	check(game.hero.needs.flask==1,"Crafting adds capacity without creating water")
	check(not kit.craft("waterskin") and camp.count("Hide")==96,"A crafted kit item cannot consume materials again")
	game.expedition.switch_mode("survival");game.set_player_position(exp.SPRING)
	check(exp.drink(true) and game.hero.needs.flask==6,"The actual spring fills all six drinks")
	game.hero.needs.water=0
	check(exp.drink() and game.hero.needs.flask==5 and game.hero.needs.water==45,"The larger waterskin still consumes a single drink per use")
	check(not Data.migrate(JSON.parse_string(JSON.stringify(game.hero))).is_empty(),"An upgraded flask survives JSON export and validation")
	game.set_player_position(Vector2.ZERO)
	check(kit.craft("cloak") and kit.wearing_cloak(),"A crafted cloak is worn immediately")
	game.hero.worldTime=3600;game.hero.warmUntil=0
	check(exp.exposure_target()==30,"Cloak raises the real winter exposure target by 25")
	check(kit.toggle_cloak() and exp.exposure_target()==5,"Taking off the cloak restores normal winter exposure")
	game.hero.worldTime=1200;kit.toggle_cloak()
	check(exp.exposure_target()==100,"Wearing a cloak in summer sun increases heat")
	kit.toggle_cloak();check(exp.exposure_target()==96,"Removing the cloak reduces summer heat")
	game.hero.worldTime=3600;kit.toggle_cloak();game.hero.needs.temperature=5;game.playing=true
	exp.tick(10);check(game.hero.needs.temperature>5,"The real Survival tick applies cloak protection")
	game.hero.mode="classic";check(exp.exposure_target()==50,"Classic keeps comfortable exposure regardless of cloak")
	game.hero.mode="survival";game.hero.needs.temperature=50
	check(kit.craft("bedroll") and kit.owns("bedroll"),"A travel bedroll is crafted by hand")
	check(game.hero.inventory==bag and game.hero.equipped==weapon,"Kit does not fill the gear bag or replace weapons and armor")
	game.hero.survival.structures=[];game.hero.needs.sleep=10;game.hero.needs.hunger=100;game.hero.needs.water=100
	game.hero.hp=60;game.hero.mp=20;var respawn=game.hero.respawn.duplicate();var clock=game.hero.worldTime
	check(kit.rest() and game.hero.needs.sleep==55,"A bedroll restores 45 rest outdoors")
	check(game.hero.needs.hunger==88 and game.hero.needs.water==84,"Bedroll rest spends food and water once")
	check(game.hero.hp==60 and game.hero.mp==20 and game.hero.respawn==respawn,"Bedroll does not heal or replace the home return point")
	check(game.hero.worldTime==clock and game.hero.kit.rest_until==clock+120,"Bedroll sets an active-time cooldown without advancing the chapter")
	check(not kit.rest() and game.hero.needs.sleep==55,"Repeated rest cannot bypass the cooldown")
	game.save_game();var saved=Data.read_save();game.start_character(saved);game.set_physics_process(false);game.enemies.clear()
	check(kit.owns("bedroll") and kit.capacity()==6 and not kit.rest(),"Ownership and bedroll cooldown survive a disk reload")
	game.hero.worldTime+=120;game.hero.needs.sleep=60
	check(kit.rest() and game.hero.needs.sleep==80,"Bedroll rest is capped at 80")
	game.hero.worldTime+=120;check(not kit.rest(),"A proper bed is needed above the bedroll rest cap")
	game.hero.needs.sleep=10;game.hero.needs.hunger=11
	check(not kit.rest(),"Insufficient food prevents rest")
	game.hero.needs.hunger=100;game.hero.needs.water=15
	check(not kit.rest(),"Insufficient water prevents rest")
	game.hero.needs.water=100;game.hero.needs.temperature=10
	check(not kit.rest(),"Dangerous cold prevents field rest")
	game.hero.needs.temperature=90;check(not kit.rest(),"Dangerous heat prevents field rest")
	game.hero.needs.temperature=50;game.enemies=[game.create_enemy(Vector2(80,0),1,"goblin")]
	check(not kit.rest(),"Nearby hostile enemies prevent bedroll use")
	game.enemies[0].neutral=true;check(kit.rest(),"Peaceful wildlife does not prevent safe field rest")
	game.enemies.clear();game.hero.worldTime+=120;game.hero.needs.sleep=10;game.hero.dungeon={"floor":1}
	check(not kit.rest() and not kit.craft("waterskin"),"Dungeons prevent outdoor rest and kit crafting")
	game.hero.dungeon=null;game.build_recipe="Wall"
	check(not kit.rest(),"A building ghost prevents field rest")
	game.build_recipe="";game.hero.mode="classic";check(not kit.rest(),"Bedroll needs rules apply only in Survival")
	game.hero.mode="survival";game.hero.hp=0;check(not kit.rest(),"Defeated characters cannot use bedrolls")
	game.hero.hp=60;game.hero.survival.structures=[structure("Bed")]
	check(camp.rest(game.hero.survival.structures[0]) and game.hero.needs.sleep==100,"A permanent bed still restores full rest")
	var desktop=game.desktop.enabled
	for size in [Vector2i(480,900),Vector2i(900,480),Vector2i(1280,720)]:
		game.desktop.enabled=size.x==1280;root.size=size;game.adapt_screen();await settle()
		game.hud.show_character("kit");await settle()
		check(not game.playing and game.hud.current_page=="kit","Kit menu pauses gameplay at "+str(size))
		check(game.hud.content.size.x<=game.hud.scroll.size.x+1,"Kit content fits the scrolling menu at "+str(size))
		for button in descendants(game.hud.content).filter(func(n):return n is Button):
			check(button.size.x<=game.hud.scroll.size.x+1,"Kit button fits: "+button.text)
		game.hud.resume();game.set_physics_process(false);await settle();game.hud.layout();game.hud.update_hud();await settle()
		var panel=game.hud.advanced.needs_panel
		check(panel.position.x+panel.size.x<=game.get_viewport_rect().size.x,"Survival gauges fit the live view at "+str(size))
		if not game.desktop.enabled:
			check(not panel.get_global_rect().intersects(game.hud.skill_button.get_global_rect()),"Phone Survival gauges do not overlap the class skill")
	game.desktop.enabled=desktop
	check(not Data.migrate(JSON.parse_string(JSON.stringify(game.hero))).is_empty(),"Final kit state remains a valid portable save")
	print("%d KIT CHECKS; %d FAILURES" % [checks,failures]);quit(1 if failures else 0)
