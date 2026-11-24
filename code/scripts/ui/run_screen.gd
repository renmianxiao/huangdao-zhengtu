extends Control

const Cinematics=preload("res://code/scripts/cinematics/catalog.gd")
const CinematicPlayer=preload("res://code/scripts/ui/floor_cinematic.gd")
const DialogSkin = preload("res://code/scripts/ui/dialog_skin.gd")
const Camp = preload("res://code/scripts/run/camp_rules.gd")
const Run = preload("res://code/scripts/run/run_rules.gd")
const Nodes = preload("res://code/scripts/run/node_rules.gd")
const Catalog = preload("res://code/scripts/run/run_catalog.gd")
const Map = preload("res://code/scripts/run/map_generator.gd")
const BattleScene = preload("res://code/scenes/battle_screen.tscn")
const Battle = preload("res://code/scripts/battle.gd")
const Party = preload("res://code/scripts/party.gd")
const Progress = preload("res://code/scripts/run/progression.gd")
const Characters = preload("res://code/scripts/characters/character_catalog.gd")
const Saves = preload("res://code/scripts/run/save_store.gd")
const PaperStyle=preload("res://code/scripts/ui/global_theme.gd")
const Attributes=preload("res://code/scripts/combat/attributes.gd")
const Numbers=preload("res://code/scripts/number_text.gd")
const Professions=preload("res://code/scripts/profession_names.gd")
const Growth=preload("res://code/scripts/characters/character_growth.gd")
const SummonScene=preload("res://code/scripts/ui/summon_screen.gd")
const LootScene=preload("res://code/scripts/ui/loot_screen.gd")
const Opening=preload("res://code/scripts/run/opening_rules.gd")
const OpeningScene=preload("res://code/scripts/ui/opening_screen.gd")
const FormationScene=preload("res://code/scripts/ui/formation_screen.gd")
const RelicScene=preload("res://code/scripts/ui/relic_screen.gd")
const RelicCatalog=preload("res://code/scripts/relics/relic_catalog.gd")
const Encyclopedia=preload("res://code/scripts/ui/encyclopedia_screen.gd")
const Discoveries=preload("res://code/scripts/encyclopedia/profile.gd")
const CLASSES := ["刺客型", "战士型", "盾牌型", "奶妈型", "法师型", "辅助型"]

@export var start_at_menu := true
var save_directory := Saves.ROOT
var active_slot := -1
var menu_mode := ""
var pending_new_slot := -1
var slot_buttons: Dictionary = {}
var delete_buttons: Dictionary = {}
var pending_delete_slot := -1
var delete_confirm: ConfirmationDialog
var save_notice: AcceptDialog
var exit_confirm: ConfirmationDialog
var run_state: Dictionary
var node_buttons: Dictionary = {}
var map_view: Control
var battle_view: Control
var summon_view: Control
var loot_view: Control
var opening_view: Control
var initial_formation_view: Control
var body: Control
var header: Label
var header_frame: PanelContainer
var page_margin: MarginContainer
var confirm: ConfirmationDialog
var generation := 0
var member_buttons: Dictionary = {}
var recruit_buttons: Dictionary = {}
var upgrade_buttons: Dictionary = {}
var progression_summary: Label
var formation_slots: Array[Button] = []
var confirm_team_button: Button
var selected_front_slot := -1
var formation_from_map := false
var formation_slot_mode := "new"
var class_filter: OptionButton
var selected_class := ""
var detail_buttons: Dictionary = {}
var detail_dialog: AcceptDialog
var detail_text: RichTextLabel
var detail_artwork: TextureRect
var relic_dialog: AcceptDialog
var relic_view: Control
var relic_button: Button
var battle_relic_button: Button
var music_dialog: AcceptDialog
var music_controls: Control
var floor_cinematic: Control
var legacy_cinematic_floor := -1
var encyclopedia_directory := Discoveries.ROOT
var encyclopedia_history: Dictionary = Discoveries.empty()
var encyclopedia_notice := ""
var encyclopedia_dirty := false
var encyclopedia_view: Control
var encyclopedia_focus: Control
var encyclopedia_blocked_battle := false
var expedition_menu: AcceptDialog
var discovery_status: Label
var paper_view: Control

func _ready() -> void:
	add_to_group("right_click_navigation")
	var discoveries:=Discoveries.load_profile(encyclopedia_directory)
	encyclopedia_history=discoveries.data
	encyclopedia_notice=discoveries.message
	get_window().min_size = Vector2i(900, 650)
	theme=PaperStyle.make(17)
	var paper=preload("res://code/scripts/ui/paper_backdrop.gd").new()
	paper_view=paper
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(paper)
	var frame := MarginContainer.new()
	page_margin=frame
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		frame.add_theme_constant_override("margin_" + side, 20)
	add_child(frame)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	frame.add_child(column)
	header_frame = PanelContainer.new()
	header_frame.theme=PaperStyle.make_dark(18)
	header_frame.add_theme_stylebox_override("panel",PaperStyle.panel_style(true))
	column.add_child(header_frame)
	var top := HBoxContainer.new()
	header_frame.add_child(top)
	header = Label.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.custom_minimum_size.x = 100
	header.add_theme_font_size_override("font_size", 20)
	top.add_child(header)
	var menu_button := button(top, "菜单", _show_expedition_menu)
	menu_button.custom_minimum_size.x = 80
	menu_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	relic_button = button(top,"藏品 0",_show_relics)
	relic_button.custom_minimum_size.x = 100
	relic_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	body = Control.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	confirm = ConfirmationDialog.new()
	confirm.title = "开始新远征"
	confirm.confirmed.connect(_confirm_new_slot)
	confirm.canceled.connect(func(): pending_new_slot = -1)
	add_child(confirm)
	delete_confirm = ConfirmationDialog.new()
	delete_confirm.title = "删除存档"
	delete_confirm.get_ok_button().text = "删除存档"
	delete_confirm.get_cancel_button().text = "取消"
	delete_confirm.confirmed.connect(_confirm_delete_slot)
	delete_confirm.canceled.connect(func(): pending_delete_slot = -1)
	add_child(delete_confirm)
	detail_dialog = AcceptDialog.new()
	detail_dialog.title = "角色详情"
	detail_dialog.get_ok_button().text = "返回编队"
	var detail_row := HBoxContainer.new()
	detail_row.add_theme_constant_override("separation",24)
	detail_dialog.add_child(detail_row)
	detail_artwork = TextureRect.new()
	detail_artwork.custom_minimum_size = Vector2(170,220)
	detail_artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_row.add_child(detail_artwork)
	detail_text = RichTextLabel.new()
	detail_text.custom_minimum_size = Vector2(300, 220)
	detail_text.scroll_active = true
	detail_text.selection_enabled = true
	detail_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_row.add_child(detail_text)
	add_child(detail_dialog)
	relic_dialog = AcceptDialog.new()
	relic_dialog.title = "藏品图鉴"
	relic_dialog.exclusive = true
	relic_dialog.get_ok_button().text = "返回"
	relic_dialog.close_requested.connect(relic_dialog.hide)
	relic_dialog.window_input.connect(_relic_input)
	relic_view = RelicScene.new()
	relic_view.custom_minimum_size = Vector2(630,390)
	relic_dialog.add_child(relic_view)
	add_child(relic_dialog)
	save_notice = AcceptDialog.new()
	save_notice.title = "存档提示"
	add_child(save_notice)
	exit_confirm = ConfirmationDialog.new()
	exit_confirm.title = "退出战斗"
	exit_confirm.dialog_text = "本场战斗进度不会保存；下次读取将回到战前状态。仍要退出？"
	exit_confirm.confirmed.connect(_exit_now)
	add_child(exit_confirm)
	confirm.get_ok_button().text = "开始新远征"
	confirm.get_cancel_button().text = "取消"
	exit_confirm.get_ok_button().text = "退出战斗"
	exit_confirm.get_cancel_button().text = "继续战斗"
	save_notice.get_ok_button().text = "知道了"
	for pair: Array in [[confirm,"confirm"],[delete_confirm,"confirm"],[detail_dialog,"detail"],[relic_dialog,"relic"],[save_notice,"info"],[exit_confirm,"confirm"]]:
		DialogSkin.apply(pair[0],pair[1])
	music_dialog=AcceptDialog.new()
	music_dialog.title="音乐设置";music_dialog.get_ok_button().text="返回"
	music_controls=preload("res://code/scripts/ui/audio_controls.gd").new()
	music_dialog.add_child(music_controls);add_child(music_dialog)
	music_controls.setup(Music,"背景音乐")
	DialogSkin.apply(music_dialog,"info")
	expedition_menu=AcceptDialog.new()
	expedition_menu.title="远征菜单";expedition_menu.exclusive=true;expedition_menu.get_ok_button().text="继续远征"
	var expedition_options:=VBoxContainer.new();expedition_options.add_theme_constant_override("separation",10);expedition_menu.add_child(expedition_options)
	button(expedition_options,"江湖见闻录 · 图鉴",_show_encyclopedia)
	button(expedition_options,"本局藏品",func():expedition_menu.hide();_show_relics())
	button(expedition_options,"返回主菜单",func():expedition_menu.hide();_return_to_menu())
	add_child(expedition_menu);DialogSkin.apply(expedition_menu,"menu")
	discovery_status=Label.new()
	discovery_status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	discovery_status.offset_left=26;discovery_status.offset_right=-26;discovery_status.offset_top=-76;discovery_status.offset_bottom=-18
	discovery_status.z_index=125;discovery_status.mouse_filter=Control.MOUSE_FILTER_IGNORE
	discovery_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;discovery_status.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	discovery_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	discovery_status.add_theme_stylebox_override("normal",PaperStyle.box(PaperStyle.PANEL,PaperStyle.RED))
	discovery_status.add_theme_color_override("font_color",PaperStyle.RED)
	add_child(discovery_status);_update_discovery_notice()
	get_tree().auto_accept_quit = false
	get_window().close_requested.connect(_request_exit)
	new_run(int(Time.get_ticks_usec() & 0x7fffffff))
	if start_at_menu: _show_main_menu()

func button(parent: Node, title: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = title
	b.custom_minimum_size = Vector2(135, 48)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.size_flags_vertical = Control.SIZE_FILL
	if title.begins_with("确认阵容") or title in ["开始新局","接受"]: PaperStyle.primary(b)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func label(parent: Node, value: String, size: int = 17) -> Label:
	var l := Label.new()
	l.text = value
	if not parent is HBoxContainer:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 1
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l

func _process(delta: float) -> void:
	_tick_run_time(delta)

func _tick_run_time(delta: float) -> void:
	if run_state.is_empty() or not menu_mode.is_empty(): return
	if run_state.phase in ["lost","abandoned"] or (run_state.phase == "won" and run_state.get("loot_resolved",false)): return
	run_state.run_seconds = float(run_state.get("run_seconds",0.0)) + maxf(0.0,delta)

func new_run(seed: int) -> void:
	formation_from_map = false
	generation += 1
	menu_mode = ""
	selected_front_slot = -1
	selected_class = ""
	run_state = Run.create_opening_run(seed)
	run_state.cinematic_floor = 0
	legacy_cinematic_floor = -1
	run_state.formation_origin = "slots"
	_render()

func _clear() -> void:
	_close_encyclopedia()
	_stop_cinematic()
	if is_instance_valid(relic_dialog): relic_dialog.hide()
	battle_relic_button = null
	map_view = null
	summon_view = null
	loot_view = null
	opening_view = null
	initial_formation_view = null
	if battle_view != null:
		battle_view.cancel_pending()
		battle_view = null
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	node_buttons.clear()
	member_buttons.clear()
	recruit_buttons.clear()
	upgrade_buttons.clear()
	detail_buttons.clear()
	class_filter = null
	progression_summary = null
	formation_slots.clear()

func _render(skip_save: bool = false) -> void:
	_record_discoveries(Discoveries.observe(encyclopedia_history,run_state))
	Music.for_phase("menu" if not menu_mode.is_empty() else str(run_state.phase),str(Run.current_node(run_state).get("type","")))
	if not skip_save and menu_mode.is_empty() and run_state.phase != "battle": _autosave()
	_clear()
	for side in ["left","right","top","bottom"]:
		page_margin.add_theme_constant_override("margin_"+side,0 if run_state.phase in ["battle","map"] else 20)
	_update_header()
	header.get_parent().visible = not run_state.phase in ["battle", "map"] and not (run_state.phase in ["reward","won"] and not bool(run_state.get("loot_resolved",false)))
	if run_state.phase in ["opening","formation"]: header.get_parent().hide()
	if run_state.phase == "node" and Run.current_node(run_state).get("type","") in ["shop","camp","event"]: header.get_parent().hide()
	header_frame.visible = header.get_parent().visible
	var node_type: String = str(Run.current_node(run_state).get("type","")) if run_state.phase == "node" else ""
	if node_type in ["shop","camp","event"]:
		var event_id := str(run_state.get("node_state",{}).get("event",""))
		var category := str(preload("res://code/scripts/run/event_catalog.gd").EVENTS.get(event_id,{}).get("category",""))
		paper_view.scene = load(preload("res://code/scripts/ui/scene_art.gd").backdrop(node_type,Run.map_floor(run_state),event_id,category))
	else: paper_view.scene = null
	if run_state.phase in ["reward", "won"] and not bool(run_state.get("loot_resolved",false)):
		if bool(run_state.get("summon_active",false)): _show_summon()
		else: _show_loot()
		return
	match run_state.phase:
		"opening":
			if run_state.summon_active: _show_summon()
			else: _show_opening()
		"formation": _show_formation()
		"map": _show_map()
		"battle": _show_battle()
		"reward": _show_reward()
		"node": _show_node()
		"won", "lost", "abandoned": _show_result()

func _update_header(live_hp: int = -1, live_max_hp: int = -1) -> void:
	relic_button.text = "藏品 %d" % RelicCatalog.ids(run_state).size()
	var shown_floor: int = Run.map_floor(run_state)
	var floor_text := "第 %d/%d 层 · 起点" % [shown_floor, Map.FLOOR_COUNT]
	if not run_state.current_node.is_empty() and Run.current_node(run_state).floor == shown_floor:
		floor_text = "第 %d/%d 层 · 节点 %d/%d" % [shown_floor, Map.FLOOR_COUNT, Run.current_node(run_state).floor_row, Map.ROWS_PER_FLOOR]
	var upgrades: Array[String] = []
	for key: String in run_state.upgrades:
		var display: String = {"attack": "攻击", "shield": "护盾", "heal": "治疗", "initial_ap": "初始 AP", "slash": "迅捷斩", "burst": "破晓剑", "shot": "穿云箭", "toxin": "淬毒箭", "break": "盾击"}.get(key, key)
		if Characters.SKILLS.has(key): display = Characters.SKILLS[key].name
		var bonus: String=str(run_state.upgrades[key])
		if key in ["attack","shield","heal"]: bonus="%s%%" % Numbers.integer(float(run_state.upgrades[key]) * 10 / (15 if key=="attack" else 20))
		elif Characters.SKILLS.has(key): bonus="%s%% 攻击/治疗基准 / +%s%% 生命基准" % [Numbers.integer(float(run_state.upgrades[key])),Numbers.integer(float(run_state.upgrades[key])/3.0)]
		upgrades.append("%s +%s" % [display,bonus])
	var experience_text := "%d/%d" % [run_state.experience, Progress.xp_to_next(int(run_state.level))] if run_state.level < Progress.MAX_LEVEL else "满级 · 累计 %d" % run_state.total_experience
	header.tooltip_text = "召集令在本次战后或营地立即使用，不留存。"
	header.text = "黄道征途  ·  %s  ·  HP %d/%d  ·  金币 %d\n队伍 %d/%d 槽  ·  等级 %d  ·  经验 %s  ·  声望 %d\n角色强化：%d 人  ·  通用强化：%s" % [floor_text, run_state.hp if live_hp < 0 else live_hp, run_state.max_hp if live_max_hp < 0 else live_max_hp, run_state.gold, run_state.team.size(), run_state.slot_capacity, run_state.level, experience_text, run_state.renown, run_state.character_upgrades.size(), "、".join(upgrades) if not upgrades.is_empty() else "无"]

func _progression_text() -> String:
	var gain: Dictionary = run_state.last_progression
	if gain.is_empty(): return ""
	var parts: Array[String] = ["本场经验 +%d" % gain.experience]
	if gain.to_level > gain.from_level:
		parts.append("等级 %d → %d" % [gain.from_level, gain.to_level])
		parts.append("声望 +%d" % gain.renown)
	if gain.slots > 0: parts.append("卡槽 +%d" % gain.slots)
	return " · ".join(parts)

func _show_opening() -> void:
	opening_view=OpeningScene.new()
	opening_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.add_child(opening_view)
	opening_view.configure(run_state)
	opening_view.confirmed.connect(func(id:String):_apply(Run.choose_opening_bundle(run_state,id)))
	opening_view.canceled.connect(_return_to_menu)

func _show_formation() -> void:
	_show_initial_formation()

func _show_initial_formation() -> void:
	initial_formation_view = FormationScene.new()
	initial_formation_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.add_child(initial_formation_view)
	initial_formation_view.configure(run_state)
	initial_formation_view.placement_requested.connect(_place_formation_member)
	initial_formation_view.confirmed.connect(_confirm_formation)
	initial_formation_view.canceled.connect(handle_right_click)
	member_buttons = initial_formation_view.member_buttons.duplicate()
	detail_buttons = initial_formation_view.detail_buttons.duplicate()
	formation_slots = initial_formation_view.formation_slots.duplicate()
	confirm_team_button = initial_formation_view.confirm_button

func _place_formation_member(id: String, target: int) -> void:
	var next: Dictionary = Run.place_formation_member(run_state,id,target)
	if next == run_state: return
	run_state = next
	_autosave()
	initial_formation_view.configure(run_state)

func _character_row(parent: Node) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	return row

func _select_order(category: String) -> void:
	selected_class = category
	_render()
	class_filter.grab_focus()

func _filter_class(index: int) -> void:
	var scroll_position: int = body.get_child(0).scroll_vertical
	selected_class = "" if index == 0 else CLASSES[index - 1]
	_render()
	body.get_child(0).set_deferred("scroll_vertical", scroll_position)
	class_filter.grab_focus()

func _character_description(id: String) -> String:
	var leader: Dictionary = Characters.leader(id)
	if leader.is_empty(): return ""
	var parts: Array[String] = ["%s\n%s · 攻击 %s · 血量 %s · 招募 %d 声望" % [leader.name, Professions.label(leader["class"]), Attributes.display(Attributes.stats(run_state,id).attack), Attributes.display(Attributes.stats(run_state,id).max_hp), Run.recruit_cost(run_state,id)]]
	parts.append("本局强化：已强化，攻击与血量 +20%，不能再次强化。" if Growth.is_upgraded(run_state,id) else "本局强化：尚未强化；消耗本职业召集令和 %d 声望，攻击与血量 +20%%，每人限一次。" % Run.upgrade_cost(run_state,id))
	if not leader.positioning.is_empty(): parts.append(leader.positioning)
	if not leader.tags.is_empty(): parts.append("定位：" + " / ".join(leader.tags))
	for skill_id: String in leader.skills:
		var skill: Dictionary = Characters.SKILLS[skill_id]
		parts.append("主动 · %s（基础 %d AP）\n%s" % [skill.name, skill.cost, skill.text])
		if not str(skill.get("rules", "")).is_empty(): parts.append(str(skill.rules))
	var passive: Dictionary = leader.passive
	if not passive.is_empty(): parts.append("被动 · %s（仅前台生效）\n%s" % [passive.name, passive.text])
	if not leader.synergy.is_empty(): parts.append("搭配\n" + leader.synergy)
	if not leader.caution.is_empty(): parts.append("短板\n" + leader.caution)
	return Professions.text(Numbers.description("\n\n".join(parts)))

func _show_character_detail(id: String) -> void:
	detail_dialog.get_ok_button().text = "返回结算" if run_state.phase in ["won","lost","abandoned"] else "返回编队"
	var leader: Dictionary = Characters.leader(id)
	if leader.is_empty(): return
	detail_artwork.texture = load("res://art/characters/"+id+".png")
	detail_dialog.title = leader.name
	detail_text.text = _character_description(id)
	detail_text.scroll_to_line(0)
	var viewport_size := get_viewport_rect().size
	detail_dialog.popup_centered(Vector2i(mini(760, int(viewport_size.x) - 60), mini(640, int(viewport_size.y) - 120)))

func _toggle_member(id: String) -> void:
	selected_front_slot = -1
	_apply(Run.toggle_member(run_state, id))
	if member_buttons.has(id): member_buttons[id].grab_focus()

func _recruit(id: String) -> void:
	_apply(Run.recruit(run_state, id))
	if member_buttons.has(id): member_buttons[id].grab_focus()

func _upgrade_character(id: String) -> void:
	_apply(Run.upgrade_character(run_state,id))

func _confirm_formation() -> void:
	selected_front_slot = -1
	_apply(Run.confirm_team(run_state))

func _select_formation_slot(index: int) -> void:
	if run_state.phase != "formation" or index >= run_state.slot_capacity: return
	if index < 4:
		selected_front_slot = index
		_render()
	elif selected_front_slot >= 0:
		var next: Dictionary = Run.swap_formation_slots(run_state, selected_front_slot, index)
		selected_front_slot = -1
		_apply(next)

func _column() -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_theme_stylebox_override("panel", PaperStyle.box(PaperStyle.PANEL))
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	return content

func _show_map() -> void:
	formation_from_map = true
	map_view = preload("res://code/scripts/ui/map_view.gd").new()
	map_view.setup(run_state)
	map_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.add_child(map_view)
	map_view.entered.connect(_node_click)
	map_view.formation_requested.connect(func(): _apply(Run.open_formation(run_state)))
	map_view.menu_requested.connect(_show_expedition_menu)
	map_view.relic_requested.connect(_show_relics)
	node_buttons = map_view.node_buttons
	_maybe_show_cinematic()

func _stop_cinematic() -> void:
	if not is_instance_valid(floor_cinematic): return
	var view := floor_cinematic
	floor_cinematic = null
	view.cancel()
	if view.get_parent()!=null: view.get_parent().remove_child(view)
	view.queue_free()

func _maybe_show_cinematic() -> void:
	var candidate := run_state
	if not run_state.has("cinematic_floor"):
		if legacy_cinematic_floor<0: legacy_cinematic_floor=Run.map_floor(run_state)
		candidate=run_state.duplicate(true)
		candidate.cinematic_floor=legacy_cinematic_floor
	var floor_number := Cinematics.pending_floor(candidate)
	if floor_number==0: return
	var before := run_state
	run_state=Cinematics.acknowledge(candidate)
	if not _autosave():
		run_state=before
		return
	floor_cinematic=CinematicPlayer.new()
	floor_cinematic.setup(floor_number)
	floor_cinematic.z_index=100
	floor_cinematic.finished.connect(func(_skipped): _stop_cinematic())
	add_child(floor_cinematic)

func _node_click(id: String) -> void:
	var next: Dictionary = Run.enter_node(run_state, id)
	if next == run_state:
		return
	if next.phase == "battle" and not _autosave(): return
	run_state = Nodes.prepare(next)
	_render()

func _show_battle() -> void:
	battle_view = BattleScene.instantiate()
	battle_view.content_inset = 0
	battle_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_view.setup_battle(run_state.encounter.config)
	body.add_child(battle_view)
	for child in battle_view.battle_menu.get_children():
		if child is VBoxContainer:
			battle_relic_button = button(child,"查看藏品",func(): battle_view.battle_menu.hide(); _show_relics())
			button(child,"江湖见闻录 · 图鉴",_show_encyclopedia)
			break
	var current_generation := generation
	battle_view.state_changed.connect(func(result: Dictionary):
		if current_generation == generation and run_state.phase == "battle":
			_update_header(int(result.hp), int(result.max_hp))
	)
	battle_view.battle_finished.connect(func(result: Dictionary):
		if current_generation == generation:
			_on_battle_finished(result)
	)

func _on_battle_finished(result: Dictionary) -> void:
	if run_state.phase != "battle": return
	_record_discoveries(Discoveries.mark_battle(encyclopedia_history,str(run_state.encounter.config.get("enemy_id","")),result.get("status","")=="won"))
	run_state = Nodes.prepare(Run.finish_battle(run_state, result))
	_render()

func _drop_banner(parent: Control) -> void:
	var banner := preload("res://code/scripts/ui/relic_drop_banner.gd").new()
	parent.add_child(banner)
	banner.configure(run_state)

func _show_reward() -> void:
	_show_loot()

func _show_loot() -> void:
	loot_view = LootScene.new()
	loot_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.add_child(loot_view)
	loot_view.configure(run_state)
	loot_view.claimed.connect(func(id: String): _apply(Run.claim_loot(run_state,id)))
	loot_view.direct_claimed.connect(func(): _apply(Run.claim_direct_loot(run_state)))
	loot_view.left.connect(func(): _apply(Run.leave_loot(run_state)))
	progression_summary = loot_view.progression_summary

func _continue_after_battle() -> void:
	_apply(Run.leave_loot(run_state))

func _show_node() -> void:
	var node: Dictionary = Run.current_node(run_state)
	if node.type == "shop":
		var shop := preload("res://code/scripts/ui/relic_shop_screen.gd").new()
		shop.name = "RelicShop"
		shop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		body.add_child(shop)
		shop.configure(run_state)
		shop.relic_bought.connect(func(index: int, id: String): _apply(Nodes.buy_relic(run_state,index,id)))
		shop.service_bought.connect(func(id: String): _apply(Nodes.buy(run_state,id)))
		shop.left.connect(func(): _apply(Nodes.leave_shop(run_state)))
		shop.relic_view_requested.connect(_show_relics)
		shop.menu_requested.connect(_return_to_menu)
		return
	if node.type == "camp":
		if Camp.free_upgrade_active(run_state) or Camp.orders_active(run_state):
			_show_summon()
		else:
			var camp := preload("res://code/scripts/ui/camp_screen.gd").new()
			camp.name = "Camp"
			camp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			body.add_child(camp)
			camp.configure(run_state)
			camp.chosen.connect(func(action: String): _apply(Nodes.choose_camp(run_state,action)))
			camp.menu_requested.connect(_return_to_menu)
		return
	if node.type == "event":
		var event := preload("res://code/scripts/ui/event_screen.gd").new()
		event.name = "Event"
		event.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		body.add_child(event)
		event.configure(run_state)
		event.chosen.connect(_choose_event)
		event.menu_requested.connect(_return_to_menu)
		return
	var content := _column()
	label(content, "第 %d 层 · 节点 %d/%d · %s" % [node.floor, node.floor_row, Map.ROWS_PER_FLOOR, Catalog.NODE_NAMES[node.type]], 26)

func _apply(next: Dictionary) -> void:
	if next == run_state: return
	run_state = next
	_render()

func _show_result() -> void:
	header.get_parent().hide()
	header_frame.hide()
	var summary = preload("res://code/scripts/ui/run_summary_screen.gd").new()
	summary.name = "RunSummary"
	summary.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.add_child(summary)
	summary.configure(run_state)
	summary.character_requested.connect(func(id: String):
		detail_dialog.get_ok_button().text = "返回结算"
		_show_character_detail(id))
	summary.relic_requested.connect(func(id: String):
		_show_relics()
		relic_view.select_relic(id))
	summary.new_requested.connect(func(): _show_slots("new"))
	summary.menu_requested.connect(_return_to_menu)

func _show_summon() -> void:
	summon_view = SummonScene.new()
	summon_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.add_child(summon_view)
	summon_view.configure(run_state)
	summon_view.confirmed.connect(_confirm_summon)
	summon_view.canceled.connect(_cancel_summon)
	for id: String in summon_view.card_buttons:
		if run_state.roster.has(id): upgrade_buttons[id] = summon_view.card_buttons[id]
		else: recruit_buttons[id] = summon_view.card_buttons[id]

func _cancel_summon() -> void:
	if Opening.recruiting(run_state):
		if run_state.opening.index==0:_apply(Opening.back(run_state))
		else:_return_to_menu()
		return
	if Camp.free_upgrade_active(run_state): _apply(Nodes.choose_camp(run_state,"back"))
	else: _apply(Run.skip_recruit_order(run_state))

func _confirm_summon(id: String) -> void:
	if run_state.roster.has(id): _upgrade_character(id)
	else: _recruit(id)



func _autosave() -> bool:
	if active_slot < 1 or not menu_mode.is_empty() or run_state.phase == "battle": return true
	var result := Saves.write(active_slot,run_state,save_directory)
	if not result.ok:
		save_notice.dialog_text = "保存失败：%s。旧存档保持不变，请重试。" % result.message
		save_notice.popup_centered(Vector2i(560,180))
	return bool(result.ok)

func _menu_panel(width: float) -> VBoxContainer:
	var center:=CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.add_child(center)
	var panel:=PanelContainer.new()
	panel.custom_minimum_size.x=width
	var style:=PaperStyle.box(PaperStyle.PANEL)
	style.content_margin_left=30; style.content_margin_right=30
	style.content_margin_top=28; style.content_margin_bottom=28
	panel.add_theme_stylebox_override("panel",style)
	center.add_child(panel)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",16)
	panel.add_child(column)
	return column

func _show_main_menu() -> void:
	pending_delete_slot = -1
	delete_confirm.hide()
	Music.request_track("menu")
	menu_mode = "main"
	generation += 1
	_clear()
	paper_view.scene = null
	detail_dialog.hide()
	header.get_parent().hide()
	header_frame.hide()
	for side in ["left","right","top","bottom"]:page_margin.add_theme_constant_override("margin_"+side,0)
	var scenery:=preload("res://code/scripts/ui/menu_backdrop.gd").new()
	scenery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);body.add_child(scenery)
	var menu_area:=MarginContainer.new();menu_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_area.anchor_right=0.47
	menu_area.add_theme_constant_override("margin_left",48);menu_area.add_theme_constant_override("margin_right",24)
	menu_area.add_theme_constant_override("margin_top",40);menu_area.add_theme_constant_override("margin_bottom",40)
	menu_area.theme=PaperStyle.make_dark(20);body.add_child(menu_area)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",14);menu_area.add_child(content)
	var game_title:=label(content,"黄道征途",52);game_title.add_theme_font_override("font",PaperStyle.title_font());game_title.add_theme_color_override("font_color",PaperStyle.DARK_TEXT)
	var subtitle:=label(content,"越山河，赴征途",20);subtitle.add_theme_color_override("font_color",PaperStyle.DARK_MUTED)
	var gap:=Control.new();gap.custom_minimum_size.y=20;content.add_child(gap)
	var start_button:=preload("res://code/scripts/ui/map_enter_button.gd").new()
	start_button.text="开始新局"
	start_button.custom_minimum_size=Vector2(0,60)
	content.add_child(start_button)
	start_button.pressed.connect(func(): _show_slots("new"))
	button(content,"读取存档",func(): _show_slots("load"))
	button(content,"江湖见闻录 · 图鉴",_show_encyclopedia)
	button(content,"音乐设置",_show_music_settings)
	button(content,"退出游戏",_request_exit)

func _show_music_settings() -> void:
	music_dialog.popup_centered(Vector2i(420,230))

func _return_to_menu() -> bool:
	if run_state.phase == "battle": return false
	if not _autosave():
		if is_instance_valid(summon_view): summon_view.resume_offer()
		if is_instance_valid(initial_formation_view): initial_formation_view.resume_selection()
		return false
	_show_main_menu()
	return true

func _show_slots(mode: String) -> void:
	pending_delete_slot = -1
	delete_confirm.hide()
	Music.request_track("menu")
	formation_slot_mode = mode
	menu_mode = mode
	_clear()
	header.get_parent().hide()
	header_frame.hide()
	slot_buttons.clear()
	delete_buttons.clear()
	paper_view.scene = null
	for side in ["left", "right", "top", "bottom"]: page_margin.add_theme_constant_override("margin_" + side, 0)
	var entries: Array = []
	for slot in range(1, 4):
		entries.append({"slot": slot, "result": Saves.load_slot(slot, save_directory), "has_files": Saves.has_files(slot, save_directory)})
	var view = preload("res://code/scripts/ui/save_slot_screen.gd").new()
	view.name = "SaveSlotScreen"
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.add_child(view)
	view.slot_selected.connect(_select_slot)
	view.delete_requested.connect(_request_delete_slot)
	view.back_requested.connect(_show_main_menu)
	view.configure(mode, entries)
	slot_buttons = view.slot_buttons
	delete_buttons = view.delete_buttons

func _request_delete_slot(slot: int) -> void:
	if menu_mode != "load" or not Saves.has_files(slot,save_directory): return
	pending_delete_slot = slot
	delete_confirm.title = "删除存档 %d" % slot
	delete_confirm.dialog_text = "确定删除存档 %d？\n此槽位的远征进度及备份将被永久删除，无法恢复。" % slot
	delete_confirm.popup_centered(Vector2i(560,220))

func _confirm_delete_slot() -> void:
	var slot := pending_delete_slot
	pending_delete_slot = -1
	if menu_mode != "load" or not slot in [1,2,3]: return
	var result := Saves.delete_slot(slot,save_directory)
	if result.ok and active_slot == slot: active_slot = -1
	_show_slots("load")
	if not result.ok:
		save_notice.dialog_text = "删除失败：%s" % result.message
		save_notice.popup_centered(Vector2i(560,180))

func _select_slot(slot: int) -> void:
	if not slot in [1,2,3]: return
	if menu_mode == "load":
		_load_slot(slot)
	elif menu_mode == "new":
		pending_new_slot = slot
		if Saves.occupied(slot,save_directory):
			confirm.title = "覆盖存档 %d" % slot
			confirm.dialog_text = "此槽已有存档。开启新局将覆盖它，是否继续？"
			confirm.popup_centered(Vector2i(520,180))
		else: _confirm_new_slot()

func _confirm_new_slot() -> void:
	if not pending_new_slot in [1,2,3]: return
	active_slot = pending_new_slot
	pending_new_slot = -1
	new_run(int(Time.get_ticks_usec() & 0x7fffffff))

func _load_slot(slot: int) -> void:
	var result := Saves.load_slot(slot,save_directory)
	if not result.ok:
		save_notice.dialog_text = result.message
		save_notice.popup_centered(Vector2i(520,180))
		return
	active_slot = slot
	menu_mode = ""
	generation += 1
	selected_front_slot = -1
	selected_class = ""
	run_state = result.state.duplicate(true)
	legacy_cinematic_floor = Run.map_floor(run_state) if not run_state.has("cinematic_floor") else -1
	formation_from_map = str(run_state.get("formation_origin", "slots")) == "map"
	_render(true)
	if result.recovered:
		save_notice.dialog_text = "主存档无法读取，已从上一份有效备份恢复。"
		save_notice.popup_centered(Vector2i(520,180))

func _request_exit() -> void:
	if menu_mode.is_empty() and run_state.phase == "battle": exit_confirm.popup_centered(Vector2i(560,180))
	else: _exit_now()

func _exit_now() -> void:
	if not _autosave(): return
	_stop_cinematic()
	Music.shutdown()
	if is_instance_valid(battle_view):battle_view.cancel_pending()
	get_tree().create_timer(0.4).timeout.connect(get_tree().quit)








func handle_right_click() -> void:
	if is_instance_valid(initial_formation_view) and initial_formation_view.cancel_drag(): return
	if is_instance_valid(encyclopedia_view) and encyclopedia_view.visible:
		encyclopedia_view.handle_back()
		return
	if is_instance_valid(floor_cinematic):
		floor_cinematic.skip()
		return
	if is_instance_valid(relic_dialog) and relic_dialog.visible:
		relic_dialog.hide()
		return
	if menu_mode in ["new", "load"]:
		pending_new_slot = -1
		_show_main_menu()
		return
	if menu_mode == "main": return
	if run_state.phase == "battle":
		if is_instance_valid(battle_view): battle_view.handle_right_click()
		return
	if is_instance_valid(summon_view):
		summon_view.cancel_offer()
		return
	if is_instance_valid(loot_view):
		loot_view.leave()
		return
	if run_state.phase == "node" and Run.current_node(run_state).get("type","")=="event" and run_state.node_state.get("mode","")=="exchange":
		_apply(Nodes.choose_event(run_state,"back"))
		return
	if run_state.phase=="opening" or Opening.ready(run_state):
		_return_to_menu()
		return
	if run_state.phase == "formation":
		selected_front_slot = -1
		if run_state.current_node.is_empty() and not formation_from_map:
			_show_slots(formation_slot_mode)
		else:
			_apply(Run.cancel_formation(run_state, true))
		return
	# Keep pending node/reward/summon choices intact when returning to the menu.
	_return_to_menu()

func _show_relics() -> void:
	var shown_state: Dictionary = battle_view.state if is_instance_valid(battle_view) and run_state.phase == "battle" else run_state
	relic_view.configure(shown_state)
	var available := get_viewport_rect().size
	relic_dialog.popup_centered(Vector2i(mini(1160,int(available.x)-60),mini(820,int(available.y)-120)))

func _relic_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		relic_dialog.set_input_as_handled()
		get_viewport().set_input_as_handled()
		relic_dialog.hide()


func _record_discoveries(value: Dictionary) -> void:
	if value==encyclopedia_history and not encyclopedia_dirty:return
	encyclopedia_history=value
	encyclopedia_dirty=true
	var result:=Discoveries.save(encyclopedia_history,encyclopedia_directory)
	if result.ok:
		encyclopedia_dirty=false
		encyclopedia_notice=""
	else:encyclopedia_notice=result.message
	_update_discovery_notice()

func _choose_event(action: String,source: String,target: String) -> void:
	var next:=Nodes.choose_event(run_state,action,source,target)
	if next==run_state:return
	var event_id: String=str(run_state.get("node_state",{}).get("event",""))
	var recorded:=action
	if action=="swap":recorded="higher_done" if run_state.node_state.get("higher",false) else "same_done"
	_record_discoveries(Discoveries.choose(encyclopedia_history,event_id,recorded))
	_apply(next)

func _show_expedition_menu() -> void:
	if not menu_mode.is_empty():return
	expedition_menu.popup_centered(Vector2i(380,330))

func _show_encyclopedia() -> void:
	if is_instance_valid(floor_cinematic):return
	if is_instance_valid(battle_view) and run_state.phase=="battle":
		if battle_view.busy or battle_view.state.status!="playing":return
	if is_instance_valid(encyclopedia_view) and encyclopedia_view.visible:return
	encyclopedia_focus=get_viewport().gui_get_focus_owner()
	expedition_menu.hide()
	if is_instance_valid(battle_view):battle_view.battle_menu.hide()
	relic_dialog.hide()
	encyclopedia_blocked_battle=is_instance_valid(battle_view) and run_state.phase=="battle"
	if encyclopedia_blocked_battle:
		battle_view.busy=true
		battle_view._render()
	if not is_instance_valid(encyclopedia_view):
		encyclopedia_view=Encyclopedia.new()
		encyclopedia_view.z_index=110
		encyclopedia_view.add_to_group("encyclopedia_overlay")
		encyclopedia_view.closed.connect(_close_encyclopedia)
		add_child(encyclopedia_view)
	encyclopedia_view.show()
	var shown:=run_state if menu_mode.is_empty() and not (run_state.phase=="formation" and run_state.current_node.is_empty()) else {}
	if not shown.is_empty() and str(shown.current_node).is_empty():
		shown=shown.duplicate(true)
		shown.roster=shown.team.duplicate()
	encyclopedia_view.configure(shown,encyclopedia_history,encyclopedia_notice)

func _close_encyclopedia() -> void:
	if not is_instance_valid(encyclopedia_view) or not encyclopedia_view.visible:return
	encyclopedia_view.hide()
	if encyclopedia_blocked_battle and is_instance_valid(battle_view):
		battle_view.busy=false
		battle_view._render()
	encyclopedia_blocked_battle=false
	if is_instance_valid(encyclopedia_focus) and encyclopedia_focus.is_visible_in_tree():encyclopedia_focus.grab_focus()

func _update_discovery_notice() -> void:
	if not is_instance_valid(discovery_status):return
	discovery_status.text="图鉴记录："+encyclopedia_notice
	discovery_status.visible=not encyclopedia_notice.is_empty()


