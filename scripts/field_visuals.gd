extends RefCounted
# Shared rasterized SVG atlas; detailed props cost one cached texture draw each.
const ATLAS=preload("res://assets/field_props.svg")
const KINDS=["Wood","Stone","Fiber","Berries","Herbs","Iron","Resin","Crystal","Glowcap","Reeds","Frost shard","Pine resin","cart","watch","grove","cache"]
var textures:Dictionary={}
func _init() -> void:
 for i in range(KINDS.size()):
  var texture=AtlasTexture.new();texture.atlas=ATLAS;texture.region=Rect2(i%4*128,int(i/4)*128,128,128);texture.filter_clip=true
  textures[KINDS[i]]=texture
func size_for(kind:String) -> Vector2:
 if kind=="cart":return Vector2(152,152)
 if kind=="watch":return Vector2(136,136)
 if kind=="grove":return Vector2(112,112)
 return Vector2(80,80) if kind in ["Wood","Resin","Pine resin"] else Vector2(72,72)
func bounds(kind:String,pos:Vector2) -> Rect2:
 var size=size_for(kind)
 return Rect2(pos-Vector2(size.x*.5,size.y*.78),size)
func draw_prop(canvas:CanvasItem,kind:String,pos:Vector2) -> void:
 if textures.has(kind):canvas.draw_texture_rect(textures[kind],bounds(kind,pos),false)
