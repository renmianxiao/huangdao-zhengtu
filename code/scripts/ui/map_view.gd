extends Control
const Paper=preload("res://code/scripts/ui/global_theme.gd")
var silk:Texture2D
var scenery:Texture2D
const Map = preload("res://code/scripts/run/map_generator.gd")
const Run = preload("res://code/scripts/run/run_rules.gd")
const Catalog = preload("res://code/scripts/run/run_catalog.gd")
const Progress = preload("res://code/scripts/run/progression.gd")
signal entered(id: String)
signal formation_requested
signal menu_requested
signal relic_requested
const INK = Color("493f31")
const GOLD = Color("b59b69")
const PAPER = Color("f4eddf")
const TIMES = ["上午", "正午", "下午", "傍晚", "夜晚"]
const NUMBERS = ["一", "二", "三", "四", "五"]
const SYMBOLS = {"battle":"剑", "elite":"锋", "event":"？", "shop":"店", "camp":"火", "midboss":"将", "boss":"魁"}
var state: Dictionary
var shown_floor: int
var available: Array[String]
var node_buttons: Dictionary = {}
var selected_id := ""
var enter_button: Button
var info_title: Label
var info_text: Label
var grid: Control
var title: Label
var sidebar: Control
var positions: Dictionary = {}
var relic_button: Button

func setup(value: Dictionary) -> void:
	state = value
	shown_floor = Run.map_floor(state)
	available = Map.reachable(state.map,state.current_node)

func _ready() -> void:
	var skin := Theme.new()
	var font := Paper.body_font()
	skin.default_font = font
	skin.default_font_size = 23
	skin.set_color("font_color","Label",INK)
	skin.set_color("font_color","Button",INK)
	for state in ["font_hover_color","font_hover_pressed_color"]:skin.set_color(state,"Button",Color("792b24"))
	for name in ["normal","hover","pressed","disabled","focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("e9dcc3") if name in ["hover","pressed"] else PAPER
		box.border_color = GOLD
		box.set_border_width_all(1)
		box.set_corner_radius_all(3)
		box.content_margin_left = 10; box.content_margin_right = 10
		skin.set_stylebox(name,"Button",box)
	theme = skin
	silk=load("res://art/ui/materials/light_silk.png")
	scenery=load("res://art/cinematics/floor_%d.png" % clampi(shown_floor,1,5))
	title = _label(self,"第%s层 · %s" % [NUMBERS[shown_floor-1],TIMES[shown_floor-1]],30)
	title.add_theme_font_override("font",Paper.title_font())
	title.add_theme_color_override("font_color",Paper.DARK_TEXT)
	grid = Control.new()
	add_child(grid)
	for node: Dictionary in state.map.nodes:
		if node.floor != shown_floor: continue
		var b := preload("res://code/scripts/ui/map_seal.gd").new()
		b.kind = node.type
		b.caption = Catalog.NODE_NAMES[node.type]
		b.text = SYMBOLS[node.type] + "\n" + Catalog.NODE_NAMES[node.type]
		b.add_theme_font_size_override("font_size",18)
		b.disabled = not available.has(node.id)
		b.tooltip_text = Catalog.NODE_NAMES[node.type] + (" · 已完成" if state.completed.has(node.id) else "")
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.pressed.connect(select_node.bind(node.id))
		grid.add_child(b)
		node_buttons[node.id] = b
	sidebar = preload("res://code/scripts/ui/map_sidebar.gd").new()
	sidebar.setup(state,shown_floor)
	add_child(sidebar)
	info_title=sidebar.info_title
	info_text=sidebar.info_text
	enter_button=sidebar.enter_button
	enter_button.pressed.connect(func():
		if available.has(selected_id): entered.emit(selected_id)
	)
	var legend := HBoxContainer.new(); legend.name = "Legend"; legend.add_theme_constant_override("separation",8); add_child(legend)
	for key in ["battle","elite","event","shop","camp"]:
		var icon:=preload("res://code/scripts/ui/map_footer_icon.gd").new()
		icon.kind=key; icon.caption=Catalog.NODE_NAMES[key]
		icon.custom_minimum_size=Vector2(133 if key in ["battle","elite","event"] else 106,50)
		legend.add_child(icon)
	var actions := HBoxContainer.new(); actions.name = "Actions"; add_child(actions)
	relic_button = Button.new()
	relic_button.text = "藏品 %d" % state.get("relics",[]).size()
	relic_button.custom_minimum_size = Vector2(112,44)
	relic_button.pressed.connect(func(): relic_requested.emit())
	actions.add_child(relic_button)
	for item in [["队伍",formation_requested],["菜单",menu_requested]]:
		var b:=preload("res://code/scripts/ui/map_footer_icon.gd").new(); b.kind="team" if item[0]=="队伍" else "menu"; b.caption=item[0]; b.is_action=true; b.custom_minimum_size=Vector2(124,50); actions.add_child(b); b.pressed.connect(func(): item[1].emit())
	resized.connect(_layout)
	_layout()
	if not available.is_empty(): select_node(available[0])

func _label(parent: Node, text_value: String, font_size: int) -> Label:
	var l := Label.new(); l.text=text_value; l.add_theme_font_size_override("font_size",font_size); parent.add_child(l); return l

func select_node(id: String) -> void:
	if not available.has(id): return
	selected_id = id
	for node: Dictionary in state.map.nodes:
		if node.id != id: continue
		sidebar.set_node(node.type)
		info_text.text = {"battle":"江湖路险，迎战拦路之敌。胜利后获得经验、金币与一次召集机会。","elite":"强敌坐镇。胜利可获得更丰厚的战斗奖励。","event":"偶遇江湖异事：金币交易、珍藏机缘或特殊战斗，进入后选择如何应对。","shop":"拜访行商，使用金币购买补给与强化。","camp":"六种营地奖励随机提供三项，从中任选一项。","midboss":"道中强敌拦路，击败后继续远征。","boss":"最终决战，击败强敌完成本局远征。"}.get(node.type,"")
	enter_button.disabled = false
	queue_redraw()
	_style_nodes()

func _style_nodes() -> void:
	for node: Dictionary in state.map.nodes:
		if not node_buttons.has(node.id): continue
		var b = node_buttons[node.id]
		b.selected = node.id == selected_id
		b.visited = state.completed.has(node.id)
		for mode in ["normal", "hover", "pressed", "disabled", "focus"]:
			b.add_theme_stylebox_override(mode,StyleBoxEmpty.new())
		for mode in ["font_color", "font_disabled_color", "font_hover_color", "font_hover_pressed_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(mode,Color.TRANSPARENT)
		b.queue_redraw()

func _layout() -> void:
	var right_width := clampf(size.x * 0.24,225,460)
	var split := size.x-right_width-20
	title.position=Vector2(32,12); title.size=Vector2(split-50,42)
	grid.position=Vector2(30,112); grid.size=Vector2(split-65,size.y-238)
	sidebar.position=Vector2(split+7,65); sidebar.size=Vector2(right_width-6,size.y-136)
	var legend: HBoxContainer = get_node("Legend")
	var actions: HBoxContainer = get_node("Actions")
	_fit_footer(legend, Vector2(20,size.y-45), maxf(1,split-40), false)
	_fit_footer(actions, Vector2(size.x-20,size.y-45), maxf(1,right_width-20), true)
	positions.clear()
	for node: Dictionary in state.map.nodes:
		if not node_buttons.has(node.id): continue
		var center := Vector2(grid.size.x*(0.20+node.column*0.30),grid.size.y*(1.0-float(node.floor_row-1)/5.0))
		positions[node.id]=grid.position+center
		var b: Button=node_buttons[node.id]
		b.position=center-Vector2(42,42); b.size=Vector2(84,84)
	_style_nodes()
	queue_redraw()

func _fit_footer(row: HBoxContainer, anchor: Vector2, available_width: float, from_right: bool) -> void:
	var minimum := row.get_combined_minimum_size()
	row.size = minimum
	var factor := minf(1.0, available_width / maxf(1.0,minimum.x))
	row.scale = Vector2.ONE * factor
	row.position = Vector2(anchor.x - minimum.x * factor if from_right else anchor.x, anchor.y - minimum.y * factor / 2.0)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Paper.PAPER)
	if scenery!=null: preload("res://code/scripts/ui/paper_backdrop.gd").draw_scene_wash(self,scenery,Rect2(Vector2.ZERO,size),Paper.PAPER,0.75)
	if silk!=null:draw_texture_rect(silk,Rect2(Vector2.ZERO,size),false,Color(1,1,1,0.24))
	var split := sidebar.position.x-18 if sidebar != null else size.x*0.72
	draw_rect(Rect2(0,0,size.x,64),Paper.DARK)
	draw_rect(Rect2(split,64,size.x-split,size.y-64),Paper.DARK)
	draw_rect(Rect2(0,size.y-66,size.x,66),Paper.DARK)
	var accent:Color=Paper.floor_palette(shown_floor).accent
	draw_rect(Rect2(0,61,size.x,3),accent)
	draw_line(Vector2(0,64),Vector2(size.x,64),Paper.OLD_GOLD,1)
	draw_rect(Rect2(split,64,3,size.y-130),Color(accent,0.8))
	draw_line(Vector2(split,64),Vector2(split,size.y-66),GOLD,1)
	draw_line(Vector2(10,size.y-66),Vector2(size.x-10,size.y-66),GOLD,1)
	for node: Dictionary in state.get("map",{}).get("nodes",[]):
		if not positions.has(node.id): continue
		for target: String in node.next:
			if not positions.has(target): continue
			var from: Vector2=positions[node.id]; var to: Vector2=positions[target]
			var direction := (to-from).normalized()
			var color := Color("ba985d") if state.completed.has(node.id) and (state.completed.has(target) or available.has(target)) else Color("9b907d")
			draw_dashed_line(from+direction*36,to-direction*36,color,1.5,6,true)







