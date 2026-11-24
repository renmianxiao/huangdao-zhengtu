extends Control
const Paper=preload("res://code/scripts/ui/global_theme.gd")
const Art = preload("res://code/scripts/ui/map_ornament.gd")
const Catalog = preload("res://code/scripts/run/run_catalog.gd")
const Progress = preload("res://code/scripts/run/progression.gd")
var state: Dictionary
var shown_floor := 1
var badge_kind := "battle"
var content: Control
var info_title: Label
var info_text: Label
var enter_button: Button
const DESIGN := Vector2(320,800)
const INK := Color("e8decc")
var layout_scale := 1.0
var layout_offset := Vector2.ZERO
func setup(value: Dictionary, floor_number: int) -> void:
	state=value
	shown_floor=floor_number
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	content=Control.new(); content.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(content)
	info_title=_label("普通战斗",Rect2(26,270,268,36),29,HORIZONTAL_ALIGNMENT_CENTER)
	info_text=_label("",Rect2(38,345,244,126),20,HORIZONTAL_ALIGNMENT_CENTER)
	info_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	info_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	_label("队伍",Rect2(27,509,48,28),21)
	_label("%d / %d" % [state.hp,state.max_hp],Rect2(198,509,99,28),17,HORIZONTAL_ALIGNMENT_RIGHT)
	_label("等级",Rect2(27,555,70,30),22)
	_label("Lv.%d" % state.level,Rect2(217,555,80,30),22,HORIZONTAL_ALIGNMENT_RIGHT)
	_label("声望",Rect2(27,597,70,30),22)
	_label(str(state.renown),Rect2(217,597,80,30),22,HORIZONTAL_ALIGNMENT_RIGHT)
	var xp := "%d/%d" % [state.experience,Progress.xp_to_next(state.level)] if state.level < Progress.MAX_LEVEL else "满级"
	_label("经验 %s  ·  金币 %d\n卡槽 %d / %d" % [xp,state.gold,state.team.size(),state.slot_capacity],Rect2(27,638,270,45),17,HORIZONTAL_ALIGNMENT_CENTER)
	enter_button=preload("res://code/scripts/ui/map_enter_button.gd").new()
	enter_button.text="进入节点"; enter_button.position=Vector2(15,711); enter_button.size=Vector2(290,73)
	enter_button.disabled=true; content.add_child(enter_button)
	resized.connect(_layout)
	_layout()
func _label(value: String, rect: Rect2, font_size: int, alignment: int=HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l:=Label.new(); l.text=value; l.position=rect.position; l.size=rect.size
	l.add_theme_font_size_override("font_size",font_size); l.add_theme_color_override("font_color",INK)
	l.horizontal_alignment=alignment; content.add_child(l); return l
func _layout() -> void:
	layout_scale=minf(size.x/DESIGN.x,size.y/DESIGN.y)
	layout_offset=(size-DESIGN*layout_scale)/2
	if content != null:
		content.scale=Vector2.ONE*layout_scale
		content.position=layout_offset
	queue_redraw()
func set_node(kind: String) -> void:
	badge_kind=kind
	info_title.text=Catalog.NODE_NAMES[kind]
	queue_redraw()
func _draw() -> void:
	draw_set_transform(layout_offset,0,Vector2.ONE*layout_scale)
	draw_rect(Rect2(0,0,320,800),Paper.DARK)
	# Five connected seals. Floor three and five carry a vermilion boss mask.
	draw_line(Vector2(32,64),Vector2(288,64),Art.GOLD,1,true)
	var font := get_theme_default_font()
	for i in range(5):
		var center:=Vector2(34+i*63,64)
		var fill:=Color("a34237") if i+1==shown_floor else Color("3e4241")
		if i in [2,4]: fill=Color("4e4539")
		draw_circle(center,18,fill,true,-1,true)
		draw_circle(center,18,Art.GOLD,false,1.2,true)
		if i+1==shown_floor: draw_circle(center,22,Art.GOLD,false,0.8,true)
		Art.diamond(self,center+Vector2(0,-22),2.5,Art.GOLD)
		if i in [2,4]: Art.boss(self,center,11,Color("b84b36"))
		else:
			var word: String=["一","二","三","四","五"][i]
			draw_string(font,center+Vector2(-10,7),word,HORIZONTAL_ALIGNMENT_LEFT,-1,22,INK)
	# Ornate content frame and large encounter medallion; no landscape art.
	var center:=Vector2(160,203)
	draw_circle(center,47,Color("51483b"),true,-1,true)
	for radius in [47.0,52.0]: draw_circle(center,radius,Art.GOLD,false,0.9,true)
	for side in [-1,1]:
		Art.diamond(self,center+Vector2(side*61,0),4,Art.GOLD)
		Art.curl(self,center+Vector2(side*56,-6),Vector2(side*0.3,0.3))
		Art.diamond(self,center+Vector2(0,side*60),4,Art.GOLD)
	Art.icon(self,badge_kind,center,36)
	Art.divider(self,Vector2(160,323),108)
	Art.divider(self,Vector2(160,493),125)
	# Team life meter shares the same row as its numeric readout.
	var hp_rect:=Rect2(84,519,108,12)
	draw_style_box(_meter_box(Color("b7af9d")),hp_rect)
	var ratio:=clampf(float(state.hp)/maxf(1,state.max_hp),0,1)
	if ratio>0: draw_style_box(_meter_box(Color("75a084")),Rect2(hp_rect.position,hp_rect.size*Vector2(ratio,1)))
	Art.divider(self,Vector2(160,703),130)
	draw_set_transform(Vector2.ZERO)
func _meter_box(color: Color) -> StyleBoxFlat:
	var box:=StyleBoxFlat.new(); box.bg_color=color; box.border_color=Color("756a55")
	box.set_border_width_all(1); box.set_corner_radius_all(6); return box

