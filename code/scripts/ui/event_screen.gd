extends Control
signal chosen(action: String, source: String, target: String)
signal menu_requested
const Events=preload("res://code/scripts/run/event_rules.gd")
const Catalog=preload("res://code/scripts/run/event_catalog.gd")
const Seeds=preload("res://code/scripts/run/run_catalog.gd")
const Relics=preload("res://code/scripts/relics/relic_catalog.gd")
const Paper=preload("res://code/scripts/ui/global_theme.gd")
var state: Dictionary
var action_buttons: Dictionary={}
var source_buttons: Dictionary={}
var _title: Label
var _inventory: Label
var _content: VBoxContainer
var _footer: HBoxContainer
var _source_grid: GridContainer
var _banner_frame: PanelContainer
var _submitted:=false
func _label(parent: Node,text: String,size: int=18) -> Label:
	var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x=1;label.add_theme_font_size_override("font_size",size);parent.add_child(label);return label
func _ready():
	theme=Paper.make(17)
	var page:=VBoxContainer.new();page.set_anchors_and_offsets_preset(PRESET_FULL_RECT);page.add_theme_constant_override("separation",14);add_child(page)
	_title=_label(page,"江湖异事",30);_title.add_theme_font_override("font",Paper.title_font());_inventory=_label(page,"",17)
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true;page.add_child(scroll)
	_content=VBoxContainer.new();_content.size_flags_horizontal=SIZE_EXPAND_FILL;_content.add_theme_constant_override("separation",14);scroll.add_child(_content)
	_footer=HBoxContainer.new();_footer.alignment=BoxContainer.ALIGNMENT_END;_footer.add_theme_constant_override("separation",14);page.add_child(_footer)
	resized.connect(func():if _source_grid!=null:_source_grid.columns=3 if size.x>=1400 else 2)
	resized.connect(_layout_banner)
func _panel(parent: Node) -> PanelContainer:
	var panel:=PanelContainer.new();panel.size_flags_horizontal=SIZE_EXPAND_FILL
	var style:=Paper.box(Paper.PANEL);style.content_margin_left=16;style.content_margin_right=16;style.content_margin_top=14;style.content_margin_bottom=14
	panel.add_theme_stylebox_override("panel",Paper.ornate(style));parent.add_child(panel);return panel
func _icon(parent: Node,path: String,side: int=72):
	var icon:=TextureRect.new();icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size=Vector2(side,side);icon.texture=load(path);parent.add_child(icon)
func _button(parent: Node,title: String,action: String,source: String="",target: String="",primary: bool=false) -> Button:
	var button:=Button.new();button.text=title;button.custom_minimum_size=Vector2(110,46)
	button.tooltip_text=Events.reason(state,action,source,target);button.disabled=not button.tooltip_text.is_empty()
	if primary:Paper.primary(button)
	parent.add_child(button);button.pressed.connect(_submit.bind(action,source,target));return button
func _action(title: String,details: String,action: String,icon_path: String="",source: String="",target: String=""):
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);_panel(_content).add_child(row)
	if not icon_path.is_empty():_icon(row,icon_path)
	var column:=VBoxContainer.new();column.size_flags_horizontal=SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",7);row.add_child(column)
	_label(column,title,21)
	if not details.is_empty():_label(column,details,17).add_theme_color_override("font_color",Paper.MUTED)
	var reason:=Events.reason(state,action,source,target)
	if not reason.is_empty():_label(column,reason,16).add_theme_color_override("font_color",Paper.RED)
	action_buttons[action if target.is_empty() else target]=_button(row,"开战" if action=="fight" else "选择",action,source,target,true)
func _gift(gift: Dictionary,action: String,source: String="",target: String="",title: String=""):
	var icon_path: String="res://art/resources/gold.png" if str(gift.id).is_empty() else str(Relics.definition(gift.id).icon)
	_action(title if not title.is_empty() else ("金币补偿" if str(gift.id).is_empty() else str(Relics.definition(gift.id).name)),Events.describe(gift),action,icon_path,source,target)
func configure(run: Dictionary):
	state=run.duplicate(true)
	var node: Dictionary=state.node_state;var info: Dictionary=Catalog.EVENTS[node.event]
	_title.text=("事件结果 · " if node.mode=="result" else "")+str(info.title)
	_inventory.text="生命 %d / %d    ·    金币 %d    ·    声望 %d"%[state.hp,state.max_hp,state.gold,state.renown]
	var scene_path:=preload("res://code/scripts/ui/scene_art.gd").illustration("event",str(node.event),str(info.category))
	if not scene_path.is_empty():
		var focus:float={"purse":0.20,"village":0.16,"merchant":0.24,"wounded":0.06,"exchange":0.08}.get(str(node.event),0.10)
		_banner(scene_path,focus)
	var story:=HBoxContainer.new();story.add_theme_constant_override("separation",16);_panel(_content).add_child(story)
	var icon_path: String=preload("res://code/scripts/ui/scene_art.gd").event_emblem(str(node.event),{"money":"res://art/resources/gold.png","relic":"res://art/relics/legacy_case.png","battle":"res://art/resources/order_warrior.png"}[info.category])
	if node.mode=="result" and not node.data.get("awarded",[]).is_empty():
		var gift: Dictionary=node.data.awarded[0]
		icon_path="res://art/resources/gold.png" if str(gift.id).is_empty() else str(Relics.definition(gift.id).icon)
	_icon(story,icon_path,88)
	var text=_label(story,str(node.outcome) if node.mode=="result" else str(info.story),19);text.size_flags_horizontal=SIZE_EXPAND_FILL
	if node.mode=="result":
		action_buttons["continue"]=_button(_footer,"继续前行","continue","","",true)
	elif node.mode=="exchange":
		_label(_content,"交出「%s」%s，选择一份固定结果："%[Relics.definition(node.source).name,"并支付3金币" if node.higher else ""],20)
		var gifts: Array=node.data.swaps[node.source].higher if node.higher else node.data.swaps[node.source].same
		for gift: Dictionary in gifts:_gift(gift,"swap",node.source,gift.key)
		action_buttons.back=_button(_footer,"返回置换选项","back")
	elif node.event=="exchange":
		_label(_content,"选择一件持有的藏品；确认置换前不会扣除藏品或金币。",17)
		_source_grid=GridContainer.new();_source_grid.columns=3 if size.x>=1400 else 2;_source_grid.add_theme_constant_override("h_separation",14);_source_grid.add_theme_constant_override("v_separation",14);_content.add_child(_source_grid)
		if state.relics.is_empty():_label(_content,"尚未持有可用于置换的藏品。",20)
		for source: String in state.relics:
			var item:=Relics.definition(source);var column:=VBoxContainer.new();column.add_theme_constant_override("separation",10);_panel(_source_grid).add_child(column)
			var top:=HBoxContainer.new();top.add_theme_constant_override("separation",10);column.add_child(top);_icon(top,str(item.icon),52)
			var title=_label(top,"%s\n%d金币档"%[item.name,item.price],19);title.size_flags_horizontal=SIZE_EXPAND_FILL
			var buttons:=HBoxContainer.new();buttons.add_theme_constant_override("separation",8);column.add_child(buttons)
			source_buttons[source]={"same":_button(buttons,"同档置换","same",source),"higher":_button(buttons,"升档 +3金币","higher",source)}
		action_buttons.leave=_button(_footer,"离开","leave")
	else:
		for action: String in info.actions:
			if node.event=="merchant":_gift(node.data.offer8 if action=="buy8" else node.data.offer12,action,"","",str(info.actions[action]));continue
			if node.event=="cache" and action in ["gift0","gift1"]:
				var index:=0 if action=="gift0" else 1
				if index<node.data.offers8.size():_gift(node.data.offers8[index],action)
				continue
			if (node.event=="inscription" and action=="study") or (node.event=="wounded" and action=="heal"):_gift(node.data.offer12,action,"","",str(info.actions[action]));continue
			var details:=""
			if action=="fight":
				var special: Dictionary=Catalog.FIGHTS[node.event]
				var enemy:=Seeds.encounter(str(special.kind),int(preload("res://code/scripts/relics/relic_run.gd").current_node(state).row),int(state.seed),str(state.current_node))
				details="本层敌人：%s\n战败将结束本局远征。"%str(enemy.name)
				if node.data.has("combat_reward"):details+="\n胜利指定奖励："+Events.describe(node.data.combat_reward)
			_action(str(info.actions[action]),details,action)
		action_buttons.leave=_button(_footer,"离开","leave")
	var menu:=Button.new();menu.text="主菜单";menu.custom_minimum_size=Vector2(110,46);menu.pressed.connect(func():menu_requested.emit());_footer.add_child(menu)
func _submit(action: String,source: String,target: String):
	if _submitted or not Events.reason(state,action,source,target).is_empty():return
	_submitted=true
	for button: Button in action_buttons.values():button.disabled=true
	chosen.emit(action,source,target)
## A framed, cover-cropped strip of the event's own painting above the story.
func _banner(path: String, focus_y: float=0.10) -> void:
	var frame:=PanelContainer.new();frame.name="EventIllustration";_banner_frame=frame
	var style:=Paper.box(Paper.DARK,Paper.GOLD);style.set_content_margin_all(4)
	frame.add_theme_stylebox_override("panel",Paper.ornate(style,true,1));_content.add_child(frame)
	var art:=preload("res://code/scripts/ui/location_painting.gd").new();art.texture=load(path)
	# P1 paintings place the story in the upper 40%; avoid cropping it out of a wide banner.
	art.focus_y=focus_y
	frame.add_child(art)
	_layout_banner()

func _layout_banner() -> void:
	if is_instance_valid(_banner_frame):_banner_frame.custom_minimum_size.y=clampf(size.y*0.22,115,230)
