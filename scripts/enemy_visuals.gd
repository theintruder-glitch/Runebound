extends RefCounted
# One shared atlas; all variants stay available at every graphics quality.
const ATLAS=preload("res://assets/enemies.svg")
const KINDS=["goblin","skeleton","archer","ice_archer","guardian","slime","bog_toad","wisp","crystal_wisp","wolf","frost_wolf","root_warden","hollow_heart"]
var textures:Dictionary={}
func _init() -> void:
	for i in range(KINDS.size()):
		var texture=AtlasTexture.new();texture.atlas=ATLAS
		texture.region=Rect2(i%5*128,int(i/5)*160,128,160);texture.filter_clip=true
		textures[KINDS[i]]=texture
func kind(enemy:Dictionary) -> String:
	if enemy.get("chapter_boss",false): return "hollow_heart"
	if enemy.get("named","")=="The Root Warden": return "root_warden"
	return enemy.type if textures.has(enemy.type) else "guardian"
func scale_for(enemy:Dictionary) -> float: return 1.5 if enemy.boss or enemy.has("named") else 1.0
func bounds(enemy:Dictionary,at:Vector2) -> Rect2:
	var size=scale_for(enemy)
	return Rect2(at-Vector2(32,64)*size,Vector2(64,80)*size)
func draw(canvas:CanvasItem,enemy:Dictionary,at:Vector2,clock:float,target:Vector2) -> void:
	var id=kind(enemy)
	var size=scale_for(enemy)
	var phase=clock*2.5+enemy.get("tactic_order",0)*.9
	var flying=id in ["wisp","crystal_wisp"]
	var motion:Vector2=enemy.get("motion",Vector2.ZERO)
	var offset=Vector2(0,sin(phase)*3 if flying else -absf(sin(clock*11))*1.5 if motion.length()>.1 else sin(phase)*.6)
	canvas.draw_set_transform(at,0,Vector2(size,size))
	canvas.draw_circle(Vector2(0,3),14,Color("07131c44"))
	if flying:
		canvas.draw_circle(Vector2(0,-25),23,Color("b49ad612"))
	# Hovering, breathing, recoil and attack lunge never change collision positions.
	var tint=Color(1.65,1.6,1.45) if enemy.flash>0 else Color(.65,1.1,1.35) if enemy.slow>0 else Color.WHITE
	var mirror=id in ["wolf","frost_wolf","archer","ice_archer"] and (motion.x if absf(motion.x)>.1 else target.x-at.x)<0
	canvas.draw_set_transform(at+offset*size,0,Vector2(-size if mirror else size,size))
	canvas.draw_texture_rect(textures[id],Rect2(-32,-64,64,80),false,tint)
	canvas.draw_set_transform(Vector2.ZERO)
