extends Control
const Professions=preload("res://code/scripts/profession_names.gd")
## Read-only inventory and encyclopedia. Selection never grants or spends items.
const Catalog = preload("res://code/scripts/relics/relic_catalog.gd")
const Paper = preload("res://code/scripts/ui/global_theme.gd")
const ItemArt = preload("res://code/scripts/ui/item_artwork.gd")
const Items = preload("res://code/scripts/ui/item_presentation.gd")
var state: Dictionary = {}
var entries: Array = []
var selected_id := ""
var owned_only := true
var summary_label: Label
var owned_button: Button
var all_button: Button
var item_list: ItemList
var empty_label: Label
var detail_frame: PanelContainer
var detail_art: TextureRect
var detail_name: Label
var detail_meta: Label
var ownership_label: Label
var detail_effect: RichTextLabel
func _ready() -> void:
	theme = Paper.make(18)
	var page := VBoxContainer.new()
	page.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	page.add_theme_constant_override("separation",12)
	add_child(page)
	var top := HBoxContainer.new(); top.add_theme_constant_override("separation",10); page.add_child(top)
	summary_label = _label(top,"",22); summary_label.size_flags_horizontal = SIZE_EXPAND_FILL
	owned_button = Button.new(); owned_button.text = "已持有"; owned_button.custom_minimum_size = Vector2(110,42)
	top.add_child(owned_button); owned_button.pressed.connect(show_owned)
	all_button = Button.new(); all_button.text = "全部图鉴"; all_button.custom_minimum_size = Vector2(120,42)
	top.add_child(all_button); all_button.pressed.connect(show_all)
	var main := HBoxContainer.new(); main.add_theme_constant_override("separation",16); main.size_flags_vertical = SIZE_EXPAND_FILL; page.add_child(main)
	var list_area := Control.new(); list_area.size_flags_horizontal = SIZE_EXPAND_FILL; list_area.custom_minimum_size.x = 170; main.add_child(list_area)
	item_list = ItemList.new()
	item_list.texture_filter=TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	item_list.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	item_list.icon_mode = ItemList.ICON_MODE_TOP
	item_list.fixed_icon_size = Vector2i(76,76)
	item_list.max_text_lines = 2
	item_list.allow_reselect = true
	item_list.same_column_width = true
	item_list.add_theme_font_size_override("font_size",17)
	item_list.add_theme_color_override("font_color",Paper.INK)
	item_list.add_theme_color_override("font_selected_color",Paper.INK)
	item_list.add_theme_stylebox_override("panel",Paper.box(Paper.PANEL))
	item_list.add_theme_stylebox_override("selected",Paper.box(Color("e7d7b9"),Paper.GOLD))
	item_list.add_theme_stylebox_override("selected_focus",Paper.box(Color("e7d7b9"),Paper.GOLD))
	list_area.add_child(item_list); item_list.item_selected.connect(_select_index)
	item_list.resized.connect(_layout_grid)
	empty_label = _label(list_area,"本局尚未持有藏品\n可切换全部图鉴查看",20)
	empty_label.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.mouse_filter = MOUSE_FILTER_IGNORE; empty_label.add_theme_color_override("font_color",Paper.MUTED)
	detail_frame = PanelContainer.new(); detail_frame.custom_minimum_size.x = 260; main.add_child(detail_frame)
	var style := Paper.box(Paper.PANEL); style.content_margin_left = 16; style.content_margin_right = 16; style.content_margin_top = 12; style.content_margin_bottom = 10
	detail_frame.add_theme_stylebox_override("panel",style)
	var details := VBoxContainer.new(); details.add_theme_constant_override("separation",8); detail_frame.add_child(details)
	detail_name = _label(details,"藏品详情",26)
	detail_meta = _label(details,"",16); detail_meta.add_theme_color_override("font_color",Paper.MUTED)
	detail_art = ItemArt.new()
	detail_art.custom_minimum_size.y = 140; detail_art.size_flags_vertical = SIZE_EXPAND_FILL; details.add_child(detail_art)
	ownership_label = _label(details,"",17)
	detail_effect = RichTextLabel.new(); detail_effect.bbcode_enabled = false; detail_effect.selection_enabled = true
	detail_effect.add_theme_font_size_override("normal_font_size",18); detail_effect.add_theme_constant_override("line_separation",4)
	detail_effect.custom_minimum_size.y = 104; detail_effect.size_flags_vertical = SIZE_EXPAND_FILL; details.add_child(detail_effect)
	resized.connect(_layout_grid)
	_layout_grid.call_deferred()
func _label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new(); label.text = text; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size); parent.add_child(label); return label
func configure(value: Dictionary) -> void:
	state = value.duplicate(true)
	show_owned()
func show_owned() -> void:
	owned_only = true
	_rebuild()
func show_all() -> void:
	owned_only = false
	_rebuild()
func _rebuild() -> void:
	if item_list == null: return
	var previous := selected_id
	entries.clear(); item_list.clear(); selected_id = ""
	summary_label.text = "已持有 %d / %d" % [Catalog.ids(state).size(),Catalog.ITEMS.size()]
	owned_button.disabled = owned_only; all_button.disabled = not owned_only
	for item: Dictionary in Catalog.ITEMS:
		if owned_only and not Catalog.has(state,str(item.id)): continue
		entries.append(item)
		item_list.add_item("%s\n%d 金币" % [item.name,int(item.price)],Items.texture_for(str(item.icon),76))
		item_list.set_item_tooltip(entries.size()-1,Professions.text("%s · %s\n%s" % [item.name,item.category,item.effect]))
	empty_label.visible = entries.is_empty()
	detail_art.set_art(""); detail_name.text = "藏品详情"; detail_meta.text = ""
	ownership_label.text = ""; detail_effect.text = "选择藏品查看效果。"
	if not entries.is_empty():
		if not select_relic(previous): _select_index(0)
	_layout_grid.call_deferred()
func select_relic(id: String) -> bool:
	for index in range(entries.size()):
		if str(entries[index].id) == id:
			_select_index(index); return true
	return false
func _select_index(index: int) -> void:
	if index < 0 or index >= entries.size(): return
	var item: Dictionary = entries[index]
	selected_id = str(item.id); item_list.select(index)
	detail_name.text = str(item.name)
	detail_meta.text = "%s · %d 金币\n%s" % [item.category,int(item.price),item.route]
	detail_art.set_art(str(item.icon))
	var owned := Catalog.has(state,selected_id)
	ownership_label.text = "已持有 · 本局生效" if owned else "未持有"
	ownership_label.add_theme_color_override("font_color",Paper.GREEN if owned else Paper.MUTED)
	detail_effect.text = Professions.text(str(item.effect)); detail_effect.scroll_to_line(0)
func _layout_grid() -> void:
	if item_list == null or detail_frame == null: return
	detail_frame.custom_minimum_size.x = clampf(size.x*0.34,260,400)
	var columns := clampi(int(item_list.size.x/150.0),1,4)
	item_list.max_columns = columns
	item_list.fixed_column_width = maxi(120,int((item_list.size.x-24)/columns))

