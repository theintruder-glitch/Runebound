extends RefCounted
var game
func faster_phase(e:Dictionary) -> bool:
 return e.get("chapter_boss",false) or e.get("forge_boss",false) or e.get("thornwatch_boss",false) or e.has("realm_boss") or e.get("cave_boss",false) or e.get("beacon_boss",false)
func phase_two(e:Dictionary) -> bool:return faster_phase(e) and e.hp>0 and e.hp<e.max_hp*.5
func on_damage(e:Dictionary) -> bool:
 if not game.playing or not phase_two(e) or e.get("phase_announced",false):return false
 e["phase_announced"]=true
 game.floating(e.pos+Vector2(-55,-95),"PHASE II · FASTER ATTACKS",Color("ffc482"))
 game.visual_fx("impact",e.pos,64,Color("ffbe83"),.65)
 return true
func nearest_boss() -> Dictionary:
 var found={};var distance=INF
 for e in game.enemies:
  if e.dead or not e.boss:continue
  var d=e.pos.distance_squared_to(game.player_position())
  if d<distance:distance=d;found=e
 return found
func update_hud() -> void:
 var hud=game.hud;var boss=nearest_boss();var title="";var detail=""
 var encounter=game.beacons.foes if game.beacons.active() else game.forge.foes if game.forge.active() else game.exploration.foes if game.exploration.active() else []
 if not encounter.is_empty():
  boss={}
  for e in encounter:
   if not e.dead and e.boss:boss=e;break
 elif game.forest.active():boss=game.forest.boss
 if game.beacons.active():title=game.beacons.SITES[game.beacons.running].name+" · watchers";detail="%d remaining" % game.beacons.foes.filter(func(e):return not e.dead).size()
 elif game.forge.active():title="Ashen binding";detail="%d remaining" % game.forge.foes.filter(func(e):return not e.dead).size()
 elif game.exploration.active():title=game.exploration.REGIONS[game.exploration.trial].landmark+" · trial";detail="%d remaining" % game.exploration.foes.filter(func(e):return not e.dead).size()
 elif not boss.is_empty() and (game.hero.dungeon!=null or boss.pos.distance_to(game.player_position())<700):
  title=boss.get("named","Dungeon Lord" if game.hero.dungeon!=null else "Wilds Guardian")
  hud.boss_bar.visible=true;hud.boss_bar.max_value=boss.max_hp;hud.boss_bar.value=maxf(0,boss.hp)
  detail="PHASE II · faster attacks" if phase_two(boss) else "Phase I" if faster_phase(boss) else "Boss encounter"
 if not boss.is_empty() and phase_two(boss) and not title.is_empty() and not detail.begins_with("PHASE II"):detail+=" · Keeper phase II"
 hud.boss_name.visible=hud.boss_bar.visible and not title.is_empty() and not hud.overlay.visible
 if hud.boss_name.visible:
  var percent=roundi(100*hud.boss_bar.value/maxf(1,hud.boss_bar.max_value))
  hud.boss_name.text=title+"\n"+detail+" · %d%% HP" % percent
  hud.boss_name.size=hud.boss_bar.size
func draw_warning(c:CanvasItem,e:Dictionary) -> void:
 if not e.boss and not e.has("named"):return
 var p:Vector2=e.strike;var r:float=e.strike_radius
 var color=Color("ffd59a") if not phase_two(e) else Color("ffb584")
 # Boundary marks reinforce the actual circular hit area; no fake cone/line.
 for i in range(8):
  var v=Vector2.from_angle(i*TAU/8)
  c.draw_line(p+v*(r-2),p+v*(r+6),color,2,true)
 c.draw_line(p-Vector2(8,0),p+Vector2(8,0),color,2,true)
 c.draw_line(p-Vector2(0,8),p+Vector2(0,8),color,2,true)
 if not e.has("castle_attack"):
  c.draw_string(ThemeDB.fallback_font,p+Vector2(-47,-r-12),"HEAVY STRIKE",HORIZONTAL_ALIGNMENT_LEFT,-1,11,color)
