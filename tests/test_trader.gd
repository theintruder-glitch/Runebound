extends SceneTree
const Data=preload("res://scripts/data.gd")
const Card=preload("res://scripts/ui_card.gd")
var checks=0
func _initialize(): call_deferred("run")
func check(ok:bool,message:String):
	if not ok:
		push_error("FAIL: "+message);quit(1);assert(ok,message)
	checks+=1;print("PASS: "+message)
func descendants(node:Node) -> Array:
	var out:Array=[]
	for child in node.get_children(): out.append(child);out.append_array(descendants(child))
	return out
func button(node:Node,prefix:String) -> Button:
	for item in descendants(node):
		if item is Button and item.text.begins_with(prefix): return item
	return null
func run():
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size=Vector2i(1080,2400)
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.start_character(Data.fresh("Warrior"));game.set_physics_process(false)
	game.enemies.clear();game.hero.auto=false;game.spawn_timer=100000
	var market=game.trader;var camp=game.survival;var hud=game.hud
	var legacy=Data.fresh("Mage");legacy.erase("trader")
	check(Data.migrate(legacy).trader.buyback.is_empty(),"Old characters receive trader defaults")
	check(market.offers().size()==13,"Eight supply bundles and five equipment offers exist")
	game.hero.gold=5000
	var gold=game.hero.gold
	check(not market.buy("wood") and game.hero.gold==gold,"Remote purchases cannot spend gold")
	check(not market.buy("unknown"),"Unknown offers are rejected")
	game.set_player_position(market.POSITION);game.update_interaction()
	check(hud.interaction.text=="TRADE WITH MARA","Mara has a world interaction prompt")
	game.playing=true;game.interact();await process_frame;await process_frame
	check(hud.current_page=="trader" and not game.playing,"Interacting opens a paused shop")
	var wood=camp.count("Wood");var offer=market.offer("wood")
	var buy=button(hud.content,"Buy Wood ·")
	check(buy!=null and not buy.disabled,"Shop shows a usable bundle purchase button")
	buy.pressed.emit()
	check(camp.count("Wood")==wood+8 and game.hero.gold==gold-offer.price,"UI purchases the advertised quantity at its preview price")
	check(market.stock("wood")==4,"Purchase reduces finite daily stock")
	var stock=market.stock("wood");hud.show_character("trader");await process_frame
	check(market.stock("wood")==stock,"Reopening the shop does not refill stock")
	var same=market.offer("bow").duplicate(true)
	market.refresh();game.hero.level+=3;market.refresh()
	check(market.offer("bow")==same,"Menu refresh and leveling do not reroll the day's equipment")
	game.hero.gold=0;wood=camp.count("Wood");stock=market.stock("wood")
	check(not market.buy("wood") and camp.count("Wood")==wood and market.stock("wood")==stock,"Unaffordable purchases leave inventory and stock intact")
	game.hero.gold=10000
	for i in range(stock): check(market.buy("wood"),"Remaining bundle can be purchased "+str(i))
	gold=game.hero.gold;wood=camp.count("Wood")
	check(not market.buy("wood") and market.stock("wood")==0 and game.hero.gold==gold and camp.count("Wood")==wood,"Sold-out offers cannot be purchased again")
	var size=game.hero.inventory.size();var bow=market.offer("bow")
	check(market.buy("bow") and game.hero.inventory.size()==size+1,"Buying equipment adds a real inventory item")
	var item=game.hero.inventory[-1]
	check(item.kind=="bow" and item.rarity==2 and item.enchant>0 and item.power==bow.item.power,"Rare bow keeps its previewed stats and enchantment")
	check(not market.buy("bow"),"A unique daily weapon cannot be bought twice")
	game.save_game();var loaded=Data.read_save()
	check(loaded.trader.bought.wood==5 and loaded.trader.bought.bow==1,"Daily purchase counts survive saving")
	game.start_character(loaded);game.set_physics_process(false);game.enemies.clear();game.hero.auto=false
	game.set_player_position(market.POSITION)
	check(market.stock("wood")==0 and market.stock("bow")==0,"Reloading preserves sold-out items")
	var before=game.hero.worldTime;var timer=market.restock_in()
	game.pause_game();game.set_physics_process(true);await create_timer(.12).timeout;game.set_physics_process(false)
	check(game.hero.worldTime==before and market.restock_in()==timer,"Menus pause the restock clock")
	game.hero.worldTime+=600;market.refresh()
	check(market.stock("wood")==5 and market.stock("bow")==1,"A new active game day restocks offers")
	check(market.data().level==game.hero.level,"The new day updates the stock level snapshot")
	game.hero.contracts.completed=0;var base=market.offer("sword").price
	game.hero.contracts.completed=6
	check(market.discount()==10 and market.offer("sword").price==ceili(base*.9),"Six completed jobs earn the advertised ten-percent discount")
	game.hero.contracts.completed=18
	check(market.discount()==15 and market.offer("sword").price==ceili(base*.85),"Eighteen completed jobs earn fifteen percent off")
	for level in [1,1000]:
		game.hero.level=level;game.hero.worldTime+=600;market.refresh()
		for listing in market.offers():
			var resale=market.gear_value(listing.item) if listing.type=="gear" else market.SELL_RATES[listing.name]*listing.amount
			check(resale<listing.price,"Discounted purchase/resale cannot generate free gold: level %d %s" % [level,listing.key])
	game.hero.level=4;game.hero.worldTime+=600;market.refresh();game.hero.gold=10000
	var starter=game.hero.inventory[0].duplicate(true)
	gold=game.hero.gold
	check(not market.sell_gear(game.hero.equipped.weapon) and game.hero.gold==gold,"Equipped gear is protected from sale")
	var spare=starter.duplicate(true);spare.id="buyback-check";spare.name="Remembered Blade";spare.upgrade=4;spare.enchant=3;spare.rarity=3;spare.power=91
	game.hero.inventory.append(spare);var value=market.gear_value(spare)
	check(market.sell_gear(spare.id) and market.item_by_id(spare.id).is_empty(),"Selling removes only the chosen spare item")
	check(game.hero.gold==gold+value and market.receipt(spare.id).item==spare,"Sale grants quoted gold and preserves full item data in buyback")
	gold=game.hero.gold
	check(not market.sell_gear(spare.id) and game.hero.gold==gold,"Repeated sale of a stale item ID cannot duplicate gold")
	game.save_game();loaded=Data.read_save()
	check(loaded.trader.buyback[0].item.upgrade==4 and loaded.trader.buyback[0].item.enchant==3,"Buyback upgrades and enchantments survive save/reload")
	game.hero.worldTime+=600;market.refresh()
	check(not market.receipt(spare.id).is_empty(),"Daily restock keeps buyback equipment")
	game.set_player_position(Vector2.ZERO)
	check(not market.buyback(spare.id) and not market.sell_supplies("Wood",1),"Remote buyback and selling are rejected")
	game.set_player_position(market.POSITION)
	var cost=market.buyback_price(market.receipt(spare.id))
	check(cost==value+maxi(1,ceili(value*.1)),"Buyback applies the documented recovery fee")
	game.hero.gold=0
	check(not market.buyback(spare.id) and not market.receipt(spare.id).is_empty(),"Unaffordable buyback retains the item")
	game.hero.gold=10000;gold=game.hero.gold
	check(market.buyback(spare.id) and game.hero.gold==gold-cost,"Buyback charges exactly its preview price")
	check(market.item_by_id(spare.id)==spare and market.receipt(spare.id).is_empty(),"Buyback restores the original item exactly once")
	check(not market.buyback(spare.id),"Recovered gear cannot be cloned by repeat buyback")
	market.data().buyback.clear()
	for i in range(9):
		var extra=starter.duplicate(true);extra.id="queue-"+str(i);game.hero.inventory.append(extra);market.sell_gear(extra.id)
	check(market.data().buyback.size()==8 and market.receipt("queue-0").is_empty() and not market.receipt("queue-8").is_empty(),"Buyback keeps exactly the eight most recent equipment sales")
	game.hero.inventory.clear()
	for i in range(40):
		var fill=starter.duplicate(true);fill.id="full-"+str(i);game.hero.inventory.append(fill)
	gold=game.hero.gold;stock=market.stock("staff")
	check(not market.buy("staff") and market.stock("staff")==stock and game.hero.gold==gold,"Full bags block equipment purchases without charging")
	check(not market.buyback("queue-8") and not market.receipt("queue-8").is_empty(),"Full bags keep buyback items pending")
	check(market.buy("tea"),"A full equipment bag still accepts a supplies bundle")
	game.hero.inventory=[starter];game.hero.equipped.weapon=starter.id
	camp.data().materials.Wood=99999;stock=market.stock("wood");gold=game.hero.gold
	check(not market.buy("wood") and camp.count("Wood")==99999 and market.stock("wood")==stock and game.hero.gold==gold,"Full supplies stacks reject a bundle without clipping or charging")
	camp.data().materials.Wood=20;gold=game.hero.gold
	check(market.sell_supplies("Wood",10) and camp.count("Wood")==10 and game.hero.gold==gold+10,"Material selling consumes the exact quantity and pays its unit price")
	check(not market.sell_supplies("Wood",0) and not market.sell_supplies("Wood",-1) and not market.sell_supplies("Wood",11),"Invalid or excessive material sale quantities are rejected")
	game.hero.dungeon={"floor":1}
	check(not market.near() and not market.buy("wood"),"Dungeon coordinates cannot impersonate the world trader")
	market.track()
	check(game.exploration.objective().contains("Leave dungeon"),"Tracking Mara from underground directs the player to the exit")
	game.hero.dungeon=null;game.set_player_position(market.POSITION);game.playing=false
	game.hero.contracts.target="board";market.track()
	check(game.hero.exploration.target=="trader" and game.hero.contracts.target.is_empty(),"Trader tracking replaces competing quest objectives")
	game.save_game();check(Data.read_save().exploration.target=="trader","Mara's map target survives saving")
	for dims in [Vector2i(1080,2400),Vector2i(2400,1080)]:
		root.size=dims;game.adapt_screen();await process_frame;await process_frame
		for page in ["Buy","Sell","Buyback"]:
			hud.trader_page=page;hud.trader_filter="Gear" if page=="Sell" else "Supplies";hud.show_character("trader");await process_frame;await process_frame
			var bounds=hud.scroll.get_global_rect();var fits=true
			for node in descendants(hud.content):
				if node is Button:
					var rect=node.get_global_rect();fits=fits and rect.position.x>=bounds.position.x-.5 and rect.end.x<=bounds.end.x+.5
			check(fits,"Trader actions fit "+page+" "+str(dims))
		hud.show_character("map");await process_frame;await process_frame
		check(hud.map_widget.markers.has("trader"),"Mara has a selectable map marker "+str(dims))
		var touch=InputEventScreenTouch.new();touch.index=7;touch.pressed=true;touch.position=hud.map_widget.global_position+hud.map_widget.markers.trader
		root.push_input(touch,true);check(hud.map_selection=="trader","Touch selects Mara's map marker "+str(dims))
		touch.pressed=false;root.push_input(touch,true)
		button(hud.content,"Track selected").pressed.emit()
		check(game.hero.exploration.target=="trader" and game.playing,"Map tracks Mara and returns to play "+str(dims))
	game.set_player_position(market.POSITION-Vector2(0,96));game.facing=Vector2.DOWN;game.enemies.clear()
	for material in camp.MATERIALS: camp.add(material,30)
	check(camp.reason("Wall").contains("Mara"),"New construction preserves access to Mara")
	game.camera.position=market.POSITION;game.world.profile_enabled=true;game.world.refresh(true);game.world.queue_redraw()
	await process_frame;await process_frame
	check(game.world.profile_draw_samples.size()>0,"Trader scenery executes native drawing without script errors")
	for malformed in ["container","level","cycle","stock","count","buyback","receipt","duplicate","fractional"]:
		var bad=Data.fresh("Warrior")
		match malformed:
			"container": bad.trader=[]
			"level": bad.trader.level=0
			"cycle": bad.trader.cycle="bad"
			"stock": bad.trader.bought.unknown=1
			"count": bad.trader.bought.sword=2
			"buyback": bad.trader.buyback={}
			"receipt": bad.trader.buyback=[{"item":starter,"price":-1}]
			"fractional":
				var malformed_item=starter.duplicate();malformed_item.rarity=2.5;bad.trader.buyback=[{"item":malformed_item,"price":5}]
			"duplicate": bad.trader.buyback=[{"item":starter,"price":5},{"item":starter.duplicate(),"price":5}]
		check(Data.migrate(bad).is_empty(),"Malformed trader save rejected: "+malformed)
	print(str(checks)+" TRADER CHECKS PASSED")
	quit()
