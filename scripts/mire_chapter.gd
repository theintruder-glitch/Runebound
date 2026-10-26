extends RefCounted
# Chapter III connects existing world locations, without another live encounter.
const CLUES={
 "mire-watch":"The scout's ledger records empty prison wagons entering Blackmire. Their chains were forged at Emberforge, and every wagon bore the same sealed royal order.",
 "mire-grove":"A pilgrim scratched a warning into the witchroot: the fortress did not drown by accident. Its gaoler bound the dead to keep an old royal testament from leaving the archive."
}
var game
func data() -> Dictionary:return game.hero.mire_chapter
func stage() -> int:
 if not game.hero.forge_chapter.claimed:return -1
 if not data().accepted:return 0
 if data().clues.size()<2:return 1
 if not game.hero.exploration.challenges.get("swamp",false):return 2
 if not game.hero.opened.get("blackmire-cleared",false):return 3
 if not data().testament:return 4
 if not data().claimed:return 5
 return 6
func mara_near() -> bool:return game.trader.near() and game.line_clear(game.player_position(),game.trader.POSITION)
func accept() -> bool:
 if stage()!=0 or not mara_near():return false
 data().accepted=true
 for id in CLUES:
  if game.hero.opened.get(id,false):data().clues[id]=true
 track(false);game.notify("THE DROWNED OATH · Read the scout ledger and witchroot warning. Earlier discoveries and victories count.",7);return true
func clue_near() -> String:
 if stage()!=1 or game.hero.dungeon!=null:return ""
 for id in CLUES:
  var p:Vector2=game.landscape.realms.SITES[id].point
  if not data().clues.has(id) and game.player_position().distance_to(p)<60 and game.line_clear(game.player_position(),p):return id
 return ""
func investigate(id:String) -> bool:
 if id.is_empty() or clue_near()!=id:return false
 data().clues[id]=true;game.notify(CLUES[id],10);game.world.refresh_scenery(true);game.sound("reward");game.save_game();return true
func archive_cell() -> Vector2i:
 return game.castle.features().archive.cell if game.hero.dungeon!=null and game.hero.dungeon.get("castle","")=="blackmire" and game.hero.dungeon.floor==2 else Vector2i(-1,-1)
func testament_near() -> bool:
 if stage()!=4:return false
 var cell=archive_cell()
 if cell.x<0:return false
 var p=game.cell_center(cell)
 return game.player_position().distance_to(p)<50 and game.line_clear(game.player_position(),p)
func recover() -> bool:
 if not testament_near():return false
 data().testament=true;game.notify("DROWNED TESTAMENT RECOVERED · The drowned king ordered the bindings severed. Someone carried a false oath to Frostspire. Bring this record to Mara.",10)
 game.sound("reward");game.world.refresh_scenery(true);game.save_game();return true
func claim() -> bool:
 if stage()!=5 or not mara_near():return false
 data().claimed=true;game.hero.gold+=450;game.hero.essence+=8;game.hero.points+=3
 game.notify("THE DROWNED OATH COMPLETE · +450 gold, +8 essence, +3 stat points · Mirewarden's Oath: 40% less weather wetness in the swamp.",10)
 game.sound("reward");game.save_game();return true
func weather_multiplier() -> float:
 return .6 if data().claimed and game.hero.dungeon==null and game.exploration.region_at(game.player_position())=="swamp" else 1.0
func track(close_menu:bool=true) -> void:
 game.hero.chapter.tracking=true;game.hero.exploration.target="";game.hero.contracts.target="";game.hero.angler.target=""
 game.save_game()
 if close_menu:game.hud.resume()
func objective() -> String:
 var step=stage()
 if step<0 or step==6:return ""
 var prefix="THE DROWNED OATH · "
 if game.hero.dungeon!=null:
  if step==4 and game.hero.dungeon.get("castle","")=="blackmire":return prefix+("Recover the testament in this floor's archive" if game.hero.dungeon.floor==2 else "Backtrack to Blackmire level 2 · recover the archive testament")
  return prefix+"Leave via entrance stairs · return to Mara" if step in [0,5] else prefix+"Follow the castle objective; review your chapter journal"
 if step in [0,5]:return prefix+"Speak with Mara · "+game.exploration.bearing(game.trader.POSITION)
 if step==1:
  for id in CLUES:
   if not data().clues.has(id):return prefix+game.landscape.realms.SITES[id].name+" · "+game.exploration.bearing(game.landscape.realms.SITES[id].point)
 if step==2:return prefix+"Complete the Veil Altar trial · "+game.exploration.bearing(game.exploration.REGIONS.swamp.point)
 return prefix+("Defeat Blackmire's Abomination" if step==3 else "Recover testament · Blackmire level 2 archive")+" · "+game.exploration.bearing(game.landscape.realms.Catalog.ZONES.blackmire.gate)
func interaction() -> String:
 if testament_near():return "RECOVER DROWNED TESTAMENT"
 var id=clue_near()
 return "READ SCOUT LEDGER" if id=="mire-watch" else "READ WITCHROOT WARNING" if id=="mire-grove" else ""
func interact() -> void:
 if testament_near():recover()
 else:investigate(clue_near())
func draw(c:CanvasItem,b:Rect2) -> void:
 if game.hero.dungeon==null and stage()==1:
  for id in CLUES:
   var p:Vector2=game.landscape.realms.SITES[id].point
   if not data().clues.has(id) and b.has_point(p):c.draw_arc(p+Vector2(0,-35),15,0,TAU,20,Color("dfca98"),2);c.draw_string(ThemeDB.fallback_font,p+Vector2(-7,-29),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("e9d6ac"))
 if stage()!=4 or archive_cell().x<0:return
 var p=game.cell_center(archive_cell())
 if not b.grow(60).has_point(p):return
 c.draw_rect(Rect2(p+Vector2(-26,11),Vector2(52,12)),Color("4d4c51"))
 c.draw_rect(Rect2(p-Vector2(24,14),Vector2(48,29)),Color("c9b98c"));c.draw_line(p+Vector2(0,-13),p+Vector2(0,14),Color("685d49"),2)
 for i in range(4):
  for side in [-1,1]:c.draw_line(p+Vector2(side*5,-8+i*5),p+Vector2(side*18,-8+i*5),Color("756748"),1)
 c.draw_circle(p+Vector2(14,8),4,Color("8468b0"));c.draw_arc(p,35,0,TAU,24,Color("b69bcf"),2)
 c.draw_string(ThemeDB.fallback_font,p+Vector2(-60,-28),"DROWNED TESTAMENT",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("ead7a6"))
func show_menu() -> void:
 var hud=game.hud;var step=stage()
 hud.section("Chapter III · The Drowned Oath")
 if step<0: hud.paragraph("Finish The Hollow Root and claim Mara's Ash and Oath reward to follow the chain into Whisperfen.",14)
 elif step==0:
  hud.paragraph("Mara: The forge made the chains, but someone wrote the order. A scout at Sunken Watch followed the prison wagons west. Pilgrims at Witchroot Grove heard the dead repeating a king's name. Find what Blackmire tried to bury.",14)
  hud.action(hud.content,"Ask Mara about the drowned oath",func():accept();hud.show_character("mire"),not mara_near())
 else:
  for id in CLUES:
   var site=game.landscape.realms.SITES[id]
   hud.paragraph(("✓ " if data().clues.has(id) else "○ ")+site.name+" · "+game.exploration.bearing(site.point),14)
   if data().clues.has(id):hud.paragraph(CLUES[id],13)
  if step==1:hud.paragraph("Read both records at their actual world locations. Earlier searched caches count. Their normal supplies remain available separately.",14)
  elif step==2:hud.paragraph("The Veil Altar tests whether you can escape the grasp of the shades. Complete the existing swamp trial by dodging a warned strike and defeating its shades. Earlier wins count; the Reaper unlock and regional relic stay available.",14)
  elif step in [3,4]:
   hud.paragraph("Mara's notes: Blackmire has three floors. Find its armory key and drainage wheel, bind the level-two checkpoint, then face the Drowned Abomination. Its warned attacks grow faster below half health. Return up the entrance stairs to the level-two archive after the boss falls and recover the Drowned Testament. The rune puzzle, treasure and legendary castle relic remain separate rewards.",14)
   if step==4:hud.paragraph("The Abomination's defeat is recorded. You only need the archive testament now. An earlier castle victory counts; if you already left, re-enter and reach the level-two archive. The Dungeon Atlas marks the record after you discover its location.",14,Color("e8d3a4"))
   if testament_near():hud.action(hud.content,"Recover Drowned Testament",func():recover();hud.show_character("mire"))
  elif step==5:
   hud.paragraph("The king's testament names the bindings a betrayal, not a royal command. Its final page bears Frostspire's seal. Bring the record to Mara. Make no inventory space: the testament is a quest record, not a carried item.",14)
   hud.action(hud.content,"Claim chapter reward · 450 gold, 8 essence, 3 points",func():claim();hud.show_character("mire"),not mara_near())
  else:
   hud.paragraph("Mara: A false oath traveled farther than any army. Frostspire holds the next seal. Take the drowned king's promise with you: no traveler should become another prisoner of the mire.",14)
   hud.paragraph("CHAPTER III COMPLETE · Mirewarden's Oath permanently reduces positive weather wetness buildup by 40% in the Drowned Mire wilds during Survival. Hunger, thirst, sleep, temperature, drying and other regions keep their usual rules. It does not refill supplies or grant immunity.",14)
   hud.action(hud.content,"Next lead · track Frostspire Citadel",func():game.exploration.track("frostspire"))
  if step<6:hud.action(hud.content,"Track The Drowned Oath",track)
 hud.action(hud.content,"Back to story journal",func():hud.show_character("chapter"))
