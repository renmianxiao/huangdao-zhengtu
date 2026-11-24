extends RefCounted
const PAPER=Color("e8decc")
const PANEL=Color("f1e9db")
const INK=Color("413c34")
const MUTED=Color("706858")
const GOLD=Color("927344")
const BORDER=Color("b3a184")
const RED=Color("a34237")
const HOVER=Color("792b24")
const HOVER_GOLD=Color("ffe3a4")
const GREEN=Color("426d65")
const DARK=Color("252829")
const DARK_TEXT=Color("e8decc")
const DARK_MUTED=Color("b7ad98")
const OLD_GOLD=Color("ae915d")
## One accent per floor, matching its cinematic: dawn jade, bamboo green, cloud
## grey-blue, dusk vermilion, night indigo. "battle" dims that floor's painting
## into a fighting stage.
const FLOORS:=[
	{"accent":Color("6f9a8f"),"battle":Color(0.46,0.46,0.45)},
	{"accent":Color("6a8f4e"),"battle":Color(0.42,0.48,0.41)},
	{"accent":Color("8a9fb3"),"battle":Color(0.46,0.48,0.54)},
	{"accent":Color("c0703f"),"battle":Color(0.58,0.46,0.39)},
	{"accent":Color("5a6aa6"),"battle":Color(0.50,0.52,0.68)}]
static var _body: Font
static var _heading: Font
static var _title: Font

static func floor_palette(floor_number: int) -> Dictionary:
	return FLOORS[clampi(floor_number,1,FLOORS.size())-1]

static func body_font() -> Font:
	if _body == null:
		_body=load("res://art/fonts/NotoSansCJKsc-Regular.otf")
	return _body

static func heading_font() -> Font:
	if _heading == null:
		_heading=load("res://art/fonts/NotoSerifCJKsc-SemiBold.otf")
	return _heading

static func panel_style(dark: bool=false) -> StyleBoxFlat:
	var panel:=box(DARK if dark else PANEL,Color("71634b") if dark else BORDER)
	panel.content_margin_left=16;panel.content_margin_right=16
	panel.content_margin_top=12;panel.content_margin_bottom=12
	return panel

## Card surfaces: a soft lift plus gilt corner brackets around any flat box.
static func ornate(style: StyleBoxFlat, dark: bool=false, grade: int=0) -> StyleBox:
	style.shadow_color=Color(0,0,0,0.32) if dark else Color(0.30,0.20,0.08,0.16)
	style.shadow_size=6; style.shadow_offset=Vector2(0,2)
	return preload("res://code/scripts/ui/ornate_box.gd").wrap(style,OLD_GOLD if dark else GOLD,grade)

static func trimmed(style: StyleBoxFlat, rule: Color=Color("f1d3a0")) -> StyleBox:
	var box=preload("res://code/scripts/ui/ornate_box.gd").wrap(style,rule)
	box.trim=true
	return box

## Calligraphic display face for page and floor titles; falls back to the serif.
static func title_font() -> Font:
	if _title == null:
		for path in ["res://art/fonts/MaShanZheng-Regular.ttf","res://art/fonts/title.ttf","res://art/fonts/title.otf"]:
			if ResourceLoader.exists(path): _title=load(path); break
		if _title == null: _title=heading_font()
	return _title

static func box(color: Color, border: Color=BORDER) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new(); s.bg_color=color; s.border_color=border
	s.set_border_width_all(1); s.set_corner_radius_all(2)
	s.content_margin_left=8; s.content_margin_right=8; s.content_margin_top=5; s.content_margin_bottom=5
	return s

static func make(font_size: int=17) -> Theme:
	var t:=Theme.new()
	t.default_font=body_font(); t.default_font_size=font_size
	t.set_font("title_font","Window",heading_font())
	for type_name in ["Label","Button","OptionButton","CheckButton","CheckBox","LineEdit","TextEdit","PopupMenu","Tree","ItemList"]:
		t.set_color("font_color",type_name,INK)
		t.set_color("font_hover_color",type_name,HOVER)
		t.set_color("font_hover_pressed_color",type_name,HOVER)
		t.set_color("font_pressed_color",type_name,INK)
		t.set_color("font_focus_color",type_name,INK)
		t.set_color("font_disabled_color",type_name,Color("6e6557"))
		t.set_color("font_selected_color",type_name,INK)
	# ItemList/Tree use hovered rather than Button's hover color names.
	for type_name in ["ItemList","Tree"]:
		for state in ["font_hovered_color","font_hovered_selected_color"]:
			t.set_color(state,type_name,HOVER)
	t.set_color("font_hovered_dimmed_color","Tree",HOVER)
	for type_name in ["Button","OptionButton","CheckButton","CheckBox"]:
		for mode in ["normal","hover","pressed","disabled"]:
			var color:=PANEL
			var edge:=BORDER
			if mode=="hover": color=Color("e6d6b6");edge=GOLD
			elif mode=="pressed": color=Color("d8c7a5");edge=Color("80633c")
			elif mode=="disabled": color=Color("eee6d8")
			t.set_stylebox(mode,type_name,box(color,edge))
		t.set_constant("outline_size",type_name,0)
		var focus:=box(Color.TRANSPARENT,GOLD); focus.set_border_width_all(2)
		t.set_stylebox("focus",type_name,focus)
	t.set_color("default_color","RichTextLabel",INK)
	t.set_color("font_selected_color","RichTextLabel",INK)
	t.set_color("selection_color","RichTextLabel",Color("dfc999"))
	t.set_stylebox("normal","RichTextLabel",box(Color.TRANSPARENT,Color.TRANSPARENT))
	t.set_stylebox("panel","PanelContainer",ornate(box(PANEL)))
	t.set_stylebox("panel","Panel",ornate(box(PANEL)))
	t.set_stylebox("panel","PopupMenu",box(PANEL))
	t.set_stylebox("hover","PopupMenu",box(Color("e7d6b4")))
	t.set_stylebox("panel","AcceptDialog",box(PANEL))
	t.set_stylebox("panel","PopupPanel",box(PANEL))
	t.set_stylebox("panel","TooltipPanel",box(PANEL))
	t.set_stylebox("normal","LineEdit",box(PANEL))
	t.set_stylebox("focus","LineEdit",box(PANEL,GOLD))
	t.set_stylebox("panel","ItemList",box(PANEL))
	t.set_stylebox("selected","ItemList",box(Color("e0d2b9"),RED))
	t.set_stylebox("selected_focus","ItemList",box(Color("e0d2b9"),RED))
	t.set_color("font_color","TooltipLabel",INK)
	t.set_stylebox("background","ProgressBar",box(Color("d8cfbc")))
	t.set_stylebox("fill","ProgressBar",box(Color("75a084"),Color("756a55")))
	for type_name in ["HScrollBar","VScrollBar"]:
		t.set_stylebox("scroll",type_name,box(Color("e9dfcd"),Color.TRANSPARENT))
		for mode in ["grabber","grabber_highlight","grabber_pressed"]:
			t.set_stylebox(mode,type_name,box(Color("bc9c65"),Color.TRANSPARENT))
	t.set_color("title_color","Window",INK)
	t.set_color("title_outline_modulate","Window",Color.TRANSPARENT)
	var window_box:=box(PANEL)
	window_box.expand_margin_top=30; window_box.content_margin_top=12
	t.set_stylebox("embedded_border","Window",window_box)
	t.set_icon("close","Window",load("res://art/ui/close.svg"))
	t.set_icon("close_pressed","Window",load("res://art/ui/close.svg"))
	t.set_icon("arrow","OptionButton",load("res://art/ui/arrow.svg"))
	return t

static func make_dark(font_size: int=18) -> Theme:
	var t:=make(font_size)
	for type_name in ["Label","Button","OptionButton","CheckButton","CheckBox","LineEdit","TextEdit","PopupMenu","Tree","ItemList"]:
		for state in ["font_color","font_pressed_color","font_focus_color","font_selected_color"]:
			t.set_color(state,type_name,DARK_TEXT)
		for state in ["font_hover_color","font_hover_pressed_color","font_hovered_color","font_hovered_selected_color"]:
			t.set_color(state,type_name,HOVER_GOLD)
		t.set_color("font_disabled_color",type_name,Color("a19a8c"))
	for type_name in ["Button","OptionButton","CheckButton","CheckBox"]:
		for state in ["normal","hover","pressed","disabled"]:
			var fill:=Color("333738") if state=="normal" else (Color("44443a") if state=="hover" else Color("232627"))
			t.set_stylebox(state,type_name,box(fill,OLD_GOLD if state=="hover" else Color("71634b")))
		var focus:=box(Color.TRANSPARENT,OLD_GOLD);focus.set_border_width_all(2)
		t.set_stylebox("focus",type_name,focus)
	for type_name in ["Panel","PanelContainer","PopupPanel","PopupMenu","ItemList","Tree"]:
		t.set_stylebox("panel",type_name,ornate(panel_style(true),true) if type_name in ["Panel","PanelContainer"] else panel_style(true))
	# Selected rows must replace the parchment styles inherited from make().
	# Hover and keyboard focus use their native ItemList/Tree style names.
	for type_name in ["ItemList","Tree"]:
		for state in ["selected","selected_focus","hovered","hovered_selected","hovered_selected_focus","hovered_dimmed"]:
			if state=="hovered_dimmed" and type_name!="Tree": continue
			var selected:bool=state.contains("selected")
			var hovered:bool=state.begins_with("hovered")
			var fill:=Color("3c4841") if selected and hovered else (Color("34403b") if selected else Color("343b37"))
			var edge:=OLD_GOLD if state.ends_with("focus") else (Color("83917b") if selected else Color("5b6b60"))
			var existing:=t.get_stylebox(state,type_name) if t.has_stylebox(state,type_name) else ThemeDB.get_default_theme().get_stylebox(state,type_name)
			var surface:=box(fill,edge)
			for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: surface.set_content_margin(side,existing.get_content_margin(side))
			t.set_stylebox(state,type_name,surface)
		for state in ["focus","cursor","cursor_unfocused"]:
			var outline:=box(Color.TRANSPARENT,OLD_GOLD if state!="cursor_unfocused" else Color("798572"))
			outline.set_border_width_all(2 if state=="focus" else 1)
			t.set_stylebox(state,type_name,outline)
	t.set_color("font_hovered_dimmed_color","Tree",DARK_MUTED)
	t.set_stylebox("hover","PopupMenu",box(Color("3c443b"),OLD_GOLD))
	t.set_stylebox("normal","LineEdit",box(Color("303435"),Color("71634b")))
	t.set_stylebox("focus","LineEdit",box(Color("303435"),OLD_GOLD))
	t.set_color("default_color","RichTextLabel",DARK_TEXT)
	t.set_color("font_placeholder_color","LineEdit",DARK_MUTED)
	for type_name in ["VScrollBar","HScrollBar"]:
		t.set_stylebox("scroll",type_name,box(Color("1e2223"),Color.TRANSPARENT))
	return t

static func primary(button: Button) -> void:
	for mode in ["normal","hover","pressed","disabled"]:
		var color:=RED
		if mode=="hover": color=Color("b64b3b")
		elif mode=="pressed": color=Color("813025")
		elif mode=="disabled": color=Color("897866")
		button.add_theme_stylebox_override(mode,trimmed(box(color,Color("c9a46a") if mode!="disabled" else BORDER),Color("f1d3a0") if mode!="disabled" else Color("c7b9a2")))
	for mode in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color","font_hover_pressed_color"]:
		button.add_theme_color_override(mode,Color("fff1d6"))


	button.add_theme_color_override("font_hover_color",HOVER_GOLD)
	button.add_theme_color_override("font_hover_pressed_color",HOVER_GOLD)
	button.add_theme_color_override("font_outline_color",Color.TRANSPARENT)
	button.add_theme_constant_override("outline_size",0)
