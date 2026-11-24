extends Control
const Recommendations=preload("res://code/scripts/run/opening_recommendations.gd")
var recommendation_button:Button
const Tags=preload("res://code/scripts/characters/tactical_tags.gd")
var tier_filter:OptionButton
var tag_filter:OptionButton
var filter_count:Label
var filter_empty:Label
const TIER_VALUES=[-1,3,1,0]
const TAG_HELP="爆发：拥有基础费用至少3 AP的直接伤害技能；其余标签表示技能或被动具备相应机制。费用筛选按原始招募档位。"
const Professions=preload("res://code/scripts/profession_names.gd")
const CardColors=preload("res://code/scripts/ui/character_card_colors.gd")
## Selection is transient; only the bottom actions emit commands to the run.
signal confirmed(character_id: String)
signal canceled

const Opening=preload("res://code/scripts/run/opening_rules.gd")
const Camp = preload("res://code/scripts/run/camp_rules.gd")
const Characters = preload("res://code/scripts/characters/character_catalog.gd")
const Orders = preload("res://code/scripts/run/recruit_orders.gd")
const Rules = preload("res://code/scripts/run/run_rules.gd")
const Attributes = preload("res://code/scripts/combat/attributes.gd")
const Numbers = preload("res://code/scripts/number_text.gd")
const Growth = preload("res://code/scripts/characters/character_growth.gd")
const Paper = preload("res://code/scripts/ui/global_theme.gd")
const Card = preload("res://code/scripts/ui/summon_character_card.gd")

var state: Dictionary
var selected_id := ""
var card_buttons: Dictionary = {}
var card_scroll: ScrollContainer
var card_grid: GridContainer
var preview_frame: PanelContainer
var preview_art: TextureRect
var preview_name: Label
var preview_stats: Label
var preview_notice: Label
var preview_skills: RichTextLabel
var skill_slot_count := 0
var footer: HBoxContainer
var confirm_button: Button
var cancel_button: Button
var _title: Label
var _renown: Label
var _profession: Label
var _empty_art: Label
var _submitted := false
var hint: Label
var drop_banner: HBoxContainer
var _art_area: Control

func _ready() -> void:
	theme = Paper.make_dark(18)
	CardColors.gallery(self)
	var page := VBoxContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation",12)
	page.offset_left = 18; page.offset_right = -18
	page.offset_top = 14; page.offset_bottom = -14
	add_child(page)
	var top := HBoxContainer.new()
	top.custom_minimum_size.y = 40
	page.add_child(top)
	_title = _label(top,"角色召集",32)
	_title.add_theme_font_override("font",Paper.title_font())
	_title.size_flags_horizontal = SIZE_EXPAND_FILL
	_renown = _label(top,"",24)
	_renown.custom_minimum_size.x = 150
	_renown.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint = _label(page,"选择角色查看详情，确认后招募或强化。取消将放弃本次召集令。",17)
	hint.add_theme_color_override("font_color",Color("b7ad98"))
	var filters:=HBoxContainer.new()
	filters.add_theme_constant_override("separation",12)
	page.add_child(filters)
	tier_filter=OptionButton.new()
	for text in ["全部声望档","3 声望档","1 声望档","0 声望档"]:tier_filter.add_item(text)
	filters.add_child(tier_filter)
	tag_filter=OptionButton.new();tag_filter.add_item("全部定位")
	for tag:String in Tags.FILTERS:tag_filter.add_item(tag)
	filters.add_child(tag_filter)
	recommendation_button=Button.new();recommendation_button.text="查看推荐角色"
	filters.add_child(recommendation_button);recommendation_button.pressed.connect(_select_recommendation)
	filter_count=_label(filters,"",16);filter_count.tooltip_text=TAG_HELP
	filter_count.custom_minimum_size.x=130;filter_count.autowrap_mode=TextServer.AUTOWRAP_OFF
	tier_filter.custom_minimum_size=Vector2(150,36);tag_filter.custom_minimum_size=Vector2(140,36)
	tier_filter.item_selected.connect(func(_index):_apply_filters())
	tag_filter.item_selected.connect(func(_index):_apply_filters())
	filter_empty=_label(page,"没有符合筛选条件的角色，请调整筛选。",18)
	filter_empty.hide()
	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation",20)
	main.size_flags_vertical = SIZE_EXPAND_FILL
	page.add_child(main)
	card_scroll = ScrollContainer.new()
	card_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card_scroll.follow_focus = true
	main.add_child(card_scroll)
	card_grid = GridContainer.new()
	card_grid.columns = 2
	card_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	card_grid.add_theme_constant_override("h_separation",16)
	card_grid.add_theme_constant_override("v_separation",16)
	card_scroll.add_child(card_grid)
	preview_frame = PanelContainer.new()
	preview_frame.theme = Paper.make(18)
	var style := Paper.panel_style()
	style.content_margin_left = 16; style.content_margin_right = 16
	style.content_margin_top = 16; style.content_margin_bottom = 14
	preview_frame.add_theme_stylebox_override("panel",Paper.ornate(style))
	main.add_child(preview_frame)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation",5)
	preview_frame.add_child(details)
	preview_name = _label(details,"请选择角色",30)
	preview_name.add_theme_font_override("font",Paper.heading_font())
	preview_name.add_theme_color_override("font_color",Paper.INK)
	_profession = _label(details,"点击左侧角色卡查看立绘与技能",17)
	_profession.add_theme_color_override("font_color",Paper.MUTED)
	_art_area = Control.new()
	_art_area.name = "PortraitWindow"
	_art_area.clip_contents = true
	_art_area.size_flags_vertical = SIZE_EXPAND_FILL
	_art_area.size_flags_stretch_ratio = 3.0
	_art_area.custom_minimum_size.y = 105
	details.add_child(_art_area)
	_art_area.resized.connect(_layout_portrait)
	preview_art = TextureRect.new()
	preview_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_art.mouse_filter = MOUSE_FILTER_IGNORE
	_art_area.add_child(preview_art)
	_empty_art = _label(_art_area,"待选角色",28)
	_empty_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_empty_art.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_art.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_art.add_theme_color_override("font_color",Color("aa9472"))
	preview_stats = _label(details,"",19)
	preview_notice = _label(details,"",17)
	preview_skills = RichTextLabel.new()
	preview_skills.bbcode_enabled = true
	preview_skills.selection_enabled = true
	preview_skills.size_flags_vertical = SIZE_EXPAND_FILL
	preview_skills.custom_minimum_size.y = 70
	preview_skills.size_flags_stretch_ratio = 0.65
	preview_skills.add_theme_font_size_override("normal_font_size",18)
	preview_skills.add_theme_font_override("normal_font",Paper.body_font())
	preview_skills.add_theme_color_override("default_color",Paper.INK)
	preview_skills.add_theme_constant_override("line_separation",4)
	details.add_child(preview_skills)
	footer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation",16)
	page.add_child(footer)
	cancel_button = Button.new()
	cancel_button.text = "取消"
	cancel_button.tooltip_text = "放弃本次召集，召集令立即作废。"
	cancel_button.custom_minimum_size = Vector2(150,52)
	cancel_button.pressed.connect(cancel_offer)
	footer.add_child(cancel_button)
	confirm_button = Button.new()
	confirm_button.text = "确认"
	confirm_button.custom_minimum_size = Vector2(170,52)
	confirm_button.disabled = true
	Paper.primary(confirm_button)
	confirm_button.pressed.connect(_confirm)
	footer.add_child(confirm_button)
	resized.connect(_layout)
	card_scroll.resized.connect(_layout_grid)
	_layout.call_deferred()

func _label(parent: Node, value: String, font_size: int) -> Label:
	var node := Label.new()
	node.text = value
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size",font_size)
	parent.add_child(node)
	return node

func configure(run: Dictionary) -> void:
	state = run.duplicate(true)
	selected_id = ""
	tier_filter.select(0);tag_filter.select(0)
	_submitted = false
	# A later invitation must not retain cards or previews from the previous one.
	for child in card_grid.get_children():
		card_grid.remove_child(child)
		child.queue_free()
	card_buttons.clear()
	preview_art.texture = null
	preview_name.text = "请选择角色"
	_profession.text = "点击左侧角色卡查看立绘与技能"
	preview_stats.text = ""
	preview_notice.text = ""
	preview_skills.text = ""
	skill_slot_count = 0
	_empty_art.text = "待选角色"
	_empty_art.show()
	CardColors.panel(preview_frame, "")
	confirm_button.text = "确认"
	confirm_button.tooltip_text = ""
	confirm_button.disabled = true
	cancel_button.text = "取消"
	cancel_button.tooltip_text = "放弃本次召集，召集令立即作废。"
	cancel_button.disabled = false
	hint.text = "选择角色查看详情，确认后招募或强化。取消将放弃本次召集令。"
	var free_upgrade := Camp.free_upgrade_active(state)
	_title.text = "营地免费强化" if free_upgrade else ("%s召集令" % Professions.label(str(state.pending_recruit_order)))
	if Opening.recruiting(state):
		_title.text="开局招募 %d / 3 · %s召集令" % [state.opening.index+1,Professions.label(str(state.pending_recruit_order))]
		hint.text="三次招募共用3声望。可选择本职业全部角色，声望不足时仍可招募0声望角色。"
		cancel_button.text="返回组合选择" if state.opening.index==0 else "返回主菜单"
		cancel_button.tooltip_text="更换组合前不会消耗声望。" if state.opening.index==0 else "保存当前开局进度，读取存档后继续招募。"
	elif free_upgrade:
		hint.text = "选择一名已招募且尚未强化的角色；不消耗声望或召集令。取消可返回营地选项。"
		cancel_button.tooltip_text = "返回原来的三个营地选项，本次尚未领取奖励。"
	elif Camp.orders_active(state):
		_title.text = "营地召集 %d / 3 · %s" % [int(state.node_state.camp_order_index)+1,Professions.label(str(state.pending_recruit_order))]
		hint.text = "三张召集令依次处理，招募或强化沿用原有声望费用。取消只跳过当前这一张。"
	var recommendation:String=Recommendations.current(state)
	recommendation_button.visible=not recommendation.is_empty()
	if not recommendation.is_empty():
		hint.text+="\n"+Recommendations.describe(str(state.opening.bundle))
		recommendation_button.tooltip_text="本次推荐："+str(Characters.leader(recommendation).name)
	_renown.text = "声望  %d" % int(state.renown)
	for owned: bool in [true,false]:
		for leader: Dictionary in Characters.LEADERS:
			var id: String = leader.id
			if state.roster.has(id) != owned: continue
			if Growth.is_upgraded(state,id): continue
			if free_upgrade and not owned: continue
			if not free_upgrade and Orders.profession(id) != state.pending_recruit_order: continue
			var card := Card.new()
			card.configure({"id":id,"name":leader.name,"profession":Orders.profession(id),"cost":Rules.upgrade_cost(state,id) if owned else Rules.recruit_cost(state,id),"action":"强化" if owned else "招募","state":"已强化" if Growth.is_upgraded(state,id) else ("已招募" if owned else "未招募"),"tier":int(Characters.RECRUIT_COSTS[id]),"texture":load("res://art/characters/%s.png" % id),"reason":_reason(id)})
			card.tooltip_text += "\n定位："+" / ".join(Tags.for_character(id))+"\n"+TAG_HELP
			card.pressed.connect(select_character.bind(id))
			card_grid.add_child(card)
			card_buttons[id] = card
	if card_buttons.is_empty():
		hint.text = "当前已无可强化的角色，可取消并返回营地。" if free_upgrade else "本职业已无可招募或强化的角色，可取消本次召集令。"
		preview_name.text = "暂无可选角色"
		_profession.text = ""
		_empty_art.text = "无可选角色"
	_apply_filters()
	_layout.call_deferred()

func _layout() -> void:
	if preview_frame == null: return
	preview_frame.custom_minimum_size.x = floorf(maxf(1,size.x-36)*0.38)
	_layout_grid.call_deferred()

func _layout_grid() -> void:
	if card_scroll == null: return
	var width := maxf(1,card_scroll.size.x-20)
	card_grid.columns = 3 if width >= 900 else 2
	var cell_width := maxf(1,floorf((width-16*(card_grid.columns-1))/card_grid.columns))
	for card: Button in card_buttons.values():
		card.custom_minimum_size = Vector2(cell_width,clampf(size.y*0.235,164,215))

func _reason(id: String) -> String:
	return Rules.upgrade_reason(state,id) if state.roster.has(id) else Rules.recruit_reason(state,id)

func select_character(id: String) -> void:
	if _submitted or not card_buttons.has(id) or not card_buttons[id].visible: return
	selected_id = id
	CardColors.panel(preview_frame,id)
	for key: String in card_buttons: card_buttons[key].selected = key == id
	var leader := Characters.leader(id)
	var owned: bool = state.roster.has(id)
	var upgraded := Growth.is_upgraded(state,id)
	var stats := Attributes.stats(state,id)
	preview_name.text = leader.name
	_profession.text = "%s  /  %s" % [Professions.label(Orders.profession(id)),"已强化" if upgraded else ("已招募 · 可强化" if owned else "未招募")]
	preview_art.texture = load("res://art/characters/%s.png" % id)
	_layout_portrait.call_deferred()
	_empty_art.hide()
	if owned and not upgraded:
		var after_state := state.duplicate(true)
		after_state.character_upgrades[id] = true
		var after := Attributes.stats(after_state,id)
		preview_stats.text = "攻击  %s → %s\n血量  %s → %s" % [Attributes.display(stats.attack),Attributes.display(after.attack),Attributes.display(stats.max_hp),Attributes.display(after.max_hp)]
	else:
		preview_stats.text = "攻击  %s     血量  %s" % [Attributes.display(stats.attack),Attributes.display(stats.max_hp)]
	var reason := _reason(id)
	var cost: int = Rules.upgrade_cost(state,id) if owned else Rules.recruit_cost(state,id)
	var cost_text := "营地免费强化" if Camp.free_upgrade_active(state) else ("%s需 %d 声望" % ["强化" if owned else "招募",cost])
	preview_notice.text = reason if not reason.is_empty() else (cost_text+" · 每人本局限一次" if owned else cost_text+" · 加入候补")
	preview_notice.add_theme_color_override("font_color",Paper.RED if not reason.is_empty() else Paper.GOLD)
	preview_skills.text = "[color=#66513b]定位："+" / ".join(Tags.for_character(id))+"[/color]\n"+str(leader.get("positioning",""))+"\n\n"+_skill_text(leader)
	preview_skills.scroll_to_line(0)
	confirm_button.text = "确认强化" if owned else "确认招募"
	confirm_button.disabled = not reason.is_empty()
	confirm_button.tooltip_text = reason if not reason.is_empty() else cost_text

func _skill_text(leader: Dictionary) -> String:
	var blocks: Array[String] = []
	for skill_id: String in leader.skills:
		var skill: Dictionary = Characters.SKILLS[skill_id]
		var block := "[color=#66513b]主动 · %s   %d AP[/color]\n%s" % [skill.name,int(skill.cost),skill.text]
		if not str(skill.get("rules","")).is_empty(): block += "\n[color=#635d53]%s[/color]" % str(skill.rules)
		blocks.append(block)
	if not leader.passive.is_empty():
		blocks.append("[color=#66513b]被动 · %s[/color]\n%s" % [leader.passive.name,leader.passive.text])
	skill_slot_count = blocks.size()
	return Professions.text(Numbers.description("\n\n".join(blocks)))

func _confirm() -> void:
	if _submitted or selected_id.is_empty() or not _reason(selected_id).is_empty(): return
	_submitted = true
	confirm_button.disabled = true
	cancel_button.disabled = true
	confirmed.emit(selected_id)

func cancel_offer() -> void:
	if _submitted: return
	_submitted = true
	canceled.emit()

func resume_offer() -> void:
	_submitted=false


func _apply_filters()->void:
	var tier:int=TIER_VALUES[tier_filter.selected]
	var tag:String="" if tag_filter.selected==0 else str(Tags.FILTERS[tag_filter.selected-1])
	var count:=0
	for id:String in card_buttons:
		var shown:bool=Tags.matches(id,tier,tag)
		card_buttons[id].visible=shown
		if shown:count+=1
	filter_count.text="%d / %d 人"%[count,card_buttons.size()]
	if filter_empty!=null:filter_empty.visible=count==0 and not card_buttons.is_empty()
	if not selected_id.is_empty() and not card_buttons[selected_id].visible:
		card_buttons[selected_id].selected=false;selected_id=""
		preview_art.texture=null;preview_name.text="请选择角色";preview_stats.text="";preview_notice.text="";preview_skills.text=""
		_profession.text="点击左侧角色卡查看立绘与技能";_empty_art.show();skill_slot_count=0
		CardColors.panel(preview_frame,"");confirm_button.disabled=true;confirm_button.text="确认"
	card_scroll.scroll_vertical=0

func _select_recommendation()->void:
	var id:String=Recommendations.current(state)
	if _submitted or id.is_empty() or not card_buttons.has(id):return
	tier_filter.select(0);tag_filter.select(0);_apply_filters();select_character(id)
	card_scroll.ensure_control_visible.call_deferred(card_buttons[id])

func _layout_portrait() -> void:
	if preview_art == null or preview_art.texture == null or _art_area.size.x <= 0 or _art_area.size.y <= 0:
		return
	# Keep the source texture intact and expose its upper body through a viewport.
	# This scales the head with the available panel, rather than shrinking a full figure.
	var source := CardColors.portrait_region(selected_id,preview_art.texture,_art_area.size)
	var fitted := CardColors.portrait_destination(source,Rect2(Vector2.ZERO,_art_area.size))
	var scale_factor := fitted.size.x / maxf(1.0,source.size.x)
	preview_art.size = preview_art.texture.get_size() * scale_factor
	preview_art.position = fitted.position-source.position*scale_factor
