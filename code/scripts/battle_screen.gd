extends Control
const Preview=preload("res://code/scripts/combat/action_preview.gd")

signal battle_finished(result: Dictionary)
signal state_changed(result: Dictionary)

const DialogSkin = preload("res://code/scripts/ui/dialog_skin.gd")
const CombatAudio = preload("res://code/scripts/audio/combat_audio.gd")
const AudioControls = preload("res://code/scripts/ui/audio_controls.gd")
const Battle = preload("res://code/scripts/battle.gd")
const Party = preload("res://code/scripts/party.gd")
const Characters = preload("res://code/scripts/characters/character_catalog.gd")
const PaperStyle=preload("res://code/scripts/ui/reference_battle_theme.gd")
const INK = PaperStyle.INK
const MUTED = PaperStyle.MUTED
const GOLD = PaperStyle.GOLD
const TEAL = PaperStyle.GREEN
const RED = PaperStyle.RED
const Chrome = preload("res://code/scripts/ui/reference_battle_chrome.gd")
const Characters_Enemies = preload("res://code/scripts/characters/enemy_catalog.gd")
const Paper = preload("res://code/scripts/ui/global_theme.gd")
const SkillIcons = preload("res://code/scripts/ui/reference_skill_icons.gd")
const AttackVfx = preload("res://code/scripts/ui/battle_vfx.gd")
const AttackProfiles = preload("res://code/scripts/ui/attack_profiles.gd")

@export var content_inset: int = 20
var state: Dictionary = Battle.create_battle()
var busy: bool = false
var painted_background: TextureRect
var displayed_stage := ""
var hurt_veil: TextureRect
var hurt_reaction: Tween
var expedition_mode: bool = false
var result_sent: bool = false
var skill_buttons: Dictionary = {}
var skill_slots: Dictionary = {}
var leader_labels: Dictionary = {}
var attribute_labels: Dictionary = {}
var leader_panels: Dictionary = {}
var passive_labels: Dictionary = {}
const CARD_HEIGHT := 280
const PORTRAIT_HEIGHT := 100
var display_slots: Array[Control] = []
var empty_labels: Array[Label] = []
var portrait_panels: Dictionary = {}
var card_storage: Control
var detail_dialog: AcceptDialog
var detail_text: RichTextLabel
var detail_artwork: TextureRect
var slot_grid: GridContainer
var content_scroll: ScrollContainer
var empty_slot_panels: Array[Control] = []
var position_buttons: Dictionary = {}
var position_panel: VBoxContainer
var swap_status: Label
var formation_dialog: AcceptDialog
var reserve_button: Button
var selected_front := -1
var end_turn_button: Button
var restart_button: Button
var result_dialog: AcceptDialog
var help_dialog: AcceptDialog
var help_text: RichTextLabel
var enemy_timer: Timer
var round_label: Label
var enemy_hp_label: Label
var enemy_bar: ProgressBar
var enemy_effects: Label
var intent_label: Label
var team_hp_label: Label
var team_bar: ProgressBar
var ap_label: Label
var team_effects: Label
var phase_label: Label
var ap_pips: Array[Label] = []
var battlefield: Control
var enemy_artwork: Control
var displayed_enemy_id := ""
var log_dialog: AcceptDialog
var full_log: RichTextLabel
var log_view: RichTextLabel
var ui_layer: Control
var chrome_layer: Control
var enemy_hud: PanelContainer
var ally_hud: PanelContainer
var enemy_glass: Control
var ally_glass: Control
var round_badge: Control
var ap_row: HBoxContainer
var tools_frame: PanelContainer
var actions_frame: PanelContainer
var tools_column: VBoxContainer
var actions_column: VBoxContainer
var help_button: Button
var menu_button: Button
var speed_button: Button
var defense_button: Button
var defense_skill := ""
var battle_menu: AcceptDialog
var portrait_names: Dictionary = {}
var quick_speed := false
var attack_vfx: Control
var battle_audio: Node
var audio_controls: Control
var music_controls: Control
var artwork_reaction: Tween
var result_delay := 0.0
var effect_canvas_size := Vector2.ZERO


func _ready() -> void:
	if not expedition_mode:Music.request_track("battle")
	add_to_group("right_click_battle")
	get_window().min_size = Vector2i(900, 650)
	_build_theme()
	_build_ui()
	restart_button.visible = not expedition_mode
	_apply_slots()
	_render()
	get_viewport().size_changed.connect(_update_battle_layout)
	visibility_changed.connect(func(): if not is_visible_in_tree(): cancel_pending())
	_update_battle_layout()


func _build_theme() -> void:
	theme=PaperStyle.make(18)


func _box(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style


func _label(parent: Node, text: String, size: int = 16, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = text
	if not parent is HBoxContainer:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 1
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _row(parent: Node) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	return row


func _panel(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _box(PaperStyle.PANEL, PaperStyle.BORDER))
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	return column


func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _bar(parent: Node, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 12
	bar.show_percentage = false
	var fill := _box(color)
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	var background := _box(Color("d8cfbc"))
	background.content_margin_top = 0
	background.content_margin_bottom = 0
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	return bar


func _build_ui() -> void:
	# The stage and HUD share one canvas, like the reference composition.
	content_scroll = ScrollContainer.new()
	content_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(content_scroll)
	ui_layer = Control.new()
	ui_layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.add_child(ui_layer)
	var scenery := Chrome.new()
	scenery.mode = "backdrop"
	scenery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(scenery)
	painted_background = TextureRect.new()
	painted_background.texture = load("res://art/ui/reference_battlefield.png")
	painted_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	painted_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	painted_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	painted_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(painted_background)
	battlefield = Control.new()
	battlefield.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(battlefield)
	enemy_artwork = preload("res://code/scripts/ui/enemy_artwork.gd").new()
	enemy_artwork.name = "EnemyArtwork"
	enemy_artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battlefield.add_child(enemy_artwork)
	chrome_layer = Chrome.new()
	chrome_layer.mode = "frame"
	chrome_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(chrome_layer)
	intent_label = _hud_label(ui_layer, "", 20, INK)
	intent_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intent_label.max_lines_visible = 3
	intent_label.add_theme_stylebox_override("normal", _box(Color(0.13,0.15,0.15,0.94), PaperStyle.BORDER))
	intent_label.mouse_filter = Control.MOUSE_FILTER_PASS
	enemy_effects = _hud_label(ui_layer, "", 18, GOLD)
	enemy_effects.add_theme_stylebox_override("normal",_box(Color(0.13,0.15,0.15,0.90),Color.TRANSPARENT))
	enemy_effects.mouse_filter=Control.MOUSE_FILTER_PASS
	enemy_hud = _make_resource_hud(false)
	ally_hud = _make_resource_hud(true)
	round_badge = Chrome.new()
	round_badge.mode = "round"
	ui_layer.add_child(round_badge)
	round_label = _hud_label(round_badge,"",24,GOLD)
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ap_row = HBoxContainer.new()
	ap_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ui_layer.add_child(ap_row)
	ap_label = _hud_label(ap_row,"",20,GOLD)
	for i in range(8):
		var pip := _hud_label(ap_row,"",20)
		pip.tooltip_text = "第 %d 点行动力" % (i + 1)
		pip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ap_pips.append(pip)
	team_effects = _hud_label(ui_layer,"",18,GOLD)
	team_effects.add_theme_stylebox_override("normal",_box(Color(0.13,0.15,0.15,0.90),Color.TRANSPARENT))
	team_effects.mouse_filter=Control.MOUSE_FILTER_PASS
	team_effects.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	team_effects.max_lines_visible = 2
	tools_frame = PanelContainer.new()
	tools_frame.name = "ToolsFrame"
	tools_frame.add_theme_stylebox_override("panel",_box(Color(0,0,0,0.20),Color.TRANSPARENT))
	ui_layer.add_child(tools_frame)
	tools_column = VBoxContainer.new()
	tools_column.add_theme_constant_override("separation",10)
	tools_frame.add_child(tools_column)
	reserve_button = _button(tools_column,"换位",_toggle_formation)
	PaperStyle.style_tool(reserve_button,"silver")
	speed_button = _button(tools_column,"速度\n常速",_toggle_speed)
	PaperStyle.style_tool(speed_button,"gold")
	var log_button := _button(tools_column,"战报",_show_log)
	PaperStyle.style_tool(log_button,"gold")
	var tool_spacer := Control.new()
	tool_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tools_column.add_child(tool_spacer)
	menu_button = _button(tools_column,"菜单",_show_battle_menu)
	PaperStyle.style_tool(menu_button,"gold")
	card_storage = Control.new()
	card_storage.hide()
	add_child(card_storage)
	slot_grid = GridContainer.new()
	slot_grid.columns = 4
	slot_grid.add_theme_constant_override("h_separation",8)
	ui_layer.add_child(slot_grid)
	for index in range(4):
		var slot := PanelContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
		slot_grid.add_child(slot)
		var empty := _hud_label(slot,"—\n空位",24,MUTED)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		display_slots.append(slot)
		empty_labels.append(empty)
	_ensure_party_cards()
	actions_frame = PanelContainer.new()
	actions_frame.name = "ActionsFrame"
	actions_frame.add_theme_stylebox_override("panel",_box(Color(0,0,0,0.20),Color.TRANSPARENT))
	ui_layer.add_child(actions_frame)
	actions_column = VBoxContainer.new()
	actions_column.add_theme_constant_override("separation",10)
	actions_frame.add_child(actions_column)
	defense_button = _button(actions_column,"防御",_use_defense)
	PaperStyle.style_tool(defense_button,"blue")
	defense_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	phase_label = _hud_label(actions_column,"",13,TEAL)
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_turn_button = _button(actions_column,"结束回合",request_end_round)
	end_turn_button.mouse_entered.connect(_preview_end_turn)
	end_turn_button.mouse_exited.connect(_clear_preview)
	defense_button.mouse_entered.connect(func():
		if not defense_skill.is_empty():_preview_skill(defense_skill)
	)
	defense_button.mouse_exited.connect(_clear_preview)
	end_turn_button.clip_text = true
	end_turn_button.tooltip_text = "鼠标右键：结束回合；有弹窗时优先取消。"
	PaperStyle.primary(end_turn_button)
	help_button = _button(ui_layer,"?\n帮助",func(): help_dialog.popup_centered(Vector2i(660,440)))
	PaperStyle.style_tool(help_button,"gold")
	log_view = RichTextLabel.new()
	log_view.bbcode_enabled = true
	log_view.scroll_active = false
	log_view.add_theme_font_size_override("normal_font_size",13)
	log_view.add_theme_color_override("default_color",MUTED)
	log_view.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	ui_layer.add_child(log_view)
	_build_dialogs()
	battle_menu = AcceptDialog.new()
	battle_menu.title = "战斗菜单"
	battle_menu.get_ok_button().text = "继续战斗"
	var options := VBoxContainer.new()
	options.add_theme_constant_override("separation",12)
	battle_menu.add_child(options)
	_button(options,"查看战报",func(): battle_menu.hide(); _show_log())
	_button(options,"玩法说明",func(): battle_menu.hide(); help_dialog.popup_centered(Vector2i(660,440)))
	restart_button = _button(options,"重新挑战",func(): battle_menu.hide(); restart_battle())
	audio_controls=AudioControls.new()
	options.add_child(audio_controls)
	options.custom_minimum_size = Vector2(280,150)
	add_child(battle_menu)
	audio_controls.setup(battle_audio)
	music_controls=AudioControls.new()
	options.add_child(music_controls)
	music_controls.setup(Music,"背景音乐")
	for pair: Array in [[formation_dialog,"formation"],[log_dialog,"log"],[help_dialog,"help"],[detail_dialog,"detail"],[result_dialog,"result"],[battle_menu,"menu"]]:
		DialogSkin.apply(pair[0],pair[1])
	resized.connect(_update_battle_layout)
	ui_layer.resized.connect(_update_battle_layout)
	_update_battle_layout.call_deferred()


func _hud_label(parent: Node,value: String,font_size: int,color: Color=INK) -> Label:
	var label := _label(parent,value,font_size,color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_resource_hud(ally: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	ui_layer.add_child(panel)
	var layer := Control.new()
	panel.add_child(layer)
	var glass := Chrome.new()
	glass.mode = "health_right" if ally else "health_left"
	layer.add_child(glass)
	var title := _hud_label(layer,"我方部队" if ally else "",21,INK)
	title.name = "TeamTitle" if ally else "EnemyTitle"
	var hp := _hud_label(layer,"",29,INK)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background",StyleBoxEmpty.new())
	bar.add_theme_stylebox_override("fill",StyleBoxEmpty.new())
	layer.add_child(bar)
	if ally:
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		team_hp_label = hp; team_bar = bar; ally_glass = glass
	else:
		enemy_hp_label = hp; enemy_bar = bar; enemy_glass = glass
	return panel


func _build_dialogs() -> void:
	formation_dialog = AcceptDialog.new()
	formation_dialog.title = "阵容 · 四前台 / 四后台"
	formation_dialog.canceled.connect(_cancel_formation_selection)
	formation_dialog.get_ok_button().text = "返回战斗"
	add_child(formation_dialog)
	position_panel = _panel(formation_dialog)
	swap_status = _label(position_panel, "", 14, MUTED)
	# Give hidden status text its real reading width before native minimum-size layout.
	swap_status.custom_minimum_size.x = 600
	var positions := GridContainer.new()
	positions.columns = 4
	positions.add_theme_constant_override("h_separation", 10)
	positions.add_theme_constant_override("v_separation", 8)
	position_panel.add_child(positions)
	for i in range(Party.MAX_SIZE):
		var b := _button(positions, "", _select_position.bind(i))
		b.custom_minimum_size = Vector2(145, 65)
		b.add_theme_font_size_override("font_size", 13)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		position_buttons[i] = b
	log_dialog = AcceptDialog.new()
	log_dialog.title = "战报"
	log_dialog.get_ok_button().text = "返回战斗"
	full_log = RichTextLabel.new()
	full_log.bbcode_enabled = true
	full_log.selection_enabled = true
	full_log.custom_minimum_size = Vector2(280,250)
	log_dialog.add_child(full_log)
	add_child(log_dialog)
	enemy_timer = Timer.new()
	enemy_timer.one_shot = true
	enemy_timer.wait_time = 0.45
	enemy_timer.timeout.connect(_resolve_enemy)
	add_child(enemy_timer)
	help_dialog = AcceptDialog.new()
	help_dialog.title = "玩法说明"
	help_text = RichTextLabel.new()
	help_text.custom_minimum_size = Vector2(280,180)
	help_text.scroll_active = true
	help_text.selection_enabled = true
	help_text.bbcode_enabled = true
	help_dialog.add_child(help_text)
	help_text.text = "目标：在部队 HP 耗尽前击败当前敌人。\n\n部队共享 HP 与 AP；每名队长每轮只能行动一次。\n初始 4 AP，每轮恢复 2 AP，剩余结转，上限 8。\n\n护盾与祝福仅本轮有效；祝福强化下一次攻击。\n中毒每层每轮造成施毒者施放时攻击力 ×0.35 的穿透伤害，最多 3 层，满层不刷新。\n所有主动技能上回合使用后，本回合费用 +1 AP；停用一回合恢复，额外费用最多 1 AP。\n敌方预告标记「可打断」时，盾击可以取消其行动。\n穿透攻击绕过护盾，百分比与固定减伤仍然有效。\n敌人按行动倾向随机选择招式，本回合预告不会重抽。\n重招需要准备动作且有间隔，重招后会转入防守或休整。\n敌人半血进入狂怒，下一次新预告起每段攻击 +30。\n毒素先于敌人行动结算；毒触发狂怒从下一轮生效。\n\n观察敌方预告，合理留 AP、防御和打断。"
	help_text.text = "[b][color=#8e6939]胜负与共享资源[/color][/b]\n" + help_text.text
	help_text.text = help_text.text.replace("\n\n护盾与祝福","\n\n[b][color=#8e6939]技能与状态[/color][/b]\n护盾与祝福")
	help_text.text = help_text.text.replace("\n敌方预告标记","\n\n[b][color=#8e6939]敌方行动[/color][/b]\n敌方预告标记")
	help_text.text = Battle.Numbers.description(help_text.text)
	help_dialog.get_ok_button().text = "开始谋划"
	add_child(help_dialog)
	detail_dialog = AcceptDialog.new()
	detail_dialog.get_ok_button().text = "返回战斗"
	var detail_row := HBoxContainer.new()
	detail_row.add_theme_constant_override("separation",24)
	detail_dialog.add_child(detail_row)
	detail_artwork = TextureRect.new()
	detail_artwork.custom_minimum_size = Vector2(160,220)
	detail_artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_row.add_child(detail_artwork)
	detail_text = RichTextLabel.new()
	detail_text.custom_minimum_size = Vector2(300, 220)
	detail_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_text.scroll_active = true
	detail_text.selection_enabled = true
	detail_row.add_child(detail_text)
	add_child(detail_dialog)
	result_dialog = AcceptDialog.new()
	result_dialog.get_ok_button().text = "查看战斗记录"
	result_dialog.confirmed.connect(_show_log)
	result_dialog.add_button("再次挑战", false, "restart")
	result_dialog.custom_action.connect(func(action: StringName):
		if action == "restart":
			restart_battle()
	)
	add_child(result_dialog)
	# Transparent feedback uses the same coordinates as the battle canvas.
	attack_vfx = AttackVfx.new()
	attack_vfx.name = "AttackVfx"
	attack_vfx.z_index = 20
	ui_layer.add_child(attack_vfx)
	attack_vfx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_audio=CombatAudio.new()
	battle_audio.name="CombatAudio"
	add_child(battle_audio)
	attack_vfx.sound_requested.connect(battle_audio.play_cue)
	attack_vfx.effects_cleared.connect(battle_audio.stop_all)


## Only party members need controls or portraits; reserves are ready for swaps.
func _ensure_party_cards() -> void:
	var ids: Array = Party.members(state.party_slots) if state.has("party_slots") else state.config.get("team",Characters.STARTER_IDS)
	for id: String in ids:
		var leader: Dictionary = Characters.leader(id)
		if not leader.is_empty(): _build_leader_card(leader)

func _build_leader_card(leader: Dictionary) -> void:
	if leader_panels.has(leader.id): return
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var frame := _box(PaperStyle.PANEL,PaperStyle.BORDER)
	frame.content_margin_left = 3
	frame.content_margin_right = 3
	frame.content_margin_top = 3
	frame.content_margin_bottom = 3
	panel.add_theme_stylebox_override("panel",frame)
	card_storage.add_child(panel)
	leader_panels[leader.id] = panel
	var card := Control.new()
	panel.add_child(card)
	var portrait := PanelContainer.new()
	PaperStyle.style_portrait(portrait)
	card.add_child(portrait)
	portrait_panels[leader.id] = portrait
	var art := preload("res://code/scripts/ui/enemy_artwork.gd").new()
	art.portrait_mode = true
	art.character_id = leader.id
	art.name = "CharacterArtwork"
	art.texture = load("res://art/characters/"+leader.id+".png")
	portrait.add_child(art)
	var name_label := _hud_label(card,leader.name,17,INK)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.add_theme_font_override("font", PaperStyle.Paper.heading_font())
	name_label.add_theme_stylebox_override("normal",_box(Color(0.10,0.12,0.12,0.84),Color.TRANSPARENT))
	portrait_names[leader.id] = name_label
	leader_labels[leader.id] = _hud_label(card,"",12,TEAL)
	leader_labels[leader.id].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	leader_labels[leader.id].add_theme_stylebox_override("normal",_box(Color(0.10,0.12,0.12,0.84),Color.TRANSPARENT))
	portrait.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	portrait.tooltip_text = "查看 %s 的属性、技能与被动" % leader.name
	portrait.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_show_character_detail(leader.id)
	)
	skill_slots[leader.id] = []
	for skill_id: String in leader.skills:
		var skill_button := _button(card,"",_use_skill.bind(skill_id))
		skill_button.clip_text = true
		PaperStyle.style_skill(skill_button)
		skill_button.icon = SkillIcons.for_skill(Battle.SKILLS[skill_id])
		skill_button.expand_icon = true
		skill_button.add_theme_color_override("icon_normal_color", Color("c5b88e"))
		skill_button.add_theme_color_override("icon_hover_color", Color("e8decc"))
		skill_buttons[skill_id] = skill_button
		skill_button.mouse_entered.connect(_preview_skill.bind(skill_id))
		skill_button.mouse_exited.connect(_clear_preview)
		skill_slots[leader.id].append(skill_button)
	if not leader.passive.is_empty():
		var passive_slot := _button(card,"",_show_character_detail.bind(leader.id))
		passive_slot.clip_text = true
		PaperStyle.style_passive(passive_slot)
		passive_slot.icon = SkillIcons.passive()
		passive_slot.expand_icon = true
		passive_labels[leader.id] = passive_slot
		skill_slots[leader.id].append(passive_slot)
	panel.resized.connect(_layout_leader_card.bind(leader.id))


func _place(control: Control,area: Rect2) -> void:
	control.position = area.position
	control.size = area.size


func _update_battle_layout() -> void:
	if ui_layer == null or end_turn_button == null: return
	var bounds := size
	if bounds.x <= 0 or bounds.y <= 0: bounds = get_viewport_rect().size
	if not effect_canvas_size.is_equal_approx(bounds):
		if attack_vfx != null: attack_vfx.clear_effects()
		effect_canvas_size = bounds
	ui_layer.custom_minimum_size = bounds
	var w := bounds.x
	var h := bounds.y
	var s := minf(w / 1920.0, h / 1080.0)
	# Upper painting, compact shared resource band, then four fixed portrait slots.
	_place(battlefield, Rect2(0, 0, w, h * 0.584))
	_place(intent_label, Rect2(w * 0.018, h * 0.028, w * 0.31, maxf(60, h * 0.088)))
	intent_label.add_theme_font_size_override("font_size", maxi(15, roundi(21 * s)))
	_place(enemy_effects, Rect2(w * 0.018, h * 0.422, w * 0.42, maxf(25, h * 0.032)))
	enemy_effects.add_theme_font_size_override("font_size", maxi(13, roundi(18 * s)))
	_place(team_effects, Rect2(w * 0.56, h * 0.422, w * 0.422, maxf(25, h * 0.032)))
	team_effects.add_theme_font_size_override("font_size", maxi(13, roundi(18 * s)))
	_place(enemy_hud, Rect2(w * 0.012, h * 0.468, w * 0.437, h * 0.066))
	_place(ally_hud, Rect2(w * 0.551, h * 0.468, w * 0.437, h * 0.066))
	for hud in [enemy_hud, ally_hud]:
		var layer: Control = hud.get_child(0)
		var hw: float = hud.size.x
		var hh: float = hud.size.y
		var line_height := maxf(24, hh * 0.57)
		_place(layer.get_child(0), Rect2(0, line_height + 3, hw, maxf(12, hh - line_height - 3)))
		_place(layer.get_child(1), Rect2(5, 0, hw * 0.55 - 5, line_height))
		_place(layer.get_child(2), Rect2(hw * 0.55, 0, hw * 0.45 - 5, line_height))
		_place(layer.get_child(3), Rect2(0, line_height + 3, hw, maxf(12, hh - line_height - 3)))
		layer.get_child(1).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		layer.get_child(2).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		layer.get_child(1).add_theme_font_size_override("font_size", maxi(15, roundi(22 * s)))
		layer.get_child(2).add_theme_font_size_override("font_size", maxi(16, roundi(23 * s)))
	var dial_size := minf(w * 0.087, h * 0.108)
	_place(round_badge, Rect2((w - dial_size) / 2, h * 0.441, dial_size, dial_size))
	_place(round_label, Rect2(5, 5, dial_size - 10, dial_size - 10))
	round_label.add_theme_font_size_override("font_size", maxi(15, roundi(23 * s)))
	_place(ap_row, Rect2(w * 0.30, h * 0.545, w * 0.40, h * 0.037))
	ap_row.add_theme_constant_override("separation", maxi(2, roundi(5 * s)))
	ap_label.add_theme_font_size_override("font_size", maxi(15, roundi(21 * s)))
	ap_label.custom_minimum_size.x = maxf(98, 145 * s)
	for pip: Label in ap_pips:
		pip.custom_minimum_size = Vector2(maxf(20, 32 * s), maxf(20, 32 * s))
	var top := h * 0.594
	var bottom := h * 0.967
	var left_width := maxf(76, w * 0.077)
	var right_width := maxf(98, w * 0.092)
	var gap := maxf(5, w * 0.006)
	_place(tools_frame, Rect2(8, top, left_width - 8, bottom - top))
	_place(actions_frame, Rect2(w - right_width, top, right_width - 8, bottom - top))
	_place(slot_grid, Rect2(left_width + gap, top, w - left_width - right_width - gap * 2, bottom - top))
	slot_grid.add_theme_constant_override("h_separation", maxi(5, roundi(10 * s)))
	for slot: Control in display_slots: slot.custom_minimum_size = Vector2(1, 0)
	tools_column.add_theme_constant_override("separation", maxi(5, roundi(10 * s)))
	for child in tools_column.get_children():
		if child is Button:
			child.clip_text = true
			child.custom_minimum_size = Vector2(0, maxf(36, 61 * s))
			child.add_theme_font_size_override("font_size", maxi(14, roundi(20 * s)))
	reserve_button.custom_minimum_size.y = maxf(44, 78 * s)
	menu_button.custom_minimum_size.y = maxf(40, 67 * s)
	end_turn_button.custom_minimum_size = Vector2(0, maxf(55, 95 * s))
	end_turn_button.add_theme_font_size_override("font_size", maxi(15, roundi(23 * s)))
	defense_button.add_theme_font_size_override("font_size", maxi(17, roundi(26 * s)))
	phase_label.add_theme_font_size_override("font_size", maxi(12, roundi(17 * s)))
	_place(help_button, Rect2(w - maxf(48, 72 * s) - 16, 16, maxf(48, 72 * s), maxf(44, 66 * s)))
	help_button.add_theme_font_size_override("font_size", maxi(14, roundi(20 * s)))
	_place(log_view, Rect2(left_width + gap, h * 0.973, w - left_width - right_width - gap * 2, h * 0.026))
	log_view.add_theme_font_size_override("normal_font_size", maxi(11, roundi(14 * s)))
	for id: String in leader_panels: _layout_leader_card(id)


func _layout_leader_card(id: String) -> void:
	if not leader_panels.has(id) or not skill_slots.has(id): return
	var panel: Control = leader_panels[id]
	var cw := maxf(1, panel.size.x - 6)
	var ch := maxf(1, panel.size.y - 6)
	var s := minf(size.x / 1920.0, size.y / 1080.0)
	var skill_height := maxf(31, 45 * s)
	var py := skill_height + 3
	var ph := maxf(1, ch - 2 * skill_height - 6)
	_place(skill_slots[id][0], Rect2(0, 0, cw, skill_height))
	_place(skill_slots[id][1], Rect2(0, ch - skill_height, cw, skill_height))
	_place(portrait_panels[id], Rect2(0, py, cw, ph))
	var caption_height := maxf(28, 37 * s)
	_place(portrait_names[id], Rect2(0, py + ph - caption_height, cw * 0.55, caption_height))
	_place(leader_labels[id], Rect2(cw * 0.55, py + ph - caption_height, cw * 0.45, caption_height))
	portrait_names[id].add_theme_font_size_override("font_size", maxi(16, roundi(25 * s)))
	leader_labels[id].add_theme_font_size_override("font_size", maxi(13, roundi(17 * s)))
	for button: Button in skill_slots[id]:
		button.add_theme_font_size_override("font_size", maxi(12, roundi(21 * s)))
		button.add_theme_constant_override("icon_max_width", maxi(17, roundi(25 * s)))


func _show_battle_menu() -> void:
	battle_menu.popup_centered(Vector2i(380,mini(530,int(get_viewport_rect().size.y)-120)))


func _toggle_speed() -> void:
	quick_speed = not quick_speed
	enemy_timer.wait_time = 0.16 if quick_speed else 0.45
	speed_button.text = "速度\n快速" if quick_speed else "速度\n常速"


func _use_defense() -> void:
	if not defense_skill.is_empty(): _use_skill(defense_skill)


func _update_defense_button() -> void:
	defense_skill = ""
	for id: String in skill_buttons:
		if not leader_panels[Battle.SKILLS[id].leader].visible: continue
		for effect: Dictionary in Battle.SKILLS[id].get("effects",[]):
			if effect.get("op","") == "shield" and Battle.action_reason(state,id).is_empty():
				defense_skill=id
				break
		if not defense_skill.is_empty(): break
	defense_button.disabled = busy or defense_skill.is_empty()
	defense_button.text = "防御\n%d AP" % Battle.skill_cost(state,defense_skill) if not defense_skill.is_empty() else "防御\n—"
	defense_button.tooltip_text = "快捷施放：%s（仍消耗该角色本轮行动）" % Battle.SKILLS[defense_skill].name if not defense_skill.is_empty() else "当前前台没有可用的护盾技能"


func _show_character_detail(id: String) -> void:
	var leader: Dictionary = Characters.leader(id)
	if leader.is_empty(): return
	detail_artwork.texture = load("res://art/characters/" + id + ".png")
	var parts: Array[String] = ["%s\n%s · 攻击 %s · 血量 %s" % [leader.name, Battle.Professions.label(leader["class"]), Battle.Attributes.display(Battle.Attributes.stats(state,id).attack), Battle.Attributes.display(Battle.Attributes.stats(state,id).max_hp)]]
	if not leader.positioning.is_empty(): parts.append(leader.positioning)
	for skill_id: String in leader.skills:
		var skill: Dictionary = Battle.SKILLS[skill_id]
		parts.append("主动 · %s（当前 %d AP）\n%s" % [skill.name, Battle.skill_cost(state, skill_id), Battle.skill_description(state, skill_id)])
	if not leader.passive.is_empty(): parts.append(Battle.passive_description(state, id))
	if not leader.synergy.is_empty(): parts.append("搭配\n" + leader.synergy)
	if not leader.caution.is_empty(): parts.append("短板\n" + leader.caution)
	detail_dialog.title = "%s · 技能与被动" % leader.name
	detail_text.text = "\n\n".join(parts)
	detail_text.scroll_to_line(0)
	var viewport_size := get_viewport_rect().size
	detail_dialog.popup_centered(Vector2i(mini(760, int(viewport_size.x) - 60), mini(640, int(viewport_size.y) - 120)))


func _process(delta: float) -> void:
	if result_delay <= 0.0: return
	result_delay = maxf(0.0,result_delay-delta)
	if result_delay <= 0.0: _show_result()

func _effect_rect(control: Control) -> Rect2:
	var relative := ui_layer.get_global_transform().affine_inverse()*control.get_global_transform()
	return relative*Rect2(Vector2.ZERO,control.size)

func _play_feedback(skill_id: String = "", enemy_pattern: Dictionary = {}) -> float:
	if attack_vfx == null: return 0.0
	var w := ui_layer.size.x
	var h := ui_layer.size.y
	var area := Rect2(8,8,maxf(1,w-16),maxf(1,h*0.645-8))
	var enemy_point := Vector2(w*0.52,h*0.255)
	var team_point := Vector2(w*0.77,h*0.465)
	var cues: Array = []
	var actor := str(Battle.SKILLS.get(skill_id,{}).get("leader",""))
	if leader_panels.has(actor) and leader_panels[actor].is_visible_in_tree():
		var card_area := _effect_rect(leader_panels[actor])
		cues.append({"kind":"cast","family":"support","origin":card_area.get_center(),"target":card_area.get_center(),"area":card_area,"name":str(Battle.SKILLS[skill_id].name),"primary_op":AttackProfiles.for_skill(skill_id).get("primary_op","")})
	var index := 0
	var reaction_index := -1
	var reaction_cue: Dictionary = {}
	var heavy_hit := false
	var team_hit_index := -1
	var team_hit_cue: Dictionary = {}
	var enemy_max := maxf(1.0,float(state.get("enemy_max",1)))
	for entry: Dictionary in state.get("feedback",[]):
		var cue := entry.duplicate(true)
		var event_skill := str(entry.get("skill",""))
		var source := str(entry.get("source",""))
		var profile: Dictionary = AttackProfiles.for_enemy(enemy_pattern) if source == "enemy" else AttackProfiles.for_skill(event_skill)
		if event_skill.is_empty() and not skill_id.is_empty() and source != "enemy": profile=AttackProfiles.for_skill(skill_id)
		cue.merge(profile,true)
		cue.kind = str(entry.get("kind","buff"))
		cue.side = str(entry.get("target","team"))
		if cue.kind == "enemy_action" and profile.get("primary_op","") == "shield": cue.family="shield"
		if cue.kind == "counter": cue.family="counter"
		if cue.kind in ["poison_tick","poison_add","poison_consume"]: cue.family="poison"
		var to_enemy := str(entry.get("target","team")) == "enemy"
		cue.target = enemy_point if to_enemy else team_point
		cue.target.x += (index%3-1)*minf(44,w*0.025)
		cue.origin = enemy_point if source == "enemy" else Vector2(w*0.5,h*0.62)
		if source != "enemy" and portrait_panels.has(source) and portrait_panels[source].is_visible_in_tree():
			cue.origin = _effect_rect(portrait_panels[source]).get_center()
			cue.origin.y = minf(cue.origin.y,h*0.63)
		if cue.kind == "counter": cue.origin=team_point
		cue.area=area
		var dealt := int(entry.get("amount",0))+int(entry.get("absorbed",0))
		if to_enemy and cue.kind in ["damage","counter","poison_tick"] and dealt > 0:
			# Heavy blows (big share of the foe's life, or a power skill) get hit-stop and shake.
			if cue.kind != "poison_tick" and (dealt >= enemy_max*0.08 or float(cue.get("power",1.0)) >= 1.2):
				cue.heavy = true
				heavy_hit = true
			reaction_index=cues.size()
			reaction_cue=cue
		elif not to_enemy and source == "enemy" and cue.kind == "damage" and int(entry.get("amount",0)) > 0 and team_hit_index < 0:
			team_hit_index=cues.size()
			team_hit_cue=cue
		cues.append(cue)
		index += 1
	if reaction_index >= 0:
		var interval := minf(0.065,0.61/maxf(1,float(cues.size()-1)))
		_pulse_enemy((reaction_index*interval+AttackVfx.impact_phase(reaction_cue)*0.62)*(0.5 if quick_speed else 1.0),heavy_hit)
	if team_hit_index >= 0:
		var team_interval := minf(0.065,0.61/maxf(1,float(cues.size()-1)))
		_flash_team((team_hit_index*team_interval+AttackVfx.impact_phase(team_hit_cue)*0.62)*(0.5 if quick_speed else 1.0))
	return attack_vfx.play(cues,quick_speed)

func _pulse_enemy(delay: float = 0.12, heavy: bool = false) -> void:
	if artwork_reaction != null and artwork_reaction.is_valid(): artwork_reaction.kill()
	enemy_artwork.position=Vector2.ZERO
	enemy_artwork.modulate=Color.WHITE
	ui_layer.position=Vector2.ZERO
	var strength := minf(1.5,ui_layer.size.x/1280.0)
	var speed := 0.5 if quick_speed else 1.0
	artwork_reaction=create_tween()
	artwork_reaction.tween_interval(delay)
	if heavy:
		# Hit-stop: a held white flash, then a decaying shake of the foe and the whole stage.
		artwork_reaction.tween_property(enemy_artwork,"modulate",Color(1.75,1.65,1.5),0.02*speed)
		artwork_reaction.tween_interval(0.07*speed)
		for offset: float in [10.0,-8.0,6.0,-4.0,2.0]:
			artwork_reaction.tween_property(enemy_artwork,"position",Vector2(offset*strength,-absf(offset)*0.3*strength),0.035*speed)
			artwork_reaction.parallel().tween_property(ui_layer,"position",Vector2(0,offset*0.35*strength),0.035*speed)
		artwork_reaction.tween_property(enemy_artwork,"modulate",Color.WHITE,0.14*speed)
		artwork_reaction.parallel().tween_property(enemy_artwork,"position",Vector2.ZERO,0.14*speed)
		artwork_reaction.parallel().tween_property(ui_layer,"position",Vector2.ZERO,0.10*speed)
		return
	artwork_reaction.tween_property(enemy_artwork,"modulate",Color(1.18,1.10,1.04),0.04*speed)
	artwork_reaction.parallel().tween_property(enemy_artwork,"position",Vector2(4*strength,0),0.04*speed)
	artwork_reaction.tween_property(enemy_artwork,"modulate",Color.WHITE,0.16*speed)
	artwork_reaction.parallel().tween_property(enemy_artwork,"position",Vector2.ZERO,0.16*speed)

## A red edge veil and a short jolt when the foe lands a blow on the party.
func _flash_team(delay: float) -> void:
	if hurt_veil == null:
		var gradient := Gradient.new()
		gradient.offsets=PackedFloat32Array([0.0,0.55,1.0])
		gradient.colors=PackedColorArray([Color(0.55,0.06,0.04,0.0),Color(0.55,0.06,0.04,0.0),Color(0.62,0.08,0.05,0.85)])
		var texture := GradientTexture2D.new()
		texture.gradient=gradient
		texture.fill=GradientTexture2D.FILL_RADIAL
		texture.fill_from=Vector2(0.5,0.5); texture.fill_to=Vector2(1.05,1.05)
		hurt_veil=TextureRect.new()
		hurt_veil.texture=texture
		hurt_veil.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		hurt_veil.stretch_mode=TextureRect.STRETCH_SCALE
		hurt_veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
		hurt_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hurt_veil.modulate=Color(1,1,1,0)
		ui_layer.add_child(hurt_veil)
	if hurt_reaction != null and hurt_reaction.is_valid(): hurt_reaction.kill()
	var speed := 0.5 if quick_speed else 1.0
	var strength := minf(1.5,ui_layer.size.x/1280.0)
	hurt_reaction=create_tween()
	hurt_reaction.tween_interval(delay)
	hurt_reaction.tween_property(hurt_veil,"modulate:a",0.75,0.05*speed)
	for offset: float in [-6.0,5.0,-3.0,0.0]:
		hurt_reaction.tween_property(ui_layer,"position",Vector2(offset*strength,0),0.04*speed)
	hurt_reaction.tween_property(hurt_veil,"modulate:a",0.0,0.35*speed)

func _clear_feedback() -> void:
	result_delay=0.0
	if attack_vfx != null: attack_vfx.clear_effects()
	if artwork_reaction != null and artwork_reaction.is_valid(): artwork_reaction.kill()
	if hurt_reaction != null and hurt_reaction.is_valid(): hurt_reaction.kill()
	if hurt_veil != null: hurt_veil.modulate=Color(1,1,1,0)
	if ui_layer != null: ui_layer.position=Vector2.ZERO
	if enemy_artwork != null:
		enemy_artwork.position=Vector2.ZERO
		enemy_artwork.modulate=Color.WHITE

func _finish_feedback(duration: float) -> void:
	if state.status == "playing": return
	result_delay=maxf(0.01,duration)


func _use_skill(id: String) -> void:
	if busy or not skill_buttons.has(id) or not leader_panels[Battle.SKILLS[id].leader].visible:
		return
	if not Battle.action_reason(state,id).is_empty(): return
	state = Battle.act(state, id)
	if state.get("swap_locked", false): selected_front = -1
	_render()
	_finish_feedback(_play_feedback(id))


func request_end_round() -> void:
	if busy or state.status != "playing":
		return
	busy = true
	selected_front = -1
	_render()
	enemy_timer.start()


func _resolve_enemy() -> void:
	if not busy:
		return
	var pattern := Battle.intent(state)
	state = Battle.end_round(state)
	busy = false
	_render()
	_finish_feedback(_play_feedback("",pattern))


func restart_battle() -> void:
	_clear_feedback()
	enemy_timer.stop()
	busy = false
	state = Battle.create_battle()
	_ensure_party_cards()
	result_sent = false
	result_dialog.hide()
	formation_dialog.hide()
	detail_dialog.hide()
	_apply_slots()
	_render()
	skill_buttons.slash.grab_focus()

func setup_battle(config: Dictionary) -> void:
	_clear_feedback()
	expedition_mode = true
	result_sent = false
	busy = false
	selected_front = -1
	if enemy_timer != null:
		enemy_timer.stop()
	state = Battle.create_battle(config)
	if restart_button != null:
		restart_button.hide()
	if result_dialog != null:
		result_dialog.hide()
	if log_dialog != null:
		log_dialog.hide()
	if formation_dialog != null:
		formation_dialog.hide()
	if detail_dialog != null:
		detail_dialog.hide()
	if is_node_ready():
		_ensure_party_cards()
		_apply_slots()
		_render()

func _select_position(index: int) -> void:
	if busy or state.status != "playing" or state.get("swap_locked", false) or not state.has("party_slots"): return
	if index >= int(state.config.get("slot_capacity", 8)): return
	if index < Party.FRONT_SIZE:
		selected_front = index
		_render()
		return
	if selected_front < 0: return
	var reason: String = Battle.swap_reason(state, selected_front, index)
	if not reason.is_empty():
		swap_status.text = reason
		return
	state = Battle.swap_slots(state, selected_front, index)
	selected_front = -1
	_apply_slots()
	_render()

func _apply_slots() -> void:
	empty_slot_panels.clear()
	slot_grid.columns = 4
	for panel: Control in leader_panels.values():
		panel.hide()
		if panel.get_parent() != card_storage: panel.reparent(card_storage,false)
	var occupants: Array = []
	if state.has("party_slots"):
		occupants = state.party_slots.slice(0,4)
	else:
		occupants = state.get("front_team",state.config.get("team",Characters.STARTER_IDS)).slice(0,4)
	while occupants.size() < 4: occupants.append("")
	for index in range(4):
		var id: String = occupants[index]
		var occupied := leader_panels.has(id)
		empty_labels[index].visible = not occupied
		display_slots[index].add_theme_stylebox_override("panel",StyleBoxEmpty.new() if occupied else _box(PaperStyle.PANEL,PaperStyle.BORDER))
		if not occupied:
			empty_slot_panels.append(display_slots[index])
			continue
		var panel: Control = leader_panels[id]
		panel.reparent(display_slots[index],false)
		panel.show()
	for id: String in occupants:
		if not leader_panels.has(id): continue
		var leader: Dictionary = Characters.leader(id)
		skill_buttons[leader.skills[0]].grab_focus()
		break

func cancel_pending() -> void:
	_clear_feedback()
	if enemy_timer != null:
		enemy_timer.stop()
	busy = false


func _update_enemy_artwork() -> void:
	var enemy_id: String = str(state.config.get("enemy_id", "gate_colossus"))
	_update_stage(enemy_id, int(state.config.get("enemy_floor", 1)))
	if enemy_id == displayed_enemy_id: return
	displayed_enemy_id = enemy_id
	# Only catalog IDs are valid resource names; never retain the previous foe.
	var path := "res://art/monsters/" + enemy_id + ".png"
	enemy_artwork.enemy_id = enemy_id
	enemy_artwork.texture = load(path) as Texture2D if enemy_id.is_valid_identifier() and ResourceLoader.exists(path) else null
	enemy_artwork.visible = enemy_artwork.texture != null

## Stage priority: foe-specific painting, dedicated floor painting, legacy backdrop.
func _update_stage(enemy_id: String, floor_number: int) -> void:
	var floor_number_clamped := clampi(floor_number, 1, 5)
	var tint := Color.WHITE
	var path := "res://art/battlefields/%s.png" % enemy_id
	if not (enemy_id.is_valid_identifier() and ResourceLoader.exists(path)):
		path = "res://art/battlefields/floor_%d.png" % floor_number_clamped
		if not ResourceLoader.exists(path):
			path = "res://art/ui/reference_battlefield.png"
			if ResourceLoader.exists("res://art/cinematics/floor_%d.png" % floor_number_clamped):
				path = "res://art/cinematics/floor_%d.png" % floor_number_clamped
				tint = Paper.floor_palette(floor_number_clamped).battle
	if path == displayed_stage: return
	displayed_stage = path
	painted_background.texture = load(path) as Texture2D
	painted_background.modulate = tint


func _render() -> void:
	_update_battle_layout()
	_update_enemy_artwork()
	reserve_button.visible = state.has("party_slots")
	if state.has("party_slots"):
		var locked: bool = busy or state.status != "playing" or state.swap_locked
		swap_status.text = "敌方行动中，不能换位" if busy else ("本回合已行动，全队禁止换位" if state.swap_locked else "先点前台槽，再点后台槽换位；首次成功行动后全队锁定")
		if int(state.config.slot_capacity) < 5: swap_status.text = "后台尚未解锁；第 5—8 槽为后台"
		for i: int in position_buttons:
			var name_text := "空槽"
			for leader: Dictionary in Battle.LEADERS:
				if leader.id == state.party_slots[i]: name_text = "%s%s" % [leader.name, "（已强化）" if Battle.Growth.is_upgraded(state,leader.id) else ""]
			var unlocked: bool = i < int(state.config.slot_capacity)
			position_buttons[i].text = "%s %d%s\n%s" % ["前台" if i < 4 else "后台", (i % 4) + 1, " ✓" if i == selected_front else "", name_text if unlocked else "未解锁"]
			position_buttons[i].disabled = locked or not unlocked or int(state.config.slot_capacity) < 5 or (i >= 4 and selected_front < 0)
	var enemy_title := find_child("EnemyTitle", true, false)
	if enemy_title != null:
		enemy_title.text = state.config.get("enemy_name", "守门巨像")
	round_label.text = "第 %d\n回合" % state.round
	enemy_hp_label.text = "%d / %d" % [state.enemy_hp, state.enemy_max]
	enemy_bar.max_value = state.enemy_max
	enemy_bar.value = state.enemy_hp
	enemy_effects.text = "护甲%d · 毒%d层（%d/轮）· %s" % [state.ward, state.poison, Battle.Attributes.poison_damage(state), "狂怒+30/段" if state.enraged else "未狂怒"]
	enemy_effects.tooltip_text=enemy_effects.text+"\n中毒在敌方行动前结算；狂怒从下一次新预告起提高每段攻击伤害。\n"+Battle.EnemyAI.description(str(state.config.get("enemy_id","")))
	var upcoming: Dictionary = Battle.intent(state)
	intent_label.text = "敌方意图 · %s\n%s" % [upcoming.name, "已被打断，本轮无法行动" if state.interrupted else upcoming.text]
	intent_label.tooltip_text = intent_label.text
	if state.status != "playing":
		intent_label.text = "战斗结束 · " + ("城门已经打开" if state.status == "won" else "部队失去战斗能力")
	team_hp_label.text = "%d / %d" % [state.hp, state.max_hp]
	if state.has("party_slots"):
		team_hp_label.text = "%d / %d" % [state.hp, state.max_hp]
	team_bar.max_value = state.max_hp
	team_bar.value = state.hp
	team_effects.text = Battle.team_status_description(state)
	team_effects.tooltip_text = team_effects.text
	team_effects.visible = team_effects.text != "暂无临时状态"
	enemy_glass.ratio = float(state.enemy_hp)/maxf(1,state.enemy_max)
	ally_glass.ratio = float(state.hp)/maxf(1,state.max_hp)
	ap_label.text = "行动力 %d / %d" % [state.ap, state.max_ap]
	for i in range(ap_pips.size()):
		var lit := i < int(state.ap)
		PaperStyle.style_coin(ap_pips[i],lit)
		ap_pips[i].add_theme_color_override("font_color",GOLD if lit else MUTED)
	_update_defense_button()
	end_turn_button.disabled = busy or state.status != "playing"
	end_turn_button.text = "敌方行动中…" if busy else "结束回合"
	phase_label.text = "敌方行动中" if busy else "我方行动\n每人一次"
	if state.has("party_slots") and not busy: phase_label.text += "\n" + ("换位已锁定" if state.swap_locked else "行动前可换位")
	if state.status != "playing":
		phase_label.text = "远征胜利！可查看记录或重新开始。" if state.status == "won" else "远征失败。可调整策略，再次挑战。"
	for leader_id: String in leader_labels:
		var leader: Dictionary = Characters.leader(leader_id)
		var used: bool = state.used.has(leader_id)
		var waiting: bool = busy or state.status != "playing"
		leader_labels[leader_id].text = "已行动" if used else ("等待" if waiting else "可行动")
		leader_labels[leader_id].add_theme_color_override("font_color",Color("a8aea2") if used or waiting else GOLD)
		PaperStyle.style_card_state(leader_panels[leader_id], used, waiting)
		if passive_labels.has(leader_id):
			passive_labels[leader_id].text = "%s  · 被动" % leader.passive.name
			passive_labels[leader_id].tooltip_text = Battle.passive_description(state,leader_id) + "\n当前状态：" + Battle.passive_status(state,leader_id) + "\n被动自动触发，占第二技能格；点击仅查看详情，不扣AP或消耗动作。"
	for id: String in skill_buttons:
		var skill: Dictionary = Battle.SKILLS[id]
		var reason: String = "敌方行动中" if busy else Battle.action_reason(state, id)
		if reason.is_empty() and not leader_panels[skill.leader].visible: reason = "角色未上阵"
		var button: Button = skill_buttons[id]
		button.disabled = not reason.is_empty()
		var description: String = Battle.skill_description(state, id)
		var usage := "\n费用变化：连续两回合使用此技能，本轮 +1 AP。" if state.get("previous_round_skills", {}).has(id) else ""
		button.text = "%s  %d AP" % [skill.name, Battle.skill_cost(state, id)]
		button.tooltip_text = description + usage + ("\n" + reason if not reason.is_empty() else "")

	full_log.clear()
	for entry: Dictionary in state.log:
		var color: Color = Color("756a59")
		if entry.type in ["attack", "win"]:
			color = Color("8e6939")
		elif entry.type in ["heal", "guard", "poison"]:
			color = Color("356b53")
		elif entry.type == "enemy":
			color = Color("a13e32")
		full_log.append_text("[color=#%s]R%02d  %s[/color]\n" % [color.to_html(false), entry.round, Battle.Professions.text(entry.text)])
	if not state.log.is_empty():
		var last: Dictionary = state.log.back()
		log_view.text = "战斗记录 · " + Battle.Professions.text(str(last.text))
	else:
		log_view.text = ""
	log_view.scroll_to_line(0)
	state_changed.emit(state.duplicate(true))


func _show_result() -> void:
	if state.status == "playing":
		return
	if expedition_mode:
		if not result_sent:
			result_sent = true
			battle_finished.emit(state.duplicate(true))
		return
	result_dialog.title = "远征胜利" if state.status == "won" else "远征失败"
	result_dialog.dialog_text = "%s\n\n经过 %d 回合，队长行动 %d 次。\n部队剩余 %d HP，护盾累计抵挡 %d 伤害。" % ["守门巨像倒下，通往迷雾的道路已开启。" if state.status == "won" else "队伍暂时撤退。观察敌方预告，尝试新的技能组合。", state.round, state.actions, state.hp, state.blocked]
	result_dialog.popup_centered(Vector2i(560, 220))

func _toggle_formation() -> void:
	if formation_dialog.visible:
		formation_dialog.hide()
	else:
		formation_dialog.popup_centered(Vector2i(mini(720, int(get_viewport_rect().size.x) - 40), 270))



func _show_log() -> void:
	log_dialog.popup_centered(Vector2i(mini(780,int(get_viewport_rect().size.x)-60),mini(520,int(get_viewport_rect().size.y)-60)))












func handle_right_click() -> void:
	request_end_round()

func _cancel_formation_selection() -> void:
	selected_front = -1
	_render()



func _preview_skill(id:String)->void:
	if busy or state.status!="playing":return
	_show_preview(Preview.skill(state,id))
func _preview_end_turn()->void:
	if busy or state.status!="playing":return
	_show_preview(Preview.end_turn(state),true)
func _show_preview(value:Dictionary,ending:bool=false)->void:
	if value.is_empty():return
	var after:Dictionary=value.after
	intent_label.text=Preview.describe(value,ending)
	enemy_hp_label.text="HP  %d → %d / %d"%[state.enemy_hp,after.enemy_hp,state.enemy_max]
	team_hp_label.text="HP  %d → %d / %d"%[state.hp,after.hp,state.max_hp]
	enemy_glass.ratio=float(after.enemy_hp)/maxf(1,state.enemy_max)
	ally_glass.ratio=float(after.hp)/maxf(1,state.max_hp)
func _clear_preview()->void:
	if enemy_hp_label==null or state.is_empty():return
	enemy_hp_label.text="%d / %d"%[state.enemy_hp,state.enemy_max]
	team_hp_label.text="%d / %d"%[state.hp,state.max_hp]
	enemy_glass.ratio=float(state.enemy_hp)/maxf(1,state.enemy_max)
	ally_glass.ratio=float(state.hp)/maxf(1,state.max_hp)
	ap_label.text="AP  %d / %d"%[state.ap,state.max_ap]
	var upcoming:Dictionary=Battle.intent(state)
	intent_label.text="敌方预告 · %s   /   %s"%[upcoming.name,"已被打断，本轮无法行动" if state.interrupted else upcoming.text]
	if state.status!="playing":intent_label.text="战斗结束"
