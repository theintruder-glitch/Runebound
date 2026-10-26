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
func reach(cell:Vector2i) -> bool:return not game.astar.get_id_path(game.dungeon_map.start,cell).is_empty()
func visit(flag:String) -> bool:
 game.set_player_position(game.cell_center(game.castle.features()[flag].cell));return game.castle.use_feature()
func restore() -> void:
 var saved=Data.migrate(JSON.parse_string(JSON.stringify(game.hero)))
 check(not saved.is_empty(),"Expedition survives actual JSON migration")
 if not saved.is_empty():game.start_character(saved);game.set_physics_process(false)
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;await process_frame
 var plans={}
 for orientation in [Vector2i(720,1280),Vector2i(1280,720)]:
  root.size=orientation;await process_frame
  for id in game.castle.caves.SITES:
   var hero=Data.fresh("Mage");hero.mode="survival"
   game.start_character(hero);game.set_physics_process(false);game.spawn_timer=999999
   var cave=game.castle.caves;var info=cave.SITES[id]
   check(not cave.enter(id),"Remote entry rejected")
   var trail=game.landscape.realms.Catalog.SIDE_TRAILS[id]
   for i in range(trail.size()-1):
    var a:Vector2=trail[i];var b:Vector2=trail[i+1]
    check(game.move_position(a,b-a,12).distance_to(b)<1 and game.move_position(b,a-b,12).distance_to(a)<1,"Side trail traversable in both directions")
   game.set_player_position(info.point)
   check(game.walkable(info.point,12),"Outdoor cave mouth has hero-radius clearance")
   check(game.landscape.feature_near()=="ENTER "+info.name.to_upper(),"Outdoor entrance offers the actual expedition")
   game.hero.opened[id]=true # Old outdoor-cache saves can still enter.
   check(game.landscape.feature_near().begins_with("ENTER"),"Previously looted outdoor cache remains enterable")
   game.interact()
   check(cave.active() and game.hero.dungeon.floor==1,"Real interaction loads the single expedition floor")
   check(game.enemies.size()==4 and game.chests.is_empty(),"Only four authored enemies and current floor load")
   check(not cave.enter(id),"Duplicate entrance cannot reset a run")
   var signature=JSON.stringify(game.dungeon_map.grid)
   if orientation.x<orientation.y:check(not plans.has(signature),"Cave plans are structurally different");plans[signature]=true
   check(not reach(cave.rooms()[4][0].get_center()),"Optional treasure chamber sealed by real collision")
   for i in range(4):check(reach(cave.rooms()[i][0].get_center()),"Exploration room connected: "+cave.rooms()[i][1])
   check(reach(game.castle.features().mechanism.cell),"Mechanism reachable before unlocking")
   check(visit("journal"),"Expedition journal provides mechanism clue")
   check(visit("mechanism"),"Mechanism opens the side passage")
   check(reach(cave.rooms()[4][0].get_center()),"Unlocked passage updates actual pathfinding")
   # Traverse every path to the rooms with the real movement/collision radius.
   for room in cave.rooms():
    var path=game.astar.get_id_path(game.dungeon_map.start,room[0].get_center());var ok=true
    for i in range(path.size()-1):
     var a=game.cell_center(path[i]);var b=game.cell_center(path[i+1])
     if game.move_position(a,b-a,12).distance_to(b)>1:ok=false
    check(ok,"Hero can traverse room path: "+room[1])
   check(not visit("treasure"),"Living boss/watchman block treasure")
   var enemy=game.enemies[0];game.kill_enemy(enemy,"melee");restore()
   check(game.castle.has("mechanism") and not game.enemies.any(func(e):return e.castle_index==0),"Reload retains open passage and defeated guard")
   var boss=game.enemies.filter(func(e):return e.get("cave_boss",false))[0];game.set_player_position(boss.pos+Vector2(0,90));var patterns={}
   for i in range(2):
    boss.cooldown=0;boss.windup=0;game.update_enemy_attack(boss,.016);patterns[boss.castle_attack]=true
    check(boss.windup>=1.2,"Boss pattern visibly warns before strike")
   check(patterns.size()==2,"Guardian has two distinct attack patterns")
   boss.hp=boss.max_hp*.4;boss.cooldown=0;boss.windup=0;game.update_enemy_attack(boss,.016)
   check(boss.windup<1,"Wounded guardian attacks faster")
   game.hud._process(0);check(game.hud.boss_bar.visible,"Cave guardian has a health bar")
   var trap=cave.traps()[0];game.set_player_position(game.cell_center(trap));var hp=game.hero.hp
   check(game.walkable(game.player_position(),12),"Trap occupies reachable terrain")
   game.castle.trap_clock=2.5;game.castle.tick(.3);check(game.hero.hp==hp,"Warning phase harmless")
   game.castle.tick(1.3);check(game.hero.hp<hp,"Warned environmental hazard deals damage")
   hp=game.hero.hp;game.dash_time=.3;game.castle.trap_clock=3.9;game.castle.tick(.2);check(game.hero.hp==hp,"Dodge avoids environmental hazard")
   game.dash_time=0;game.hud.show_pause();var clock=game.castle.trap_clock;game.castle.tick(4);check(game.castle.trap_clock==clock,"Menu pauses cave hazards")
   game.hud.resume();game.set_physics_process(false);game.hero.hp=0;game.defeated()
   check(cave.active() and not game.playing and game.player_position()==game.cell_center(game.dungeon_map.start),"Defeat restores safe entrance and pauses")
   check(game.castle.has("mechanism"),"Defeat retains mechanism progress")
   game.hud.resume();game.set_physics_process(false)
   for e in game.enemies.duplicate():
    if not e.dead and not e.get("castle_optional",false):game.kill_enemy(e,"melee")
   check(game.floor_clear(),"Optional guardian does not block retreat through gold stairs")
   check(not visit("treasure"),"Optional living guardian still protects reward")
   for e in game.enemies.duplicate():
    if not e.dead:game.kill_enemy(e,"melee")
   game.hero.survival.materials[info.material]=99995
   check(not visit("treasure") and not game.castle.has("treasure"),"Full supply stack preserves treasure")
   game.hero.survival.materials[info.material]=0;var gold=game.hero.gold;var essence=game.hero.essence
   check(visit("treasure"),"Cleared treasure can be collected after making room")
   check(game.hero.gold==gold+180 and game.hero.essence==essence+4 and game.survival.count(info.material)==5,"Treasure awards exact regional supplies and currency")
   check(not visit("treasure") and game.hero.gold==gold+180,"Repeated tap cannot duplicate reward")
   restore();check(game.hero.opened.get(id+"-treasure",false),"Character-wide reward flag persists")
   game.set_player_position(game.cell_center(game.dungeon_map.exit));game.interact()
   check(game.hero.dungeon==null and game.player_position()==info.point,"Gold stairs return to exact outdoor entrance")
   check(cave.enter(id),"Cleared cave can be revisited")
   visit("mechanism")
   for e in game.enemies.duplicate():
    if not e.dead:game.kill_enemy(e,"melee")
   gold=game.hero.gold;check(not visit("treasure") and game.hero.gold==gold,"New run cannot duplicate one-time expedition treasure")
   game.set_player_position(game.cell_center(game.dungeon_map.start));game.interact()
   check(game.hero.dungeon==null and game.player_position()==info.point,"Entrance stairs always provide retreat")
   game.exploration.track(id);check(game.hero.exploration.target==id and info.name in game.exploration.objective(),"Camp navigation tracks side expedition")
   var saved=Data.migrate(JSON.parse_string(JSON.stringify(game.hero)));check(not saved.is_empty() and saved.exploration.target==id,"Side expedition target survives save migration")
 # Reject malformed authored expeditions instead of loading arbitrary floors.
 game.start_character(Data.fresh("Mage"));game.set_physics_process(false);game.set_player_position(game.castle.caves.SITES["frost-cave"].point);game.castle.caves.enter("frost-cave")
 var invalid=game.hero.duplicate(true);invalid.dungeon.floor=2
 check(Data.migrate(invalid).is_empty(),"Side expedition save rejects nonexistent floors")
 print("%d SIDE CAVE CHECKS; %d FAILURES" % [checks,failures]);quit(1 if failures else 0)
