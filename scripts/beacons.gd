extends RefCounted
# Optional outdoor discoveries. Persistent flags share the existing opened map;
# a live encounter is deliberately transient and can be retried after retreat.
const SITES={
 "beacon-emerald":{"name":"Rootlight Beacon","point":Vector2(660,900),"accent":Color("9fd7a3"),"order":["leaf","moon","star"],"level":3,"boss":"The Rootbound Watcher","kind":"wolf","core":"Thorn sigil","reward":"Rootlight Talisman","slot":"charm","enchant":1,"lore":"Before Thornwatch fell, rootlight guided travelers across the king's river. The carved oath reads: Leaf, Moon, Star. Answer the three stones in that order, then awaken the watch."},
 "beacon-frost":{"name":"Last Ember Beacon","point":Vector2(540,-2350),"accent":Color("9ddbea"),"order":["star","leaf","moon"],"level":5,"boss":"The Emberless Knight","kind":"ice_archer","core":"Rime seal","reward":"Last Ember Ring","slot":"ring","enchant":2,"lore":"Frostspire's wardens kept this fire alive through a hundred winters. Its final keeper wrote: Star, Leaf, Moon. Restore the three stones, then face the knight who forgot his oath."},
 "beacon-mire":{"name":"Drowned Lantern","point":Vector2(-2600,700),"accent":Color("c4a1ef"),"order":["moon","star","leaf"],"level":6,"boss":"The Lantern's Gaoler","kind":"bog_toad","core":"Mire chain","reward":"Lanternkeeper's Sigil","slot":"charm","enchant":4,"lore":"Blackmire chained its warning lantern to the dead. A prisoner's scratched message survives: Moon, Star, Leaf. Answer the stones and free the lantern from its gaoler."},
 "beacon-storm":{"name":"Skywatch Orrery","point":Vector2(2650,1140),"accent":Color("abcfff"),"order":["leaf","star","moon"],"level":7,"boss":"The Oathless Astronomer","kind":"crystal_wisp","core":"Stormcore","reward":"Skywatch Signet","slot":"ring","enchant":3,"lore":"Stormbreak once read the heavens here. The broken star chart records: Leaf, Star, Moon. Restore the three stones, then challenge the keeper who turned the sky against his king."}
}
const OFFSETS={"leaf":Vector2(-88,0),"moon":Vector2(0,42),"star":Vector2(88,0)}
var game
var running=""
var foes:Array=[]
func flag(id:String,key:String) -> String:return id+":"+key
func has(id:String,key:String) -> bool:return game.hero.opened.get(flag(id,key),false)==true
func mark(id:String,key:String,value:bool=true) -> void:game.hero.opened[flag(id,key)]=value
func active() -> bool:return not running.is_empty()
func reset() -> void:
 for e in foes:game.enemies.erase(e)
 foes.clear();running=""
func near(id:String,p:Vector2) -> bool:return game.hero.dungeon==null and game.player_position().distance_to(p)<39 and game.line_clear(game.player_position(),p)
func progress(id:String) -> int:
 var count=0
 for key in ["step-0","step-1","step-2"]:
  if has(id,key):count+=1
 return count
func stage(id:String) -> String:
 if has(id,"claimed"):return "Restored"
 if has(id,"cleared"):return "Reward waiting"
 if running==id:return "Watchers awakened"
 if has(id,"solved"):return "Challenge ready"
 return "Runes %d/3" % progress(id) if has(id,"read") else "Unexplored"
func feature() -> Dictionary:
 if game.hero.dungeon!=null:return {}
 for id in SITES:
  var info=SITES[id]
  if near(id,info.point):return {"id":id,"key":"center"}
  if has(id,"claimed"):continue
  for key in OFFSETS:
   if near(id,info.point+OFFSETS[key]):return {"id":id,"key":key}
 return {}
func interaction() -> String:
 var found=feature()
 if found.is_empty():return ""
 var id:String=found.id
 if found.key!="center":return "ALIGN "+found.key.to_upper()+" STONE" if not has(id,"solved") else "RUNES ALIGNED"
 if not has(id,"read"):return "READ "+SITES[id].name.to_upper()
 if has(id,"claimed"):return SITES[id].name.to_upper()+" · RESTORED"
 if has(id,"cleared"):return "CLAIM BEACON RELIC"
 if has(id,"solved"):return "WATCHERS AWAKENED" if running==id else "AWAKEN BEACON WATCHERS"
 return "READ BEACON OATH"
func interact() -> void:
 var found=feature()
 if found.is_empty():return
 var id:String=found.id
 if found.key!="center":align(id,found.key);return
 if not has(id,"read"):mark(id,"read");game.world.refresh_scenery(true);game.save_game()
 if has(id,"claimed"):game.notify(SITES[id].name+" restored. The road remembers your oath.",5)
 elif has(id,"cleared"):claim(id)
 elif has(id,"solved"):begin(id)
 else:game.notify(SITES[id].lore,10)
func align(id:String,key:String) -> bool:
 if not SITES.has(id) or not OFFSETS.has(key) or not near(id,SITES[id].point+OFFSETS[key]) or active() or has(id,"solved"):return false
 if not has(id,"read"):game.notify("Read the central beacon's oath first.",4);return false
 var step=progress(id)
 if key!=SITES[id].order[step]:
  for i in range(3):mark(id,"step-"+str(i),false)
  game.notify("The stones fall silent. Read the oath and start the sequence again.",5);game.world.refresh_scenery(true);game.save_game();return false
 mark(id,"step-"+str(step))
 if step==2:mark(id,"solved");game.notify("The oath answers. Return to the central beacon and awaken its watchers.",6)
 else:game.notify(key.capitalize()+" stone answers · %d/3" % (step+1),4)
 game.sound("spell");game.world.refresh_scenery(true);game.save_game();return true
func begin(id:String) -> bool:
 if not SITES.has(id) or not near(id,SITES[id].point) or not has(id,"solved") or has(id,"cleared") or active() or game.hero.hp<=0 or not game.build_recipe.is_empty():return false
 if game.forest.active() or game.exploration.active() or game.forge.active():game.notify("Finish the current encounter before awakening another.",4);return false
 # Keep the existing crowd budget: recycle only distant idle ambient actors.
 var safe_to_recycle=[]
 for e in game.enemies:
  if e.dead or not game.protected_encounter_enemy(e) and e.pos.distance_to(game.player_position())>400 and e.aggro<=0 and e.burn<=0 and e.windup<=0:safe_to_recycle.append(e)
 var remaining=game.enemies.size()-safe_to_recycle.size()
 if remaining+3>game.roaming_limit() or game.enemies.any(func(e):return not e.dead and not e.get("neutral",false) and e.pos.distance_to(game.player_position())<180):game.notify("Clear the nearby threats before awakening the beacon watchers.",5);return false
 var positions=[]
 for offset in [Vector2(-66,-28),Vector2(66,-28),Vector2(0,-56)]:
  var p=SITES[id].point+offset
  if not game.walkable(p,22) or not game.line_clear(SITES[id].point,p):game.notify("The watchers need clear ground. Move obstructions away from the beacon.",5);return false
  positions.append(p)
 for e in safe_to_recycle:game.enemies.erase(e)
 running=id;foes.clear()
 for i in range(3):
  var boss=i==2;var level=maxi(SITES[id].level,game.hero.level)
  var e=game.create_enemy(positions[i],level,"guardian" if boss else SITES[id].kind,boss)
  e.named=SITES[id].boss if boss else "Bound Watcher";e["beacon_id"]=id;e["beacon_boss"]=boss;e.home=SITES[id].point;e.aggro=60;e.cooldown=1+i*.4
  e.hp=float(240+level*20) if boss else float(40+level*7);e.max_hp=e.hp;e.contact_damage=10+level if boss else 5+level
  foes.append(e);game.enemies.append(e)
 game.notify("BEACON WATCHERS · Defeat all three. Dodge the keeper's locked mark and wide slam. Stay near the beacon; retreat or reload allows a retry.",8);game.world.refresh_scenery(true);game.save_game();return true
func tick(_dt:float) -> void:
 if not active():return
 if game.hero.dungeon!=null or game.hero.hp<=0 or game.player_position().distance_to(SITES[running].point)>380 or foes.any(func(e):return not e.dead and not game.enemies.has(e)):
  reset();game.world.refresh_scenery(true);game.notify("Beacon challenge abandoned. Your solved runes remain; return to retry.",5)
func on_kill(enemy:Dictionary) -> void:
 if not active() or not foes.any(func(e):return is_same(e,enemy)) or foes.any(func(e):return not e.dead):return
 var id=running;running="";foes.clear();mark(id,"cleared");game.world.refresh_scenery(true);game.save_game();game.notify(SITES[id].name+" freed. Return to its center for the relic.",6)
func claim(id:String) -> bool:
 if not SITES.has(id) or not near(id,SITES[id].point) or not has(id,"cleared") or has(id,"claimed"):return false
 var info=SITES[id]
 if game.hero.inventory.size()>=40:game.notify("Make one slot in Gear for the beacon relic.",4);return false
 if game.survival.count(info.core)>99997:game.notify("Make room for 2 "+info.core+" before claiming.",4);return false
 var level=maxi(info.level,game.hero.level)
 game.hero.inventory.append({"id":id+"-relic","kind":info.slot,"name":info.reward,"level":level,"rarity":3,"power":12+level*3,"upgrade":0,"enchant":info.enchant})
 game.hero.gold+=250;game.hero.essence+=5;game.survival.add(info.core,2);mark(id,"claimed")
 var accord=SITES.keys().all(func(site):return has(site,"claimed")) and not game.hero.opened.get("waykeeper-accord",false)
 if accord:game.hero.opened["waykeeper-accord"]=true;game.hero.points+=2
 game.notify(info.reward+" · +250 gold, +5 essence, +2 "+info.core+(" · ALL FOUR BEACONS RESTORED: +2 stat points" if accord else ""),8)
 game.sound("reward");game.world.refresh_scenery(true);game.save_game();return true
func prepare_attack(enemy:Dictionary) -> void:
 enemy["beacon_pattern"]=enemy.get("beacon_pattern",0)+1
 var slam=enemy.beacon_pattern%2==0
 enemy.windup=.85 if enemy.hp<enemy.max_hp*.5 else 1.35;enemy.strike_radius=90.0 if slam else 43.0
 enemy.strike=enemy.pos if slam else game.player_position();enemy["castle_attack"]="OATHBREAK SLAM" if slam else "KEEPER'S MARK"
func objective(id:String) -> String:
 var target=SITES[id].point
 if game.hero.dungeon!=null:return SITES[id].name+" · Leave dungeon via entrance stairs"
 if running==id:return SITES[id].name+" · Defeat all three watchers · Stay near the beacon"
 if has(id,"read") and not has(id,"solved"):target+=OFFSETS[SITES[id].order[progress(id)]]
 return SITES[id].name+" · "+stage(id)+" · "+game.exploration.bearing(target)
func reserved(p:Vector2) -> bool:
 for info in SITES.values():
  if Rect2(info.point-Vector2(140,110),Vector2(280,220)).has_point(p):return true
 return false
func cache_position(p:Vector2) -> Vector2:
 if not reserved(p):return p
 for offset in [Vector2(0,240),Vector2(240,0),Vector2(-240,0),Vector2(0,-240),Vector2(240,240),Vector2(-240,240)]:
  var candidate=p+offset
  if not reserved(candidate) and game.walkable(candidate,10):return candidate
 return p
func draw(c:CanvasItem,b:Rect2) -> void:
 for id in SITES:
  var info=SITES[id];var p:Vector2=info.point;var color:Color=info.accent
  if not b.grow(140).has_point(p):continue
  c.draw_set_transform(p,0,Vector2(1,.55));c.draw_circle(Vector2(0,18),105,Color("101c25aa"));c.draw_circle(Vector2.ZERO,100,Color("535b58"));c.draw_arc(Vector2.ZERO,95,0,TAU,40,Color("a89d78"),4);c.draw_set_transform(Vector2.ZERO)
  for key in OFFSETS:
   var q=p+OFFSETS[key];var lit=has(id,"solved")
   for i in range(progress(id)):
    if info.order[i]==key:lit=true
   c.draw_circle(q+Vector2(4,9),20,Color("11202b88"));c.draw_rect(Rect2(q-Vector2(14,22),Vector2(28,32)),Color("5b6670"));c.draw_rect(Rect2(q-Vector2(11,20),Vector2(22,27)),Color("84918e"))
   var rune_color=color if lit else Color("363f4b")
   if key=="moon":c.draw_arc(q+Vector2(0,-7),8,.7,5.2,14,rune_color,3)
   elif key=="leaf":c.draw_polyline(PackedVector2Array([q+Vector2(-7,0),q+Vector2(0,-15),q+Vector2(7,-1),q+Vector2(-7,0)]),rune_color,2,true)
   else:
    for i in range(3):c.draw_line(q+Vector2.from_angle(i*PI/3)*8+Vector2(0,-7),q-Vector2.from_angle(i*PI/3)*8+Vector2(0,-7),rune_color,2,true)
   c.draw_string(ThemeDB.fallback_font,q+Vector2(-15,25),key.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,10,color)
  c.draw_rect(Rect2(p-Vector2(28,16),Vector2(56,28)),Color("38434a"));c.draw_rect(Rect2(p-Vector2(32,3),Vector2(64,13)),Color("94866b"))
  if id=="beacon-emerald":
   for side in [-1,1]:c.draw_polyline(PackedVector2Array([p+Vector2(side*40,8),p+Vector2(side*17,-8),p+Vector2(side*12,-52),p+Vector2(0,-69)]),Color("647353"),10,true)
  elif id=="beacon-frost":
   c.draw_line(p+Vector2(-25,-40),p+Vector2(25,-40),Color("a3abb0"),9);c.draw_line(p+Vector2(-20,-40),p+Vector2(-10,-14),Color("707f8b"),7);c.draw_line(p+Vector2(20,-40),p+Vector2(10,-14),Color("707f8b"),7)
  elif id=="beacon-mire":
   for side in [-1,1]:
    c.draw_line(p+Vector2(side*28,-8),p+Vector2(side*28,-80),Color("6b7778"),8);c.draw_line(p+Vector2(side*28,-80),p+Vector2(0,-80),Color("9d9175"),5)
    for y in range(-77,-44,7):c.draw_arc(p+Vector2(side*5,y),3,0,TAU,8,Color("9b9288"),1)
  else:
   c.draw_arc(p+Vector2(0,-42),27,0,TAU,32,Color("bfac75"),3);c.draw_arc(p+Vector2(0,-42),17,0,TAU,24,color,2);c.draw_line(p+Vector2(0,-15),p+Vector2(0,-1),Color("b9ab87"),6)
  var glow=color if has(id,"solved") else color.darkened(.5)
  c.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-64),p+Vector2(12,-42),p+Vector2(0,-27),p+Vector2(-12,-42)]),glow)
  c.draw_string(ThemeDB.fallback_font,p+Vector2(-64,-98),info.name.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)
  c.draw_string(ThemeDB.fallback_font,p+Vector2(-48,85),stage(id).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,10,color)
func show_menu() -> void:
 var hud=game.hud;hud.paragraph("The Waykeepers' lost beacons",21)
 hud.paragraph("Read each central oath, then touch Leaf, Moon and Star in its recorded order. A wrong stone resets that sequence. Restore the runes and return to awaken three watchers. Solve first and fight when ready; retreat or reload keeps the puzzle and resets an unfinished fight.",14)
 hud.paragraph("Each beacon: one Epic ring/charm, 250 gold, 5 essence and 2 regional forging cores. Restore all four for 2 extra stat points. Make room in Gear and supplies before claiming. Rewards are once per character.",14)
 for id in SITES:
  var site=id;var info=SITES[id]
  hud.section(info.name+" · "+stage(id));hud.paragraph(info.lore if has(id,"read") else "An ancient roadside beacon awaits beside the road to its regional castle.",14)
  hud.paragraph("Relic: "+info.reward+" · "+info.core,13)
  hud.action(hud.content,"Track "+info.name,func():game.exploration.track(site))
  if has(id,"read") and not has(id,"solved"):
   hud.paragraph("Recorded order: "+", ".join(info.order)+" · %d/3 answered" % progress(id),13)
  if has(id,"cleared") and not has(id,"claimed"):hud.action(hud.content,"Claim "+info.reward,func():claim(site);hud.show_character("beacons"),not near(id,info.point))
  if has(id,"solved") and not has(id,"cleared"):hud.action(hud.content,"Awaken watchers · 3 enemies",func():
   if begin(site):hud.resume()
   else:hud.show_character("beacons"),not near(id,info.point) or active())
