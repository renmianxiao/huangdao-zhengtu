extends Control
## Presentation only: RunScreen retains all save, recovery and confirmation logic.
const Paper = preload("res://code/scripts/ui/global_theme.gd")
const Saves = preload("res://code/scripts/run/save_store.gd")
const Run = preload("res://code/scripts/run/run_rules.gd")
const Cinematics = preload("res://code/scripts/cinematics/catalog.gd")

signal slot_selected(slot: int)
signal delete_requested(slot: int)
signal back_requested

var slot_buttons: Dictionary = {}
var delete_buttons: Dictionary = {}
var _margin: MarginContainer
var _intro: VBoxContainer
var _mode := "load"

func configure(mode: String, entries: Array) -> void:
	_mode = mode
	theme = Paper.make(18)
	var backdrop = preload("res://code/scripts/ui/menu_backdrop.gd").new()
	backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(backdrop)
	var shade := ColorRect.new()
	shade.color = Color(0.07, 0.10, 0.11, 0.30)
	shade.mouse_filter = MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(shade)
	_margin = MarginContainer.new()
	_margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_margin.add_child(scroll)
	var spread := HBoxContainer.new()
	spread.size_flags_horizontal = SIZE_EXPAND_FILL
	spread.size_flags_vertical = SIZE_EXPAND_FILL
	spread.add_theme_constant_override("separation", 44)
	scroll.add_child(spread)
	_intro = VBoxContainer.new()
	_intro.alignment = BoxContainer.ALIGNMENT_CENTER
	_intro.add_theme_constant_override("separation", 18)
	_intro.theme = Paper.make_dark(18)
	spread.add_child(_intro)
	_text(_intro, "黄道征途", 22, Paper.OLD_GOLD).add_theme_font_override("font", Paper.heading_font())
	_text(_intro, "江湖行记", 54, Paper.DARK_TEXT).add_theme_font_override("font", Paper.title_font())
	_rule(_intro, Paper.OLD_GOLD)
	_text(_intro, "开启新征途" if mode == "new" else "重返山河", 28, Paper.DARK_TEXT).add_theme_font_override("font", Paper.heading_font())
	var instruction := _text(_intro, "选择一卷空白行记，\n记下新的江湖故事。" if mode == "new" else "翻开旧卷，\n继续未尽的征途。", 18, Paper.DARK_MUTED)
	instruction.add_theme_constant_override("line_spacing", 8)
	var gap := Control.new()
	gap.custom_minimum_size.y = 24
	_intro.add_child(gap)
	var back := Button.new()
	back.name = "BackButton"
	back.text = "返回主界面"
	back.custom_minimum_size.y = 48
	back.pressed.connect(func(): back_requested.emit())
	_intro.add_child(back)
	var pages := VBoxContainer.new()
	pages.size_flags_horizontal = SIZE_EXPAND_FILL
	pages.alignment = BoxContainer.ALIGNMENT_CENTER
	pages.add_theme_constant_override("separation", 16)
	spread.add_child(pages)
	var heading := HBoxContainer.new()
	pages.add_child(heading)
	var caption := _text(heading, "选择新局存档" if mode == "new" else "读取存档", 24, Paper.DARK_TEXT)
	caption.size_flags_horizontal = SIZE_EXPAND_FILL
	caption.add_theme_font_override("font", Paper.heading_font())
	var available := 0
	for entry in entries:
		if entry.result.ok: available += 1
	_text(heading, "%d / 3 卷已有记录" % available, 16, Paper.DARK_MUTED)
	for entry in entries: _add_slot(pages, entry)
	var hint := _text(pages, "已有记录的槽位会先询问是否覆盖。" if mode == "new" else "进度随旅程自动记录。删除存档前需要再次确认。", 16, Paper.DARK_TEXT)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 1
	resized.connect(_layout)
	_layout()
	# Keyboard users can enter the first usable slot without traversing decoration.
	back.grab_focus()
	for value in slot_buttons.values():
		if not value.disabled:
			value.grab_focus()
			break

func _add_slot(parent: Node, entry: Dictionary) -> void:
	var slot := int(entry.slot)
	var result: Dictionary = entry.result
	var valid := bool(result.ok)
	var has_files := bool(entry.has_files)
	var state: Dictionary = result.get("state", {})
	var recovered := bool(result.get("recovered", false))
	var floor_number := clampi(Run.map_floor(state), 1, 5) if valid else 1
	var panel := PanelContainer.new()
	panel.name = "SaveSlot%d" % slot
	panel.custom_minimum_size.y = 184
	var style := Paper.box(Paper.PANEL if valid else Color("ddd4c2"), Paper.BORDER)
	style.content_margin_left = 18
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", Paper.ornate(style))
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	panel.add_child(row)
	var landscape := TextureRect.new()
	landscape.custom_minimum_size = Vector2(170, 138)
	landscape.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	landscape.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	landscape.texture = load(Cinematics.SCENES[floor_number - 1].background)
	landscape.mouse_filter = MOUSE_FILTER_IGNORE
	if not valid: landscape.self_modulate = Color(0.65, 0.65, 0.60, 0.48)
	row.add_child(landscape)
	var seal := Label.new()
	seal.text = ["壹", "贰", "叁"][slot - 1]
	seal.position = Vector2(8, 8)
	seal.add_theme_font_override("font", Paper.title_font())
	seal.add_theme_font_size_override("font_size", 26)
	seal.add_theme_color_override("font_color", Paper.PANEL)
	seal.add_theme_stylebox_override("normal", Paper.box(Paper.RED, Paper.RED))
	landscape.add_child(seal)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = SIZE_EXPAND_FILL
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	details.add_theme_constant_override("separation", 7)
	row.add_child(details)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 14)
	details.add_child(title_row)
	var title := _text(title_row, "存档 %d" % slot, 25, Paper.INK)
	title.add_theme_font_override("font", Paper.heading_font())
	var status := "可从备份恢复" if recovered else ("已有记录" if valid else ("存档异常" if has_files else "空白行记"))
	_text(title_row, status, 15, Paper.RED if recovered or (has_files and not valid) else Paper.GREEN).size_flags_vertical = SIZE_SHRINK_CENTER
	if valid:
		var summary := Saves.summary(result)
		var phase := summary.split(" · ")[0]
		_clipped(details, "第%d层 · %s    %s" % [floor_number, Cinematics.SCENES[floor_number - 1].title, phase], 18, Paper.INK)
		_clipped(details, "等级 %d    已过 %d 个节点    金币 %d" % [state.level, state.completed.size(), state.gold], 16, Paper.MUTED)
		var team_names := str(summary.split("\n")[1])
		_clipped(details, "同行  " + (team_names if not team_names.is_empty() else "尚未编队"), 16, Paper.MUTED)
		_clipped(details, "上次记录  " + str(result.saved_at).replace("T", "  "), 14, Paper.MUTED)
		panel.tooltip_text = summary
	else:
		_clipped(details, "此卷尚无旅程" if not has_files else "未能读取有效进度", 21, Paper.INK)
		var empty_hint := "可在「开始新局」中使用此槽位。" if _mode == "load" else "从这里写下新的江湖故事。"
		var message := str(result.get("message", "请检查存档文件。")) if has_files else empty_hint
		var note := _text(details, message, 16, Paper.MUTED)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size.x = 1
	var actions := VBoxContainer.new()
	actions.custom_minimum_size.x = 146
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	row.add_child(actions)
	var select := Button.new()
	select.name = "SelectSlot%d" % slot
	select.custom_minimum_size = Vector2(146, 48)
	if _mode == "new": select.text = "重新启程" if has_files else "在此启程"
	else: select.text = "恢复并继续" if recovered else ("继续征途" if valid else "无法读取" if has_files else "暂无存档")
	select.disabled = _mode == "load" and not valid
	if not select.disabled: Paper.primary(select)
	select.tooltip_text = "存档 %d：%s" % [slot, Saves.summary(result)]
	select.pressed.connect(func(): slot_selected.emit(slot))
	actions.add_child(select)
	slot_buttons[slot] = select
	if _mode == "load":
		var remove := Button.new()
		remove.name = "DeleteSlot%d" % slot
		remove.text = "删除存档"
		remove.flat = true
		remove.custom_minimum_size.y = 36
		remove.disabled = not has_files
		remove.add_theme_font_size_override("font_size", 15)
		remove.add_theme_color_override("font_color", Paper.RED)
		remove.tooltip_text = "删除存档 %d 及备份；点击后需再次确认。" % slot
		remove.pressed.connect(func(): delete_requested.emit(slot))
		actions.add_child(remove)
		delete_buttons[slot] = remove

func _layout() -> void:
	if _margin == null: return
	var inset := 64 if size.x >= 1400 else 36
	for side in ["left", "right"]: _margin.add_theme_constant_override("margin_" + side, inset)
	for side in ["top", "bottom"]: _margin.add_theme_constant_override("margin_" + side, 48)
	_intro.custom_minimum_size.x = 252 if size.x >= 1400 else 220

func _text(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var item := Label.new()
	item.text = value
	item.mouse_filter = MOUSE_FILTER_IGNORE
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	parent.add_child(item)
	return item

func _clipped(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var item := _text(parent, value, font_size, color)
	item.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	item.tooltip_text = value
	item.mouse_filter = MOUSE_FILTER_PASS
	return item

func _rule(parent: Node, color: Color) -> void:
	var rule := ColorRect.new()
	rule.color = color
	rule.custom_minimum_size = Vector2(0, 1)
	rule.mouse_filter = MOUSE_FILTER_IGNORE
	parent.add_child(rule)
