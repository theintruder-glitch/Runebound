extends RefCounted
# Exploration belongs to the active run, never the permanent character map.
var game
var stamp=""
var seen={}
var last_cell=Vector2i(-999,-999)
var revision=0
func active() -> bool:return not game.hero.is_empty() and game.hero.dungeon!=null and not game.dungeon_map.is_empty()
func observe(force:bool=false) -> void:
 if not active():stamp="";seen.clear();return
 var d=game.hero.dungeon;var key=str(int(d.floor))
 var current=str(d.run)+":"+str(d.seed)+":"+key
 var size_value:int=game.dungeon_map.size
 if current!=stamp:
  stamp=current;seen.clear();last_cell=Vector2i(-999,-999)
  if not d.has("atlas"):d.atlas={}
  if not d.atlas.has(key):d.atlas[key]=[]
  while d.atlas.size()>8:
   var oldest=""
   for floor_key in d.atlas:
    if floor_key!=key and (oldest.is_empty() or int(floor_key)<int(oldest)):oldest=floor_key
   d.atlas.erase(oldest)
  var remembered=d.atlas[key];d.atlas[key]=[]
  for value in remembered:
   var index=int(value)
   if index>=0 and index<size_value*size_value and not seen.has(index):seen[index]=true;d.atlas[key].append(index)
  revision+=1
 var cell=Vector2i(floori(game.hero.x/48),floori(game.hero.y/48))
 if not force and cell==last_cell:return
 last_cell=cell
 var changed=false
 for y in range(maxi(0,cell.y-2),mini(size_value,cell.y+3)):
  for x in range(maxi(0,cell.x-2),mini(size_value,cell.x+3)):
   var index=y*size_value+x
   if seen.has(index) or not game.dungeon_map.grid[y][x]:continue
   if not game.line_clear(game.player_position(),game.cell_center(Vector2i(x,y))):continue
   seen[index]=true;d.atlas[key].append(index);changed=true
 if changed:revision+=1
func known(cell:Vector2i) -> bool:return active() and seen.has(cell.y*game.dungeon_map.size+cell.x)
func destinations() -> Dictionary:
 if not active():return {}
 var result={"entrance":{"cell":game.dungeon_map.start,"name":"Entrance · back one floor" if game.castle.active() and game.hero.dungeon.floor>1 else "Entrance · return outside"}}
 if known(game.dungeon_map.exit):result["stairs"]={"cell":game.dungeon_map.exit,"name":"Gold stairs · "+("ready" if game.floor_clear() else "guards remain")}
 if game.castle.active():
  var features=game.castle.features()
  for id in features:
   if known(features[id].cell) and not game.castle.has(id):result["feature:"+id]={"cell":features[id].cell,"name":features[id].label.capitalize()}
  var rooms=game.castle.rooms(game.hero.dungeon.floor)
  for i in range(rooms.size()):
   var cell:Vector2i=rooms[i][0].get_center()
   if known(cell):result["room:"+str(i)]={"cell":cell,"name":rooms[i][1]}
 if game.mire.stage()==4 and game.mire.archive_cell().x>=0 and known(game.mire.archive_cell()):result["story:testament"]={"cell":game.mire.archive_cell(),"name":"Recover Drowned Testament"}
 return result
func route(id:String) -> PackedVector2Array:
 var result=PackedVector2Array();var places=destinations()
 if not places.has(id):return result
 var cell=Vector2i(floori(game.hero.x/48),floori(game.hero.y/48))
 var path=game.astar.get_id_path(cell,places[id].cell)
 for step in path:
  if id!="entrance" and not known(step):return PackedVector2Array()
  result.append(game.cell_center(step))
 return result
func describe(id:String) -> String:
 var places=destinations()
 if not places.has(id):return "Choose a discovered room or landmark."
 return places[id].name+"\n"+("Follow the gold route. Walk there using your normal controls." if not route(id).is_empty() else "No explored route yet. Explore the corridors and check keys or mechanisms.")
