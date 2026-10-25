extends RefCounted
# One shared six-cell atlas. Source bitmap stays intact; AtlasTexture selects cells.
const ATLAS=preload("res://assets/realm_environment.png")
const KINDS=["mountain","snow-mountain","oak","swamp-tree","boulders","snow-pine"]
var textures={}
func _init() -> void:
 var cell=Vector2(ATLAS.get_width()/3.0,ATLAS.get_height()/2.0)
 for i in range(KINDS.size()):
  var t=AtlasTexture.new();t.atlas=ATLAS;t.region=Rect2(Vector2(i%3,int(i/3))*cell,cell);t.filter_clip=true;textures[KINDS[i]]=t
func draw(c:CanvasItem,kind:String,p:Vector2,size:Vector2) -> void:
 c.draw_texture_rect(textures[kind],Rect2(p-size*Vector2(.5,.96),size),false)
