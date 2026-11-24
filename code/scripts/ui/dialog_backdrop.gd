extends RefCounted
## Generated nine-patch paper: its corners keep their shape at every popup size.
## Materials carry all ornamentation, so decorative nodes cannot intercept input.
static var _paper: Texture2D
static var _close: Texture2D

static func paper_panel() -> StyleBoxTexture:
	if _paper == null:
		_paper = _texture(_paper_svg())
	var panel := StyleBoxTexture.new()
	panel.texture = _paper
	for edge in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		panel.set_texture_margin(edge, 32)
	panel.content_margin_left = 32
	panel.content_margin_right = 32
	panel.content_margin_top = 24
	panel.content_margin_bottom = 24
	return panel

static func window_frame() -> StyleBoxFlat:
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("252829")
	frame.border_color = Color("ae915d")
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(2)
	frame.expand_margin_top = 40
	frame.expand_margin_left = 2
	frame.expand_margin_right = 2
	frame.expand_margin_bottom = 2
	frame.content_margin_left = 2
	frame.content_margin_right = 2
	frame.content_margin_top = 0
	frame.content_margin_bottom = 2
	frame.shadow_color = Color(0.10, 0.06, 0.025, 0.35)
	frame.shadow_size = 14
	frame.shadow_offset = Vector2(0, 5)
	return frame

static func close_icon() -> Texture2D:
	if _close == null:
		_close = _texture('<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20"><path d="M5 5L15 15M15 5L5 15" fill="none" stroke="#e8decc" stroke-width="1.5" stroke-linecap="round"/></svg>')
	return _close

static func _texture(source: String) -> ImageTexture:
	var bitmap := Image.new()
	bitmap.load_svg_from_string(source)
	return ImageTexture.create_from_image(bitmap)

static func _paper_svg() -> String:
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="720" height="480" viewBox="0 0 720 480"><defs><radialGradient id="paper" cx=".48" cy=".40" r=".8"><stop stop-color="#fcf6e9"/><stop offset=".7" stop-color="#f5ebd7"/><stop offset="1" stop-color="#e9d8b4"/></radialGradient></defs><rect width="720" height="480" fill="url(#paper)"/>'
	# Deterministic fibres are baked once; there is no shader or per-frame noise.
	for i in range(1300):
		var x := 10 + (i * 137 + i * i * 17) % 700
		var y := 10 + (i * 83 + i * i * 11) % 460
		var width := 1 + i % 3
		svg += '<path d="M%d %dh%d" stroke="#8a7048" stroke-width=".6" opacity=".055"/>' % [x, y, width]
	for i in range(170):
		var x := 12 + (i * 103) % 696
		var y := 12 + (i * 149) % 456
		svg += '<path d="M%d %dl4 -1" stroke="#ffffff" stroke-width=".8" opacity=".24"/>' % [x, y]
	# The outer ink-gold keyline and fine inset rule read as a bound paper note.
	svg += '<rect x="1" y="1" width="718" height="478" rx="2" fill="none" stroke="#a17b43" stroke-width="1.5"/><rect x="6" y="6" width="708" height="468" rx="1" fill="none" stroke="#c8ae77" stroke-width=".7"/>'
	for transform in ['translate(0 0)', 'translate(720 0) scale(-1 1)', 'translate(0 480) scale(1 -1)', 'translate(720 480) scale(-1 -1)']:
		svg += '<g transform="%s" fill="none" stroke="#b3935b" stroke-width="1" opacity=".8"><path d="M11 30V12h19M14 26v-11h12M16 21h5c4 0 6-2 6-5 0-2-2-4-4-4M20 27v-5h5"/><path d="M10 34h5M34 10v5" stroke-width=".65"/></g>' % transform
	svg += '<path d="M39 10H333M387 10H681" fill="none" stroke="#b49459" stroke-width=".65" opacity=".52"/><path d="M360 7l3 3-3 3-3-3z" fill="#aa8044" opacity=".75"/></svg>'
	return svg
