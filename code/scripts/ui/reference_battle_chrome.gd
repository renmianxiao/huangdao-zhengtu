extends Control
## Subtle silk, narrow metal rules and one solar round dial. Never takes input.
const GOLD_DARK := Color("504b3d")
const GOLD_MID := Color("8d7853")
const GOLD_LIGHT := Color("ae915d")
var silk: Texture2D
var mode: String = "frame":
	set(value):
		mode = value
		queue_redraw()
var ratio: float = 1.0:
	set(value):
		ratio = clampf(value, 0.0, 1.0)
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if mode == "frame" and ResourceLoader.exists("res://art/ui/materials/ink_silk.png"):
		silk = load("res://art/ui/materials/ink_silk.png")
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0: return
	match mode:
		"health_left", "health_right": _draw_health(mode == "health_right")
		"round": _draw_round()
		"portrait": _draw_portrait()
		_:
			draw_set_transform(Vector2.ZERO, 0, size / Vector2(1920, 1080))
			if mode == "backdrop": _draw_backdrop()
			else: _draw_frame()

func _draw_backdrop() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color("252829"))
	for layer in range(3):
		var points := PackedVector2Array([Vector2(-40, 640)])
		for i in range(18):
			points.append(Vector2(float(i) * 120.0 - 40.0, 250.0 + float(layer) * 77.0 + sin(float(i) * 1.91 + float(layer)) * 90.0))
		points.append(Vector2(2000, 640))
		draw_colored_polygon(points, Color("4b4b44").lerp(Color("252829"), float(layer) / 3.0))

func _draw_frame() -> void:
	# A soft lower veil joins the illustration to the shared resource band.
	for y in range(430, 632, 4):
		var t := float(y - 430) / 202.0
		draw_rect(Rect2(0, y, 1920, 4), Color(0.10, 0.12, 0.12, t * t * 0.94))
	for x in range(0, 1920, 12):
		var edge := pow(absf((float(x) - 960.0) / 960.0), 3.0)
		draw_rect(Rect2(x, 0, 12, 632), Color(0.06, 0.07, 0.07, edge * 0.22))
	var deck := Rect2(0, 631, 1920, 449)
	draw_rect(deck, Color("252829"))
	if silk != null:
		draw_texture_rect(silk, deck, false, Color(1, 1, 1, 0.30))
	# The deck and cards each have one edge, with quiet travel-route marks.
	draw_line(Vector2(20, 628), Vector2(1900, 628), GOLD_MID, 1, true)
	draw_line(Vector2(20, 1047), Vector2(1900, 1047), GOLD_DARK, 1, true)
	for side in [0, 1]:
		var x := 30.0 if side == 0 else 1890.0
		var direction := 1.0 if side == 0 else -1.0
		for y in [638.0, 1036.0]:
			draw_line(Vector2(x, y), Vector2(x + direction * 42, y), GOLD_LIGHT, 1, true)
			draw_circle(Vector2(x + direction * 48, y), 2, GOLD_LIGHT)
	# AP sits on one restrained horizontal rule, with no large ornaments.
	draw_line(Vector2(510, 601), Vector2(630, 601), GOLD_DARK, 1, true)
	draw_line(Vector2(1290, 601), Vector2(1410, 601), GOLD_DARK, 1, true)

func _draw_round() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.5)
	var radius := minf(size.x, size.y) * 0.48
	draw_circle(center, radius, Color("252829"))
	draw_arc(center, radius, 0, TAU, 80, GOLD_MID, 1, true)
	for i in range(24):
		var angle := float(i) * TAU / 24.0
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(center + direction * (radius - (6 if i % 3 == 0 else 3)), center + direction * (radius - 1), GOLD_LIGHT, 1, true)

func _draw_health(ally: bool) -> void:
	var body := Rect2(Vector2.ZERO, size)
	draw_rect(body, Color("171c1c"))
	var inner := body.grow(-2)
	var fill_width := maxf(0, inner.size.x * ratio)
	var fill := Rect2(inner.position + Vector2(inner.size.x - fill_width if ally else 0.0, 0), Vector2(fill_width, inner.size.y))
	if fill_width > 0:
		var hue := Color("597e79") if ally else Color("a34237")
		draw_rect(fill, hue)
		# Lacquer sheen on the upper half, a deeper lower lip, and a bright leading edge.
		draw_rect(Rect2(fill.position, Vector2(fill.size.x, fill.size.y * 0.45)), Color(1, 0.95, 0.85, 0.16))
		draw_rect(Rect2(fill.position + Vector2(0, fill.size.y * 0.75), Vector2(fill.size.x, fill.size.y * 0.25)), Color(0, 0, 0, 0.22))
		draw_line(fill.position + Vector2(0, 1), fill.position + Vector2(fill.size.x, 1), Color(0.91, 0.87, 0.8, 0.30), 1)
		var lead := fill.position.x if ally else fill.end.x
		draw_line(Vector2(lead, fill.position.y), Vector2(lead, fill.end.y), hue.lightened(0.45), 2)
	draw_rect(body, GOLD_MID, false, 1)
	for x in [0.0, size.x]:
		var c := Vector2(x, size.y * 0.5)
		var r := minf(6.0, size.y * 0.5)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-r, 0), c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r)]), GOLD_LIGHT)
	for i in range(1, 5):
		var x := size.x * float(i) / 5.0
		draw_line(Vector2(x, size.y - 5), Vector2(x, size.y - 1), Color(0.91, 0.87, 0.8, 0.26), 1)

func _draw_portrait() -> void:
	draw_rect(Rect2(Vector2.ONE, size - Vector2.ONE * 2), GOLD_MID, false, 1)
