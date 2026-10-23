extends RefCounted
const Data=preload("res://scripts/data.gd")
const POSITION=Vector2(448,-256)
const SUPPLIES={
	"wood":{"name":"Wood","amount":8,"price":16,"stock":5},
	"stone":{"name":"Stone","amount":6,"price":14,"stock":4},
	"fiber":{"name":"Fiber","amount":6,"price":12,"stock":4},
	"herbs":{"name":"Herbs","amount":3,"price":15,"stock":3},
	"iron":{"name":"Iron","amount":3,"price":36,"stock":2},
	"rations":{"name":"Roasted berries","amount":2,"price":15,"stock":4},
	"stew":{"name":"Herbal stew","amount":1,"price":25,"stock":3},
	"tea":{"name":"Warm tea","amount":1,"price":20,"stock":3}
}
const SELL_RATES={"Wood":1,"Stone":1,"Fiber":1,"Berries":1,"Herbs":2,"Iron":4,"Plank":2,"Rope":3,"Resin":2,"Crystal":3,"Glowcap":2,"Reeds":1,"Frost shard":3,"Pine resin":2,"Raw meat":2,"Hide":2,"Roasted berries":3,"Herbal stew":6,"Roasted meat":5,"Bog remedy":7,"Trail stew":8,"Warm tea":4}
const GEAR=["sword","bow","staff","armor","relic"]
var game
func data() -> Dictionary: return game.hero.trader
func near() -> bool: return game.hero.dungeon==null and game.player_position().distance_to(POSITION)<=110
func refresh() -> void:
	var cycle=floori(game.hero.worldTime/600)
	if data().cycle!=cycle:
		data().cycle=cycle;data().level=clampi(int(game.hero.level),1,1000);data().bought={}
func restock_in() -> int: return ceili(600-fposmod(game.hero.worldTime,600))
func discount() -> int: return 15 if game.hero.contracts.completed>=18 else 10 if game.hero.contracts.completed>=6 else 0
func relation() -> String: return "Trusted regular · 15% off" if discount()==15 else "Known adventurer · 10% off" if discount()==10 else "New customer · 6 completed jobs earn 10% off"
func stock(key:String) -> int:
	refresh()
	return maxi(0,(int(SUPPLIES[key].stock) if SUPPLIES.has(key) else 1 if key in GEAR else 0)-int(data().bought.get(key,0)))
func offer(key:String) -> Dictionary:
	refresh()
	if SUPPLIES.has(key):
		var result=SUPPLIES[key].duplicate();result.key=key;result.type="supplies"
		result.price=maxi(1,ceili(result.price*(100-discount())/100.0));return result
	if key not in GEAR: return {}
	var rng=RandomNumberGenerator.new();rng.seed=int(data().cycle)*7919+int(data().level)*131+GEAR.find(key)*47
	var kind=key if key!="relic" else ["sword","bow","staff"][posmod(int(data().cycle),3)]
	var rarity=3 if key=="relic" else 2
	var level=int(data().level)
	var enchant=rng.randi_range(1,4) if kind!="armor" else 0
	var name_value="Mara's "+{"sword":"Trailblade","bow":"Longbow","staff":"Runestaff","armor":"Travel Coat"}[kind]
	if key=="relic": name_value="Wayfarer Relic "+str(kind).capitalize()
	var item={"id":"mara-%d-%s" % [data().cycle,key],"kind":kind,"name":name_value,"level":level,"rarity":rarity,"power":int((18+level*3 if kind=="armor" else 5+level*2)*Data.RARITIES[rarity].mult),"upgrade":0,"enchant":enchant}
	var price=(400+level*100) if key=="relic" else (180+level*35) if kind=="armor" else (100+level*30)
	price=maxi(1,ceili(price*(100-discount())/100.0))
	return {"key":key,"type":"gear","name":item.name,"price":price,"stock":1,"amount":1,"item":item}
func offers() -> Array:
	var result:Array=[]
	for key in SUPPLIES: result.append(offer(key))
	for key in GEAR: result.append(offer(key))
	return result
func buy_reason(key:String) -> String:
	var listing=offer(key)
	if listing.is_empty(): return "Unknown offer"
	if not near(): return "Visit Mara in the wilds to trade"
	if stock(key)<1: return "Sold out until the next game day"
	if game.hero.gold<listing.price: return "Not enough gold"
	if listing.type=="gear":
		if game.hero.inventory.size()>=40: return "Make room in Gear first"
		if game.hero.inventory.any(func(item):return item.id==listing.item.id): return "This item is already in your bag"
	elif game.survival.count(listing.name)+listing.amount>99999: return "No room for this supplies bundle"
	return ""
func buy(key:String) -> bool:
	var why=buy_reason(key)
	if not why.is_empty(): game.notify(why,3);return false
	var listing=offer(key)
	data().bought[key]=int(data().bought.get(key,0))+1
	game.hero.gold-=listing.price
	if listing.type=="gear": game.hero.inventory.append(listing.item.duplicate(true))
	else: game.survival.add(listing.name,listing.amount)
	game.sound("reward");game.notify("Bought "+listing.name,3);game.save_game();return true
func item_by_id(id:String) -> Dictionary:
	for item in game.hero.inventory:
		if item.id==id: return item
	return {}
func gear_value(item:Dictionary) -> int:
	return int(clampf((4.0+item.level*2)*(item.rarity+1)+item.upgrade*3+item.enchant*4,5,1000000000))
func sell_reason(id:String) -> String:
	if not near(): return "Visit Mara in the wilds to trade"
	if item_by_id(id).is_empty(): return "This item is no longer in your bag"
	if id in game.hero.equipped.values(): return "Equipped items are protected"
	return ""
func sell_gear(id:String) -> bool:
	var why=sell_reason(id)
	if not why.is_empty(): game.notify(why,3);return false
	var item=item_by_id(id);var value=gear_value(item)
	data().buyback.push_front({"item":item.duplicate(true),"price":value})
	if data().buyback.size()>8: data().buyback.pop_back()
	game.hero.inventory.erase(item);game.hero.gold+=value
	game.sound("reward");game.notify("Sold "+item.name+" · +%d gold" % value,3);game.save_game();return true
func sell_supplies(name_value:String,amount:int) -> bool:
	if not near() or not SELL_RATES.has(name_value) or amount<1 or amount>game.survival.count(name_value): return false
	game.survival.add(name_value,-amount);game.hero.gold+=SELL_RATES[name_value]*amount
	game.sound("reward");game.notify("Sold %d %s" % [amount,name_value],3);game.save_game();return true
func receipt(id:String) -> Dictionary:
	for entry in data().buyback:
		if entry.item.id==id: return entry
	return {}
func buyback_price(entry:Dictionary) -> int: return int(entry.price)+maxi(1,ceili(entry.price*.1))
func buyback_reason(id:String) -> String:
	var entry=receipt(id)
	if entry.is_empty(): return "This item is no longer in buyback"
	if not near(): return "Visit Mara in the wilds to trade"
	if game.hero.inventory.size()>=40: return "Make room in Gear first"
	if not item_by_id(id).is_empty(): return "This item is already in your bag"
	if game.hero.gold<buyback_price(entry): return "Not enough gold"
	return ""
func buyback(id:String) -> bool:
	var why=buyback_reason(id)
	if not why.is_empty(): game.notify(why,3);return false
	var entry=receipt(id)
	game.hero.gold-=buyback_price(entry);game.hero.inventory.append(entry.item.duplicate(true));data().buyback.erase(entry)
	game.sound("reward");game.notify("Recovered "+entry.item.name,3);game.save_game();return true
func track() -> void:
	game.hero.contracts.target="";game.hero.exploration.target="trader";game.save_game();game.hud.resume()
