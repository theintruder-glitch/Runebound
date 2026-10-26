extends RefCounted
# Stable world coordinates and IDs: new regions never rename legacy save keys.
const SIDE_TRAILS={
 "frost-cave":[Vector2(280,-2230),Vector2(280,-2310),Vector2(-260,-2310),Vector2(-260,-2440)],
 "highland-mine":[Vector2(1800,0),Vector2(1800,-160),Vector2(1870,-260)]
}
static func side_trail(p:Vector2) -> bool:
 var bounds={"frost-cave":Rect2(-320,-2500,660,340),"highland-mine":Rect2(1740,-320,190,380)}
 for id in SIDE_TRAILS:
  if bounds[id].has_point(p) and distance_to_trail(p,SIDE_TRAILS[id])<42:return true
 return false
const ZONES={
 "frostspire":{"name":"The Frostbound Peaks","castle":"Frostspire Citadel","region":"snow","area":Rect2(-450,-3450,1900,2000),"gate":Vector2(800,-2800),"trail":[Vector2(-100,-1460),Vector2(-100,-1840),Vector2(280,-2000),Vector2(280,-2230),Vector2(640,-2350),Vector2(800,-2540),Vector2(800,-2800)],"accent":Color("8cdaef"),"floor":5,"level":5,"material":"Frost shard","boss":"The Frost King","core":"Rime seal","spell":"wintercrown","relic":"Winter Sovereign","kind":"staff","order":["rune-c","rune-a","rune-b"],"clue":"Winter yields to dawn: Moon, Sun, then Star.","mechanism":"LIGHT THAW BRAZIER","image":"res://assets/frostspire.png"},
 "blackmire":{"name":"The Drowned Mire","castle":"Blackmire Fortress","region":"swamp","area":Rect2(-3400,-900,1850,1900),"gate":Vector2(-2820,640),"trail":[Vector2(-1500,440),Vector2(-1770,480),Vector2(-1770,180),Vector2(-2200,180),Vector2(-2440,400),Vector2(-2440,700),Vector2(-2700,700),Vector2(-2820,700),Vector2(-2820,640)],"accent":Color("c4a1f1"),"floor":3,"level":6,"material":"Glowcap","boss":"The Drowned Abomination","core":"Mire chain","spell":"mireward","relic":"Blackmire Carapace","kind":"armor","order":["rune-b","rune-c","rune-a"],"clue":"The drowned oath: Star, Moon, then Sun.","mechanism":"TURN DRAINAGE WHEEL","image":"res://assets/blackmire.png"},
 "stormbreak":{"name":"The Shattered Highlands","castle":"Stormbreak Bastion","region":"caves","area":Rect2(1480,-1250,1850,2600),"gate":Vector2(2780,950),"trail":[Vector2(1480,0),Vector2(1800,0),Vector2(1800,430),Vector2(2480,430),Vector2(2440,680),Vector2(2440,1140),Vector2(2780,1140),Vector2(2780,950)],"accent":Color("a8cfff"),"floor":4,"level":7,"material":"Crystal","boss":"The Storm Warden","core":"Stormcore","spell":"stormlance","relic":"Stormbreak Oath","kind":"sword","order":["rune-a","rune-c","rune-b"],"clue":"The first storm: Sun, Moon, then Star.","mechanism":"ALIGN STORM CONDUIT","image":"res://assets/stormbreak.png"}
}
static func zone_at(p:Vector2) -> String:
 for id in ZONES:
  if ZONES[id].area.has_point(p):return id
 return ""
static func distance_to_trail(p:Vector2,trail:Array) -> float:
 var result=INF
 for i in range(trail.size()-1):result=minf(result,Geometry2D.get_closest_point_to_segment(p,trail[i],trail[i+1]).distance_to(p))
 return result
static func foundation(id:String) -> Rect2:return Rect2(ZONES[id].gate-Vector2(270,560),Vector2(540,475))
static func room(r:Rect2i,title:String) -> Array:return [r,title]
