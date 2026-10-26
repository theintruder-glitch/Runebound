extends SceneTree
const Data=preload("res://scripts/data.gd")
const Card=preload("res://scripts/ui_card.gd")
var checks=0
func _initialize(): call_deferred("run")
func check(ok:bool,message:String):
 if not ok:
  push_error("FAIL: "+message); quit(1); assert(ok,message)
 checks+=1; print("PASS: "+message)
func descendants(node:Node) -> Array:
 var out:Array=[]
 for child in node.get_children():
  out.append(child);out.append_array(descendants(child))
 return out
func find_button(node:Node,title:String) -> Button:
 for item in descendants(node):
  if item is Button and item.text==title: return item
 return null
func run():
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
 root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
 root.size=Vector2i(1080,2400)
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game);await process_frame
 game.start_character(Data.fresh("Warrior"));game.set_physics_process(false)
 game.enemies.clear();game.hero.auto=false;game.spawn_timer=10000
 var hud=game.hud;var camp=game.survival
 for kind in ["sword","bow","staff","armor","shield","helmet","ring","charm"]:
  game.hero.inventory.append({"id":"ui-"+kind,"kind":kind,"name":"Presentation "+kind,"rarity":2,"level":1,"power":25,"upgrade":0,"enchant":1 if kind=="sword" else 0})
 for kind in camp.MATERIALS: camp.add(kind,10)
 hud.show_character("gear");await process_frame;await process_frame
 var cards=descendants(hud.content).filter(func(n):return n.get_script()==Card)
 check(cards.size()==9,"Equipment renders as a selectable item grid")
 check(cards.any(func(c):return c.marked),"Equipped item is marked visually")
 var bow_card=cards.filter(func(c):return c.kind=="bow")[0]
 bow_card.pressed.emit();await process_frame
 check(hud.gear_selected=="ui-bow","Selecting a card updates the item detail")
 var equip=find_button(hud.content,"Equip")
 check(equip!=null,"Selected item offers an equip action")
 equip.pressed.emit()
 check(Data.equipped(game.hero,"weapon").id=="ui-bow","Card detail equips the selected item")
 hud.gear_filter="Weapons";hud.show_character("gear");await process_frame
 cards=descendants(hud.content).filter(func(n):return n.get_script()==Card)
 check(cards.size()==4 and cards.all(func(c):return c.kind in ["sword","bow","staff"]),"Weapon filter hides nonweapon equipment")
 hud.camp_page="Craft";hud.craft_filter="Parts";hud.show_character("camp");await process_frame
 var plank=find_button(hud.content,"Make Plank")
 check(plank!=null and not plank.disabled,"Crafting Parts page exposes the plank recipe")
 var count=camp.count("Plank");plank.pressed.emit()
 check(camp.count("Plank")==count+1,"Visual crafting card creates the correct component")
 hud.camp_page="Supplies";hud.show_character("camp");await process_frame
 cards=descendants(hud.content).filter(func(n):return n.get_script()==Card)
 check(cards.size()==camp.MATERIALS.size(),"Owned supplies show icons and quantities")
 game.hero.hp=20
 var eat=find_button(hud.content,"Eat Roasted berries · %d owned" % camp.count("Roasted berries"))
 check(eat!=null,"Supplies page exposes carried food")
 eat.pressed.emit()
 check(game.hero.hp==55,"Food action still restores the expected health")
 for dims in [Vector2i(1080,2400),Vector2i(2400,1080)]:
  root.size=dims;game.adapt_screen();await process_frame;await process_frame
  hud.show_character("gear");await process_frame;await process_frame
  cards=descendants(hud.content).filter(func(n):return n.get_script()==Card)
  var fit=true
  var bounds=hud.scroll.get_global_rect()
  for card in cards:
   var rect=card.get_global_rect()
   fit=fit and rect.position.x>=bounds.position.x-.5 and rect.end.x<=bounds.end.x+.5
  check(fit,"Equipment grid has no horizontal overflow "+str(dims))
  hud.show_character("map");await process_frame;await process_frame
  var map=hud.map_widget
  check(map.markers.size()==13 and ["forest","caves","swamp","snow","home","trader","ruins","keep","frostspire","blackmire","stormbreak","frost-cave","highland-mine"].all(func(id):return map.markers.has(id)),"Map draws all thirteen region, camp, castle and side-expedition markers "+str(dims))
  check(hud.scroll.get_global_rect().encloses(map.get_global_rect()),"Whole map fits the visible menu area "+str(dims))
  var touch=InputEventScreenTouch.new();touch.index=9;touch.pressed=true
  touch.position=map.global_position+map.markers.snow
  root.push_input(touch,true)
  check(hud.map_selection=="snow" and map.selected=="snow","Touch selects a map landmark "+str(dims))
  touch.pressed=false;root.push_input(touch,true)
  find_button(hud.content,"Track selected").pressed.emit()
  check(game.hero.exploration.target=="snow" and not hud.overlay.visible,"Tracking returns to gameplay with the selected objective "+str(dims))
  hud.show_character("map");await process_frame;await process_frame
  find_button(hud.content,"Around me").pressed.emit();await process_frame
  check(hud.map_widget.local_view and hud.map_widget.world_bounds.size==Vector2(2000,2000),"Local map centers on the player "+str(dims))
 for target in ["home","ruins"]:
  game.hero.exploration.target=target;game.save_game()
  check(Data.read_save().exploration.target==target,"New map tracking target survives saving: "+target)
  check(not game.exploration.objective().is_empty(),"New tracking target provides a direction: "+target)
 hud.resume();game.hero.exploration.target="";game.hero.className="Mage"
 game.hero.mp=Data.max_mp(game.hero);game.spell_cooldowns={"fire":0.0,"frost":0.0,"heal":0.0}
 game.enemies=[game.create_enemy(game.player_position()+Vector2(60,0),1,"goblin")]
 game.enemies[0].hp=10000;game.enemies[0].max_hp=10000
 check(game.cast("frost") and game.visuals.any(func(v):return v.kind=="frost"),"Frost spell produces a visible expanding ring")
 check(game.cast("heal") and game.visuals.any(func(v):return v.kind=="heal"),"Healing produces a distinct effect")
 for kind in ["impact","dash","storm","heal","fire","frost","rune"]:
  var visual=game.visual_fx(kind,game.player_position(),60,Color("b4d9ed"),.5)
  if kind=="storm": visual["end"]=game.player_position()+Vector2(70,20)
 game.world.profile_enabled=true;game.world.queue_redraw()
 await process_frame;await process_frame
 check(game.world.profile_draw_samples.size()>0,"New effects execute through the real draw callback")
 game.set_low_power(true)
 for i in range(100): game.visual_fx("impact",game.player_position(),20,Color.WHITE)
 check(game.visuals.size()==24,"Low-power visual effects remain bounded")
 game.enemies.clear();game.abilities.reset();game.tick(2)
 check(game.visuals.is_empty(),"Expired effects are removed from memory")
 game.hero.mp=Data.max_mp(game.hero);game.spell_cooldowns.frost=0
 game.cast("frost");game.clear_scene()
 check(game.visuals.is_empty(),"Scene changes clear previous combat effects")
 print(str(checks)+" PRESENTATION CHECKS PASSED")
 quit()
