extends Control
const Professions=preload("res://code/scripts/profession_names.gd")
const CardColors=preload("res://code/scripts/ui/character_card_colors.gd")
## Displays only owned cards. Position edits are commands against the parent's draft.
signal placement_requested(id: String, target: int)
signal confirmed
signal canceled
signal detail_requested(id: String)

const Opening=preload("res://code/scripts/run/opening_rules.gd")
const Characters=preload("res://code/scripts/characters/character_catalog.gd")
const Attributes=preload("res://code/scripts/combat/attributes.gd")
const Numbers=preload("res://code/scripts/number_text.gd")
const Growth=preload("res://code/scripts/characters/character_growth.gd")
const Party=preload("res://code/scripts/party.gd")
const Paper=preload("res://code/scripts/ui/global_theme.gd")
var state:Dictionary={}
var selected_slot:=-1
var selected_id:=""
var member_buttons:Dictionary={}
var detail_buttons:Dictionary={}
var formation_slots:Array[Button]=[]
var confirm_button:Button
var cancel_button:Button
var team_count:Label
var cards_area:Control
var roster_scroll:ScrollContainer
var board:Control
var preview_frame:PanelContainer
var preview_name:Label
var preview_stats:Label
var preview_skills:RichTextLabel
var skill_slot_count:=0
var _title:Label
var _subtitle:Label
var _roster_title:Label
var _front_title:Label
var _back_title:Label
var _health:Label
var _notice:Label
var _submitted:=false
var _revision:=0
var _drag_active:=false
var _drop_target:=-1
var _roster_target:=false
var _rest_notice:=""

func _ready() -> void:
	theme=Paper.make_dark(18)
	CardColors.gallery(self)
	set_process(false)
	_title=_label(self,"角色编队",30)
	_title.add_theme_font_override("font",Paper.title_font())
	_subtitle=_label(self,"拖动角色安排站位；拖回左侧可撤下，右键取消拖动。",16)
	_subtitle.add_theme_color_override("font_color",Paper.DARK_MUTED)
	team_count=_label(self,"",22);team_count.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	team_count.add_theme_color_override("font_color",Paper.DARK_TEXT)
	_roster_title=_label(self,"",19)
	roster_scroll=ScrollContainer.new();roster_scroll.name="RecruitedCharacters"
	roster_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	roster_scroll.set_drag_forwarding(Callable(),_can_drop_roster,_drop_roster)
	roster_scroll.add_theme_stylebox_override("panel",Paper.box(Color("202323"),Color("71634b")))
	add_child(roster_scroll)
	cards_area=Control.new();cards_area.name="CharacterCards";cards_area.size_flags_horizontal=SIZE_EXPAND_FILL
	cards_area.set_drag_forwarding(Callable(),_can_drop_roster,_drop_roster)
	roster_scroll.add_child(cards_area)
	preview_frame=PanelContainer.new();preview_frame.name="CharacterDetail"
	preview_frame.theme=Paper.make(18)
	preview_frame.add_theme_stylebox_override("panel",Paper.panel_style())
	add_child(preview_frame)
	var details:=VBoxContainer.new();details.add_theme_constant_override("separation",6);preview_frame.add_child(details)
	preview_name=_label(details,"",22)
	preview_name.add_theme_font_override("font",Paper.heading_font())
	preview_stats=_label(details,"",17)
	preview_stats.add_theme_color_override("font_color",Paper.GOLD)
	preview_skills=RichTextLabel.new();preview_skills.bbcode_enabled=true
	preview_skills.size_flags_vertical=SIZE_EXPAND_FILL;preview_skills.selection_enabled=true
	preview_skills.add_theme_font_size_override("normal_font_size",17)
	details.add_child(preview_skills)
	board=Control.new();board.name="FormationBoard";add_child(board)
	_front_title=_label(board,"前台 · 属性与招式生效",18)
	_back_title=_label(board,"后台 · 待命",18)
	_health=_label(board,"",17);_health.add_theme_color_override("font_color",Paper.DARK_MUTED)
	for index in range(8):
		var slot:=Button.new();slot.name="Position%d"%index;slot.clip_contents=true
		slot.theme=Paper.make(18)
		slot.mouse_default_cursor_shape=CURSOR_POINTING_HAND
		slot.set_drag_forwarding(_drag_from_slot.bind(index),_can_drop_slot.bind(index),_drop_slot.bind(index))
		slot.pressed.connect(_inspect_slot.bind(index))
		board.add_child(slot);formation_slots.append(slot)
		var art:=TextureRect.new();art.name="CharacterArtwork";art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.mouse_filter=MOUSE_FILTER_IGNORE;slot.add_child(art)
		var title:=_label(slot,"",14);title.name="PositionTitle"
		var name_label:=_label(slot,"",19);name_label.name="CharacterName";name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_override("font",Paper.heading_font())
		var status:=_label(slot,"",15);status.name="CharacterStatus";status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_notice=_label(self,"",17);_notice.add_theme_color_override("font_color",Paper.DARK_MUTED)
	cancel_button=Button.new();cancel_button.text="取消";cancel_button.pressed.connect(cancel_selection);add_child(cancel_button)
	confirm_button=Button.new();Paper.primary(confirm_button);confirm_button.pressed.connect(_confirm);add_child(confirm_button)
	resized.connect(_layout)
	if not state.is_empty():configure(state)
	_layout.call_deferred()

func _label(parent:Node,value:String,font_size:int) -> Label:
	var label:=Label.new();label.text=value;label.mouse_filter=MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",font_size);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label);return label

func configure(run:Dictionary) -> void:
	state=run.duplicate(true)
	if not is_node_ready():return
	_submitted=false;_revision+=1
	var roster:Array=state.roster
	if member_buttons.keys()!=roster:
		member_buttons.clear();detail_buttons.clear()
		for child in cards_area.get_children():cards_area.remove_child(child);child.queue_free()
		for id:String in roster:_make_member(id)
	var draft:Array=state.get("draft_team",[])
	var slots:Array=state.get("draft_slots",[])
	var front:=Party.members(slots,0,4).size()
	team_count.text="上阵 %d / %d"%[draft.size(),state.slot_capacity]
	_roster_title.text="已招募 %d 人 · 拖回此处撤下"%roster.size()
	for id:String in member_buttons:
		var card:Button=member_buttons[id]
		var position:int=slots.find(id)
		var upgraded:=Growth.is_upgraded(state,id)
		var badge:Label=card.get_node("SelectionBadge")
		badge.text=("前台" if position<4 else "后台")+" %d"%(position%4+1) if position>=0 else "候补"
		if upgraded:badge.text+=" · 已强化"
		badge.add_theme_color_override("font_color",Paper.RED if upgraded else (Paper.GOLD if position>=0 else Paper.MUTED))
		card.tooltip_text=Characters.leader(id).name+(" · 已强化" if upgraded else "")+" · 拖入右侧槽位安排位置"
	for index in range(8):
		var slot:=formation_slots[index]
		var unlocked:bool=index<int(state.slot_capacity)
		var id:String=slots[index] if index<slots.size() else ""
		var leader:=Characters.leader(id)
		var upgraded:=Growth.is_upgraded(state,id)
		slot.disabled=not unlocked
		slot.get_node("PositionTitle").text="%s %d"%["前台" if index<4 else "后台",index%4+1]
		slot.get_node("CharacterArtwork").set_meta("character_id",id)
		slot.get_node("CharacterArtwork").texture=load("res://art/characters/%s.png"%id) if not id.is_empty() else null
		slot.get_node("CharacterName").text=leader.get("name","") if not id.is_empty() else ("空位" if unlocked else "未解锁")
		slot.get_node("CharacterStatus").text=Professions.label(leader.get("class","")) if not id.is_empty() else ("拖入角色" if unlocked else "解锁卡槽后开放")
		if upgraded:slot.get_node("CharacterStatus").text+=" · 已强化"
		slot.get_node("CharacterStatus").add_theme_color_override("font_color",Paper.GOLD if upgraded else Paper.INK)
		slot.tooltip_text="拖动交换站位，或拖回左侧撤下" if not id.is_empty() else ("拖入已招募角色" if unlocked else "该卡槽尚未解锁")
	var preview:=Party.apply_layout(state,slots,int(state.hp_bonus))
	_health.text="确认后前台生命 %d / %d · 保留当前生命比例"%[preview.hp,preview.max_hp] if front>0 else "前台至少需要一位角色"
	confirm_button.text="确认编队，出发" if state.current_node.is_empty() else "确认编队"
	confirm_button.disabled=front==0 or (state.current_node.is_empty() and draft.size()!=3)
	cancel_button.disabled=false
	_notice.text="前台 %d 人 · 后台 %d 人；确认后生效。"%[front,Party.members(slots,4,8).size()]
	if state.current_node.is_empty() and draft.size()!=3:_notice.text="开局需三位角色上阵，当前 %d 人。"%draft.size()
	elif front==0:_notice.text="请将至少一位角色放入前台。"
	_rest_notice=_notice.text
	if not roster.has(selected_id):selected_id=str(roster[0]) if not roster.is_empty() else ""
	_update_preview(selected_id);_refresh_styles();_layout.call_deferred()

func _make_member(id:String) -> void:
	var leader:=Characters.leader(id)
	var card:=Button.new();card.name="Member_"+id;card.clip_contents=true;card.mouse_default_cursor_shape=CURSOR_POINTING_HAND
	card.theme=Paper.make(18)
	card.set_drag_forwarding(_drag_from_card.bind(id),_can_drop_roster,_drop_roster)
	card.pressed.connect(select_character.bind(id));cards_area.add_child(card);member_buttons[id]=card;detail_buttons[id]=card
	var art:=TextureRect.new();art.name="CharacterArtwork";art.texture=load("res://art/characters/%s.png"%id)
	art.set_meta("character_id",id)
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter=MOUSE_FILTER_IGNORE;card.add_child(art)
	var badge:=_label(card,"",14);badge.name="SelectionBadge"
	var title:=_label(card,leader.name,18);title.name="CharacterName";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font",Paper.heading_font())
	var profession:=_label(card,Professions.label(leader["class"]),14);profession.name="Profession";profession.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	profession.add_theme_color_override("font_color",Paper.MUTED)

func select_character(id:String) -> void:
	if _submitted or not member_buttons.has(id):return
	_update_preview(id);_refresh_styles()

func _update_preview(id:String) -> void:
	var leader:=Characters.leader(id)
	if leader.is_empty():return
	CardColors.panel(preview_frame,id,false,Growth.is_upgraded(state,id))
	selected_id=id;preview_name.text=leader.name+("〔已强化〕" if Growth.is_upgraded(state,id) else "")
	var stats:=Attributes.stats(state,id)
	preview_stats.text="%s · 攻击 %s · 血量 %s"%[Professions.label(leader["class"]),Attributes.display(stats.attack),Attributes.display(stats.max_hp)]
	var blocks:Array[String]=[]
	for skill_id:String in leader.skills:
		var skill:Dictionary=Characters.SKILLS[skill_id]
		var block:="[color=#66513b]%s · %d AP[/color]\n%s"%[skill.name,int(skill.cost),skill.text]
		if not str(skill.get("rules","")).is_empty():block+="\n[color=#635d53]%s[/color]"%str(skill.rules)
		blocks.append(block)
	if not leader.passive.is_empty():blocks.append("[color=#66513b]被动 · %s[/color]\n%s"%[leader.passive.name,leader.passive.text])
	skill_slot_count=blocks.size();preview_skills.text=Professions.text(Numbers.description("\n\n".join(blocks)));preview_skills.scroll_to_line(0)

func _inspect_slot(index:int) -> void:
	var id:String=state.draft_slots[index]
	if not id.is_empty():select_character(id)

func drag_payload(id:String) -> Dictionary:
	if _submitted or not state.get("roster",[]).has(id):return {}
	return {"kind":"formation_character","owner":get_instance_id(),"revision":_revision,"id":id}

func _payload_valid(data:Variant) -> bool:
	return not _submitted and data is Dictionary and data.get("kind")=="formation_character" and data.get("owner")==get_instance_id() and data.get("revision")==_revision and data.get("id") is String and state.roster.has(data.id)

func _drag_from_card(_position:Vector2,id:String) -> Variant:
	var data:=drag_payload(id)
	if data.is_empty():return null
	select_character(id)
	member_buttons[id].set_drag_preview(_make_drag_preview(id))
	return data

func _make_drag_preview(id:String) -> PanelContainer:
	var preview:=PanelContainer.new();preview.theme=Paper.make(18);preview.size=Vector2(136,180);preview.position=Vector2(-68,-70);preview.modulate.a=0.94
	preview.mouse_filter=MOUSE_FILTER_IGNORE;preview.add_theme_stylebox_override("panel",Paper.box(Color("eadbc0"),Paper.GOLD))
	var upgraded:=Growth.is_upgraded(state,id)
	CardColors.panel(preview,id,false,upgraded)
	var art:=TextureRect.new();art.texture=load("res://art/characters/%s.png"%id);art.custom_minimum_size=Vector2(126,164)
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.mouse_filter=MOUSE_FILTER_IGNORE;preview.add_child(art)
	if upgraded:
		var badge:=Label.new();badge.name="UpgradeBadge";badge.text="已强化";badge.mouse_filter=MOUSE_FILTER_IGNORE
		badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;badge.vertical_alignment=VERTICAL_ALIGNMENT_TOP
		badge.add_theme_font_size_override("font_size",17);badge.add_theme_color_override("font_color",Paper.RED)
		preview.add_child(badge)
	return preview

func _drag_from_slot(position:Vector2,index:int) -> Variant:
	if index>=int(state.slot_capacity):return null
	return _drag_from_card(position,str(state.draft_slots[index]))

func _can_drop_slot(_position:Vector2,data:Variant,index:int) -> bool:
	return _payload_valid(data) and index>=0 and index<int(state.slot_capacity)

func _drop_slot(position:Vector2,data:Variant,index:int) -> void:
	if _can_drop_slot(position,data,index):_queue_placement(str(data.id),index)

func _can_drop_roster(_position:Vector2,data:Variant) -> bool:
	return _payload_valid(data) and state.draft_team.has(data.id)

func _drop_roster(position:Vector2,data:Variant) -> void:
	if _can_drop_roster(position,data):_queue_placement(str(data.id),-1)

func _queue_placement(id:String,target:int) -> void:
	# The native drag must finish before updating its source controls.
	_emit_placement.call_deferred(id,target,_revision)

func _emit_placement(id:String,target:int,revision:int) -> void:
	if _submitted or revision!=_revision:return
	placement_requested.emit(id,target)

func cancel_drag() -> bool:
	if not get_viewport().gui_is_dragging():return false
	get_viewport().gui_cancel_drag();return true

func _notification(what:int) -> void:
	if what==NOTIFICATION_DRAG_BEGIN:
		_drag_active=_payload_valid(get_viewport().gui_get_drag_data());set_process(_drag_active);_refresh_styles()
	elif what==NOTIFICATION_DRAG_END:
		_drag_active=false;_drop_target=-1;_roster_target=false;set_process(false);_refresh_styles();_refresh_drop_text()

func _process(_delta:float) -> void:
	var point:=get_global_mouse_position()
	var target:=-1
	for index in range(formation_slots.size()):
		if formation_slots[index].get_global_rect().has_point(point):target=index;break
	var roster_target:=roster_scroll.get_global_rect().has_point(point)
	if target==_drop_target and roster_target==_roster_target:return
	_drop_target=target;_roster_target=roster_target
	_refresh_styles();_refresh_drop_text()

func _refresh_drop_text() -> void:
	if not is_node_ready():return
	_notice.text=_rest_notice
	for index in range(formation_slots.size()):
		var id:=str(state.draft_slots[index])
		var status:Label=formation_slots[index].get_node("CharacterStatus")
		status.text=Professions.label(Characters.leader(id).get("class","")) if not id.is_empty() else ("拖入角色" if not formation_slots[index].disabled else "解锁卡槽后开放")
		if Growth.is_upgraded(state,id):status.text+=" · 已强化"
		if _drag_active and index==_drop_target:
			status.text="不可放入 · 未解锁" if formation_slots[index].disabled else ("放入此位" if id.is_empty() else "交换站位")
	if not _drag_active:return
	if _roster_target:
		_notice.text="松开撤下角色，保留在已招募列表。" if _can_drop_roster(Vector2.ZERO,get_viewport().gui_get_drag_data()) else "此角色已在候补列表。"
	elif _drop_target>=0:
		var target:=formation_slots[_drop_target]
		var occupant:=str(state.draft_slots[_drop_target])
		_notice.text="此阵位尚未解锁，无法放入。" if target.disabled else ("松开放入空位。" if occupant.is_empty() else "松开与%s交换站位。"%Characters.leader(occupant).name)
	else:
		_notice.text="拖入阵位安排角色；拖回左侧撤下，右键取消。"

func _refresh_styles() -> void:
	if not is_node_ready():return
	for id:String in member_buttons:
		_style(member_buttons[id],selected_id==id,false)
		CardColors.button(member_buttons[id],id,selected_id==id,Growth.is_upgraded(state,id))
	for index in range(formation_slots.size()):
		var slot:=formation_slots[index]
		var active:=not slot.disabled and _drag_active and index==_drop_target
		_style(slot,active,slot.disabled)
		if not slot.disabled:
			var id:String=str(state.draft_slots[index])
			CardColors.button(slot,id,active,Growth.is_upgraded(state,id))
		elif _drag_active and index==_drop_target:
			var invalid:StyleBoxFlat=slot.get_theme_stylebox("disabled").duplicate()
			invalid.border_color=Paper.RED;invalid.set_border_width_all(3)
			slot.add_theme_stylebox_override("disabled",invalid)
	var roster_style:=Paper.box(Color("202323"),Paper.OLD_GOLD if _roster_target else Color("71634b"))
	roster_style.set_border_width_all(3 if _roster_target else 1)
	roster_scroll.add_theme_stylebox_override("panel",roster_style)

func _style(control:Button,accent:bool,locked:bool) -> void:
	for mode:String in ["normal","hover","pressed","disabled"]:
		var fill:=Color("bcb8ad") if locked else (Color("e2d6c3") if mode in ["hover","pressed"] else Paper.PANEL)
		var style:=Paper.box(fill,Paper.GOLD if accent else Paper.BORDER);style.set_border_width_all(2 if accent else 1)
		control.add_theme_stylebox_override(mode,style)

func _confirm() -> void:
	if _submitted or confirm_button.disabled:return
	_submitted=true;confirm_button.disabled=true;cancel_button.disabled=true;confirmed.emit()

func cancel_selection() -> void:
	if cancel_drag() or _submitted:return
	_submitted=true;canceled.emit()

func resume_selection() -> void:
	_submitted=false

func _place(control:Control,x:float,y:float,width:float,height:float) -> void:
	control.position=Vector2(x,y);control.size=Vector2(maxf(1,width),maxf(1,height))

func _layout() -> void:
	if board==null or size.x<=0 or size.y<=0:return
	var gap:=20.0
	var inset:=18.0
	var width:=size.x-inset*2
	var left:=clampf(width*0.31,250,520)
	var main_height:=maxf(300,size.y-190)
	var detail_height:=clampf(main_height*0.38,172,280)
	_place(_title,inset,12,width-210,40);_place(team_count,size.x-inset-205,16,205,34)
	_place(_subtitle,inset,56,width,28)
	_place(_roster_title,inset,94,left,28)
	_place(roster_scroll,inset,128,left,main_height-detail_height-40)
	_place(preview_frame,inset,94+main_height-detail_height+4,left,detail_height-4)
	_place(board,inset+left+gap,94,width-left-gap,main_height)
	var columns:=2 if left<480 else 3
	var cell_width:=(left-30-(columns-1)*8)/columns
	var card_height:=clampf(cell_width*1.38,158,215)
	var rows:=ceili(float(maxi(1,member_buttons.size()))/columns)
	cards_area.custom_minimum_size=Vector2(0,16+rows*(card_height+8))
	var index:=0
	for id:String in member_buttons:
		var card:Button=member_buttons[id]
		_place(card,8+(index%columns)*(cell_width+8),8+floorf(float(index)/columns)*(card_height+8),cell_width,card_height)
		_place(card.get_node("CharacterArtwork"),4,22,cell_width-8,card_height-69)
		_crop_portrait(card.get_node("CharacterArtwork"))
		_place(card.get_node("SelectionBadge"),7,3,cell_width-14,20)
		_place(card.get_node("CharacterName"),3,card_height-46,cell_width-6,25)
		_place(card.get_node("Profession"),3,card_height-22,cell_width-6,20)
		index+=1
	var slot_width:=(board.size.x-30)/4
	var row_height:=(main_height-84)/2
	_place(_health,0,0,board.size.x,24)
	_place(_front_title,0,30,board.size.x,24)
	_place(_back_title,0,62+row_height,board.size.x,24)
	for i in range(8):
		var slot:=formation_slots[i]
		_place(slot,(i%4)*(slot_width+10),58+floorf(float(i)/4)*(row_height+28),slot_width,row_height-8)
		_place(slot.get_node("PositionTitle"),8,4,slot_width-16,22)
		_place(slot.get_node("CharacterArtwork"),4,28,slot_width-8,slot.size.y-78)
		_crop_portrait(slot.get_node("CharacterArtwork"))
		_place(slot.get_node("CharacterName"),3,slot.size.y-48,slot_width-6,26)
		_place(slot.get_node("CharacterStatus"),3,slot.size.y-22,slot_width-6,20)
		if slot.get_node("CharacterArtwork").texture==null:
			slot.get_node("CharacterName").position.y=slot.size.y*0.43
			slot.get_node("CharacterStatus").position.y=slot.size.y*0.43+29
	var footer_y:=size.y-66
	_place(_notice,inset,footer_y,width-355,48)
	_place(cancel_button,size.x-inset-340,footer_y,106,48)
	_place(confirm_button,size.x-inset-220,footer_y,220,48)

func _crop_portrait(art:TextureRect) -> void:
	var id:=str(art.get_meta("character_id",""))
	if id.is_empty() or art.size.x<=0.0 or art.size.y<=0.0:return
	var source:Texture2D=load("res://art/characters/%s.png"%id)
	if source==null:return
	var crop:=AtlasTexture.new();crop.atlas=source
	crop.region=CardColors.portrait_region(id,source,art.size)
	crop.filter_clip=true
	art.texture=crop

