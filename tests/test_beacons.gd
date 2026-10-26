extends SceneTree
const Data=preload("res://scripts/data.gd")
var game
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func restore():
 var saved=Data.migrate(JSON.parse_string(JSON.stringify(game.hero)))
 check(not saved.is_empty(),"Actual character JSON accepts beacon progress")
 if not saved.is_empty():game.start_character(saved);game.set_physics_process(false);game.spawn_timer=999999;game.enemies.clear()
func press_interaction(p:Vector2):
 game.hud.resume();game.set_physics_process(false);game.set_player_position(p);game.update_interaction()
 var event=InputEventScreenTouch.new();event.index=8;event.pressed=true;event.position=game.hud.interaction.get_global_rect().get_center()
 root.push_input(event,true);event.pressed=false;root.push_input(event,true)
 await process_frame
func button(parent:Node,prefix:String) -> Button:
 if parent is Button and parent.text.begins_with(prefix):return parent
 for child in parent.get_children():
  var found=button(child,prefix)
  if found!=null:return found
 return null
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;await process_frame
 for dimensions in [Vector2i(720,1280),Vector2i(1280,720)]:
  root.size=dimensions;game.adapt_screen();await process_frame
  var hero=Data.fresh("Mage");hero.mode="survival";game.start_character(hero);game.set_physics_process(false);game.enemies.clear();game.spawn_timer=999999
  var b=game.beacons
  for id in b.SITES:
   var info=b.SITES[id];var center:Vector2=info.point
   game.hero.auto=false
   check(not b.begin(id) and not b.claim(id),"Unsolved remote beacon cannot start or grant rewards")
   game.set_player_position(center);game.populate_chests(true)
   check(game.chests.all(func(c):return not b.reserved(c.pos)),"Ordinary caches leave the authored beacon clearing unobstructed")
   check(game.walkable(center,12),"Beacon center has full hero clearance: "+id)
   for key in b.OFFSETS:
    var p=center+b.OFFSETS[key]
    check(game.walkable(p,12) and game.move_position(center,p-center,12).distance_to(p)<1 and game.move_position(p,center-p,12).distance_to(center)<1,"Rune has a usable path in both directions: "+key)
   game.set_player_position(center+b.OFFSETS[info.order[0]])
   check(not b.align(id,info.order[0]) and b.progress(id)==0,"Read the actual oath before puzzle input")
   await press_interaction(center)
   check(b.has(id,"read"),"Actual mobile interaction reads the central oath")
   var wrong="moon" if info.order[0]!="moon" else "leaf"
   game.set_player_position(center+b.OFFSETS[wrong]);check(not b.align(id,wrong) and b.progress(id)==0,"Wrong first rune does not advance")
   await press_interaction(center+b.OFFSETS[info.order[0]])
   check(b.progress(id)==1,"Actual mobile interaction aligns first rune")
   restore();check(b.progress(id)==1,"Partial rune sequence persists across reload")
   game.set_player_position(center+b.OFFSETS[info.order[0]])
   check(not b.align(id,info.order[0]) and b.progress(id)==0,"Wrong later rune resets the entire sequence")
   for key in info.order:
    game.set_player_position(center+b.OFFSETS[key]);check(b.align(id,key),"Recorded rune order answers: "+key)
   check(b.has(id,"solved") and b.progress(id)==3,"All three stones solve the beacon")
   game.set_player_position(center);game.enemies.clear()
   var obstruction={"kind":"Wall","x":center.x,"y":center.y-56,"rotation":0,"fuel":0}
   game.hero.survival.structures.append(obstruction)
   check(not b.begin(id) and not b.active(),"Existing structure blocks unsafe watcher placement without deleting it")
   game.hero.survival.structures.erase(obstruction)
   var hostile=game.create_enemy(center+Vector2(0,100),1,"goblin");game.enemies.append(hostile)
   check(not b.begin(id) and game.enemies.has(hostile),"Nearby fight is preserved and prevents encounter stacking")
   game.enemies.clear()
   # Six far-idle ambient enemies should make space, but a burning distant actor stays.
   for i in range(6):game.enemies.append(game.create_enemy(center+Vector2(450+i*15,300),1,"goblin"))
   var burning=game.enemies[0];burning.burn=2
   await press_interaction(center)
   check(b.active() and game.enemies.size()==4 and game.enemies.has(burning),"Safe distant recycling preserves burning actor and keeps the six-enemy budget")
   check(game.spawn_enemy(true).is_empty(),"Ambient reinforcements pause during beacon challenge")
   check(not b.begin(id),"Repeated activation cannot duplicate the three watchers")
   game.enter_dungeon();check(game.hero.dungeon==null,"Cannot replace an active beacon challenge with a dungeon")
   game.exploration.begin_trial("snow");check(not game.exploration.active(),"Cannot stack a regional trial onto the beacon")
   var boss=b.foes.filter(func(e):return e.get("beacon_boss",false))[0]
   game.set_player_position(boss.pos+Vector2(0,80));var patterns={}
   for i in range(2):
    boss.cooldown=0;boss.windup=0;game.update_enemy_attack(boss,.016);patterns[boss.castle_attack]=true
    check(boss.windup>1 and boss.strike_radius>=43,"Keeper attack locks a readable warning before striking")
   check(patterns.size()==2,"Keeper has mark and slam attacks")
   boss.hp=boss.max_hp*.4;boss.cooldown=0;boss.windup=0;game.update_enemy_attack(boss,.016)
   check(boss.windup<1,"Wounded keeper accelerates its warning")
   game.hud._process(0);check(game.hud.boss_bar.visible,"Beacon encounter has a live health bar")
   game.hud.show_pause();var hp=game.hero.hp;await process_frame;check(game.hero.hp==hp and b.active(),"Menus pause the fight without abandoning it")
   game.hud.resume();game.set_physics_process(false);game.set_player_position(center+Vector2(400,0));b.tick(.1)
   check(not b.active() and b.has(id,"solved") and not b.has(id,"cleared"),"Retreat removes watchers but retains solved runes")
   game.enemies.clear();game.set_player_position(center);check(b.begin(id),"Abandoned encounter can be retried")
   restore();check(not b.active() and b.has(id,"solved") and not b.has(id,"cleared"),"Reload discards unfinished fight and retains puzzle")
   game.set_player_position(center);check(b.begin(id),"Reloaded encounter can be retried")
   game.hero.hp=0;game.defeated();check(not b.active() and b.has(id,"solved") and not game.playing,"Defeat cleans transient watchers without losing solved puzzle")
   game.hud.resume();game.set_physics_process(false);game.enemies.clear();game.set_player_position(center);check(b.begin(id),"Defeated player can retry at beacon")
   var decoy=game.create_enemy(center+Vector2(200,0),1,"goblin");game.enemies.append(decoy);game.kill_enemy(decoy,"melee")
   check(not b.has(id,"cleared"),"Unrelated enemy kill cannot clear beacon")
   for enemy in b.foes.duplicate():game.kill_enemy(enemy,"magic")
   check(not b.active() and b.has(id,"cleared"),"All three authored watchers must fall before completion")
   restore();game.set_player_position(center)
   check(b.has(id,"cleared") and not b.begin(id),"Cleared challenge persists and cannot be farmed again")
   while game.hero.inventory.size()<40:game.hero.inventory.append(game.hero.inventory[0].duplicate(true))
   var gold=game.hero.gold;var essence=game.hero.essence
   check(not b.claim(id) and not b.has(id,"claimed") and game.hero.gold==gold,"Full gear bag preserves unclaimed reward and currency")
   game.hero.inventory.pop_back();game.hero.survival.materials[info.core]=99998
   check(not b.claim(id) and game.hero.gold==gold,"Full core stack grants no partial reward")
   game.hero.survival.materials[info.core]=0;var points_before=game.hero.points
   check(b.claim(id),"Reward can be claimed after making room")
   check(game.hero.points==points_before+(2 if id==b.SITES.keys()[-1] else 0),"Only the fourth restored beacon grants two extra stat points")
   check(game.hero.gold==gold+250 and game.hero.essence==essence+5 and game.survival.count(info.core)==2,"Beacon grants exact currency and forging cores")
   check(game.hero.inventory[-1].name==info.reward and game.hero.inventory[-1].kind==info.slot and game.hero.inventory[-1].rarity==3,"Beacon grants its distinct Epic ring or charm")
   gold=game.hero.gold;check(not b.claim(id) and game.hero.gold==gold,"Repeated claim cannot duplicate relic or currency")
   restore();game.exploration.track(id)
   game.hud._process(0);check(info.name in game.hud.objective_label.text,"Survival HUD shows the tracked beacon objective")
   check(game.hero.exploration.target==id and info.name in game.exploration.objective(),"Tracking uses the beacon's current objective")
   restore();check(game.hero.exploration.target==id,"Beacon tracking survives JSON migration")
   # Free bag space for later beacon fixtures without touching actual saves.
   game.hero.inventory=game.hero.inventory.slice(0,1);game.enemies.clear()
  check(game.hero.opened.get("waykeeper-accord",false),"Restoring all four records the completed accord")
  var accord_points=game.hero.points;restore();check(game.hero.points==accord_points,"Accord stat reward survives reload without duplication")
  game.hud.show_character("beacons");await process_frame;await process_frame
  check(button(game.hud.content,"Track Rootlight Beacon")!=null and button(game.hud.content,"Track Skywatch Orrery")!=null,"Journal exposes all four tracking actions in both orientations")
  var old_scroll=game.hud.scroll.scroll_vertical;game.hud.scroll.scroll_vertical=200;await process_frame;old_scroll=game.hud.scroll.scroll_vertical
  game.hud.show_character("beacons");await process_frame;await process_frame
  check(abs(game.hud.scroll.scroll_vertical-old_scroll)<=1,"Beacon journal refresh preserves menu scroll fix")
  game.hud.resume();game.set_physics_process(false)
 # Malformed flags cannot forge progress or trigger out-of-range rune indexing.
 for opened in [{"beacon-emerald:read":"yes"},{"beacon-emerald:step-1":true},{"beacon-emerald:claimed":true},{"waykeeper-accord":true}]:
  var invalid=Data.fresh("Mage");invalid.opened=opened
  check(Data.migrate(invalid).is_empty(),"Malformed beacon progress rejected")
 print("%d BEACON CHECKS; %d FAILURES" % [checks,failures]);quit(1 if failures else 0)
