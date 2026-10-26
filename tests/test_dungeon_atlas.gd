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
func find_button(parent:Node,prefix:String) -> Button:
 if parent is Button and parent.text.begins_with(prefix):return parent
 for child in parent.get_children():
  var found=find_button(child,prefix)
  if found!=null:return found
 return null
func settle():
 for i in range(4):await process_frame
func restore():
 var saved=Data.migrate(JSON.parse_string(JSON.stringify(game.hero)))
 check(not saved.is_empty(),"Survey survives actual JSON migration")
 if not saved.is_empty():game.start_character(saved);game.set_physics_process(false)
func enter(id:String):
 game.start_character(Data.fresh("Mage"));game.set_physics_process(false);game.hero.auto=false
 if id=="thornwatch":game.set_player_position(game.landscape.KEEP);game.castle.enter()
 elif game.castle.caves.SITES.has(id):game.set_player_position(game.castle.caves.SITES[id].point);game.castle.caves.enter(id)
 else:game.set_player_position(game.landscape.realms.Catalog.ZONES[id].gate);game.castle.enter_region(id)
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
 for dims in [Vector2i(720,1280),Vector2i(1280,720)]:
  root.size=dims;game.adapt_screen();await settle()
  for id in ["thornwatch","frostspire","blackmire","stormbreak","frost-cave","highland-mine"]:
   enter(id)
   check(game.atlas.active() and game.atlas.seen.size()>0,"Entrance begins a survey: "+id)
   check(game.atlas.seen.size()<game.dungeon_map.floors.size()/2,"Distant rooms stay unexplored")
   check(game.atlas.destinations().has("entrance") and not game.atlas.destinations().has("stairs"),"Entrance known; unseen upper stairs remain hidden")
   var features=game.castle.features();var feature="mechanism" if game.castle.caves.active() else "key";var target:Vector2i=features[feature].cell
   check(not game.atlas.destinations().has("feature:"+feature),"Unvisited object is not spoiled by the atlas")
   var path=game.astar.get_id_path(game.dungeon_map.start,target);var walk_ok=true
   for i in range(1,path.size()):
    var a=game.cell_center(path[i-1]);var b=game.cell_center(path[i]);var p=game.move_position(a,b-a,12)
    if p.distance_to(b)>1:walk_ok=false
    game.set_player_position(p);game.atlas.observe()
   check(walk_ok and path.size()>1,"Real collision route reaches discoverable object")
   check(game.atlas.known(target) and game.atlas.destinations().has("feature:"+feature),"Object becomes a selectable discovery on arrival")
   check(not game.atlas.route("entrance").is_empty(),"Explored route connects back to entrance")
   var size_before=game.atlas.seen.size();game.atlas.observe();game.atlas.observe()
   check(game.atlas.seen.size()==size_before,"Stationary observation creates no duplicate survey cells")
   restore();check(game.atlas.known(target) and game.atlas.seen.size()>=size_before,"Object and explored corridors persist on continue")
   game.hud.show_character("map");await settle();var map=game.hud.map_widget
   check(map.get_script()==load("res://scripts/dungeon_map.gd"),"Map opens current dungeon rather than outdoor coordinates")
   check(game.hud.scroll.get_global_rect().encloses(map.get_global_rect()),"Whole floor map fits portrait and landscape menu")
   check(map.player_marker.distance_to(map.canvas_point(game.player_position()))<.1,"Marker projects actual dungeon player position")
   var previous=map.player_marker;game.set_player_position(game.player_position()+Vector2(5,0));game.facing=Vector2.RIGHT;await settle()
   check(map.player_marker.x>previous.x,"Marker follows fractional movement instead of sticking in a corner")
   var touch=InputEventScreenTouch.new();touch.index=7;touch.pressed=true;touch.position=map.global_position+map.markers.entrance
   root.push_input(touch,true);touch.pressed=false;root.push_input(touch,true);await settle()
   check(map.selected=="entrance" and "Follow the gold route" in game.hud.map_detail.text,"Actual touch selects entrance and describes its route")
   var at=game.player_position();find_button(game.hud.content,"World map").pressed.emit();await settle()
   check(game.hud.map_widget.get_script()==load("res://scripts/world_map.gd") and game.player_position()==at,"World-map toggle never teleports character")
   check(game.hud.map_widget.position_in_wilds()==Vector2(game.hero.dungeon.returnX,game.hero.dungeon.returnY),"Outdoor map still marks dungeon entrance in world coordinates")
   find_button(game.hud.content,"Current dungeon floor").pressed.emit();await settle()
   check(game.hud.map_widget.get_script()==load("res://scripts/dungeon_map.gd"),"Can return to current floor map")
   check(game.castle.use_feature(),"Existing object interaction still works after map navigation")
   game.atlas.observe(true);check(not game.atlas.destinations().has("feature:"+feature),"Collected object leaves the unclaimed-object markers")
   game.hud.resume();game.set_physics_process(false)
 # Backtracking retains a separate survey for each castle floor.
 enter("thornwatch")
 for flag in ["key","seal"]:
  game.set_player_position(game.cell_center(game.castle.features()[flag].cell));game.castle.use_feature();game.atlas.observe(true)
 var remembered=game.hero.dungeon.atlas["1"].duplicate()
 for e in game.enemies.duplicate():game.kill_enemy(e,"magic")
 check(game.castle.advance() and game.hero.dungeon.floor==2,"Actual castle stairs open a separately surveyed floor")
 check(game.hero.dungeon.atlas.has("1") and game.hero.dungeon.atlas.has("2"),"Both floors retain independent survey memory")
 check(game.castle.retreat() and game.hero.dungeon.floor==1,"Entrance stairs backtrack normally")
 check(remembered.all(func(cell):return game.atlas.seen.has(int(cell))),"Backtracking preserves all earlier discovered cells")
 game.leave_dungeon();check(not game.atlas.active() and not game.hero.has("atlas"),"Leaving ends run memory without adding global character fields")
 # Existing saves gain the map without losing progress; bad optional data is repaired.
 enter("frost-cave");game.hero.dungeon.erase("atlas");restore()
 check(game.atlas.seen.size()>0 and not game.atlas.route("entrance").is_empty(),"Old in-progress expedition gains safe entrance routing")
 for invalid in [[],{"1":[-1,999999]}, {"oops":[1]}, {"1":["bad"]}]:
  var saved=game.hero.duplicate(true);saved.dungeon.atlas=invalid;var repaired=Data.migrate(saved)
  check(not repaired.is_empty() and repaired.level==saved.level and repaired.inventory==saved.inventory,"Malformed optional survey repairs without wiping character")
 # Classic endless runs keep the newest eight floors, bounding save and memory use.
 game.start_character(Data.fresh("Warrior"));game.set_physics_process(false);game.enter_dungeon()
 for i in range(10):
  for e in game.enemies.duplicate():game.kill_enemy(e,"melee")
  game.advance_floor()
 check(game.hero.dungeon.floor==11 and game.hero.dungeon.atlas.size()==8,"Endless runs cap retained surveys at eight floors")
 check(not game.hero.dungeon.atlas.has("1") and game.hero.dungeon.atlas.has("11"),"Oldest survey drops before current floor")
 print("%d ATLAS CHECKS; %d FAILURES" % [checks,failures]);quit(1 if failures else 0)
