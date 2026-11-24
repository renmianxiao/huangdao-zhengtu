extends RefCounted
## Shared presentation for native AcceptDialog and ConfirmationDialog windows.
## Call after content is created. Repeated application never reparents content.
const Paper = preload("res://code/scripts/ui/global_theme.gd")
const Backdrop = preload("res://code/scripts/ui/dialog_backdrop.gd")
const INK = Paper.INK
const MUTED = Paper.MUTED
const GOLD = Paper.OLD_GOLD

static func apply(dialog: AcceptDialog, kind: String = "info") -> void:
	dialog.set_meta("wuxia_dialog_kind", kind)
	dialog.theme = _make_theme()
	_style_contents(dialog, dialog.get_ok_button())
	_style_primary(dialog.get_ok_button())
	# Native button box and label remain owned by AcceptDialog. Their signal and
	# keyboard handling are unchanged, including Cancel and window close.
	var label := dialog.get_label()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_constant_override("line_spacing", 5)
	label.add_theme_color_override("font_color", INK)
	label.add_theme_font_size_override("font_size", 17)

static func _make_theme() -> Theme:
	var theme := Paper.make(17)
	theme.set_stylebox("panel", "AcceptDialog", Backdrop.paper_panel())
	theme.set_stylebox("embedded_border", "Window", Backdrop.window_frame())
	theme.set_stylebox("embedded_unfocused_border", "Window", Backdrop.window_frame())
	theme.set_constant("title_height", "Window", 40)
	theme.set_font_size("title_font_size", "Window", 20)
	theme.set_constant("close_h_offset", "Window", 25)
	theme.set_constant("close_v_offset", "Window", 29)
	theme.set_color("title_color", "Window", Paper.DARK_TEXT)
	theme.set_color("title_outline_modulate", "Window", Color.TRANSPARENT)
	theme.set_icon("close", "Window", Backdrop.close_icon())
	theme.set_icon("close_pressed", "Window", Backdrop.close_icon())
	theme.set_constant("buttons_min_height", "AcceptDialog", 40)
	theme.set_constant("buttons_min_width", "AcceptDialog", 112)
	theme.set_constant("buttons_separation", "AcceptDialog", 12)
	theme.set_constant("v_separation", "AcceptDialog", 16)
	theme.set_constant("separation", "HBoxContainer", 12)
	theme.set_color("default_color", "RichTextLabel", INK)
	theme.set_constant("line_separation", "RichTextLabel", 4)
	theme.set_constant("paragraph_separation", "RichTextLabel", 9)
	theme.set_stylebox("normal", "RichTextLabel", StyleBoxEmpty.new())
	return theme

static func _style_contents(node: Node, primary: Button) -> void:
	for child in node.get_children(true):
		if child is Button:
			if child != primary:
				_style_secondary(child)
		elif child is Label:
			child.add_theme_color_override("font_color", INK)
			child.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
			child.add_theme_constant_override("outline_size", 0)
		elif child is RichTextLabel:
			child.add_theme_color_override("default_color", INK)
			child.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
			child.add_theme_constant_override("outline_size", 0)
			child.add_theme_constant_override("line_separation", 4)
			child.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		elif child is PanelContainer or (child is Panel and not node is AcceptDialog):
			# Battle-local panels may have dark style overrides; popup paper owns
			# this surface while retaining the existing children and layout.
			var surface := Paper.box(Color("f4ead5"), Color("d1ba89"))
			surface.content_margin_left = 12
			surface.content_margin_right = 12
			surface.content_margin_top = 10
			surface.content_margin_bottom = 10
			child.add_theme_stylebox_override("panel", surface)
		_style_contents(child, primary)

static func _style_secondary(button: Button) -> void:
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 40)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var color := Color("f3e8d0")
		if state == "hover": color = Color("ead8b2")
		elif state == "pressed": color = Color("dfc69b")
		elif state == "disabled": color = Color("eee5d4")
		var material := _button_box(color, GOLD)
		button.add_theme_stylebox_override(state, material)
	for state in ["font_color", "font_hover_color", "font_hover_pressed_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, INK)
	button.add_theme_color_override("font_hover_color", Paper.HOVER)
	button.add_theme_color_override("font_hover_pressed_color", Paper.HOVER)
	button.add_theme_color_override("font_disabled_color", Color("a6977d"))
	button.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	button.add_theme_constant_override("outline_size", 0)
	var focus := _button_box(Color.TRANSPARENT, Color("795b30"))
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)

static func _style_primary(button: Button) -> void:
	_style_secondary(button)
	button.custom_minimum_size.x = maxf(button.custom_minimum_size.x, 120)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var color := Color("963d30")
		if state == "hover": color = Color("af4d3a")
		elif state == "pressed": color = Color("7c2f25")
		elif state == "disabled": color = Color("9e8b76")
		button.add_theme_stylebox_override(state, _button_box(color, Color("b28b4d")))
	for state in ["font_color", "font_hover_color", "font_hover_pressed_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(state, Color("fff2da"))

	button.add_theme_color_override("font_hover_color", Paper.HOVER_GOLD)
	button.add_theme_color_override("font_hover_pressed_color", Paper.HOVER_GOLD)
	button.add_theme_color_override("font_outline_color",Color.TRANSPARENT)
	button.add_theme_constant_override("outline_size",0)

static func _button_box(color: Color, border: Color) -> StyleBoxFlat:
	var box := Paper.box(color, border)
	box.set_corner_radius_all(2)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box
