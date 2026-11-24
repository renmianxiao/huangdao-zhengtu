extends Control
const Professions=preload("res://code/scripts/profession_names.gd")
## Direct rewards support a single batch command; orders remain individual.
signal claimed(id: String)
signal direct_claimed
signal left

const Paper = preload("res://code/scripts/ui/global_theme.gd")
const Relics = preload("res://code/scripts/relics/relic_catalog.gd")
const ItemArt = preload("res://code/scripts/ui/item_artwork.gd")
const ORDER_ART := {"刺客型":"assassin", "战士型":"warrior", "盾牌型":"guardian", "奶妈型":"healer", "法师型":"mage", "辅助型":"support"}

var state: Dictionary = {}
var card_buttons: Dictionary = {}
var card_icons: Dictionary = {}
var card_scroll: ScrollContainer
var card_grid: GridContainer
var progression_summary: Label
var footer: HBoxContainer
var leave_button: Button
var claim_all_button:Button
var _title: Label
var _inventory: Label
var _remaining: Label
var _submitted: Dictionary = {}
var _leaving := false

func _ready() -> void:
	theme = Paper.make(17)
	var page := VBoxContainer.new()
	page.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	page.add_theme_constant_override("separation",16)
	add_child(page)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation",24)
	page.add_child(heading)
	_title = _label(heading,"战利品",32)
	_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title.size_flags_horizontal = SIZE_EXPAND_FILL
	_inventory = _label(heading,"",17)
	_inventory.autowrap_mode = TextServer.AUTOWRAP_OFF
	_inventory.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_inventory.size_flags_vertical = SIZE_SHRINK_CENTER
	var hint := _label(page,"可逐项领取或批量领取直接奖励；召集令需单独使用。",17)
	hint.add_theme_color_override("font_color",Paper.MUTED)
	var progression := PanelContainer.new()
	var bar_style := Paper.box(Color("eae2d1"),Color.TRANSPARENT)
	bar_style.content_margin_left = 16; bar_style.content_margin_right = 16
	bar_style.content_margin_top = 9; bar_style.content_margin_bottom = 9
	progression.add_theme_stylebox_override("panel",bar_style)
	page.add_child(progression)
	progression_summary = _label(progression,"",16)
	progression_summary.add_theme_color_override("font_color",Paper.GOLD)
	card_scroll = ScrollContainer.new()
	card_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card_scroll.follow_focus = true
	page.add_child(card_scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = SIZE_EXPAND_FILL
	center.size_flags_vertical = SIZE_EXPAND_FILL
	card_scroll.add_child(center)
	card_grid = GridContainer.new()
	card_grid.columns = 3
	card_grid.add_theme_constant_override("h_separation",20)
	card_grid.add_theme_constant_override("v_separation",20)
	center.add_child(card_grid)
	footer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation",14)
	page.add_child(footer)
	claim_all_button=Button.new();claim_all_button.text="领取全部直接奖励"
	claim_all_button.custom_minimum_size=Vector2(230,52)
	claim_all_button.tooltip_text="领取金币、声望、卡槽和藏品；召集令仍需单独使用。"
	claim_all_button.pressed.connect(_claim_all);footer.add_child(claim_all_button)
	leave_button = Button.new()
	leave_button.custom_minimum_size = Vector2(210,52)
	leave_button.pressed.connect(leave)
	Paper.primary(leave_button)
	footer.add_child(leave_button)
	resized.connect(_layout)
	card_scroll.resized.connect(_layout)
	if not state.is_empty(): configure(state)

func _label(parent: Node, value: String, font_size: int) -> Label:
	var caption := Label.new()
	caption.text = value
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_size_override("font_size",font_size)
	parent.add_child(caption)
	return caption

func configure(run: Dictionary) -> void:
	state = run.duplicate(true)
	if not is_node_ready(): return
	_submitted.clear()
	_leaving = false
	for child in card_grid.get_children():
		card_grid.remove_child(child)
		child.queue_free()
	card_buttons.clear()
	card_icons.clear()
	_title.text = "最终战利品" if state.get("phase","") == "won" else "战利品"
	_inventory.text = "金币 %d　 声望 %d　 队伍槽 %d" % [int(state.get("gold",0)),int(state.get("renown",0)),int(state.get("slot_capacity",3))]
	var gain: Dictionary = state.get("last_progression",{})
	var parts: Array[String] = ["经验 +%d" % int(gain.get("experience",0))]
	if int(gain.get("to_level",1)) > int(gain.get("from_level",1)):
		parts.append("等级 %d → %d" % [int(gain.from_level),int(gain.to_level)])
	progression_summary.text = "自动结算完成　 " + "　·　".join(parts)
	var pending := 0
	for entry: Dictionary in state.get("pending_loot",[]):
		_add_card(entry)
		if not entry.get("claimed",false): pending += 1
	claim_all_button.disabled=true
	for item:Dictionary in state.get("pending_loot",[]):
		if not item.get("claimed",false) and item.get("kind","") in ["gold","renown","slots","relic"]:claim_all_button.disabled=false
	leave_button.disabled = false
	leave_button.text = "放弃剩余并离开" if pending > 0 else "继续"
	leave_button.tooltip_text = "未领取的战利品将被放弃。" if pending > 0 else ("查看远征结果。" if state.get("phase","") == "won" else "返回地图，继续探索。")
	_layout.call_deferred()

func _add_card(entry: Dictionary) -> void:
	var id := str(entry.get("id",""))
	var info := _reward_info(entry)
	var collected := bool(entry.get("claimed",false))
	var card := Button.new()
	card.name = "Loot_" + id.replace(":","_")
	card.tooltip_text = "%s ×%d\n%s" % [info.title,int(entry.get("amount",1)),info.description]
	card.disabled = collected
	card.add_theme_stylebox_override("normal",_card_style(Paper.PANEL,Paper.BORDER))
	card.add_theme_stylebox_override("hover",_card_style(Color("eee1c7"),Paper.GOLD))
	card.add_theme_stylebox_override("pressed",_card_style(Color("e4d3b3"),Paper.GOLD))
	card.add_theme_stylebox_override("disabled",_card_style(Color("eee6d8"),Paper.BORDER))
	card.pressed.connect(_claim.bind(id))
	card_grid.add_child(card)
	card_buttons[id] = card
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.mouse_filter = MOUSE_FILTER_IGNORE
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,16)
	card.add_child(margin)
	var content := VBoxContainer.new()
	content.mouse_filter = MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation",8)
	margin.add_child(content)
	var icon := ItemArt.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = MOUSE_FILTER_IGNORE
	icon.size_flags_vertical = SIZE_EXPAND_FILL
	var path := str(info.icon)
	icon.set_art(path)
	if collected:icon.self_modulate=Color(0.80,0.78,0.73,0.68)
	content.add_child(icon)
	card_icons[id] = icon
	var name_row := HBoxContainer.new()
	name_row.custom_minimum_size.y=32
	name_row.mouse_filter = MOUSE_FILTER_IGNORE
	content.add_child(name_row)
	var title := _label(name_row,str(info.title),21)
	title.mouse_filter = MOUSE_FILTER_IGNORE
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	var amount := _label(name_row,"×%d" % int(entry.get("amount",1)),23)
	amount.autowrap_mode = TextServer.AUTOWRAP_OFF
	amount.mouse_filter = MOUSE_FILTER_IGNORE
	amount.add_theme_color_override("font_color",Paper.GOLD)
	var description := _label(content,str(info.description),15)
	# Reserve the same three-line measure so names and actions share a baseline.
	description.custom_minimum_size.y=66
	description.mouse_filter = MOUSE_FILTER_IGNORE
	description.max_lines_visible = 3
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	description.add_theme_color_override("font_color",Paper.MUTED)
	var action := _label(content,"✓ 已领取" if collected else ("使用召集令 →" if entry.get("kind","") == "order" else "领取 →"),16)
	action.mouse_filter = MOUSE_FILTER_IGNORE
	action.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	action.add_theme_color_override("font_color",Paper.GREEN if collected else Paper.HOVER)

func _card_style(fill: Color, border: Color) -> StyleBox:
	var style := Paper.box(fill,border)
	style.set_content_margin_all(0)
	return Paper.ornate(style)

func _reward_info(entry: Dictionary) -> Dictionary:
	var kind := str(entry.get("kind",""))
	match kind:
		"gold": return {"title":"金币", "description":"在商店购买藏品与补给。", "icon":"res://art/resources/gold.png"}
		"renown": return {"title":"声望", "description":"用于招募角色，或强化已拥有的角色。", "icon":"res://art/resources/renown.png"}
		"slots": return {"title":"队伍扩容", "description":"增加队伍可用卡槽，前台最多四人。", "icon":"res://art/resources/slots.png"}
		"order":
			var profession := str(entry.get("ref",""))
			return {"title":Professions.label(profession)+"召集令", "description":"立即招募或强化一名同职业角色；仅本次战后有效。", "icon":"res://art/resources/order_%s.png" % ORDER_ART.get(profession,"")}
		"relic":
			var relic := Relics.definition(str(entry.get("ref","")))
			return {"title":str(relic.get("name","藏品")), "description":Professions.text(str(relic.get("effect",""))), "icon":str(relic.get("icon",""))}
	return {"title":"战利品", "description":"点击领取。", "icon":""}

func _layout() -> void:
	if card_grid == null or card_scroll == null: return
	var width := maxf(1,card_scroll.size.x-20)
	card_grid.columns = mini(maxi(1,card_buttons.size()),5 if width >= 1500 else (4 if width >= 1150 else (3 if width >= 740 else 2)))
	if card_buttons.size() == 6 and width >= 1150: card_grid.columns = 3
	var card_width := floorf((width-20*(card_grid.columns-1))/card_grid.columns)
	var icon_size := clampf(size.y*0.15,96,176)
	for id: String in card_buttons:
		card_buttons[id].custom_minimum_size = Vector2(card_width,icon_size+184)
		card_icons[id].custom_minimum_size = Vector2(icon_size,icon_size)

func _claim(id: String) -> void:
	if _leaving or _submitted.has(id): return
	for entry: Dictionary in state.get("pending_loot",[]):
		if str(entry.get("id","")) != id: continue
		if entry.get("claimed",false): return
		_submitted[id] = true
		card_buttons[id].disabled = true
		claimed.emit(id)
		return

func leave() -> void:
	if _leaving: return
	_leaving = true
	leave_button.disabled = true
	left.emit()

func _claim_all()->void:
	if _leaving or claim_all_button.disabled:return
	_leaving=true;claim_all_button.disabled=true;leave_button.disabled=true
	for card:Button in card_buttons.values():card.disabled=true
	direct_claimed.emit()
