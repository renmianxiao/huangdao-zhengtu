extends Control
const ShortEffects=preload("res://code/scripts/ui/relic_short_effects.gd")
var effect_labels:Array[Label]=[]
const Professions=preload("res://code/scripts/profession_names.gd")
signal relic_bought(index: int, id: String)
signal service_bought(id: String)
signal left
signal relic_view_requested
signal menu_requested
const Catalog = preload("res://code/scripts/relics/relic_catalog.gd")
const Shop = preload("res://code/scripts/relics/relic_shop.gd")
const Resources = preload("res://code/scripts/relics/relic_run.gd")
const Upgrades = preload("res://code/scripts/run/run_catalog.gd")
const Paper = preload("res://code/scripts/ui/global_theme.gd")
const ItemArt = preload("res://code/scripts/ui/item_artwork.gd")
var state: Dictionary
var stock_grid: GridContainer
var service_panel: PanelContainer
var card_buttons: Array[Button] = []
var buy_buttons: Array[Button] = []
var service_buttons: Dictionary = {}
var detail_label: RichTextLabel
var leave_button: Button
var title: Label
var gold_label: Label
var selected_index := -1
var _scenery_frame: PanelContainer
var price_labels:Array[Label]=[]
var _item_art:Array[Control]=[]

func _ready() -> void:
	theme = Paper.make(17)
	var page := VBoxContainer.new(); page.set_anchors_and_offsets_preset(PRESET_FULL_RECT); page.add_theme_constant_override("separation",10); add_child(page)
	var top := HBoxContainer.new(); page.add_child(top)
	title = _label(top,"江湖行商",24); title.size_flags_horizontal = SIZE_EXPAND_FILL
	title.add_theme_font_override("font",Paper.title_font())
	gold_label = _label(top,"",20)
	gold_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	gold_label.custom_minimum_size.x = 120
	gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	for caption in ["藏品","菜单"]:
		var action := Button.new(); action.text = caption; action.custom_minimum_size = Vector2(76,40); top.add_child(action)
		action.size_flags_vertical = SIZE_SHRINK_CENTER
		if caption == "藏品": action.pressed.connect(func(): relic_view_requested.emit())
		else: action.pressed.connect(func(): menu_requested.emit())
	var shop_art:=preload("res://code/scripts/ui/scene_art.gd").illustration("shop")
	if not shop_art.is_empty():
		_scenery_frame=PanelContainer.new();_scenery_frame.name="ShopIllustration";page.add_child(_scenery_frame)
		var frame_style:=Paper.box(Paper.DARK,Paper.GOLD);frame_style.set_content_margin_all(3)
		_scenery_frame.add_theme_stylebox_override("panel",Paper.ornate(frame_style,true,1))
		var scenery:=preload("res://code/scripts/ui/location_painting.gd").new();scenery.name="ShopScenery"
		scenery.texture=load(shop_art);scenery.focus_y=0.16;_scenery_frame.add_child(scenery)
	var main := HBoxContainer.new(); main.size_flags_vertical = SIZE_EXPAND_FILL; main.add_theme_constant_override("separation",14); page.add_child(main)
	stock_grid = GridContainer.new(); stock_grid.columns = 4; stock_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	stock_grid.add_theme_constant_override("h_separation",8); stock_grid.add_theme_constant_override("v_separation",8); main.add_child(stock_grid)
	service_panel = PanelContainer.new(); service_panel.custom_minimum_size.x = 210; main.add_child(service_panel)
	service_panel.theme=Paper.make_dark(18)
	service_panel.add_theme_stylebox_override("panel",Paper.ornate(Paper.panel_style(true),true))
	var services := VBoxContainer.new(); services.add_theme_constant_override("separation",10); service_panel.add_child(services)
	_label(services,"独立服务",21)
	for key in ["heal","refresh"]:
		var button := Button.new(); button.custom_minimum_size = Vector2(0,58); button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		services.add_child(button); service_buttons[key] = button
		button.pressed.connect(_service_pressed.bind(key))
	var spacer := Control.new(); spacer.size_flags_vertical = SIZE_EXPAND_FILL; services.add_child(spacer)
	var footer := HBoxContainer.new(); footer.add_theme_constant_override("separation",14); page.add_child(footer)
	detail_label = RichTextLabel.new(); detail_label.bbcode_enabled = false; detail_label.selection_enabled = true
	detail_label.size_flags_horizontal = SIZE_EXPAND_FILL; detail_label.custom_minimum_size = Vector2(1,78)
	detail_label.add_theme_font_size_override("normal_font_size",16); footer.add_child(detail_label)
	leave_button = Button.new(); leave_button.text = "离开商店"; leave_button.custom_minimum_size = Vector2(150,48)
	leave_button.size_flags_vertical = SIZE_SHRINK_CENTER; leave_button.pressed.connect(func(): left.emit()); footer.add_child(leave_button)
	Paper.primary(leave_button)
	resized.connect(_layout)
	_layout.call_deferred()

func _service_pressed(key: String) -> void:
	var button: Button = service_buttons[key]
	if button.disabled: return
	button.disabled = true
	service_bought.emit(key)

func _label(parent: Node, value: String, font_size: int) -> Label:
	var label := Label.new(); label.text = value; label.add_theme_font_size_override("font_size",font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; parent.add_child(label); return label

func configure(value: Dictionary) -> void:
	state = value.duplicate(true)
	gold_label.text = "金币 %d" % int(state.gold)
	for child in stock_grid.get_children():stock_grid.remove_child(child);child.queue_free()
	card_buttons.clear();buy_buttons.clear();effect_labels.clear();price_labels.clear();_item_art.clear()
	for i in range(8):_card(i)
	var heal:Button=service_buttons.heal
	heal.text="恢复50%最大生命\n"+("已购买" if state.node_state.bought.has("heal") else "16 金币")
	heal.disabled=state.node_state.bought.has("heal") or state.gold<16 or state.hp>=state.max_hp
	heal.tooltip_text="每个商店限购一次，满生命时无需购买。"
	var refresh_button:Button=service_buttons.refresh
	var reason:=Shop.refresh_reason(state)
	refresh_button.text="刷新商店\n"+("次数已用尽" if state.node_state.shop_refreshes>=4 else ("首次免费" if Shop.refresh_price(state)==0 else "%d 金币"%Shop.refresh_price(state)))
	refresh_button.disabled=not reason.is_empty()
	refresh_button.tooltip_text=reason if not reason.is_empty() else "重抽全部8栏；每店最多4次：免费、4、8、12金币。"
	select_slot(0)
	_layout.call_deferred()

func _card(index: int) -> void:
	var slot: Dictionary = state.node_state.relic_stock[index]
	var card := Button.new(); card.custom_minimum_size = Vector2(112,126)
	card.size_flags_horizontal = SIZE_EXPAND_FILL; card.size_flags_vertical = SIZE_EXPAND_FILL
	card.pressed.connect(select_slot.bind(index)); stock_grid.add_child(card); card_buttons.append(card)
	var column := VBoxContainer.new(); column.mouse_filter = MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	column.offset_left = 7; column.offset_right = -7; column.offset_top = 6; column.offset_bottom = -6
	column.add_theme_constant_override("separation",3); card.add_child(column)
	var definition := Catalog.definition(str(slot.id))
	var heading := _label(column,"售罄" if definition.is_empty() else str(definition.name),18)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; heading.mouse_filter = MOUSE_FILTER_IGNORE
	var holder:=CenterContainer.new();holder.size_flags_vertical=SIZE_EXPAND_FILL;holder.mouse_filter=MOUSE_FILTER_IGNORE;column.add_child(holder)
	var art := ItemArt.new()
	art.custom_minimum_size=Vector2(56,56); holder.add_child(art);_item_art.append(art)
	if not definition.is_empty(): art.set_art(str(definition.icon))
	else:art.show_sold()
	var effect:=_label(column,"已售罄" if definition.is_empty() else ShortEffects.text(str(slot.id)),14)
	effect.autowrap_mode=TextServer.AUTOWRAP_OFF;effect.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;effect.clip_text=true
	effect.custom_minimum_size.x=1;effect.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;effect.mouse_filter=MOUSE_FILTER_IGNORE
	effect.add_theme_color_override("font_color",Paper.INK);effect_labels.append(effect)
	var price := Resources.shop_price(state,int(slot.price))
	var price_text := "—" if definition.is_empty() else ("%d 金币" % price + ("  原价%d" % int(slot.price) if price != int(slot.price) else ""))
	var cost := _label(column,price_text,16); cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; cost.mouse_filter = MOUSE_FILTER_IGNORE
	price_labels.append(cost)
	var buy := Button.new(); buy.text = "售罄" if definition.is_empty() else "购买"
	buy.custom_minimum_size.y=30
	var reason := Shop.purchase_reason(state,index,str(slot.id))
	buy.disabled = not reason.is_empty(); buy.tooltip_text = reason
	buy.pressed.connect(func(): relic_bought.emit(index,str(slot.id)))
	column.add_child(buy); buy_buttons.append(buy)
	if not definition.is_empty(): card.tooltip_text = Professions.text("%s · 原价%d金币\n%s" % [definition.name,int(slot.price),definition.effect])

func select_slot(index: int) -> void:
	if index < 0 or index >= 8: return
	selected_index = index
	for i in range(card_buttons.size()):
		for mode:String in ["normal","hover","pressed"]:
			var fill:=Paper.PANEL if mode=="normal" else Color("e6d6b6")
			var style:=Paper.box(fill,Paper.RED if i==index else Paper.BORDER)
			style.set_border_width_all(2 if i==index else 1)
			card_buttons[i].add_theme_stylebox_override(mode,Paper.ornate(style,false,1 if i==index else 0))
	var slot: Dictionary = state.node_state.relic_stock[index]
	var item := Catalog.definition(str(slot.id))
	detail_label.text = "此栏已售罄，手动刷新后重新进货。" if item.is_empty() else Professions.text("%s · %s\n%s" % [item.name,item.category,item.effect])

func _layout() -> void:
	if service_panel == null: return
	service_panel.custom_minimum_size.x = clampf(size.x*0.23,210,270)
	var card_height:=0.0
	for i in range(card_buttons.size()):
		var side:=84.0 if size.y>=800 else 56.0
		_item_art[i].custom_minimum_size=Vector2(side,side)
		card_buttons[i].custom_minimum_size.y=card_buttons[i].get_child(0).get_combined_minimum_size().y+12
		card_height=maxf(card_height,card_buttons[i].custom_minimum_size.y)
	if _scenery_frame!=null:
		var available:=size.y-(card_height*2+8+40+78+30)
		_scenery_frame.custom_minimum_size.y=clampf(available,0,160)
		_scenery_frame.visible=available>=40


