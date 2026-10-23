extends RefCounted
const Data=preload("res://scripts/data.gd")
const SKILLS={
 "Warrior":{"name":"CLEAVE","cost":15,"cooldown":10,"desc":"A wide melee strike that knocks nearby enemies back."},
 "Mage":{"name":"METEOR","cost":28,"cooldown":14,"desc":"Blast a target and surrounding enemies with burning magic."},
 "Ranger":{"name":"VOLLEY","cost":18,"cooldown":10,"desc":"Loose three fast arrows toward the nearest enemy."},
 "Rogue":{"name":"VANISH","cost":18,"cooldown":16,"desc":"Hide for four seconds and move faster. Attacking breaks concealment."},
 "Cleric":{"name":"SANCTUARY","cost":25,"cooldown":20,"desc":"Create a healing circle that also damages nearby enemies for six seconds."},
 "Spellblade":{"name":"RUNEBURST","cost":25,"cooldown":12,"desc":"Strike nearby enemies with both melee and magic damage."},
 "Arcane Archer":{"name":"STAR VOLLEY","cost":25,"cooldown":14,"desc":"Fire five enchanted arrows that chain lightning between enemies."},
 "Reaper":{"name":"SOUL HARVEST","cost":25,"cooldown":14,"desc":"Drain nearby enemies and recover health."}
}
var game
var cooldown=0.0
var stealth=0.0
var sanctuary=0.0
var sanctuary_at=Vector2.ZERO
var pulse=0.0
func reset() -> void:
 cooldown=0; stealth=0; sanctuary=0; pulse=0
func tick(dt:float) -> void:
 cooldown=maxf(0,cooldown-dt); stealth=maxf(0,stealth-dt)
 if sanctuary<=0: return
 sanctuary=maxf(0,sanctuary-dt); pulse-=dt
 if game.player_position().distance_to(sanctuary_at)<105:
  game.hero.hp=minf(Data.max_hp(game.hero),game.hero.hp+Data.max_hp(game.hero)*.08*dt)
 if pulse<=0:
  pulse=1
  for enemy in game.enemies.duplicate():
   if not enemy.dead and not enemy.get("neutral",false) and enemy.pos.distance_to(sanctuary_at)<105 and game.line_clear(sanctuary_at,enemy.pos): game.hurt(enemy,Data.damage(game.hero,"magic")*.5,"magic")
func use() -> bool:
 if not game.playing or game.hero.is_empty() or cooldown>0 or game.survival.sheltered() or not game.build_recipe.is_empty(): return false
 var cls=game.hero.className
 var skill=SKILLS[cls]
 if game.hero.mp<skill.cost: game.notify("Not enough mana for "+skill.name,2); return false
 var target=game.closest(430,game.player_position(),{},true)
 if cls in ["Mage","Ranger","Arcane Archer"] and target.is_empty(): game.notify("No enemy in skill range.",2); return false
 var near=game.enemies.filter(func(e):return not e.dead and not e.get("neutral",false) and e.pos.distance_to(game.player_position())<150 and game.line_clear(game.player_position(),e.pos))
 if cls in ["Warrior","Spellblade","Reaper"] and near.is_empty(): game.notify("Move closer to an enemy.",2); return false
 game.hero.mp-=skill.cost; cooldown=skill.cooldown; game.swing_time=.3
 game.sound("spell")
 game.visual_fx("rune",game.player_position(),105,Color(Data.CLASSES[cls].color),.5)
 match cls:
  "Warrior":
   for enemy in near:
    game.hurt(enemy,Data.damage(game.hero,"melee")*2.2,"melee")
    enemy.pos=game.move_position(enemy.pos,game.player_position().direction_to(enemy.pos)*35,enemy.radius)
  "Mage":
   for enemy in game.enemies.duplicate():
    if not enemy.dead and not enemy.get("neutral",false) and enemy.pos.distance_to(target.pos)<90 and game.line_clear(game.player_position(),enemy.pos): game.hurt(enemy,Data.damage(game.hero,"magic")*3,"magic",1)
   game.visual_fx("fire",target.pos,90,Color("f5ae71"),.6)
   game.burst(target.pos,Color("f5ae71"),20)
  "Ranger","Arcane Archer":
   var count=5 if cls=="Arcane Archer" else 3
   for i in range(count):
    var direction=game.player_position().direction_to(target.pos).rotated((i-(count-1)*.5)*.065)
    game.shots.append({"pos":game.player_position(),"velocity":direction*420,"kind":"bow","damage":Data.damage(game.hero,"bow")*1.2,"enchant":3 if cls=="Arcane Archer" else 0,"life":1.7})
  "Rogue": stealth=4
  "Cleric": sanctuary=6; sanctuary_at=game.player_position(); pulse=0
  "Spellblade":
   for enemy in near:
    game.hurt(enemy,Data.damage(game.hero,"melee")*1.3,"melee")
    game.hurt(enemy,Data.damage(game.hero,"magic")*1.3,"magic",1)
  "Reaper":
   for enemy in near: game.hurt(enemy,Data.damage(game.hero,"magic")*2.1,"magic",4)
   game.hero.hp=minf(Data.max_hp(game.hero),game.hero.hp+Data.max_hp(game.hero)*.15)
 game.burst(game.player_position(),Color(Data.CLASSES[cls].color),12)
 game.hud.update_hud(); return true
