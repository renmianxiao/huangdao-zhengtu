extends Button
const Professions=preload("res://code/scripts/profession_names.gd")
const CardColors=preload("res://code/scripts/ui/character_card_colors.gd")
## A selectable recruitment entry. Availability belongs to the screen's action,
## so even an entry with a reason remains focusable and selectable.

const ThemePaper=preload("res://code/scripts/ui/global_theme.gd")
const PAPER := Color("e8decc")
const INK := Color("413c34")
const MUTED := Color("635d53")
const GOLD := Color("ae915d")
const BORDER := Color("baa47c")
const CRIMSON := Color("a13e32")

var character_id: String = ""
var character_name: String = ""
var profession: String = ""
var cost: int = 0
var action: String = "招募"
var state: String = "未招募"
var tier: int = 0
var texture: Texture2D
var reason: String = ""
var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(0.0, 116.0)
	clip_text = true
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for mode: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(mode, StyleBoxEmpty.new())
	for mode: String in ["font_color", "font_disabled_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_outline_color"]:
		add_theme_color_override(mode, Color.TRANSPARENT)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	resized.connect(queue_redraw)


func configure(data: Dictionary) -> void:
	character_id = str(data.get("id", ""))
	character_name = str(data.get("name", ""))
	profession = Professions.label(str(data.get("profession", "")))
	cost = int(data.get("cost", 0))
	action = str(data.get("action", "招募"))
	state = str(data.get("state", "未招募"))
	tier = int(data.get("tier", 0))
	texture = data.get("texture") as Texture2D
	reason = str(data.get("reason", ""))
	disabled = false
	text = "%s · %s · %s · %d 声望 · %s" % [character_name, profession, action, cost, state]
	if not reason.is_empty():
		text += " · " + reason
	tooltip_text = text
	queue_redraw()


func _get_minimum_size() -> Vector2:
	return Vector2(0.0, 164.0)


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 48.0 or h < 48.0:
		return
	var font := ThemePaper.body_font()
	var heading := ThemePaper.heading_font()
	var portrait_right := floorf(w * 0.44)
	var content_left := portrait_right + 10.0
	var content_right := w - 13.0
	var content_width := maxf(content_right - content_left, 1.0)
	var frame := _ribbon_outline(w, h, 1.0)
	var fill := CardColors.background(character_id)
	if is_hovered():
		fill = CardColors.background(character_id).darkened(0.035)
	if button_pressed:
		fill = CardColors.background(character_id).darkened(0.065)
	if selected:
		fill = CardColors.background(character_id)
	draw_colored_polygon(frame, fill)

	# Audited head bounds protect hair and crowns across card widths.
	var portrait_rect := Rect2(3.0, 3.0, portrait_right + 6.0, h - 6.0)
	draw_rect(portrait_rect, CardColors.background(character_id).darkened(0.05))
	if texture != null:
		_draw_portrait(portrait_rect)
	else:
		draw_circle(Vector2(portrait_right * 0.5, h * 0.37), 15.0, Color("b8aa90"))
		draw_arc(Vector2(portrait_right * 0.5, h * 0.93), 35.0, PI, TAU, 24, Color("b8aa90"), 19.0, true)

	# This paper wedge makes the portrait's edge echo the angled ribbon.
	draw_colored_polygon(PackedVector2Array([
		Vector2(portrait_right - 8.0, 2.0), Vector2(w - 10.0, 2.0),
		Vector2(w - 2.0, 10.0), Vector2(w - 2.0, h - 2.0),
		Vector2(portrait_right + 9.0, h - 2.0)
	]), fill)
	draw_line(Vector2(portrait_right - 8.0, 3.0), Vector2(portrait_right + 9.0, h - 3.0), Color("cab58f"), 1.0, true)
	# Close the small outside corners after drawing the rectangular art crop.
	draw_colored_polygon(PackedVector2Array([Vector2(1.0, 1.0), Vector2(10.0, 1.0), Vector2(1.0, 10.0)]), PAPER)
	draw_colored_polygon(PackedVector2Array([Vector2(1.0, h - 1.0), Vector2(10.0, h - 1.0), Vector2(1.0, h - 10.0)]), PAPER)

	var tier_color := CardColors.edge(character_id)
	draw_colored_polygon(PackedVector2Array([
		Vector2(11.0, h - 5.0), Vector2(portrait_right + 5.0, h - 5.0),
		Vector2(portrait_right + 5.5, h - 2.0), Vector2(8.0, h - 2.0)
	]), tier_color)

	var name_size := 25 if w >= 300.0 else 21
	var name_width := content_width - (17.0 if selected else 0.0)
	_draw_fitted(heading, character_name, Vector2(content_left, 34.0), name_width, name_size, INK)
	_draw_fitted(font, profession, Vector2(content_left + 1.0, 57.0), content_width, 16, MUTED)
	draw_line(Vector2(content_left, 69.0), Vector2(content_right, 69.0), Color("d6c5a6"), 1.0, true)

	var fee_color := CRIMSON if reason.is_empty() else MUTED
	var action_color := INK if reason.is_empty() else MUTED
	draw_string(font, Vector2(content_left, 95.0), action, HORIZONTAL_ALIGNMENT_LEFT, content_width * 0.47, 16, action_color)
	var fee := "%d 声望" % cost
	var fee_width := font.get_string_size(fee, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_string(font, Vector2(content_right - fee_width, 122.0), fee, HORIZONTAL_ALIGNMENT_LEFT, fee_width, 18, fee_color)

	_draw_state_badge(font, h, portrait_right)
	if not reason.is_empty():
		_draw_fitted(font, reason, Vector2(content_left, h - 13.0), content_width, 14, MUTED)
	else:
		_draw_fitted(font, " / ".join(preload("res://code/scripts/characters/tactical_tags.gd").for_character(character_id)), Vector2(content_left, h - 13.0), content_width, 14, Color("66513b"))

	var outline_color := GOLD if selected else CardColors.edge(character_id)
	draw_polyline(frame, outline_color, 3.0 if selected else 1.0, true)
	_draw_rarity(w, h)
	if has_focus():
		draw_polyline(_ribbon_outline(w, h, 4.0), Color("b18a4b"), 1.0, true)
	if selected:
		var tick_x := w - 18.0
		draw_colored_polygon(PackedVector2Array([Vector2(w - 30.0, 2.0), Vector2(w - 10.0, 2.0), Vector2(w - 2.0, 10.0), Vector2(w - 2.0, 30.0)]), GOLD)
		draw_polyline(PackedVector2Array([Vector2(tick_x - 4.0, 11.0), Vector2(tick_x - 1.0, 14.0), Vector2(tick_x + 5.0, 7.0)]), PAPER, 1.8, true)


## Gilt double rule and curls for 3-renown heroes, bronze diamonds for 1, none for 0.
func _draw_rarity(w: float, h: float) -> void:
	var level := CardColors.tier(character_id)
	if level == 0 or character_id.is_empty():
		return
	var color: Color = CardColors.ORNAMENTS[level]
	if level == 3:
		draw_polyline(_ribbon_outline(w, h, 5.0), Color(color, 0.7), 1.0, true)
		for corner: Vector2 in [Vector2(w - 14.0, 14.0), Vector2(w - 14.0, h - 14.0)]:
			var dir := Vector2(-1.0, 1.0 if corner.y < h * 0.5 else -1.0)
			preload("res://code/scripts/ui/map_ornament.gd").curl(self, corner + dir * 4.0, dir * 0.42, color)
		draw_rect(Rect2(3.0, 3.0, w - 6.0, 3.0), Color(color, 0.55))
	else:
		for y in [12.0, h - 12.0]:
			preload("res://code/scripts/ui/map_ornament.gd").diamond(self, Vector2(w - 12.0, y), 3.0, color)


func _draw_portrait(destination: Rect2) -> void:
	var source:=CardColors.portrait_region(character_id,texture,destination.size)
	draw_texture_rect_region(texture,CardColors.portrait_destination(source,destination),source)


func _draw_state_badge(font: Font, h: float, portrait_right: float) -> void:
	var badge_color := Color("5b5140")
	if state == "已招募":
		badge_color = Color("49624d")
	elif state == "已强化":
		badge_color = Color("8b4d3b")
	var badge_width := minf(font.get_string_size(state, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 12.0, portrait_right - 14.0)
	var badge_rect := Rect2(9.0, h - 30.0, badge_width, 21.0)
	draw_rect(badge_rect, PAPER)
	draw_rect(badge_rect, Color("b9a37a"), false, 1.0)
	_draw_fitted(font, state, Vector2(15.0, h - 14.0), badge_width - 10.0, 13, badge_color)


func _draw_fitted(font: Font, value: String, position: Vector2, width: float, font_size: int, color: Color) -> void:
	if width <= 0.0 or value.is_empty():
		return
	var rendered := value
	if font.get_string_size(rendered, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		while rendered.length() > 1 and font.get_string_size(rendered + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
			rendered = rendered.left(rendered.length() - 1)
		rendered += "…"
	draw_string(font, position, rendered, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)


func _ribbon_outline(w: float, h: float, inset: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(10.0, inset), Vector2(w - 10.0, inset),
		Vector2(w - inset, 10.0), Vector2(w - inset, h - 10.0),
		Vector2(w - 10.0, h - inset), Vector2(10.0, h - inset),
		Vector2(inset, h - 10.0), Vector2(inset, 10.0), Vector2(10.0, inset)
	])

