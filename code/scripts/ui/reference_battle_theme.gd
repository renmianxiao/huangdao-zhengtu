extends RefCounted
## Battle materials share the run's charcoal, silk, jade and old-gold palette.
const Paper = preload("res://code/scripts/ui/global_theme.gd")
const INK = Color("e8decc")
const MUTED = Color("b7ad98")
const GOLD = Color("ae915d")
const TEAL = Color("597e79")
const RED = Color("a34237")
const PANEL = Color("252829")
const PAPER = Color("191c1d")
const BORDER = Color("71634b")
const GREEN = Color("8eaaa2")
static var _coin_materials: Dictionary = {}

static func box(color: Color, border: Color = BORDER) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

static func make(font_size: int = 18) -> Theme:
	return Paper.make_dark(font_size)

static func _button_states(button: Button, normal: Color, hover: Color, pressed: Color, edge: Color, text_color: Color) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var surface := normal
		if state == "hover": surface = hover
		elif state == "pressed": surface = pressed
		elif state == "disabled": surface = normal.darkened(0.16)
		var material := box(surface, edge if state != "disabled" else Color("52514a"))
		button.add_theme_stylebox_override(state, material)
	for state in ["font_color", "font_hover_color", "font_hover_pressed_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, text_color)
	button.add_theme_color_override("font_disabled_color", Color("a39d90"))
	button.add_theme_color_override("font_hover_color", Paper.HOVER_GOLD)
	button.add_theme_color_override("font_hover_pressed_color", Paper.HOVER_GOLD)
	button.add_theme_constant_override("outline_size", 0)
	var focus := box(Color.TRANSPARENT, INK)
	focus.set_border_width_all(1)
	button.add_theme_stylebox_override("focus", focus)

static func primary(button: Button) -> void:
	_button_states(button, RED, Color("b04e41"), Color("87372f"), Color("bc8263"), INK)
	for state in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, Paper.trimmed(button.get_theme_stylebox(state)))

static func style_skill(button: Button) -> void:
	_button_states(button, Color("252829"), Color("3b3d37"), Color("1b1f20"), BORDER, INK)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var material: StyleBoxFlat = button.get_theme_stylebox(state).duplicate()
		material.content_margin_left = 9
		material.content_margin_right = 9
		material.content_margin_top = 2
		material.content_margin_bottom = 2
		if state == "hover": material.border_color = GOLD
		button.add_theme_stylebox_override(state, material)
	button.add_theme_color_override("font_disabled_color", Color("99988e"))
	button.add_theme_color_override("icon_disabled_color", Color("787d73"))

static func style_passive(button: Button) -> void:
	# A jade inset distinguishes an inspectable passive from an AP action.
	_button_states(button, Color("25312f"), Color("32423d"), Color("202d2a"), Color("566d60"), Color("c5d0bd"))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var surface: StyleBoxFlat = button.get_theme_stylebox(state).duplicate()
		surface.border_width_left = 3
		surface.content_margin_left = 9
		surface.content_margin_right = 9
		surface.content_margin_top = 2
		surface.content_margin_bottom = 2
		button.add_theme_stylebox_override(state, surface)
	button.add_theme_color_override("icon_normal_color", Color("a3bda8"))

static func style_card_state(panel: PanelContainer, used: bool, waiting: bool) -> void:
	# Signal action availability in the frame; never wash out the character art.
	var surface: StyleBoxFlat = panel.get_theme_stylebox("panel")
	surface.border_color = Color("505650") if used else (Color("5c665e") if waiting else BORDER)
	panel.queue_redraw()

static func style_tool(button: Button, kind: String = "gold") -> void:
	if kind == "red":
		primary(button)
	elif kind == "blue":
		_button_states(button, Color("304340"), Color("3e5752"), Color("263633"), Color("718c80"), INK)
	else:
		_button_states(button, PANEL, Color("393c39"), Color("1d2021"), BORDER, INK)

static func style_portrait(panel: PanelContainer) -> void:
	# The card has the one outer frame; a second frame would shrink the painting.
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

static func style_coin(label: Label, lit: bool) -> void:
	if not _coin_materials.has(lit):
		# Lit pips are bronze cash coins; spent ones are their dark impressions.
		var fill := "c4a465" if lit else "262a2a"
		var edge := "ecd19a" if lit else "5d5a4c"
		var hole := "3a2f22" if lit else "1a1d1d"
		var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48"><defs><radialGradient id="g" cx=".38" cy=".32" r=".8"><stop offset="0" stop-color="#fff3d0" stop-opacity="%s"/><stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient></defs><circle cx="24" cy="24" r="19" fill="#%s" stroke="#%s" stroke-width="1.6"/><circle cx="24" cy="24" r="14.5" fill="none" stroke="#%s" stroke-opacity=".7" stroke-width="1"/><rect x="19" y="19" width="10" height="10" fill="#%s" stroke="#%s" stroke-width="1.2"/><circle cx="24" cy="24" r="19" fill="url(#g)"/></svg>' % [".55" if lit else "0", fill, edge, edge, hole, edge]
		var image := Image.new()
		image.load_svg_from_string(svg)
		var material := StyleBoxTexture.new()
		material.texture = ImageTexture.create_from_image(image)
		_coin_materials[lit] = material
	label.add_theme_stylebox_override("normal", _coin_materials[lit])
	label.add_theme_constant_override("outline_size", 0)
