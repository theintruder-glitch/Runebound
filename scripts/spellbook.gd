extends RefCounted
const Data=preload("res://scripts/data.gd")
const BOOK={
 "briarheart":{"name":"Briarheart","short":"BRIARHEART","cost":30,"cooldown":14.0,"level":1,"price":0,"color":"a7d99d","desc":"Thornwatch relic spell. Briars strike and slow nearby enemies; restore 10% health."},
 "wintercrown":{"name":"Winter Crown","short":"WINTER CROWN","cost":34,"cooldown":11.0,"level":1,"price":0,"color":"a5e3fa","desc":"Frostspire relic spell. Release a wide crown of ice that damages and slows nearby enemies."},
 "mireward":{"name":"Mirebound Ward","short":"MIRE WARD","cost":30,"cooldown":17.0,"level":1,"price":0,"color":"c6a1e3","desc":"Blackmire relic spell. Reduce strike damage for 10 seconds and lash nearby enemies with spectral chains."},
 "stormlance":{"name":"Storm Warden's Lance","short":"STORM LANCE","cost":26,"cooldown":4.0,"level":1,"price":0,"color":"a7cdff","desc":"Stormbreak relic spell. Launch a heavy lightning lance in your facing direction."},
 "fire":{"name":"Firebolt","short":"FIREBOLT","cost":12,"cooldown":1.3,"level":1,"price":0,"color":"ffb077","desc":"A burning projectile. Touch assists toward a nearby enemy; mouse aiming follows your pointer."},
 "frost":{"name":"Frost Nova","short":"FROST","cost":20,"cooldown":5.5,"level":1,"price":0,"color":"9edff4","desc":"Freeze enemies in a circle around you."},
 "heal":{"name":"Mend","short":"MEND","cost":25,"cooldown":9.0,"level":1,"price":0,"color":"aedfb6","desc":"Restore health. Can be used inside a shelter."},
 "arc":{"name":"Chain Lightning","short":"LIGHTNING","cost":22,"cooldown":4.0,"level":2,"price":90,"color":"c7b1ff","desc":"Aim near a foe to chain lightning through up to four enemies. Walls block jumps."},
 "lance":{"name":"Glacial Lance","short":"ICE LANCE","cost":18,"cooldown":2.5,"level":3,"price":140,"color":"91e8f5","desc":"A fast, heavy ice spear that slows its victim."},
 "ward":{"name":"Astral Ward","short":"WARD","cost":28,"cooldown":16.0,"level":4,"price":210,"color":"9ecfff","desc":"Reduce enemy strike damage by 60% for 8 seconds. Hunger and exposure still hurt."},
 "meteor":{"name":"Meteor Fall","short":"METEOR","cost":32,"cooldown":8.0,"level":5,"price":280,"color":"ffa46e","desc":"Choose a ground circle, then confirm. A meteor strikes after 0.9 seconds and burns enemies."},
 "sunburst":{"name":"Sunburst","short":"SUNBURST","cost":35,"cooldown":12.0,"level":6,"price":360,"color":"ffe2a0","desc":"Blast enemies around you and restore 18% health."},
 "blizzard":{"name":"Blizzard","short":"BLIZZARD","cost":40,"cooldown":12.0,"level":7,"price":460,"color":"b2edfa","desc":"Place a field that damages and slows enemies for 5 seconds."}
}
var game
var targeting=""
var zones:Array=[]
var ward_time=0.0
var aim_finger=-1
var mobile_point=Vector2.ZERO
var mobile_point_set=false
func cancel_target() -> void:
	targeting="";aim_finger=-1;mobile_point_set=false
func reset() -> void: cancel_target();zones.clear();ward_time=0.0
func known(id:String) -> bool: return not game.hero.is_empty() and game.hero.spells.known.has(id)
func rank(id:String) -> int: return int(game.hero.spells.known.get(id,0))
func power(id:String) -> float: return 1.0+maxi(0,rank(id)-1)*.25
func price(id:String) -> int: return BOOK[id].price*(rank(id)+1)
func buy_reason(id:String) -> String:
	if not BOOK.has(id) or BOOK[id].price==0: return "Starter spell"
	if not game.trader.near(): return "Visit Mara to learn spells"
	if rank(id)>=3: return "Mastered · rank III"
	if game.hero.level<BOOK[id].level+rank(id)*2: return "Requires level %d" % (BOOK[id].level+rank(id)*2)
	if game.hero.gold<price(id): return "Not enough gold"
	return ""
func buy(id:String) -> bool:
	if not buy_reason(id).is_empty(): return false
	game.hero.gold-=price(id);game.hero.spells.known[id]=rank(id)+1
	game.save_game();return true
func assign(id:String,slot:int) -> bool:
	if not known(id) or slot<0 or slot>=3: return false
	var slots=game.hero.spells.slots;var old=slots[slot];var previous=slots.find(id)
	if previous>=0: slots[previous]=old
	slots[slot]=id;game.save_game();game.hud.update_hud();return true
func can_cast(id:String) -> bool:
	return BOOK.has(id) and game.playing and known(id) and game.hero.mp>=BOOK[id].cost and float(game.spell_cooldowns.get(id,0))<=0 and (id in ["heal","ward","mireward"] or not game.survival.sheltered()) and game.build_recipe.is_empty()
func request_slot(slot:int) -> bool:
	if slot<0 or slot>=3 or game.hero.is_empty(): return false
	var id=game.hero.spells.slots[slot]
	if not can_cast(id): game.notify("Spell unavailable: check mana, cooldown, or shelter.",2);return false
	game.fishing.cancel()
	if id in ["meteor","blizzard"]:
		cancel_target();targeting=id;game.desktop.clear_input();game.attack_held=false
		game.notify("Aim "+BOOK[id].name+" · "+placement_hint(),3);return true
	cancel_target()
	return cast(id,target_point())
func placement_hint() -> String:
	return "Left click: cast · Right click / Esc: cancel" if game.desktop.enabled else "Tap or drag ground · CAST / CANCEL"
func release_touch(event:InputEvent) -> void:
	if event is InputEventScreenTouch and not event.pressed and event.index==aim_finger: aim_finger=-1
func handle_touch(event:InputEvent) -> bool:
	if game.desktop.enabled or not game.playing or targeting.is_empty(): return false
	if event is InputEventScreenTouch:
		if not event.pressed or aim_finger!=-1 or game.hud.blocks_world_pointer(event.position): return false
		aim_finger=event.index
	elif event is InputEventScreenDrag:
		if event.index!=aim_finger or game.hud.blocks_world_pointer(event.position): return false
	else: return false
	mobile_point=game.get_canvas_transform().affine_inverse()*event.position
	mobile_point_set=true
	return true
func target_point() -> Vector2:
	var at=game.player_position()
	var target=game.desktop.aim_point() if game.desktop.enabled and game.desktop.pointer_seen else mobile_point if not game.desktop.enabled and mobile_point_set else at+game.facing*180
	return at+(target-at).limit_length(380)
func valid_ground(at:Vector2) -> bool:
	return at.distance_to(game.player_position())<=381 and game.walkable(at) and game.line_clear(game.player_position(),at)
func confirm() -> bool:
	if targeting.is_empty(): return false
	if not valid_ground(target_point()): game.notify("That target is blocked. Choose clear ground.",2);return false
	var result=cast(targeting,target_point())
	if result: cancel_target()
	return result
func cast(id:String,at:Vector2=Vector2.ZERO) -> bool:
	if not can_cast(id): return false
	if id in ["fire","frost","heal"]: return game.cast_legacy(id)
	var targets:Array=[]
	if id=="arc":
		var first:Dictionary={};var best=120.0
		for e in game.enemies:
			if not e.dead and e.pos.distance_to(game.player_position())<430 and game.line_clear(game.player_position(),e.pos):
				var distance=e.pos.distance_to(at)
				if distance<best: best=distance;first=e
		if first.is_empty(): game.notify("Aim near an enemy for Chain Lightning.",2);return false
		targets.append(first)
	if id in ["meteor","blizzard"] and not valid_ground(at): return false
	game.hero.mp-=BOOK[id].cost;game.spell_cooldowns[id]=BOOK[id].cooldown;game.sound("spell")
	game.cast_feedback(Color(BOOK[id].color))
	if id!="ward": game.abilities.stealth=0
	var damage=Data.damage(game.hero,"magic")*power(id);var color=Color(BOOK[id].color)
	match id:
		"briarheart":
			area(game.player_position(),175,damage*1.2,2);game.hero.hp=minf(Data.max_hp(game.hero),game.hero.hp+Data.max_hp(game.hero)*.1);game.visual_fx("frost",game.player_position(),175,color,.7)
		"wintercrown":area(game.player_position(),215,damage*2.0,2);game.visual_fx("frost",game.player_position(),215,color,.9)
		"mireward":ward_time=10;area(game.player_position(),140,damage*1.4,0);game.visual_fx("storm",game.player_position(),140,color,.7)
		"stormlance":
			var direction=game.desktop.aim_direction() if game.desktop.enabled else game.facing
			game.shots.append({"pos":game.player_position(),"velocity":direction.normalized()*560,"kind":"magic","damage":damage*3.1,"enchant":3,"life":1.1,"color":color,"lance":true})
		"lance":
			var direction=game.desktop.aim_direction() if game.desktop.enabled else game.facing
			game.shots.append({"pos":game.player_position(),"velocity":direction.normalized()*520,"kind":"magic","damage":damage*2.5,"enchant":2,"life":1.1,"color":color,"lance":true})
		"arc":
			var origin=game.player_position()
			for i in range(4):
				var foe=targets.back();var effect=game.visual_fx("storm",origin,160,color,.4);effect["end"]=foe.pos
				game.hurt(foe,damage*1.8*pow(.8,i),"magic",0,true);origin=foe.pos
				var next:Dictionary={};var best=180.0
				for e in game.enemies:
					if not e.dead and e not in targets and e.pos.distance_to(origin)<best and game.line_clear(origin,e.pos): best=e.pos.distance_to(origin);next=e
				if next.is_empty(): break
				targets.append(next)
		"ward": ward_time=8+2*(rank(id)-1);game.visual_fx("heal",game.player_position(),50,color,.6)
		"sunburst":
			area(game.player_position(),195,damage*2.1,0)
			game.hero.hp=minf(Data.max_hp(game.hero),game.hero.hp+Data.max_hp(game.hero)*.18*power(id))
			game.visual_fx("sunburst",game.player_position(),195,color,.85)
		"meteor","blizzard":
			zones.append({"id":id,"pos":at,"delay":.9 if id=="meteor" else 0.0,"life":.91 if id=="meteor" else 5.0,"pulse":0.0,"damage":damage,"radius":110.0 if id=="meteor" else 135.0})
	return true
func area(at:Vector2,radius:float,damage:float,enchant:int) -> void:
	for e in game.enemies.duplicate():
		if not e.dead and e.pos.distance_to(at)<radius and game.line_clear(at,e.pos): game.hurt(e,damage,"magic",enchant)
func tick(dt:float) -> void:
	ward_time=maxf(0,ward_time-dt)
	for z in zones:
		z.life-=dt;z.delay-=dt;z.pulse-=dt
		if z.id=="meteor" and z.delay<=0:
			area(z.pos,z.radius,z.damage*4,1);game.visual_fx("meteor",z.pos,z.radius,Color("ffa46e"),.8);game.burst(z.pos,Color("ffcf80"),24);z.life=0
		elif z.id=="blizzard" and z.pulse<=0:
			z.pulse=.75;area(z.pos,z.radius,z.damage*.45,2);game.visual_fx("frost",z.pos,z.radius,Color("b2edfa"),.7)
	zones=zones.filter(func(z):return z.life>0)
func draw(canvas:CanvasItem) -> void:
	if ward_time>0:
		canvas.draw_circle(game.player_position(),28,Color("93d7ff22"));canvas.draw_arc(game.player_position(),29,0,TAU,40,Color("b5eaff"),2,true)
	for z in zones:
		var tint=Color("ffb97b") if z.id=="meteor" else Color("a1def4");var fill=tint;fill.a=.09
		canvas.draw_circle(z.pos,z.radius,fill);canvas.draw_arc(z.pos,z.radius,0,TAU,56,tint,1.5,true)
		if z.id=="meteor":
			var p=1-clampf(z.delay/.9,0,1);canvas.draw_circle(z.pos+Vector2(80,-220)*(1-p),12+8*p,tint)
	if not targeting.is_empty() and game.playing:
		var at=target_point();var radius=110 if targeting=="meteor" else 135
		var color=Color("a9eed4") if valid_ground(at) else Color("ff8479");var fill=color;fill.a=.1
		canvas.draw_circle(at,radius,fill);canvas.draw_arc(at,radius,0,TAU,64,color,2,true);canvas.draw_line(game.player_position(),at,Color(color,.25),1,true)
