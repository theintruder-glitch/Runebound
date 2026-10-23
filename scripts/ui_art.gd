extends RefCounted
static func icon(canvas:CanvasItem,at:Vector2,kind:String,color:Color=Color("d8c69e"),scale:float=1.0) -> void:
 canvas.draw_set_transform(at,0,Vector2.ONE*scale)
 var dark=color.darkened(.45)
 match kind.to_lower():
  "sword","resin blade","iron sword":
   canvas.draw_colored_polygon(PackedVector2Array([Vector2(-4,10),Vector2(-4,-15),Vector2(0,-23),Vector2(4,-15),Vector2(4,10)]),color)
   canvas.draw_line(Vector2(-10,8),Vector2(10,8),dark,4);canvas.draw_line(Vector2(0,8),Vector2(0,21),color,4)
  "bow","crafted bow","frost bow":
   canvas.draw_arc(Vector2(-8,0),22,-1.1,1.1,20,color,3)
   canvas.draw_line(Vector2(2,-20),Vector2(2,20),dark,1)
   canvas.draw_line(Vector2(-16,0),Vector2(22,0),color,2)
   canvas.draw_line(Vector2(22,0),Vector2(15,-5),color,2);canvas.draw_line(Vector2(22,0),Vector2(15,5),color,2)
  "staff","crystal staff":
   canvas.draw_line(Vector2(-9,21),Vector2(7,-15),dark,5)
   canvas.draw_circle(Vector2(8,-16),9,color);canvas.draw_circle(Vector2(8,-16),4,color.lightened(.4))
  "armor","leather vest":
   canvas.draw_colored_polygon(PackedVector2Array([Vector2(-10,-20),Vector2(-22,-10),Vector2(-14,0),Vector2(-10,-4),Vector2(-10,20),Vector2(10,20),Vector2(10,-4),Vector2(14,0),Vector2(22,-10),Vector2(10,-20),Vector2(0,-12)]),color)
   canvas.draw_line(Vector2(-8,7),Vector2(8,7),dark,3)
  "shield":
   canvas.draw_colored_polygon(PackedVector2Array([Vector2(-18,-17),Vector2(18,-17),Vector2(15,9),Vector2(0,23),Vector2(-15,9)]),color)
   canvas.draw_line(Vector2(0,-12),Vector2(0,14),dark,3)
  "helmet":
   canvas.draw_arc(Vector2(0,-2),19,PI,TAU,20,color,7)
   canvas.draw_rect(Rect2(-20,-2,40,8),color);canvas.draw_line(Vector2(0,0),Vector2(0,18),color,5)
  "ring":
   canvas.draw_arc(Vector2(0,5),14,0,TAU,28,color,5)
   canvas.draw_colored_polygon(PackedVector2Array([Vector2(0,-22),Vector2(9,-12),Vector2(0,-4),Vector2(-9,-12)]),color.lightened(.25))
  "charm":
   canvas.draw_arc(Vector2(0,-8),13,0,PI,20,dark,2)
   canvas.draw_colored_polygon(PackedVector2Array([Vector2(0,-6),Vector2(12,9),Vector2(0,23),Vector2(-12,9)]),color)
  "wall","door":
   canvas.draw_rect(Rect2(-22,-18,44,36),dark)
   for x in [-15,-5,5,15]: canvas.draw_line(Vector2(x,-17),Vector2(x,17),color,4)
   if kind.to_lower()=="door": canvas.draw_circle(Vector2(11,1),3,Color("f4dc9c"))
  "roof","shelter":
   canvas.draw_colored_polygon(PackedVector2Array([Vector2(-25,18),Vector2(0,-21),Vector2(25,18)]),color)
   canvas.draw_colored_polygon(PackedVector2Array([Vector2(-9,18),Vector2(0,-4),Vector2(9,18)]),dark)
  "campfire":
   canvas.draw_line(Vector2(-19,18),Vector2(17,9),dark,6);canvas.draw_line(Vector2(-17,9),Vector2(19,18),dark,6)
   canvas.draw_colored_polygon(PackedVector2Array([Vector2(-13,10),Vector2(0,-24),Vector2(13,10)]),Color("f4b579"))
   canvas.draw_circle(Vector2(0,3),6,Color("f6e1a0"))
  "workbench":
   canvas.draw_rect(Rect2(-24,-10,48,12),color)
   canvas.draw_line(Vector2(-17,0),Vector2(-17,22),dark,5);canvas.draw_line(Vector2(17,0),Vector2(17,22),dark,5)
   canvas.draw_line(Vector2(-8,-12),Vector2(3,-24),color,3)
  "garden":
   canvas.draw_rect(Rect2(-24,-15,48,37),Color("6a513b"))
   canvas.draw_rect(Rect2(-24,-15,48,37),color,false,2)
   for x in [-13,0,13]:
    canvas.draw_line(Vector2(x,15),Vector2(x,-10),dark,3)
    canvas.draw_line(Vector2(x,0),Vector2(x-6,-7),color,4)
    canvas.draw_line(Vector2(x,-4),Vector2(x+6,-11),color,4)
  "bed":
   canvas.draw_rect(Rect2(-17,-23,34,46),dark)
   canvas.draw_rect(Rect2(-13,-7,26,26),color);canvas.draw_rect(Rect2(-11,-19,22,10),color.lightened(.3))
  "storage":
   canvas.draw_rect(Rect2(-24,-16,48,35),dark);canvas.draw_rect(Rect2(-24,-16,48,35),color,false,3)
   canvas.draw_line(Vector2(-23,-3),Vector2(23,-3),color,2);canvas.draw_rect(Rect2(-4,-7,8,10),color)
  "wood","plank","resin","pine resin":
   canvas.draw_rect(Rect2(-17,-19,34,38),dark)
   for x in [-10,0,10]: canvas.draw_line(Vector2(x,-18),Vector2(x,18),color,4)
   if "resin" in kind.to_lower(): canvas.draw_circle(Vector2(0,-2),7,Color("eac17b"))
  "crystal","frost shard","iron","stone":
   canvas.draw_colored_polygon(PackedVector2Array([Vector2(-22,17),Vector2(-12,-13),Vector2(4,-24),Vector2(22,9),Vector2(11,20)]),color)
   canvas.draw_line(Vector2(4,-24),Vector2(1,12),dark,2)
  "fiber","rope","reed rope","reeds":
   for i in [-1,0,1]: canvas.draw_arc(Vector2(i*8,0),12,-2.4,1.2,20,color,3)
  "berries","herbs","glowcap":
   canvas.draw_line(Vector2(0,20),Vector2(0,-12),dark,4)
   for pos in [Vector2(-10,-5),Vector2(9,-7),Vector2(0,-19)]: canvas.draw_circle(pos,8,color)
  "hide":
   canvas.draw_colored_polygon(PackedVector2Array([Vector2(-18,-22),Vector2(0,-13),Vector2(18,-22),Vector2(12,0),Vector2(18,22),Vector2(0,14),Vector2(-18,22),Vector2(-12,0)]),color)
  "warm tea":
   canvas.draw_rect(Rect2(-15,-5,27,25),color)
   canvas.draw_arc(Vector2(14,6),9,-PI/2,PI/2,12,color,3)
   canvas.draw_line(Vector2(-15,-5),Vector2(12,-5),dark,3)
   for x in [-8,3]: canvas.draw_line(Vector2(x,-12),Vector2(x+3,-22),color.lightened(.2),2)
  "trader","coin":
   canvas.draw_circle(Vector2.ZERO,21,Color("aa824d"))
   canvas.draw_arc(Vector2.ZERO,18,0,TAU,28,color,3)
   canvas.draw_line(Vector2(0,-12),Vector2(0,12),color,3)
   canvas.draw_line(Vector2(-7,-7),Vector2(7,-7),color,2);canvas.draw_line(Vector2(-7,7),Vector2(7,7),color,2)
  "map":
   canvas.draw_colored_polygon(PackedVector2Array([Vector2(-23,-18),Vector2(-8,-23),Vector2(9,-16),Vector2(23,-22),Vector2(23,18),Vector2(8,23),Vector2(-8,16),Vector2(-23,22)]),dark)
   canvas.draw_line(Vector2(-8,-18),Vector2(-8,16),color,2);canvas.draw_line(Vector2(8,-15),Vector2(8,19),color,2)
   canvas.draw_circle(Vector2(14,0),4,color)
  _:
   canvas.draw_arc(Vector2.ZERO,19,0,PI,20,color,5)
   canvas.draw_line(Vector2(-18,0),Vector2(18,0),color,2)
   for x in [-9,0,9]: canvas.draw_line(Vector2(x,-9),Vector2(x+4,-20),color,2)
 canvas.draw_set_transform(Vector2.ZERO)
