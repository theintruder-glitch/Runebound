extends Node2D
# Fixed pool of shadow-free lights; cached scenery detail. Compatible with laptop renderer.
const LEVELS=["Performance","Balanced","Rich"]
var game
var quality="Balanced"
var ambient:CanvasModulate
var lights:Array=[]
func _ready() -> void:
	var config=ConfigFile.new()
	if config.load("user://graphics.cfg")==OK:
		var selected=config.get_value("graphics","quality","Balanced")
		if selected in LEVELS: quality=selected
	if not game.desktop.enabled or "--safe-mode" in OS.get_cmdline_user_args(): quality="Performance"
	ambient=CanvasModulate.new();add_child(ambient)
	var gradient=Gradient.new();gradient.set_color(0,Color.WHITE);gradient.set_color(1,Color(1,1,1,0))
	gradient.add_point(.25,Color(1,1,1,.8));gradient.add_point(.65,Color(1,1,1,.16))
	var tex=GradientTexture2D.new();tex.width=256;tex.height=256;tex.gradient=gradient
	tex.fill=GradientTexture2D.FILL_RADIAL;tex.fill_from=Vector2(.5,.5);tex.fill_to=Vector2(1,.5)
	for i in range(8):
		var light=PointLight2D.new();light.texture=tex;light.shadow_enabled=false;light.enabled=false;add_child(light);lights.append(light)
func set_quality(value:String) -> void:
	if value not in LEVELS: return
	quality=value
	var config=ConfigFile.new();config.set_value("graphics","quality",quality);config.save("user://graphics.cfg")
	if not game.hero.is_empty(): game.world.refresh(true)
func enhanced() -> bool: return game.desktop.enabled and quality!="Performance"
func _process(_dt:float) -> void:
	for light in lights: light.enabled=false
	if game.hero.is_empty() or not enhanced(): ambient.color=Color.WHITE;return
	var phase=game.Data.phase(game.hero.worldTime)
	var underground=game.hero.dungeon!=null or game.exploration.region_at(game.player_position())=="caves"
	ambient.color=Color("687486") if underground else Color("7789a4") if phase=="Night" else Color("c0a7a2") if phase in ["Dusk","Dawn"] else Color("dbe4d4")
	var points=[{"pos":game.player_position()+Vector2(0,-15),"color":Color("ccdfff"),"scale":2.2,"energy":.42 if not underground and phase=="Day" else .95}]
	if game.hero.dungeon==null:
		for structure in game.hero.survival.structures:
			if structure.kind=="Campfire" and structure.fuel>0 and game.survival.at(structure).distance_to(game.camera.position)<800:
				points.append({"pos":game.survival.at(structure),"color":Color("ffc184"),"scale":1.35,"energy":.9+sin(game.world.clock*7)*.06})
	for shot in game.shots:
		if shot.kind!="bow" and points.size()<8:
			points.append({"pos":shot.pos,"color":shot.get("color",Color("ffb67f") if shot.kind=="fire" else Color("cbb8f7")),"scale":.6,"energy":.6})
	for i in range(mini(points.size(),8 if quality=="Rich" else 4)):
		var p=points[i];var light=lights[i];light.enabled=true;light.position=p.pos;light.color=p.color;light.texture_scale=p.scale;light.energy=p.energy
func details(canvas:CanvasItem,bounds:Rect2) -> void:
	if not enhanced() or game.hero.dungeon!=null: return
	var size=64 if quality=="Rich" else 96
	for x in range(floori(bounds.position.x/size),ceili(bounds.end.x/size)):
		for y in range(floori(bounds.position.y/size),ceili(bounds.end.y/size)):
			var h=game.world.tile_hash(x,y,81);var at=Vector2(x*size+size*h,y*size+size*.6);var region=game.exploration.region_at(at)
			if region=="caves": continue
			if region=="snow" or game.weather.season()=="Winter": canvas.draw_arc(at,9+h*14,.1,2.2,10,Color("ebf5f128"),1,true)
			else:
				var color=Color("7f9f683b") if region!="swamp" else Color("87935d40")
				for i in range(3): canvas.draw_line(at+Vector2(i*3,0),at+Vector2(i*4-2,-4-h*5),color,1,true)
				if h>.84: canvas.draw_circle(at-Vector2(0,6),2,Color("d0b6ac88"));canvas.draw_circle(at+Vector2(5,-2),1.5,Color("d8c78f88"))
func atmosphere(canvas:CanvasItem) -> void:
	if not enhanced(): return
	var clock=game.world.clock
	if game.hero.dungeon==null and game.exploration.region_at(game.player_position()) in ["forest","swamp"] and game.Data.phase(game.hero.worldTime)=="Night":
		for i in range(10 if quality=="Rich" else 5):
			var p=game.camera.position+Vector2(sin(i*17.2+clock*.13)*470,cos(i*8.6+clock*.17)*290)
			canvas.draw_circle(p,2,Color(1,.87,.46,.35+.3*sin(clock*2+i)))
