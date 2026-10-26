extends Control

const Layout=preload("res://scripts/control_layout.gd")
var manager
var original:Dictionary
var undo_stack:Array=[]
var redo_stack:Array=[]
var selected="movement"
var previewing=false
var finger=-1
var grab=Vector2.ZERO
var drag_start=Vector2.ZERO
var moved=false
var toolbar:PanelContainer
var preview_bar:PanelContainer
var tools_toggle:Button
var properties:PanelContainer
var presets_panel:PanelContainer
var status:Label
var selection:OptionButton
var movement:OptionButton
var confirm:ConfirmationDialog
var confirmation:Callable
var undo_button:Button
var redo_button:Button
var last_orientation=""
var grid_buttons:Dictionary={}
var resizing=false
var resize_rect=Rect2()
var resize_scale=1.0

func _ready() -> void:
	original=manager.model.data.duplicate(true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
	toolbar=panel();var box=VBoxContainer.new();toolbar.add_child(box)
	status=Label.new();status.add_theme_font_size_override("font_size",12);status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(status)
	var flow=HFlowContainer.new();flow.add_theme_constant_override("h_separation",5);box.add_child(flow)
	button(flow,"Save",save_layout);button(flow,"Cancel",cancel_edit)
	undo_button=button(flow,"Undo",undo_change);redo_button=button(flow,"Redo",redo_change)
	button(flow,"Preview",begin_preview).disabled=manager.game.hero.is_empty()
	button(flow,"Reset",request_reset);button(flow,"Presets",show_presets)
	var row=HBoxContainer.new();box.add_child(row)
	movement=OptionButton.new();movement.add_item("Joystick");movement.add_item("D-Pad");movement.custom_minimum_size=Vector2(108,40)
	movement.item_selected.connect(func(index):remember();manager.model.data.options.movement="joystick" if index==0 else "dpad";changed())
	row.add_child(movement)
	selection=OptionButton.new();selection.size_flags_horizontal=Control.SIZE_EXPAND_FILL;selection.custom_minimum_size.y=40
	for id in Layout.SIZES: selection.add_item(Layout.LABELS[id])
	selection.item_selected.connect(func(index):selected=Layout.SIZES.keys()[index];show_properties())
	row.add_child(selection)
	button(row,"Options",show_properties)
	button(row,"–",minimize_tools)
	var tools=HFlowContainer.new();box.add_child(tools)
	for key in ["grid","snap"]:
		var option=key;var field=CheckButton.new();field.text=key.capitalize();field.button_pressed=manager.model.data.options[key];field.add_theme_font_size_override("font_size",12)
		field.toggled.connect(func(value):remember();manager.model.data.options[option]=value;changed());tools.add_child(field);grid_buttons[key]=field
	button(tools,"Fix overlaps",fix_overlaps)
	preview_bar=panel();var preview_row=HBoxContainer.new();preview_bar.add_child(preview_row)
	button(preview_row,"Return to Edit",end_preview)
	var hint=Label.new();hint.text="Unsaved preview";hint.add_theme_font_size_override("font_size",11);preview_row.add_child(hint)
	preview_bar.hide()
	tools_toggle=button(self,"Tools",func():toolbar.show();tools_toggle.hide())
	tools_toggle.hide()
	confirm=ConfirmationDialog.new();confirm.title="Control layout";add_child(confirm)
	confirm.confirmed.connect(func():
		if confirmation.is_valid(): confirmation.call())
	get_viewport().size_changed.connect(resize_editor)
	resize_editor();refresh()

func panel() -> PanelContainer:
	var result=PanelContainer.new();var style=StyleBoxFlat.new()
	style.bg_color=Color("101624f5");style.border_color=Color("958364");style.set_border_width_all(1);style.set_corner_radius_all(10);style.set_content_margin_all(8)
	result.add_theme_stylebox_override("panel",style);add_child(result);return result

func button(parent:Node,title:String,callback:Callable) -> Button:
	var result=Button.new();result.text=title;result.name=title;result.custom_minimum_size=Vector2(48,40);result.add_theme_font_size_override("font_size",12);result.focus_mode=Control.FOCUS_NONE
	result.pressed.connect(callback);parent.add_child(result);return result

func remember() -> void:
	undo_stack.append(manager.model.data.duplicate(true))
	if undo_stack.size()>50: undo_stack.pop_front()
	redo_stack.clear()

func changed(custom:bool=true) -> void:
	if custom: manager.model.data.preset="Custom"
	manager.apply();queue_redraw()

func undo_change() -> void:
	if undo_stack.is_empty(): return
	redo_stack.append(manager.model.data.duplicate(true));manager.model.data=undo_stack.pop_back();changed(false)
	if is_instance_valid(properties) and properties.visible: show_properties()

func redo_change() -> void:
	if redo_stack.is_empty(): return
	undo_stack.append(manager.model.data.duplicate(true));manager.model.data=redo_stack.pop_back();changed(false)
	if is_instance_valid(properties) and properties.visible: show_properties()

func refresh() -> void:
	if toolbar==null: return
	var overlaps=manager.model.overlaps(manager.safe_rect(),manager.orientation())
	status.text="LAYOUT · %s · %s\n%s" % [manager.orientation().capitalize(),manager.model.data.preset,"Drag to move · Tap for options" if overlaps.is_empty() else "%d overlapping pairs · highlighted in red" % overlaps.size()]
	for key in grid_buttons: grid_buttons[key].set_pressed_no_signal(manager.model.data.options[key])
	movement.select(1 if manager.model.data.options.movement=="dpad" else 0)
	selection.select(Layout.SIZES.keys().find(selected))
	undo_button.disabled=undo_stack.is_empty();redo_button.disabled=redo_stack.is_empty()
	if last_orientation!=manager.orientation(): resize_editor()
	queue_redraw()

func resize_editor() -> void:
	if toolbar==null: return
	finger=-1;last_orientation=manager.orientation()
	var safe=manager.safe_rect()
	toolbar.position=safe.position;toolbar.size=Vector2(safe.size.x,0)
	tools_toggle.position=safe.position+Vector2(0,safe.size.y*.3);tools_toggle.size=Vector2(58,40)
	preview_bar.position=Vector2(safe.position.x+safe.size.x/2-126,safe.position.y);preview_bar.size=Vector2(252,0)
	if is_instance_valid(properties): position_properties()
	if is_instance_valid(presets_panel): presets_panel.position=safe.get_center()-presets_panel.size/2
	queue_redraw()

func blocked(at:Vector2) -> bool:
	if confirm.visible: return true
	for control in [toolbar,preview_bar,properties,presets_panel,tools_toggle]:
		if is_instance_valid(control) and control.visible and control.get_global_rect().has_point(at): return true
	return false

func _input(event:InputEvent) -> void:
	if previewing or confirm.visible: return
	var at=Vector2.ZERO;var index=-3;var down=false;var up=false;var motion=false;var canceled=false
	if event is InputEventScreenTouch:
		at=event.position;index=event.index;down=event.pressed;up=not down;canceled=event.canceled
	elif event is InputEventScreenDrag: at=event.position;index=event.index;motion=true
	elif event is InputEventMouseButton and event.device!=-1 and event.button_index==MOUSE_BUTTON_LEFT:
		at=event.position;index=-2;down=event.pressed;up=not down
	elif event is InputEventMouseMotion and finger==-2: at=event.position;index=-2;motion=true
	else: return
	if down and finger==-1:
		if blocked(at): return
		var ids=manager.registry.keys();ids.reverse()
		for id in ids:
			if manager.registry[id].get_global_rect().has_point(at):
				resizing=selected==id and at.distance_to(manager.registry[id].get_global_rect().end)<22
				selected=id;finger=index;grab=at-manager.registry[id].global_position;drag_start=at;moved=false
				resize_rect=manager.registry[id].get_global_rect();resize_scale=manager.item(id).scale
				if is_instance_valid(properties): properties.hide()
				refresh();break
	elif motion and index==finger:
		if not moved and at.distance_to(drag_start)>3: remember();moved=true
		if moved:
			var position_value=at-grab;var safe=manager.safe_rect()
			if resizing:
				var ratio=(at-resize_rect.position)/resize_rect.size
				manager.item(selected).scale=clampf(resize_scale*maxf(ratio.x,ratio.y),.5,2)
				position_value=resize_rect.position
			if manager.model.data.options.snap: position_value=safe.position+((position_value-safe.position)/24).round()*24
			manager.model.move(selected,position_value,safe,manager.orientation());changed()
	elif up and index==finger:
		finger=-1
		if not moved and not canceled: show_properties()
	else:
		if blocked(at): return
	get_viewport().set_input_as_handled()

func show_properties() -> void:
	if is_instance_valid(properties): properties.hide();properties.queue_free()
	properties=panel();var column=VBoxContainer.new();properties.add_child(column)
	var row=HBoxContainer.new();column.add_child(row)
	var name_label=Label.new();name_label.text=Layout.LABELS[selected];name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;name_label.add_theme_font_size_override("font_size",14);row.add_child(name_label)
	button(row,"Done",func():properties.hide())
	var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.scroll_deadzone=12;column.add_child(scroll)
	var body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
	var value=manager.item(selected)
	slider(body,"Size",value.scale*100,50,200,5,func(v):value.scale=v/100;changed())
	slider(body,"Opacity",value.opacity*100,20,100,5,func(v):value.opacity=v/100;changed())
	for axis in range(2):
		var component=axis
		slider(body,"Horizontal" if axis==0 else "Vertical",value.position[axis]*100,0,100,1,func(v):value.position[component]=v/100;changed())
	var skin=OptionButton.new();skin.custom_minimum_size.y=40
	for name_value in Layout.SKINS: skin.add_item(name_value)
	skin.select(Layout.SKINS.find(value.skin));skin.item_selected.connect(func(index):remember();value.skin=Layout.SKINS[index];changed());body.add_child(skin)
	var shown=CheckButton.new();shown.text="Visible during gameplay";shown.button_pressed=value.visible;shown.disabled=value.action in Layout.ESSENTIAL
	shown.toggled.connect(func(v):remember();value.visible=v;changed());body.add_child(shown)
	if selected in Layout.ASSIGNABLE:
		var assignment=OptionButton.new();assignment.custom_minimum_size.y=40
		for action in Layout.ASSIGNABLE: assignment.add_item(Layout.LABELS[action])
		assignment.select(Layout.ASSIGNABLE.find(value.action))
		assignment.item_selected.connect(func(index):remember();manager.model.reassign(selected,Layout.ASSIGNABLE[index],manager.orientation());changed();show_properties())
		body.add_child(assignment)
		var explanation=Label.new();explanation.text="Assignments swap slots to keep every action available.";explanation.add_theme_font_size_override("font_size",11);explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(explanation)
	button(body,"Copy layout to other orientation",copy_orientation)
	position_properties()

func slider(parent:Node,title:String,value:float,minimum:float,maximum:float,step_value:float,callback:Callable) -> void:
	var row=HBoxContainer.new();parent.add_child(row)
	var text_label=Label.new();text_label.text=title;text_label.add_theme_font_size_override("font_size",12);text_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(text_label)
	var field=SpinBox.new();field.min_value=minimum;field.max_value=maximum;field.step=step_value;field.value=value;field.suffix="%";field.custom_minimum_size=Vector2(116,40)
	field.value_changed.connect(func(v):remember();callback.call(v));row.add_child(field)
	var bar=HSlider.new();bar.min_value=minimum;bar.max_value=maximum;bar.step=step_value;bar.value=value;bar.custom_minimum_size.y=26;parent.add_child(bar)
	bar.set_meta("dragging",false)
	bar.drag_started.connect(func():remember();bar.set_meta("dragging",true))
	bar.drag_ended.connect(func(_changed):bar.set_meta("dragging",false))
	bar.value_changed.connect(func(v):
		if not bar.get_meta("dragging"): remember()
		field.set_value_no_signal(v);callback.call(v))

func position_properties() -> void:
	var safe=manager.safe_rect();var extent=Vector2(minf(340,safe.size.x),minf(390,safe.size.y-toolbar.size.y-12))
	properties.size=extent;properties.position=Vector2(safe.end.x-extent.x,safe.end.y-extent.y)

func copy_orientation() -> void:
	remember();var other="portrait" if manager.orientation()=="landscape" else "landscape"
	manager.model.data.layouts[other]=manager.model.data.layouts[manager.orientation()].duplicate(true);changed()

func request_reset() -> void:
	ask("Restore default positions and button settings for this orientation? Other saved presets are kept.",func():remember();manager.model.data.layouts[manager.orientation()]=manager.model.default_layout(manager.orientation()=="landscape");changed();hide_properties())

func ask(message:String,callback:Callable) -> void:
	confirmation=callback;confirm.dialog_text=message;confirm.popup_centered(Vector2i(340,170))

func hide_properties() -> void:
	if is_instance_valid(properties): properties.hide()

func fix_overlaps() -> void:
	remember();var okay=manager.model.fix_overlaps(manager.safe_rect(),manager.orientation());changed()
	if not okay: ask("Some controls still overlap. Reduce their size, hide optional controls, or move them manually.",func():pass)

func minimize_tools() -> void:
	hide_properties();toolbar.hide();tools_toggle.show()

func begin_preview() -> void:
	if manager.game.hero.is_empty(): return
	finger=-1;previewing=true;hide_properties()
	if is_instance_valid(presets_panel): presets_panel.hide()
	toolbar.hide();tools_toggle.hide();preview_bar.show();mouse_filter=Control.MOUSE_FILTER_IGNORE
	manager.hud.resume();manager.apply();queue_redraw()

func end_preview() -> void:
	manager.game.pause_game();previewing=false;toolbar.show();preview_bar.hide();mouse_filter=Control.MOUSE_FILTER_STOP
	manager.hud.overlay.hide();manager.hud.top.show();manager.hud.buttons.show();manager.apply();queue_redraw()

func cancel_edit() -> void:
	manager.game.pause_game();manager.model.data=original.duplicate(true);finish()

func save_layout() -> void:
	manager.model.data=manager.model.sanitize(manager.model.data)
	var overlaps=manager.model.overlaps(manager.safe_rect(),manager.orientation())
	if not overlaps.is_empty():
		ask("%d control pairs overlap. You can cancel and use Fix overlaps, or save this arrangement anyway." % overlaps.size(),commit_save)
	else: commit_save()

func commit_save() -> void:
	if manager.save(): manager.game.pause_game();finish()

func finish() -> void:
	manager.release_all();manager.editor=null;hide();queue_free();manager.hud.layout();manager.apply();manager.show_settings()

func show_presets() -> void:
	hide_properties()
	if is_instance_valid(presets_panel): presets_panel.hide();presets_panel.queue_free()
	presets_panel=panel();var column=VBoxContainer.new();presets_panel.add_child(column)
	var label=Label.new();label.text="Layout presets · changes apply when you Save";label.add_theme_font_size_override("font_size",12);column.add_child(label)
	var choices=OptionButton.new();choices.custom_minimum_size.y=44
	var names=Layout.PRESETS+manager.model.data.custom.keys()
	for value in names: choices.add_item(value)
	choices.select(maxi(0,names.find(manager.model.data.preset)));column.add_child(choices)
	var name_field=LineEdit.new();name_field.placeholder_text="New preset name";name_field.max_length=32;name_field.custom_minimum_size.y=44;column.add_child(name_field)
	var message=Label.new();message.text="Up to 12 personal presets";message.add_theme_font_size_override("font_size",12);column.add_child(message)
	var row=HFlowContainer.new();column.add_child(row)
	button(row,"Load",func():remember();manager.model.apply_preset(choices.get_item_text(choices.selected));changed(false);presets_panel.hide())
	button(row,"Save copy",func():remember();var okay=manager.model.store_preset(name_field.text);changed(false);message.text="Preset saved in draft" if okay else "Use a new name (built-in names are reserved)";if okay:show_presets())
	button(row,"Overwrite",func():
		var chosen=choices.get_item_text(choices.selected)
		if not manager.model.data.custom.has(chosen): message.text="Select a personal preset to overwrite";return
		ask("Overwrite "+chosen+" with your current arrangement?",func():remember();manager.model.store_preset(chosen,true);changed(false);show_presets()))
	button(row,"Rename",func():remember();var okay=manager.model.rename_preset(choices.get_item_text(choices.selected),name_field.text);changed(false);message.text="Use a new name for a personal preset";if okay:show_presets())
	button(row,"Delete",func():
		var chosen=choices.get_item_text(choices.selected)
		if not manager.model.data.custom.has(chosen): message.text="Built-in presets cannot be deleted";return
		ask("Delete personal preset "+chosen+"?",func():remember();manager.model.delete_preset(chosen);changed(false);show_presets()))
	button(row,"Close",func():presets_panel.hide())
	var safe=manager.safe_rect();presets_panel.size=Vector2(minf(360,safe.size.x),280);presets_panel.position=safe.get_center()-presets_panel.size/2

func _draw() -> void:
	if previewing: return
	var safe=manager.safe_rect();draw_rect(safe,Color("d0bf8b"),false,1)
	if manager.model.data.options.grid:
		for x in range(int(safe.position.x),int(safe.end.x),24): draw_line(Vector2(x,safe.position.y),Vector2(x,safe.end.y),Color(1,1,1,.07))
		for y in range(int(safe.position.y),int(safe.end.y),24): draw_line(Vector2(safe.position.x,y),Vector2(safe.end.x,y),Color(1,1,1,.07))
	var conflicts=[]
	for pair in manager.model.overlaps(safe,manager.orientation()): conflicts.append_array(pair)
	for id in manager.registry:
		var rectangle=manager.registry[id].get_global_rect()
		var color=Color("ffa3a3") if id in conflicts else Color("f8d58a") if id==selected else Color("a1c4d7")
		if not manager.item(id).visible: color=Color("8d8c99")
		draw_rect(rectangle,color,false,2 if id==selected else 1)
		if id==selected: draw_circle(rectangle.end-Vector2(6,6),4,color)

func _notification(what:int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]: finger=-1
