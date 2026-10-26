extends RefCounted

# This file owns preferences only. Character/save migration never reads it.
const PATH="user://controls.json"
const PRESETS=["Classic RPG","D-Pad Classic","Compact","Large Controls","Left-handed","Combat","Exploration","Custom"]
const SKINS=["Vyrnspire","Dark stone","Gold trim","Purple magic","Blue runes"]
const SIZES={"movement":Vector2(148,148),"attack":Vector2(92,64),"dodge":Vector2(70,64),"auto":Vector2(62,56),"skill":Vector2(96,56),"spell_1":Vector2(72,64),"spell_2":Vector2(72,64),"spell_3":Vector2(72,64),"interact":Vector2(224,52),"inventory":Vector2(60,44),"camp":Vector2(68,44),"pause":Vector2(36,44),"map":Vector2(62,44),"build_rotate":Vector2(106,46),"build_cancel":Vector2(106,46),"cast_confirm":Vector2(108,52),"cast_cancel":Vector2(108,52)}
const LABELS={"movement":"Movement","attack":"Attack","dodge":"Dodge","auto":"Auto attack","skill":"Class skill","spell_1":"Spell 1","spell_2":"Spell 2","spell_3":"Spell 3","interact":"Interact / Pickup","inventory":"Inventory","camp":"Camp","pause":"Pause / Settings","map":"World map","build_rotate":"Rotate building","build_cancel":"Cancel building","cast_confirm":"Confirm spell","cast_cancel":"Cancel spell"}
const ASSIGNABLE=["attack","dodge","auto","skill","spell_1","spell_2","spell_3","inventory","camp","map"]
const ESSENTIAL=["movement","attack","dodge","interact","pause"]
var data:Dictionary={}
var recovered=false

func _init() -> void: data=defaults()

static func number(value, fallback:float, minimum:float, maximum:float) -> float:
	if not (value is float or value is int) or not is_finite(float(value)): return fallback
	return clampf(float(value),minimum,maximum)

func defaults() -> Dictionary:
	return {"schema":1,"preset":"Classic RPG","options":{"movement":"joystick","floating":false,"sensitivity":1.0,"dead_zone":.12,"dpad_spacing":.08,"haptics":false,"hide_on_gamepad":false,"grid":true,"snap":false},"layouts":{"portrait":default_layout(false),"landscape":default_layout(true)},"custom":{}}

func default_layout(landscape:bool) -> Dictionary:
	var view=Vector2(900,480) if landscape else Vector2(480,900)
	var safe=Rect2(Vector2(8,8),view-Vector2(16,16))
	var positions={"movement":Vector2(24,view.y-180),"skill":Vector2(24,view.y-252),"attack":Vector2(view.x-184,view.y-158),"auto":Vector2(view.x-254,view.y-150),"dodge":Vector2(view.x-82,view.y-158),"interact":Vector2(view.x/2-112,view.y-265),"inventory":Vector2(view.x-108,14),"camp":Vector2(view.x-182,14),"pause":Vector2(view.x-45,14),"map":Vector2(view.x-252,14),"build_rotate":Vector2(view.x/2-112,view.y-325),"build_cancel":Vector2(view.x/2+6,view.y-325),"cast_confirm":Vector2(view.x/2-112,view.y-325),"cast_cancel":Vector2(view.x/2+4,view.y-325)}
	if landscape:
		positions.skill.x=208
		positions.attack=Vector2(view.x-184,view.y-118);positions.auto=Vector2(view.x-254,view.y-98);positions.dodge=Vector2(view.x-82,view.y-108)
		positions.interact=Vector2(view.x/2-112,view.y-70)
		for id in ["build_rotate","build_cancel","cast_confirm","cast_cancel"]: positions[id].y=view.y-128
	for i in range(3): positions["spell_%d" % (i+1)]=Vector2(view.x-252+i*80,view.y-(200 if landscape else 84))
	var result={}
	for id in SIZES:
		var base=base_size(id,landscape)
		var available=(safe.size-base).max(Vector2.ONE)
		var p=(positions[id]-safe.position)/available
		result[id]={"position":[p.x,p.y],"scale":1.0,"opacity":.9,"skin":"Vyrnspire","visible":id!="map","action":id}
	return result

func base_size(id:String,landscape:bool) -> Vector2:
	if landscape:
		if id=="attack": return Vector2(92,92)
		if id=="dodge": return Vector2(70,76)
		if id=="auto": return Vector2(62,64)
		if id.begins_with("spell_"): return Vector2(72,72)
	return SIZES.get(id,Vector2(64,64))

func sanitize(raw) -> Dictionary:
	var result=defaults()
	if not raw is Dictionary: return result
	var options=raw.get("options",{})
	if options is Dictionary:
		for key in result.options:
			if result.options[key] is bool:
				if options.get(key) is bool: result.options[key]=options[key]
		for rule in [["sensitivity",1.0,.5,2.0],["dead_zone",.12,0,.4],["dpad_spacing",.08,0,.3]]:
			result.options[rule[0]]=number(options.get(rule[0]),rule[1],rule[2],rule[3])
		result.options.movement="dpad" if options.get("movement")=="dpad" else "joystick"
	var layouts=raw.get("layouts",{})
	if layouts is Dictionary:
		for orientation in result.layouts:
			var layout_value=layouts.get(orientation,{})
			if not layout_value is Dictionary: continue
			for id in SIZES:
				var item=layout_value.get(id,{})
				if not item is Dictionary: continue
				var target=result.layouts[orientation][id]
				var p=item.get("position")
				if p is Array and p.size()==2: target.position=[number(p[0],target.position[0],0,1),number(p[1],target.position[1],0,1)]
				target.scale=number(item.get("scale"),1,.5,2)
				target.opacity=number(item.get("opacity"),.9,.2,1)
				if item.get("skin") in SKINS: target.skin=item.skin
				if item.get("visible") is bool: target.visible=item.visible
				if id in ASSIGNABLE and item.get("action") in ASSIGNABLE: target.action=item.action
			# Repair conflicting/missing assignments without losing any essential action.
			var assigned=[]
			for id in ASSIGNABLE:
				var entry=result.layouts[orientation][id]
				if entry.action in assigned: entry.action=""
				else: assigned.append(entry.action)
			var missing=ASSIGNABLE.filter(func(a):return not assigned.has(a))
			for id in ASSIGNABLE:
				if result.layouts[orientation][id].action.is_empty(): result.layouts[orientation][id].action=missing.pop_front()
			for id in SIZES:
				if result.layouts[orientation][id].action in ESSENTIAL: result.layouts[orientation][id].visible=true
	var custom=raw.get("custom",{})
	if custom is Dictionary:
		for key in custom:
			if result.custom.size()>=12: break
			if key is String and valid_name(key) and custom[key] is Dictionary:
				var preset_value=sanitize({"options":custom[key].get("options",{}),"layouts":custom[key].get("layouts",{})})
				result.custom[key]={"options":preset_value.options,"layouts":preset_value.layouts}
	var selected=raw.get("preset","")
	if selected in PRESETS or result.custom.has(selected): result.preset=selected
	return result

func load_settings() -> void:
	for path in [PATH,PATH+".bak"]:
		if not FileAccess.file_exists(path): continue
		var file=FileAccess.open(path,FileAccess.READ)
		if file==null or file.get_length()>1048576: continue
		var parser=JSON.new();var error=parser.parse(file.get_as_text());file.close()
		if error!=OK: continue
		var value=parser.data
		if value is Dictionary and value.get("schema")==1:
			data=sanitize(value);recovered=path.ends_with(".bak");return
	data=defaults()

func save_settings() -> bool:
	data=sanitize(data)
	var file=FileAccess.open(PATH+".tmp",FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(data,"",true,true));file.flush()
	var okay=file.get_error()==OK;file.close()
	if not okay: return false
	var path=ProjectSettings.globalize_path(PATH)
	if FileAccess.file_exists(PATH):
		var current=JSON.new()
		var valid=current.parse(FileAccess.get_file_as_string(PATH))==OK
		if valid and current.data is Dictionary and current.data.get("schema")==1:
			if DirAccess.copy_absolute(path,path+".bak")!=OK: return false
	return DirAccess.rename_absolute(path+".tmp",path)==OK

func rect(id:String,safe:Rect2,orientation:String) -> Rect2:
	var item=data.layouts[orientation][id]
	var extent=(base_size(id,orientation=="landscape")*item.scale).min(safe.size)
	var p=Vector2(item.position[0],item.position[1])
	return Rect2(safe.position+(safe.size-extent)*p,extent)

func move(id:String,at:Vector2,safe:Rect2,orientation:String) -> void:
	var extent=rect(id,safe,orientation).size
	var available=(safe.size-extent).max(Vector2.ONE)
	var p=((at-safe.position)/available).clamp(Vector2.ZERO,Vector2.ONE)
	data.layouts[orientation][id].position=[p.x,p.y]

func reassign(id:String,action:String,orientation:String) -> bool:
	if id not in ASSIGNABLE or action not in ASSIGNABLE: return false
	var layout_value=data.layouts[orientation];var previous=layout_value[id].action
	for other in ASSIGNABLE:
		if other!=id and layout_value[other].action==action: layout_value[other].action=previous
	layout_value[id].action=action
	for key in ASSIGNABLE:
		if layout_value[key].action in ESSENTIAL: layout_value[key].visible=true
	return true

func group(id:String) -> String:
	if id.begins_with("cast_"): return "aim"
	if id.begins_with("build_"): return "build"
	return "always"

func overlaps(safe:Rect2,orientation:String) -> Array:
	var result=[];var ids=SIZES.keys()
	for i in range(ids.size()):
		if not data.layouts[orientation][ids[i]].visible: continue
		for j in range(i+1,ids.size()):
			if not data.layouts[orientation][ids[j]].visible: continue
			var a=group(ids[i]);var b=group(ids[j])
			if a!=b and a!="always" and b!="always": continue
			if rect(ids[i],safe,orientation).grow(-1).intersects(rect(ids[j],safe,orientation).grow(-1)): result.append([ids[i],ids[j]])
	return result

func fix_overlaps(safe:Rect2,orientation:String) -> bool:
	var placed=[]
	for id in ESSENTIAL+SIZES.keys().filter(func(a):return a not in ESSENTIAL):
		if not data.layouts[orientation][id].visible: continue
		var original=rect(id,safe,orientation);var best=original;var distance=INF;var found=false
		for y in range(ceil(safe.size.y/12.0)+1):
			for x in range(ceil(safe.size.x/12.0)+1):
				var p=(safe.position+Vector2(x,y)*12).min(safe.end-original.size)
				var candidate=Rect2(p,original.size);var blocked=false
				for other in placed:
					if group(id)!=group(other) and group(id)!="always" and group(other)!="always": continue
					if candidate.grow(3).intersects(rect(other,safe,orientation)): blocked=true;break
				if not blocked and p.distance_squared_to(original.position)<distance:
					best=candidate;distance=p.distance_squared_to(original.position);found=true
		if found: move(id,best.position,safe,orientation)
		placed.append(id)
	return overlaps(safe,orientation).is_empty()

func apply_preset(preset_name:String) -> bool:
	if data.custom.has(preset_name):
		data.options=data.custom[preset_name].options.duplicate(true);data.layouts=data.custom[preset_name].layouts.duplicate(true)
	elif preset_name in PRESETS:
		var original=defaults();data.options=original.options;data.layouts=original.layouts
		if preset_name=="D-Pad Classic": data.options.movement="dpad"
		for orientation in data.layouts:
			for id in SIZES:
				var item=data.layouts[orientation][id]
				if preset_name=="Compact": item.scale=.8
				if preset_name=="Large Controls": item.scale=1.25
				if preset_name=="Combat" and id in ["attack","dodge"]: item.scale=1.15;item.skin="Gold trim"
				if preset_name=="Left-handed": item.position[0]=1.0-item.position[0]
				if preset_name=="Exploration" and id in ["auto","spell_2","spell_3"]: item.visible=false
			var safe=Rect2(Vector2(8,8),Vector2(884,464) if orientation=="landscape" else Vector2(464,884))
			if preset_name in ["Large Controls","Compact","Combat"]: fix_overlaps(safe,orientation)
	else: return false
	data.preset=preset_name;return true

func valid_name(value:String) -> bool: return not value.strip_edges().is_empty() and value.length()<=32 and value not in PRESETS

func store_preset(value:String,overwrite:bool=false) -> bool:
	value=value.strip_edges()
	if not valid_name(value) or (data.custom.has(value) and not overwrite) or (not data.custom.has(value) and data.custom.size()>=12): return false
	data.custom[value]={"options":data.options.duplicate(true),"layouts":data.layouts.duplicate(true)};data.preset=value;return true

func rename_preset(old:String,value:String) -> bool:
	value=value.strip_edges()
	if not data.custom.has(old) or not valid_name(value) or data.custom.has(value): return false
	data.custom[value]=data.custom[old];data.custom.erase(old)
	if data.preset==old: data.preset=value
	return true

func delete_preset(value:String) -> bool:
	if not data.custom.has(value): return false
	data.custom.erase(value)
	if data.preset==value: data.preset="Custom"
	return true
