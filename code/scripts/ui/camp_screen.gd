extends Control
const Professions=preload("res://code/scripts/profession_names.gd")
signal chosen(action: String)
signal menu_requested
const Camp=preload("res://code/scripts/run/camp_rules.gd")
const Growth=preload("res://code/scripts/characters/character_growth.gd")
const Relics=preload("res://code/scripts/relics/relic_catalog.gd")
const Paper=preload("res://code/scripts/ui/global_theme.gd")
const ItemPresentation=preload("res://code/scripts/ui/item_presentation.gd")
const ICONS={"renown":"res://art/resources/renown.png","slots":"res://art/resources/slots.png","rest":"res://art/relics/camp_supply.png","upgrade":"res://art/relics/teaching_manual.png","orders":"res://art/resources/order_support.png"}
var option_buttons: Dictionary={}
var option_descriptions:Dictionary={}
var _hint:Label
var _cards: HBoxContainer
var _inventory: Label
var _submitted:=false
var _vista:Control
var _scenery:Control
func label(parent: Node,text: String,size: int) -> Label:
	var node:=Label.new();node.text=text;node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	node.custom_minimum_size.x=1;node.add_theme_font_size_override("font_size",size);parent.add_child(node)
	return node
func _ready():
	theme=Paper.make(17)
	var scenery:=preload("res://code/scripts/ui/location_painting.gd").new();scenery.name="CampScenery"
	var camp_art:=preload("res://code/scripts/ui/scene_art.gd").illustration("camp")
	scenery.texture=load(camp_art if not camp_art.is_empty() else "res://art/locations/camp.png")
	scenery.focus_y=0.0 if not camp_art.is_empty() else 0.8
	scenery.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	scenery.mouse_filter=MOUSE_FILTER_IGNORE;add_child(scenery);_scenery=scenery
	var veil:=TextureRect.new()
	var shade:=GradientTexture2D.new();var gradient:=Gradient.new()
	gradient.offsets=PackedFloat32Array([0.0,0.28,0.5,1.0])
	gradient.colors=PackedColorArray([Color(0.07,0.09,0.1,0.86),Color(0.07,0.09,0.1,0.18),Color(0.07,0.09,0.1,0.38),Color(0.07,0.09,0.1,0.84)])
	shade.gradient=gradient;shade.fill_from=Vector2.ZERO;shade.fill_to=Vector2.DOWN
	veil.texture=shade;veil.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	veil.mouse_filter=MOUSE_FILTER_IGNORE;add_child(veil)
	var page:=VBoxContainer.new();page.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	page.offset_left=16;page.offset_right=-16;page.offset_top=12;page.offset_bottom=-12
	page.add_theme_constant_override("separation",10);add_child(page)
	var topbar:=HBoxContainer.new();page.add_child(topbar)
	var title:=label(topbar,"营地休整",32);title.size_flags_horizontal=SIZE_EXPAND_FILL;title.add_theme_font_override("font",Paper.title_font())
	title.add_theme_color_override("font_color",Color("f0e6d3"))
	var menu:=Button.new();menu.text="主菜单";menu.custom_minimum_size=Vector2(120,44)
	menu.pressed.connect(func():menu_requested.emit());topbar.add_child(menu)
	_inventory=label(page,"",18)
	_inventory.add_theme_color_override("font_color",Color("f0e6d3"))
	_vista=Control.new();_vista.mouse_filter=MOUSE_FILTER_IGNORE;_vista.size_flags_vertical=SIZE_EXPAND_FILL;page.add_child(_vista)
	_hint=label(page,"本次提供三项机缘，请选择其中一项。选择后结束本次营地休整。",18)
	_hint.add_theme_color_override("font_color",Color("f0e6d3"))
	_hint.add_theme_color_override("font_shadow_color",Color(0.04,0.05,0.06,0.95))
	_hint.add_theme_constant_override("shadow_offset_x",1)
	_hint.add_theme_constant_override("shadow_offset_y",2)
	_hint.add_theme_constant_override("shadow_outline_size",2)
	_cards=HBoxContainer.new();_cards.add_theme_constant_override("separation",16)
	_cards.size_flags_vertical=SIZE_FILL;page.add_child(_cards)
	resized.connect(_layout_scene);_layout_scene.call_deferred()
func _layout_scene()->void:
	if _vista==null:return
	_vista.custom_minimum_size.y=30
	_cards.custom_minimum_size.y=clampf(size.y*0.53,330,400)
	# The landscape ends behind the cards, placing fire and tent in the visible band.
	_scenery.offset_bottom=-_cards.custom_minimum_size.y+60
func configure(state: Dictionary):
	_submitted=false
	for card in _cards.get_children():
		_cards.remove_child(card);card.queue_free()
	option_buttons.clear();option_descriptions.clear()
	var count:int=state.node_state.camp_options.size()
	_hint.text="本次提供三项机缘，请选择其中一项。选择后结束本次营地休整。" if count==3 else "本次有 %d 项可用机缘，请选择其中一项。选择后结束本次营地休整。"%count
	_inventory.text="生命 %d / %d    ·    声望 %d    ·    卡槽 %d / 8"%[state.hp,state.max_hp,state.renown,state.slot_capacity]
	for action: String in state.node_state.camp_options:
		var panel:=PanelContainer.new();panel.size_flags_horizontal=SIZE_EXPAND_FILL
		var style:=Paper.box(Paper.PANEL);style.content_margin_left=16;style.content_margin_right=16
		style.content_margin_top=12;style.content_margin_bottom=12
		panel.add_theme_stylebox_override("panel",Paper.ornate(style,false,1));_cards.add_child(panel)
		var column:=VBoxContainer.new();column.add_theme_constant_override("separation",8);panel.add_child(column)
		var icon:=TextureRect.new();icon.custom_minimum_size=Vector2(60,60)
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var details: String=_details(state,action)
		var path: String=ICONS.get(action,"")
		if action=="relic":
			var relic:=Relics.definition(state.node_state.camp_relic)
			path=str(relic.icon);details="「%s」\n%s"%[relic.name,relic.effect]
		icon.texture=ItemPresentation.texture_for(path,60);column.add_child(icon)
		var title=label(column,Camp.TITLES[action],23);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var description_scroll:=ScrollContainer.new();description_scroll.custom_minimum_size=Vector2(1,66)
		description_scroll.size_flags_vertical=SIZE_EXPAND_FILL
		description_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(description_scroll)
		var description=label(description_scroll,Professions.text(details),17);description.size_flags_horizontal=SIZE_EXPAND_FILL
		description.add_theme_color_override("font_color",Paper.MUTED)
		option_descriptions[action]=description
		var pick:=Button.new();pick.text="选择此项";pick.custom_minimum_size.y=48
		Paper.primary(pick);column.add_child(pick);option_buttons[action]=pick
		pick.pressed.connect(_choose.bind(action))
func _choose(action: String):
	if _submitted:return
	_submitted=true
	for button: Button in option_buttons.values():button.disabled=true
	chosen.emit(action)

func _details(state:Dictionary,action:String)->String:
	if action=="upgrade":
		var candidates:Array=Camp.upgrade_candidates(state)
		var minimum:=2
		var maximum:=0
		for id:String in candidates:
			var cost:int=Growth.upgrade_cost(id)
			minimum=mini(minimum,cost);maximum=maxi(maximum,cost)
		var savings:String=str(minimum) if minimum==maximum else "%d—%d"%[minimum,maximum]
		return "可选 %d 人，从中强化 1 人。\n按常规强化费用，可节省 %s 声望（取决于所选角色）。\n\n攻击与血量 +20%%，不消耗声望或召集令。已强化角色不可重复选择。"%[candidates.size(),savings]
	if action=="orders":
		var lines:Array[String]=["已确定的召集令，按此顺序使用："]
		for i in range(state.node_state.camp_orders.size()):
			lines.append("%d. %s召集令"%[i+1,Professions.label(str(state.node_state.camp_orders[i]))])
		lines.append("\n选择后依次招募、强化或跳过；费用沿用现有规则，不可留存。")
		return "\n".join(lines)
	if action=="rest":return "恢复 %d 生命，使前台共享生命回满。"%maxi(0,int(state.max_hp)-int(state.hp))
	return Camp.DETAILS[action]
