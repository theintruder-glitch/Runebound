extends Control
const Art=preload("res://scripts/ui_art.gd")
var kind="sword"
var tint=Color("d8c69e")
func _ready() -> void:
 custom_minimum_size=Vector2(52,52)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
 draw_circle(size/2,25,tint.darkened(.8))
 Art.icon(self,size/2,kind,tint,.8)
