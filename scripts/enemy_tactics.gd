extends RefCounted
# Transient steering only: no character schema or saved-enemy changes.
const RANGED=["wisp","skeleton","crystal_wisp","archer","ice_archer"]
const CELL=64.0
var game
var buckets:Dictionary={}
func ranged(e:Dictionary) -> bool: return e.type in RANGED and not e.boss and not e.has("named")
func cell(at:Vector2) -> Vector2i: return Vector2i(floori(at.x/CELL),floori(at.y/CELL))
func prepare() -> void:
	buckets.clear()
	for index in range(game.enemies.size()):
		var e=game.enemies[index]
		e["tactic_order"]=index
		if e.dead or e.get("neutral",false) or e.pos.distance_squared_to(game.player_position())>640000: continue
		var key=cell(e.pos)
		if not buckets.has(key): buckets[key]=[]
		buckets[key].append(e)
func clear_step(e:Dictionary,direction:Vector2) -> bool:
	var target=e.pos+direction*28
	return game.walkable(target,e.radius) and game.line_clear(e.pos,target)
func firing_direction(e:Dictionary,base:Vector2) -> Vector2:
	var pos=game.player_position()
	if not ranged(e) or not game.line_clear(e.pos,pos): return base
	var distance=e.pos.distance_to(pos)
	if distance<105:
		var retreat=-e.pos.direction_to(pos)*.75
		# A cornered shooter stands its ground instead of walking into a wall.
		return retreat if clear_step(e,retreat) else Vector2.ZERO
	return Vector2.ZERO if distance<180 else base
func direction(e:Dictionary,base:Vector2) -> Vector2:
	if e.dead or e.boss or e.has("named") or e.get("neutral",false) or e.get("returning",false) or e.get("stagger",0.0)>0 or e.get("windup",0.0)>0 or (e.aggro<=0 and (game.hero.dungeon==null or e.pos.distance_squared_to(game.player_position())>=108900)): return base
	var result=firing_direction(e,base)
	# Keep the existing pathfinder in charge around corners and through doors.
	if result.length_squared()<.01: return result
	var push=Vector2.ZERO
	var key=cell(e.pos)
	for x in range(-1,2):
		for y in range(-1,2):
			for other in buckets.get(key+Vector2i(x,y),[]):
				if is_same(e,other) or other.dead: continue
				var offset=e.pos-other.pos
				var gap=e.radius+other.radius+12.0
				if offset.length_squared()>=gap*gap: continue
				if offset.length_squared()<.01:
					# Stable opposite directions for coincident spawns; never random jitter.
					push+=Vector2.UP if e.get("tactic_order",0)<other.get("tactic_order",0) else Vector2.DOWN
				else: push+=offset.normalized()*(1-offset.length()/gap)
	var steered=(result+push.limit_length(.65)).limit_length(1.0)
	return steered if clear_step(e,steered) else result
func attack_reachable(e:Dictionary,pos:Vector2) -> bool:
	var reach=330.0 if e.has("named") else 260.0 if e.type in RANGED else e.radius+100.0
	return e.pos.distance_to(pos)<=reach and game.line_clear(e.pos,pos) and game.line_clear(e.pos,e.strike)

func wilds_direction(e:Dictionary,dt:float) -> Vector2:
	# Ordinary wilds steering is sampled; movement, damage and warnings stay per frame.
	if e.boss or e.has("named") or e.has("trial"):
		return direction(e,game.survival.enemy_direction(e,dt))
	e["think_wait"]=e.get("think_wait",0.0)-dt
	e["think_elapsed"]=e.get("think_elapsed",0.0)+dt
	var moved=game.player_position().distance_squared_to(e.get("think_player",game.player_position()))>576
	if e.think_wait<=0 or moved or not e.has("steering"):
		e["steering"]=direction(e,game.survival.enemy_direction(e,e.think_elapsed))
		e["think_player"]=game.player_position();e.think_elapsed=0.0
		e.think_wait=.12+float(e.get("tactic_order",0)%3)*.01
	return e.steering
