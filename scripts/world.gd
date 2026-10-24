extends Node2D

const Data = preload("res://scripts/data.gd")
const TILE = 48
const SpriteAtlas = preload("res://assets/sprites.svg")
const SceneryScript = preload("res://scripts/scenery.gd")
var game
var terrain: TileMapLayer
var last_region = Vector2i(999999,999999)
var last_mode = ""
var clock = 0.0
var textures: Dictionary = {}
var scenery
var scenery_key = ""
var scenery_rebuilds = 0
var profile_draw_samples: Array = []
var profile_hero_positions: Array = []
var profile_enabled = false
var terrain_cells: Dictionary = {}
var tile_origin = Vector2i.ZERO
var last_extent = Vector2i.ZERO
var draw_bounds = Rect2()
var palette_season=""

func _ready() -> void:
	for i in range(9):
		var texture = AtlasTexture.new()
		texture.atlas = SpriteAtlas
		texture.region = Rect2(i*64,0,64,96)
		textures[["tree","rock","chest","chest_open","slime","goblin","skeleton","wisp","guardian"][i]] = texture
	scenery = SceneryScript.new()
	scenery.world = self
	scenery.z_index = -5
	add_child(scenery)
	terrain = TileMapLayer.new()
	add_child(terrain)
	terrain.z_index = -10
	build_palette("Spring")

func build_palette(season:String) -> void:
	palette_season=season
	var image = Image.create(TILE*12,TILE,false,Image.FORMAT_RGBA8)
	var colors = [Color("1b3b32"),Color("203f34"),Color("17352d"),Color("203d3b"),Color("303443"),Color("b2c8d0"),Color("354348"),Color("19232f"),Color("23312c"),Color("c6d9dc"),Color("443a55"),Color("31503b")]
	if season=="Summer":
		colors[0]=Color("294a32");colors[1]=Color("345236");colors[2]=Color("24432c")
	elif season=="Autumn":
		colors[0]=Color("514331");colors[1]=Color("5c4933");colors[2]=Color("483d30");colors[11]=Color("6a5540")
	elif season=="Winter":
		colors[0]=Color("8ba4a6");colors[1]=Color("98afb0");colors[2]=Color("829da0");colors[11]=Color("728c8a");colors[3]=Color("50696a");colors[8]=Color("425c61")
	var rng = RandomNumberGenerator.new()
	rng.seed = 1594
	for tile in range(12):
		image.fill_rect(Rect2i(tile*TILE,0,TILE,TILE),colors[tile])
		for i in range(35):
			var px = tile*TILE+rng.randi_range(2,45)
			var py = rng.randi_range(2,45)
			image.fill_rect(Rect2i(px,py,2,3),colors[tile].lightened(rng.randf_range(.03,.14)))
		if tile==7:
			image.fill_rect(Rect2i(tile*TILE,0,TILE,3),colors[tile].lightened(.14))
			image.fill_rect(Rect2i(tile*TILE,0,2,TILE),colors[tile].darkened(.2))
			image.fill_rect(Rect2i(tile*TILE,TILE-2,TILE,2),colors[tile].darkened(.2))
	var atlas = TileSetAtlasSource.new()
	atlas.texture = ImageTexture.create_from_image(image)
	atlas.texture_region_size = Vector2i(TILE,TILE)
	for i in range(12):
		atlas.create_tile(Vector2i(i,0))
	var tiles = TileSet.new()
	tiles.tile_size = Vector2i(TILE,TILE)
	tiles.add_source(atlas,0)
	terrain.tile_set = tiles

func refresh(force: bool=false) -> void:
	if game==null or game.hero.is_empty():
		return
	var camera_at = game.camera.position
	var center = Vector2i(roundi(camera_at.x/TILE/8),roundi(camera_at.y/TILE/8))
	var view = get_viewport_rect().size
	var extent = Vector2i(ceili(view.x/TILE/2)+6,ceili(view.y/TILE/2)+6)
	if palette_season!=game.weather.season():
		build_palette(game.weather.season())
		force=true
	var biome = game.exploration.region_at(game.player_position())
	var mode = "wilds-"+str(biome) if game.hero.dungeon==null else "dungeon-"+str(game.hero.dungeon.seed)
	if not force and mode==last_mode and (game.hero.dungeon!=null or (center==last_region and extent==last_extent)):
		return
	var reset = force or mode!=last_mode
	last_region = center
	last_mode = mode
	last_extent = extent
	if reset:
		terrain.clear()
		terrain_cells.clear()
	if game.hero.dungeon!=null:
		terrain.position = Vector2.ZERO
		for y in range(game.dungeon_map.size):
			for x in range(game.dungeon_map.size):
				terrain.set_cell(Vector2i(x,y),0,Vector2i(6 if game.dungeon_map.grid[y][x] else 7,0))
	else:
		var global_center = center*8
		if (global_center-tile_origin).abs().x>4096 or (global_center-tile_origin).abs().y>4096:
			terrain.clear()
			terrain_cells.clear()
			tile_origin=global_center
		terrain.position = Vector2(tile_origin)*TILE
		var needed = Rect2i(global_center-extent,extent*2+Vector2i.ONE)
		for cell in terrain_cells.keys():
			if not needed.has_point(cell):
				terrain.erase_cell(cell-tile_origin)
				terrain_cells.erase(cell)
		for x in range(needed.position.x,needed.end.x):
			for y in range(needed.position.y,needed.end.y):
				var cell = Vector2i(x,y)
				if terrain_cells.has(cell):
					continue
				var id = game.exploration.terrain_id(Vector2(cell)*TILE+Vector2.ONE*24)
				terrain.set_cell(cell-tile_origin,0,Vector2i(id,0))
				terrain_cells[cell] = true
	refresh_scenery(true)
	queue_redraw()

func refresh_scenery(force: bool=false) -> void:
	var at = game.camera.position
	var view = get_viewport_rect().size
	var cell = Vector2i(floori(at.x/TILE),floori(at.y/TILE))
	var key = str(cell)+":"+str(view)+":"+str(game.chunk_key)+":"+str(game.hero.opened.size())+":"+str(game.hero.kingdom.buildings.size())+":"+last_mode+":"+str(game.survival.revision)
	if key==scenery_key and not force:
		return
	scenery_key = key
	scenery_rebuilds += 1
	scenery.bounds = Rect2(at-view/2-Vector2(120,120),view+Vector2(240,240))
	scenery.decorations.clear()
	scenery.visible_chests.clear()
	if game.hero.dungeon==null:
		var begin = Vector2i(floori(scenery.bounds.position.x/TILE),floori(scenery.bounds.position.y/TILE))
		var end = Vector2i(ceili(scenery.bounds.end.x/TILE),ceili(scenery.bounds.end.y/TILE))
		for x in range(begin.x,end.x+1):
			for y in range(begin.y,end.y+1):
				var h = tile_hash(x,y,2)
				if h<.055 or h>.974:
					var spot=Vector2(x*TILE+24,y*TILE+24)
					var region_id=game.exploration.region_at(spot)
					scenery.decorations.append({"kind":"rock" if region_id=="caves" else "tree" if h<.055 else "rock","pos":spot,"biome":region_id})
	for chest in game.chests:
		if scenery.bounds.has_point(chest.pos):
			scenery.visible_chests.append(chest)
	scenery.queue_redraw()

static func tile_hash(x: int,y: int,salt: int=0) -> float:
	var value = sin(float(x)*127.1+float(y)*311.7+salt*78.233)*43758.5453123
	return value-floor(value)

func _process(dt: float) -> void:
	if game==null or game.hero.is_empty():
		return
	refresh_scenery()
	if game.playing:
		clock += dt
		queue_redraw()

func _draw() -> void:
	if game==null or game.hero.is_empty():
		return
	var hero_position = Vector2(game.hero.x,game.hero.y)
	var profile_start = Time.get_ticks_usec() if profile_enabled else 0
	draw_bounds = Rect2(game.camera.position-get_viewport_rect().size/2-Vector2(80,80),get_viewport_rect().size+Vector2(160,160))
	if game.hero.dungeon!=null:
		for key in ["start","exit"]:
			var at = game.cell_center(game.dungeon_map[key])
			if not draw_bounds.has_point(at):
				continue
			var color = Color("a6e5c1") if key=="start" else Color("e8cc7f") if game.floor_clear() else Color("8b8799")
			for i in range(4):
				draw_rect(Rect2(at+Vector2(-17+i*2,-12+i*7),Vector2(34-i*4,4)),color)
			label(at+Vector2(-26,-21),"WILDS" if key=="start" else "DOWN" if game.floor_clear() else "LOCKED",10,color)
	if not game.build_recipe.is_empty() and game.hero.dungeon==null:
		var pos=game.survival.place_position()
		var rect=game.survival.footprint(game.build_recipe,pos,game.build_rotation)
		var valid=game.survival.reason(game.build_recipe).is_empty()
		draw_rect(rect,Color("77e5ac44") if valid else Color("ef817d55"))
		draw_rect(rect,Color("9cf7c2") if valid else Color("ff928e"),false,2)
		draw_line(pos,pos+Vector2.UP.rotated(game.build_rotation*PI/2)*27,Color("f6e5b5"),3)
		label(pos+Vector2(-25,-40),game.build_recipe,12,Color("f4e7c7"))
	for enemy in game.enemies:
		if not enemy.dead and enemy.get("windup",0.0)>0 and draw_bounds.has_point(enemy.strike):
			draw_circle(enemy.strike,enemy.strike_radius,Color("e77a6844"))
			draw_arc(enemy.strike,enemy.strike_radius,0,TAU,48,Color("ff9b7f"),2)
			var progress=1-clampf(enemy.windup/maxf(.1,enemy.get("windup_max",enemy.windup)),0,1)
			draw_arc(enemy.strike,enemy.strike_radius-5,-PI/2,-PI/2+TAU*progress,32,Color("ffe1aa"),3)
			label(enemy.strike+Vector2(-5,-8),"!",24,Color("ffe1a1"))
	if game.abilities.sanctuary>0:
		draw_circle(game.abilities.sanctuary_at,105,Color("a6dfac22"))
		draw_arc(game.abilities.sanctuary_at,105,clock,clock+TAU,48,Color("c9e8b5"),2)
	for visual in game.visuals:
		if draw_bounds.grow(visual.radius).has_point(visual.pos): draw_visual(visual)
	var actors = game.enemies.filter(func(e):return not e.dead and draw_bounds.has_point(e.pos))
	actors.append({"hero":true,"pos":hero_position})
	actors.sort_custom(func(a,b): return a.pos.y<b.pos.y)
	for actor in actors:
		if actor.has("hero"):
			draw_hero(hero_position)
		elif not actor.dead:
			draw_enemy(actor)
	for shot in game.shots:
		if not draw_bounds.has_point(shot.pos):
			continue
		var color = Color("e4cf9b") if shot.kind=="bow" else Color("ffb077") if shot.kind=="fire" else Color("c9adf8")
		if shot.get("enchant",0)>0: color=[color,Color("ffbc80"),Color("9fe0f0"),Color("cdb4f4"),Color("edabc0")][int(shot.enchant)]
		var direction = shot.velocity.normalized()
		if shot.kind!="bow":
			var trail=color;trail.a=.35
			draw_line(shot.pos-direction*26,shot.pos,trail,8)
			draw_circle(shot.pos,5,color)
		elif shot.get("enchant",0)>0:
			var trail=color;trail.a=.4
			draw_line(shot.pos-direction*22,shot.pos,trail,4)
		draw_line(shot.pos-direction*10,shot.pos+direction*5,color,2 if shot.kind=="bow" else 5)
		if shot.kind=="bow":
			draw_line(shot.pos+direction*5,shot.pos-direction.rotated(.65)*4,color,2)
			draw_line(shot.pos+direction*5,shot.pos-direction.rotated(-.65)*4,color,2)
	for effect in game.effects:
		if not draw_bounds.has_point(effect.pos):
			continue
		var color = effect.color
		color.a = clampf(effect.life*2,0,1)
		if effect.has("text"):
			label(effect.pos,effect.text,18 if effect.text.ends_with("!") else 14,color)
		else:
			draw_circle(effect.pos,2,color)

	draw_weather()
	game.desktop.draw_reticle(self)
	if profile_enabled:
		profile_draw_samples.append(Time.get_ticks_usec()-profile_start)
		profile_hero_positions.append(hero_position)

func draw_tree(at: Vector2) -> void:
	draw_set_transform(at)
	draw_circle(Vector2(2,12),20,Color("0c201d77"))
	draw_rect(Rect2(-4,0,8,20),Color("5e5039"))
	for i in range(3):
		var color = [Color("254a36"),Color("2f5a3f"),Color("426d4b")][i]
		draw_colored_polygon(PackedVector2Array([Vector2(-25+i*4,9-i*11),Vector2(0,-30-i*7),Vector2(25-i*4,9-i*11)]),color)
	draw_set_transform(Vector2.ZERO)

func draw_hero(at: Vector2) -> void:
	draw_set_transform(at)
	var cls=game.hero.className
	var facing=game.facing
	var angle=facing.angle()
	var bob=sin(clock*13)*4 if game.is_walking else 0.0
	var color=Color(Data.CLASSES[cls].color)
	if not Data.equipped(game.hero,"armor").is_empty(): color=color.lightened(.12)
	draw_circle(Vector2(0,15),14,Color("061c1c99"))
	if game.abilities.stealth>0: draw_arc(Vector2.ZERO,25,0,TAU,28,Color("bda6e388"),2)
	if cls in ["Spellblade","Arcane Archer","Reaper"]:
		draw_arc(Vector2(0,8),19,clock*.7,clock*.7+4,22,color*.9,2)
	for side in [-1,1]:
		var foot=Vector2(side*5,15)+Vector2(facing.x,facing.y*.7)*bob*side
		draw_line(Vector2(side*5,5),foot,Color("29383b"),6)
		draw_rect(Rect2(foot-Vector2(3,0),Vector2(7,4)),Color("baa381"))
	draw_rect(Rect2(-10,-9,20,19),color)
	draw_line(Vector2(-12,-5),Vector2(-14,6)+facing*bob*.4,Color("d6b494"),5)
	draw_line(Vector2(12,-5),Vector2(14,6)-facing*bob*.4,Color("d6b494"),5)
	draw_rect(Rect2(-7,-23,14,14),Color("e5c39f"))
	draw_rect(Rect2(-8,-25,16,6),Color("403d37"))
	if facing.y<-.3: draw_rect(Rect2(-7,-23,14,12),Color("403d37"))
	else: draw_rect(Rect2(2 if facing.x>=0 else -5,-17,3,3),Color("17302d"))
	match cls:
		"Warrior":
			draw_rect(Rect2(-14,-11,8,6),Color("bac6c4")); draw_rect(Rect2(6,-11,8,6),Color("bac6c4"))
		"Mage": draw_colored_polygon(PackedVector2Array([Vector2(-14,-23),Vector2(0,-43),Vector2(13,-23)]),color)
		"Ranger","Arcane Archer":
			draw_arc(Vector2(0,-18),12,PI,TAU,16,color,5)
			for i in range(3): draw_line(Vector2(-13+i*3,-2),Vector2(-14+i*3,-24),Color("d6bc83"),1)
		"Cleric": draw_line(Vector2(0,-5),Vector2(0,7),Color("f5edd6"),3); draw_line(Vector2(-4,0),Vector2(4,0),Color("f5edd6"),3)
		"Rogue","Reaper":
			draw_arc(Vector2(0,-18),12,PI,TAU,16,Color("30313e"),6)
			if facing.y>=-.3: draw_rect(Rect2(-7,-14,14,5),Color("3e344a"))
		"Spellblade": draw_colored_polygon(PackedVector2Array([Vector2(0,-6),Vector2(4,0),Vector2(0,6),Vector2(-4,0)]),Color("f2c7fa"))
	if not Data.equipped(game.hero,"helmet").is_empty(): draw_rect(Rect2(-8,-26,16,4),Color("c3cfce"))
	if not Data.equipped(game.hero,"shield").is_empty(): draw_rect(Rect2(-24,-7,10,21),Color("aa9c72"))
	var weapon=Data.equipped(game.hero,"weapon")
	var enchant=int(weapon.get("enchant",0))
	var metal=[Color("e3d6b4"),Color("ffab6b"),Color("9cddf7"),Color("c4a0f1"),Color("e999ac")][enchant]
	var hand=Vector2(12 if facing.x>=0 else -12,0)+facing*3
	var swing=(1-game.swing_time/.3) if game.swing_time>0 else .5
	draw_set_transform(at+hand,angle+(-.8+swing*1.6 if game.swing_time>0 and weapon.get("kind")=="sword" else 0))
	match weapon.get("kind","sword"):
		"bow":
			draw_arc(Vector2.ZERO,15,-1.2,1.2,15,metal,2)
			draw_line(Vector2(5,-14),Vector2(5,14),metal,1)
			if game.swing_time>0: draw_line(Vector2(-8,0),Vector2(20,0),Color("fff2c9"),2)
		"staff": draw_line(Vector2(-12,0),Vector2(21,0),metal,3); draw_circle(Vector2(23,0),5,color.lightened(.4))
		_: draw_line(Vector2(-5,0),Vector2(24,0),metal,4); draw_line(Vector2(0,-6),Vector2(0,6),Color("b9a078"),3)
	draw_set_transform(at)
	if game.swing_time>0: draw_arc(Vector2.ZERO,36,angle-.8,angle+.8,18,Color("f9e8be"),3)
	if game.dash_time>0: draw_arc(Vector2.ZERO,24,0,TAU,24,Color("a4f3cb"),2)
	draw_colored_polygon(PackedVector2Array([Vector2(0,-47),Vector2(-4,-54),Vector2(4,-54)]),Color("a7e3b6"))
	draw_set_transform(Vector2.ZERO)

func draw_enemy(enemy: Dictionary) -> void:
	var at = enemy.pos
	if enemy.has("named"):
		draw_arc(at,34,0,TAU,28,Color("d1be76"),2)
		label(at+Vector2(-54,-78),enemy.named,14,Color("edda98"))
	var tint = Color(1.5,1.5,1.5) if enemy.flash>0 else Color(.7,1,1.3) if enemy.slow>0 else Color.WHITE
	if enemy.type in ["wolf","frost_wolf","deer"]:
		draw_beast(enemy)
	else:
		var sprite={"archer":"goblin","ice_archer":"skeleton","bog_toad":"slime","crystal_wisp":"wisp"}.get(enemy.type,enemy.type)
		if enemy.type=="ice_archer": tint=Color(.8,1.2,1.5)
		elif enemy.type=="bog_toad": tint=Color(.8,1.1,.7)
		elif enemy.type=="crystal_wisp": tint=Color(1.2,.9,1.5)
		draw_texture(textures[sprite],at-Vector2(32,64),tint)
		if enemy.type in ["archer","ice_archer","skeleton"]:
			draw_set_transform(at+Vector2(12,-16),at.direction_to(game.player_position()).angle())
			draw_arc(Vector2.ZERO,14,-1.2,1.2,12,Color("dfc48e"),2)
			draw_line(Vector2(5,-13),Vector2(5,13),Color("dfc48e"),1)
			draw_set_transform(Vector2.ZERO)
	if enemy.get("named","")=="The Root Warden":
		for side in [-1,1]:
			draw_line(at+Vector2(side*10,-42),at+Vector2(side*30,-68),Color("a18a59"),5)
			draw_line(at+Vector2(side*21,-56),at+Vector2(side*40,-60),Color("a18a59"),4)
		draw_circle(at+Vector2(0,-25),7,Color("a7e5b5"))
	if enemy.hp<enemy.max_hp or enemy.boss:
		var width = 52.0 if enemy.boss else 32.0
		draw_rect(Rect2(at+Vector2(-width/2,-enemy.radius-20),Vector2(width,4)),Color("142b2d"))
		draw_rect(Rect2(at+Vector2(-width/2,-enemy.radius-20),Vector2(width*maxf(0,enemy.hp/enemy.max_hp),4)),Color("dcaa7a") if enemy.boss else Color("d18d87"))
	if enemy.boss or not game.low_power:
		label(at+Vector2(-10,enemy.radius+17),"Lv "+str(enemy.level),10,Color("c4d0bc"))

func draw_beast(enemy:Dictionary) -> void:
	var at=enemy.pos
	var direction=enemy.get("motion",Vector2.RIGHT)
	var side=1 if direction.x>=0 else -1
	var deer=enemy.type=="deer"
	var fur=Color("b19470") if deer else Color("c0d7df") if enemy.type=="frost_wolf" else Color("8e9b9c")
	if enemy.flash>0: fur=Color("f4e7cf")
	var step=sin(clock*14)*5 if direction.length()>.1 else 0.0
	draw_circle(at+Vector2(0,10),17,Color("102b2c88"))
	for x in [-10,10]:
		draw_line(at+Vector2(x,0),at+Vector2(x+step*(1 if x>0 else -1),15),fur.darkened(.25),4)
	draw_rect(Rect2(at+Vector2(-16,-10),Vector2(32,19)),fur)
	draw_circle(at+Vector2(side*19,-13),9,fur)
	draw_line(at+Vector2(-side*15,-7),at+Vector2(-side*29,-16),fur,5)
	draw_colored_polygon(PackedVector2Array([at+Vector2(side*13,-17),at+Vector2(side*12,-29),at+Vector2(side*21,-19)]),fur)
	draw_rect(Rect2(at+Vector2(side*23-4,-14),Vector2(10,6)),fur)
	draw_circle(at+Vector2(side*21,-16),2,Color("172a2b") if deer else Color("f6d697"))
	if deer:
		draw_line(at+Vector2(side*17,-20),at+Vector2(side*12,-36),Color("d8bc8d"),2)
		draw_line(at+Vector2(side*12,-30),at+Vector2(side*3,-34),Color("d8bc8d"),2)
		label(at+Vector2(-22,-42),"WILDLIFE",9,Color("bcd7c0"))

func label(at: Vector2,text_value: String,font_size: int,color: Color) -> void:
	draw_string(ThemeDB.fallback_font,at,text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func draw_visual(effect:Dictionary) -> void:
	var progress=1-clampf(effect.life/effect.duration,0,1)
	var color:Color=effect.color
	color.a*=1-progress
	var pos:Vector2=effect.pos
	var radius:float=effect.radius
	match effect.kind:
		"impact":
			var r=radius*(.4+progress*.6)
			for i in range(4):
				var direction=Vector2.from_angle(i*PI/2+.4)
				draw_line(pos+direction*r*.35,pos+direction*r,color,2)
		"dodge":
			var direction:Vector2=effect.get("direction",Vector2.DOWN)
			var side=direction.orthogonal()
			for i in range(2):
				var tip=pos+direction*(radius*(.4+progress*.5)-i*12)
				draw_polyline(PackedVector2Array([tip-direction*9+side*8,tip,tip-direction*9-side*8]),color,2)
		"dash":
			color.a*=.4
			draw_rect(Rect2(pos+Vector2(-9,-22),Vector2(18,32)),color)
		"storm":
			var end:Vector2=effect.get("end",pos)
			var delta=end-pos
			var normal=delta.normalized().orthogonal()
			var points=PackedVector2Array([pos,pos+delta*.3+normal*9,pos+delta*.6-normal*8,end])
			draw_polyline(points,color,3)
		"heal":
			draw_arc(pos,radius*(.5+progress*.5),0,TAU,32,color,2)
			for i in range(3):
				var center=pos+Vector2((i-1)*15,-progress*35-i*5)
				draw_line(center-Vector2(0,5),center+Vector2(0,5),color,2)
				draw_line(center-Vector2(5,0),center+Vector2(5,0),color,2)
		"fire":
			var r=radius*(.25+progress*.75)
			var fill=color;fill.a*=.25
			draw_circle(pos,r,fill)
			draw_arc(pos,r,0,TAU,32,color,3)
			for i in range(6):
				var direction=Vector2.from_angle(i*TAU/6+progress)
				draw_line(pos+direction*r*.65,pos+direction*r*1.15,color,2)
		"frost":
			var r=radius*progress
			draw_arc(pos,r,0,TAU,48,color,2)
			for i in range(8):
				var center=pos+Vector2.from_angle(i*TAU/8)*r
				draw_line(center-Vector2(0,6),center+Vector2(0,6),color,2)
				draw_line(center-Vector2(5,0),center+Vector2(5,0),color,2)
		_:
			var r=radius*(.35+progress*.65)
			draw_arc(pos,r,0,TAU,40,color,2)
			for i in range(6):
				var center=pos+Vector2.from_angle(i*TAU/6)*r
				draw_circle(center,3,color)

func draw_weather() -> void:
	var sky=game.weather.sky()
	if sky=="Underground" or not game.weather.particles_enabled: return
	var view=get_viewport_rect().size
	var origin=game.camera.position-view/2
	if sky=="Fog":
		draw_rect(Rect2(origin,view),Color("b8cecc12"))
		for i in range(3):
			var y=fposmod(i*view.y/3+clock*4,view.y)
			draw_rect(Rect2(origin+Vector2(0,y),Vector2(view.x,35)),Color("c4d7d40b"))
	for i in range(game.weather.particle_count()):
		var speed=150.0 if sky=="Rain" else 24.0
		var drift=30.0 if sky=="Rain" else 8.0
		var at=origin+Vector2(fposmod(i*137+clock*drift,view.x),fposmod(i*97+clock*speed,view.y))
		if game.weather.covered_at(at): continue
		if sky=="Rain": draw_line(at,at+Vector2(4,13),Color("aacede70"),1)
		else: draw_circle(at,1.5,Color("eef5f399"))
	if game.weather.season()=="Autumn" and game.hero.dungeon==null and game.exploration.region_at(game.player_position())=="forest":
		for i in range(4 if game.low_power else 9):
			var at=origin+Vector2(fposmod(i*157+clock*17,view.x),fposmod(i*131+clock*13,view.y))
			if not game.weather.covered_at(at): draw_line(at,at+Vector2(4,2),Color("d8a06599"),2)
