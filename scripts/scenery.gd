extends Node2D

# Godot retains these draw commands until queue_redraw is requested. Scenery
# only changes when the camera moves a tile, loot opens, or buildings change.
var world
var decorations: Array = []
var visible_chests: Array = []
var bounds = Rect2()

func _draw() -> void:
	if world==null or world.game.hero.is_empty():
		return
	var game = world.game
	game.graphics.details(self,bounds)
	for decoration in decorations:
		var region=decoration.get("biome","forest")
		var tint=Color(.85,1,1.15) if region=="snow" else Color(.8,.9,.85) if region=="swamp" else Color(.8,.8,1) if region=="caves" else Color.WHITE
		if region in ["forest","swamp"] and decoration.kind=="tree":
			if game.weather.season()=="Summer": tint=Color(1.05,1.08,.85)
			elif game.weather.season()=="Autumn": tint=Color(1.6,.85,.55)
			elif game.weather.season()=="Winter": tint=Color(.9,1.05,1.2)
		draw_texture_rect(world.textures[decoration.kind],Rect2(decoration.pos-Vector2(32,64),Vector2(64,96)),false,tint)
		if (region=="snow" or (region in ["forest","swamp"] and game.weather.season()=="Winter")) and decoration.kind=="tree":
			for dx in [-12,0,12]:
				draw_arc(decoration.pos+Vector2(dx,-37-abs(dx)*.3),8,PI,TAU,10,Color("d4e5e4"),3,true)
	if game.hero.dungeon==null:
		for i in range(game.hero.kingdom.buildings.size()):
			var at = Vector2(-160+i*150,-150)
			if not bounds.has_point(at):
				continue
			draw_rect(Rect2(at-Vector2(30,20),Vector2(60,48)),Color("455850"))
			draw_colored_polygon(PackedVector2Array([at+Vector2(-42,-20),at+Vector2(0,-50),at+Vector2(42,-20)]),Color("a68b68"))
			draw_rect(Rect2(at+Vector2(-6,4),Vector2(12,24)),Color("ebcc8b"))
			draw_string(ThemeDB.fallback_font,at+Vector2(-40,-60),game.hero.kingdom.buildings[i],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("e8d8b2"))
	if game.hero.dungeon==null:
		draw_survival(game)
		draw_landmarks(game)
		draw_quest_board(game)
		draw_trader(game)
		draw_spring(game)
		game.fishing.draw_pools(self,bounds)
	for chest in visible_chests:
		var opened = game.hero.opened.has(chest.id)
		draw_texture_rect(world.textures["chest_open" if opened else "chest"],Rect2(chest.pos-Vector2(32,64),Vector2(64,96)),false)
		if not opened:
			draw_string(ThemeDB.fallback_font,chest.pos+Vector2(-20,-23),"CHEST",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("e1c98f"))

func draw_survival(game) -> void:
	for node in game.survival.nodes:
		var pos:Vector2=node.pos
		if not bounds.has_point(pos): continue
		draw_circle(pos,18,Color("274c41"))
		match node.kind:
			"Wood":
				draw_texture_rect(world.textures.tree,Rect2(pos-Vector2(32,64),Vector2(64,96)),false)
			"Crystal","Frost shard":
				draw_colored_polygon(PackedVector2Array([pos+Vector2(-14,5),pos+Vector2(-6,-35),pos+Vector2(3,-16),pos+Vector2(12,-28),pos+Vector2(17,6)]),Color("b7a3ed") if node.kind=="Crystal" else Color("a6e9f3"))
			"Glowcap":
				draw_rect(Rect2(pos+Vector2(-3,-16),Vector2(6,20)),Color("ced6a5"))
				draw_circle(pos+Vector2(0,-20),14,Color("97c4b2"))
				draw_circle(pos+Vector2(4,-23),3,Color("f2e6a9"))
			"Resin","Pine resin":
				draw_rect(Rect2(pos+Vector2(-8,-30),Vector2(16,35)),Color("916c46"))
				draw_circle(pos+Vector2(0,-15),6,Color("ecc16d"))
			"Stone","Iron":
				draw_colored_polygon(PackedVector2Array([pos+Vector2(-19,4),pos+Vector2(-15,-18),pos+Vector2(5,-28),pos+Vector2(22,-3)]),Color("96adb2") if node.kind=="Stone" else Color("b79a83"))
				if node.kind=="Iron": draw_line(pos+Vector2(-8,-14),pos+Vector2(9,-4),Color("e6c28c"),4)
			_:
				for dx in [-10,0,10]:
					draw_line(pos+Vector2(dx,2),pos+Vector2(dx*1.5,-22),Color("91c783"),3)
					if node.kind=="Berries": draw_circle(pos+Vector2(dx,-15),4,Color("ed909d"))
					elif node.kind=="Herbs": draw_circle(pos+Vector2(dx,-22),4,Color("cab0ee"))
		if pos.distance_to(game.player_position())<230:
			draw_string(ThemeDB.fallback_font,pos+Vector2(-22,25),node.kind.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("d7eac1"))
	var shrine=game.forest.SHRINE
	if bounds.grow(100).has_point(shrine):
		draw_circle(shrine,90,Color("183a35"))
		for i in range(8):
			var rock=shrine+Vector2.from_angle(i*TAU/8)*74
			draw_rect(Rect2(rock-Vector2(8,15),Vector2(16,30)),Color("718782"))
		draw_arc(shrine,48,0,TAU,48,Color("a0d4b4"),2)
		draw_colored_polygon(PackedVector2Array([shrine+Vector2(0,-38),shrine+Vector2(18,-10),shrine+Vector2(0,12),shrine+Vector2(-18,-10)]),Color("a2eac4") if game.hero.journey.warden else Color("cfb77f"))
		draw_string(ThemeDB.fallback_font,shrine+Vector2(-46,110),"ELDER SHRINE",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("e6d6a8"))
	for structure in game.hero.survival.structures:
		var pos=game.survival.at(structure)
		if not bounds.has_point(pos): continue
		match structure.kind:
			"Garden":
				draw_garden(game,structure,pos)
			"Wall","Door":
				var rect=game.survival.footprint(structure.kind,pos,int(structure.get("rotation",0)))
				if structure.kind=="Door" and structure.get("open",false):
					draw_rect(rect,Color("c7ac6c"),false,2)
				else:
					draw_rect(rect,Color("99754f") if structure.kind=="Wall" else Color("bc995e"))
					draw_rect(rect,Color("e4c78d"),false,2)
			"Roof":
				draw_colored_polygon(PackedVector2Array([pos+Vector2(-32,20),pos+Vector2(0,-25),pos+Vector2(32,20)]),Color("8c695b77"))
			"Bed":
				var rect=game.survival.footprint("Bed",pos,int(structure.get("rotation",0)))
				draw_rect(rect,Color("a58465"))
				draw_rect(rect.grow(-5),Color("82a99a"))
				draw_circle(pos+Vector2(0,-17).rotated(structure.get("rotation",0)*PI/2),10,Color("e5d7b7"))
			"Storage":
				draw_rect(Rect2(pos-Vector2(23,17),Vector2(46,34)),Color("9e784d"))
				draw_rect(Rect2(pos-Vector2(23,17),Vector2(46,34)),Color("d5bd8e"),false,2)
				draw_rect(Rect2(pos-Vector2(3,4),Vector2(6,8)),Color("f0d17d"))
			"Shelter":
				draw_arc(pos,60,0,TAU,40,Color("9bd8bb99"),2)
				draw_colored_polygon(PackedVector2Array([pos+Vector2(-40,20),pos+Vector2(0,-40),pos+Vector2(40,20)]),Color("b9a275"))
				draw_colored_polygon(PackedVector2Array([pos+Vector2(-13,20),pos+Vector2(0,-15),pos+Vector2(13,20)]),Color("233d36"))
			"Campfire":
				for i in range(8): draw_circle(pos+Vector2.from_angle(i*TAU/8)*19,5,Color("9da5a1"))
				draw_line(pos+Vector2(-13,8),pos+Vector2(12,-8),Color("ab8357"),5)
				draw_line(pos+Vector2(-13,-8),pos+Vector2(12,8),Color("ab8357"),5)
				if structure.fuel>0:
					draw_colored_polygon(PackedVector2Array([pos+Vector2(-12,5),pos+Vector2(0,-29),pos+Vector2(13,5)]),Color("f5a15b"))
					draw_circle(pos+Vector2(0,-3),6,Color("ffe3a0"))
			"Workbench":
				draw_rect(Rect2(pos+Vector2(-25,-15),Vector2(50,15)),Color("ba8b60"))
				draw_line(pos+Vector2(-18,-2),pos+Vector2(-18,17),Color("8e6950"),5)
				draw_line(pos+Vector2(18,-2),pos+Vector2(18,17),Color("8e6950"),5)
		draw_string(ThemeDB.fallback_font,pos+Vector2(-30,40),structure.kind.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("f0d6a3"))

func draw_garden(game,plot:Dictionary,pos:Vector2) -> void:
	var turn=int(plot.get("rotation",0))*PI/2
	draw_set_transform(pos,turn)
	draw_rect(Rect2(-30,-29,60,58),Color("493d32"))
	draw_rect(Rect2(-30,-29,60,58),Color("a58b5c"),false,3)
	for y in [-17,0,17]: draw_line(Vector2(-25,y),Vector2(25,y),Color("6f5438"),4)
	var growth=game.farming.stage(plot)
	if growth>0:
		for x in [-16,0,16]:
			for y in [-13,12]:
				var root_pos=Vector2(x,y)
				var height=7 if growth==1 else 15
				draw_line(root_pos,root_pos-Vector2(0,height),Color("94b979"),2)
				if growth<3:
					draw_line(root_pos-Vector2(0,height*.5),root_pos+Vector2(-5,-height*.7),Color("7eac77"),3)
					draw_line(root_pos-Vector2(0,height*.5),root_pos+Vector2(5,-height*.9),Color("a3c785"),3)
				elif plot.crop=="Glowcap":
					draw_circle(root_pos-Vector2(0,height),6,Color("98ceb8"))
					draw_circle(root_pos-Vector2(-2,height+2),2,Color("eddf9e"))
				elif plot.crop=="Berries":
					draw_circle(root_pos-Vector2(0,12),7,Color("649564"))
					for dx in [-3,3]: draw_circle(root_pos+Vector2(dx,-14),2.5,Color("ed909d"))
				else:
					draw_line(root_pos-Vector2(0,6),root_pos+Vector2(6,-12),Color("91b68a"),3)
					draw_circle(root_pos-Vector2(0,height),4,Color("cab2e3"))
	if growth==3: draw_rect(Rect2(-32,-31,64,62),Color("dce4a0"),false,2)
	draw_set_transform(Vector2.ZERO)
	if growth==3:
		draw_string(ThemeDB.fallback_font,pos+Vector2(-22,-39),"READY",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("e7ecb3"))

func draw_landmarks(game) -> void:
	var ruins=game.exploration.RUINS
	if bounds.grow(70).has_point(ruins):
		for dx in [-28,28]: draw_rect(Rect2(ruins+Vector2(dx-8,-44),Vector2(16,55)),Color("88958b"))
		draw_rect(Rect2(ruins+Vector2(-36,-54),Vector2(72,14)),Color("b2ba9f"))
		draw_circle(ruins+Vector2(0,-6),17,Color("15272d"))
		draw_string(ThemeDB.fallback_font,ruins+Vector2(-52,35),"MOSSVEIL RUINS",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("dfd4ab"))
	for id in ["caves","swamp","snow"]:
		var info=game.exploration.REGIONS[id]
		var pos:Vector2=info.point
		if not bounds.grow(100).has_point(pos): continue
		var color=Color("e9b07e") if id=="caves" else Color("c29fda") if id=="swamp" else Color("a6dce9")
		draw_circle(pos,62,Color("263b43"))
		draw_arc(pos,62,0,TAU,48,color,2)
		for i in range(4):
			var pillar=pos+Vector2.from_angle(i*PI/2)*45
			draw_rect(Rect2(pillar-Vector2(7,20),Vector2(14,32)),color.darkened(.35))
		draw_colored_polygon(PackedVector2Array([pos+Vector2(0,-44),pos+Vector2(20,-9),pos+Vector2(0,14),pos+Vector2(-20,-9)]),color)
		draw_string(ThemeDB.fallback_font,pos+Vector2(-56,91),info.landmark.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)

func draw_quest_board(game) -> void:
	var pos:Vector2=game.contracts.BOARD
	if not bounds.grow(80).has_point(pos): return
	draw_circle(pos+Vector2(0,12),32,Color("142d2688"))
	for dx in [-24,24]: draw_line(pos+Vector2(dx,-12),pos+Vector2(dx,20),Color("a8875d"),6)
	draw_rect(Rect2(pos+Vector2(-35,-50),Vector2(70,44)),Color("785b40"))
	draw_rect(Rect2(pos+Vector2(-35,-50),Vector2(70,44)),Color("c5a875"),false,2)
	for dx in [-19,4]:
		draw_rect(Rect2(pos+Vector2(dx,-43),Vector2(16,27)),Color("dece9f"))
		for y in [-36,-30,-24]: draw_line(pos+Vector2(dx+3,y),pos+Vector2(dx+12,y),Color("987c55"),1)
	draw_string(ThemeDB.fallback_font,pos+Vector2(-42,-60),"QUEST BOARD",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f1dc9c"))

func draw_trader(game) -> void:
	var pos:Vector2=game.trader.POSITION
	if not bounds.grow(100).has_point(pos): return
	draw_circle(pos+Vector2(0,12),48,Color("142c2588"))
	for dx in [-43,43]: draw_line(pos+Vector2(dx,-48),pos+Vector2(dx,21),Color("aa8254"),5)
	draw_rect(Rect2(pos+Vector2(-47,-66),Vector2(94,20)),Color("a85d59"))
	for dx in [-42,-14,14]: draw_rect(Rect2(pos+Vector2(dx,-66),Vector2(13,20)),Color("d1b37a"))
	draw_rect(Rect2(pos+Vector2(-42,-13),Vector2(84,24)),Color("97734e"))
	draw_rect(Rect2(pos+Vector2(-45,-18),Vector2(90,7)),Color("c4a171"))
	for dx in [-25,-8,10,27]: draw_circle(pos+Vector2(dx,-24),5,Color("dcc487") if dx<0 else Color("9fb8a9"))
	var person=pos+Vector2(-29,26)
	draw_circle(person+Vector2(0,5),12,Color("152c2888"))
	draw_line(person+Vector2(-4,-5),person+Vector2(-5,9),Color("473f39"),5)
	draw_line(person+Vector2(4,-5),person+Vector2(6,9),Color("473f39"),5)
	draw_rect(Rect2(person+Vector2(-9,-20),Vector2(18,20)),Color("688f84"))
	draw_rect(Rect2(person+Vector2(-6,-34),Vector2(13,14)),Color("dfbb98"))
	draw_rect(Rect2(person+Vector2(-8,-36),Vector2(17,5)),Color("75523f"))
	draw_line(person+Vector2(-11,-15),person+Vector2(-14,-4),Color("dfbb98"),4)
	draw_line(person+Vector2(11,-15),person+Vector2(17,-19),Color("dfbb98"),4)
	draw_string(ThemeDB.fallback_font,pos+Vector2(-47,-79),"TRADER MARA",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("e9d89f"))

func draw_spring(game) -> void:
	var pos:Vector2=game.expedition.SPRING
	if not bounds.grow(90).has_point(pos): return
	draw_circle(pos,36,Color("233c4a"));draw_circle(pos,29,Color("4a91a5"));draw_circle(pos-Vector2(5,4),21,Color("68b9c4"))
	for i in range(9): draw_circle(pos+Vector2.from_angle(i*TAU/9)*34,7,Color("93a69c"))
	draw_arc(pos,18,.4,2.8,20,Color("ceeee7"),2,true)
	draw_string(ThemeDB.fallback_font,pos+Vector2(-48,56),"FRESH SPRING",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("c8e9e4"))
