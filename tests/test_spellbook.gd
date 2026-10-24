extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var checks=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
	if not ok: push_error("FAIL: "+message);quit(1);assert(ok,message)
	checks+=1;print("PASS: "+message)
func settle():await process_frame;await process_frame
func pointer(at:Vector2):
	game.desktop.pointer_screen=game.get_canvas_transform()*at;game.desktop.pointer_seen=true;game.desktop.update_aim()
func click(button:MouseButton):
	var event=InputEventMouseButton.new();event.position=game.desktop.pointer_screen;event.button_index=button;event.pressed=true;game.desktop.handle_input(event)
func enemy(at:Vector2):
	var e=game.create_enemy(at,1,"slime");e.hp=10000;e.max_hp=10000;e.cooldown=999;e.speed=0;game.enemies.append(e);return e
func ready_cast():
	game.hero.mp=Data.max_mp(game.hero);game.spell_cooldowns.clear();game.enemies.clear();game.shots.clear();game.hero.survival.structures=[];game.spellbook.reset();game.hud.resume();game.set_physics_process(false)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
	var old=Data.fresh("Mage");old.erase("spells");check(Data.migrate(old).spells.slots==["fire","frost","heal"],"Legacy characters receive their original spells")
	var invalid=Data.fresh("Mage");invalid.spells.slots=["meteor","frost","heal"];check(Data.migrate(invalid).is_empty(),"Unlearned spells cannot be placed in slots")
	invalid=Data.fresh("Mage");invalid.spells.known.arc=4;check(Data.migrate(invalid).is_empty(),"Ranks above the cap are rejected")
	invalid=Data.fresh("Mage");invalid.spells.slots=["fire","fire","heal"];check(Data.migrate(invalid).is_empty(),"Duplicate loadout entries are rejected")
	game.start_character(Data.fresh("Mage"));game.set_physics_process(false);game.hero.auto=false;game.enemies.clear();game.spawn_timer=99999
	var book=game.spellbook;game.hero.gold=10000;game.hero.level=1;game.set_player_position(game.trader.POSITION)
	check(not book.buy("arc") and not book.known("arc"),"Level requirement protects spell purchases")
	game.hero.level=20;game.set_player_position(Vector2.ZERO);check(not book.buy("arc"),"Purchases require visiting Mara")
	game.set_player_position(game.trader.POSITION)
	for id in ["arc","lance","ward","meteor","sunburst","blizzard"]:
		var gold=game.hero.gold
		check(book.buy(id) and book.rank(id)==1 and game.hero.gold==gold-book.BOOK[id].price,"Learn a spell and charge its price: "+id)
	var gold=game.hero.gold;check(book.buy("meteor") and book.rank("meteor")==2 and game.hero.gold==gold-560,"A second rank costs the proper upgrade price")
	check(book.buy("meteor") and book.rank("meteor")==3 and not book.buy("meteor"),"Purchased spells stop at rank III")
	check(book.assign("meteor",0),"Learned spell equips into slot one")
	check(book.assign("heal",0) and game.hero.spells.slots==["heal","frost","meteor"],"Assigning an equipped spell swaps its old slot")
	check(not book.assign("bad",0) and not book.assign("fire",4),"Invalid assignments leave slots unchanged")
	game.set_player_position(Vector2.ZERO);game.camera.position=Vector2.ZERO;game.camera.force_update_scroll();await settle();ready_cast();pointer(Vector2(150,40))
	book.assign("meteor",0);var mp=game.hero.mp
	check(book.request_slot(0) and book.targeting=="meteor" and game.hero.mp==mp,"Selecting a ground spell previews it without spending mana")
	click(MOUSE_BUTTON_RIGHT);check(book.targeting.is_empty() and game.hero.mp==mp,"Right click cancels ground placement for free")
	book.request_slot(0);var key=InputEventKey.new();key.keycode=KEY_ESCAPE;key.pressed=true
	check(game.desktop.handle_key(key) and book.targeting.is_empty() and game.playing,"Escape cancels placement without pausing")
	book.request_slot(0);var foe=enemy(Vector2(150,40));var hp=foe.hp;click(MOUSE_BUTTON_LEFT)
	check(book.targeting.is_empty() and game.hero.mp==mp-32 and book.zones.size()==1 and not game.desktop.mouse_attack,"Confirming placement spends mana exactly once")
	check(foe.hp==hp,"Meteor damage waits for the visible warning")
	book.tick(.5);check(foe.hp==hp,"Meteor has not landed before its delay")
	book.tick(.41);check(foe.hp<hp and foe.burn>0 and book.zones.is_empty(),"Meteor lands, deals damage and applies burning")
	check(not book.cast("meteor",Vector2(150,40)),"Cooldown prevents repeated casting")
	ready_cast();pointer(Vector2(150,40));game.hero.survival.structures=[{"kind":"Wall","x":80.0,"y":20.0,"rotation":1,"open":false,"stash":{},"fuel":0.0}];mp=game.hero.mp
	check(not book.cast("meteor",Vector2(150,40)) and game.hero.mp==mp,"Walls block ground placement without consuming mana")
	ready_cast();var one=enemy(Vector2(150,0));var two=enemy(Vector2(230,0));var three=enemy(Vector2(310,0));hp=one.hp
	check(book.cast("arc",one.pos) and one.hp<hp and two.hp<hp and three.hp<hp,"Lightning chains through multiple enemies")
	ready_cast();mp=game.hero.mp;check(not book.cast("arc",Vector2(150,0)) and game.hero.mp==mp,"Lightning needs a target and spends no mana on empty space")
	ready_cast();pointer(Vector2(180,0));foe=enemy(Vector2(60,0));hp=foe.hp
	check(book.cast("lance") and game.shots.size()==1 and game.shots[0].velocity.x>500,"Lance fires a fast directional projectile")
	game.tick(.12);check(foe.hp<hp and foe.slow>0,"Lance follows actual swept collision and slows its victim")
	ready_cast();foe=enemy(Vector2(100,0));hp=foe.hp;check(book.cast("blizzard",Vector2(100,0)),"Blizzard places on clear ground")
	book.tick(.1);var first=foe.hp;book.tick(.8);check(first<hp and foe.hp<first and foe.slow>0,"Blizzard deals repeated damage and slow")
	book.tick(5);check(book.zones.is_empty(),"Spell zones expire")
	ready_cast();game.hero.hp=50;foe=enemy(Vector2(100,0));hp=foe.hp
	check(book.cast("sunburst") and game.hero.hp>50 and foe.hp<hp,"Sunburst deals area damage and heals")
	ready_cast();foe=enemy(Vector2(20,0));foe.contact_damage=20;foe.windup=.01;foe.strike=Vector2.ZERO;foe.strike_radius=40
	game.hero.hp=100;game.update_enemy_attack(foe,.02);var without=100-game.hero.hp
	foe.windup=.01;game.hero.hp=100;book.cast("ward");game.update_enemy_attack(foe,.02)
	check(is_equal_approx(100-game.hero.hp,without*.4),"Ward reduces actual enemy strike damage by sixty percent")
	game.hero.mode="survival";game.hero.needs.water=0;game.hero.hp=80;game.expedition.tick(1);check(game.hero.hp==78.5,"Ward does not negate dehydration")
	game.hero.mode="classic";book.targeting="meteor";game.pause_game();check(book.targeting.is_empty(),"Menus clear placement input")
	game.hud.resume();game.set_physics_process(false);game.clear_scene();check(book.ward_time==0 and book.zones.is_empty(),"Scene changes clear transient spells")
	for page in ["spells","spellshop","needs"]:
		game.hud.show_character(page);await settle();check(game.hud.content.size.x<=game.hud.scroll.size.x+1,"New menu fits its scroll container: "+page)
	game.hud.resume();game.set_physics_process(false);game.hud.update_hud()
	check(game.hud.spell_buttons.fire.text.contains("METEOR"),"Hotbar labels track the assigned spell")
	check(not Data.migrate(JSON.parse_string(JSON.stringify(game.hero))).is_empty(),"Spell ranks and assignments round-trip through saves")
	game.graphics.set_quality("Rich");await settle();check(game.graphics.lights.size()==8,"Rich graphics uses a bounded light pool")
	game.graphics.set_quality("Performance");await settle();check(not game.graphics.lights.any(func(l):return l.enabled),"Performance quality disables dynamic lighting")
	game.free();print("%d SPELLBOOK CHECKS PASSED" % checks);quit(0)
