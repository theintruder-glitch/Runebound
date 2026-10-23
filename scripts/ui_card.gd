extends Button
const Art=preload("res://scripts/ui_art.gd")
var caption=""
var subtitle=""
var kind="sword"
var tint=Color("b9cfc1")
var marked=false
var chosen=false
func _ready() -> void:
 # Noninteractive supply cards keep IGNORE; selectable gear cards pass drags
 # to the list while continuing to receive ordinary taps.
 if mouse_filter!=Control.MOUSE_FILTER_IGNORE: mouse_filter=Control.MOUSE_FILTER_PASS
 custom_minimum_size=Vector2(78,94)
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 focus_mode=Control.FOCUS_NONE
 clip_contents=true
func _draw() -> void:
 var rect=Rect2(Vector2(2,2),size-Vector2(4,4))
 draw_style_box(frame(tint.lightened(.2) if chosen else tint.darkened(.35)),rect)
 var light=tint if not disabled else tint.darkened(.25)
 Art.icon(self,Vector2(size.x/2,33),kind,light,.68)
 var font=ThemeDB.fallback_font
 var title=caption if caption.length()<=12 else caption.left(11)+"…"
 draw_string(font,Vector2(4,69),title,HORIZONTAL_ALIGNMENT_CENTER,size.x-8,11,Color("e4e5d7"))
 draw_string(font,Vector2(4,85),subtitle,HORIZONTAL_ALIGNMENT_CENTER,size.x-8,10,tint)
 if marked: draw_circle(Vector2(size.x-10,11),4,Color("e9d294"))
func frame(border:Color) -> StyleBoxFlat:
 var box=StyleBoxFlat.new()
 box.bg_color=Color("152e32") if not is_hovered() else Color("29493f")
 box.border_color=border
 box.set_border_width_all(2 if chosen else 1)
 box.set_corner_radius_all(9)
 return box
