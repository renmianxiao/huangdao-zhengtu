extends StyleBox
## Wraps a flat paper box and adds gilt corner brackets. Ornaments scale down
## with small panels and vanish entirely on tiny ones, so dense lists stay calm.
var base: StyleBox
var ornament := Color("ad8b56")
## 0 plain brackets, 1 brackets with diamonds, 2 double rule with curls.
var grade := 0
## Buttons get an inner gilt rule and side diamonds instead of corner brackets.
var trim := false

static func wrap(source: StyleBox, color: Color = Color("ad8b56"), level: int = 0) -> StyleBox:
	var box = load("res://code/scripts/ui/ornate_box.gd").new()
	box.base = source
	box.ornament = color
	box.grade = level
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_content_margin(side, source.get_margin(side))
	return box

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if base != null: base.draw(to_canvas_item, rect)
	if trim:
		if rect.size.y < 22.0 or rect.size.x < 48.0: return
		var rule := rect.grow(-3.0)
		RenderingServer.canvas_item_add_polyline(to_canvas_item, _outline(rule), PackedColorArray([Color(ornament, 0.65)]), 1.0, true)
		for x in [rule.position.x + 8.0, rule.end.x - 8.0]:
			_diamond(to_canvas_item, Vector2(x, rect.get_center().y), 3.2)
		return
	var shortest := minf(rect.size.x, rect.size.y)
	if shortest < 56.0: return
	var arm := clampf(shortest * 0.12, 9.0, 20.0)
	var inset := 4.0
	var inner := rect.grow(-inset)
	if grade >= 2:
		RenderingServer.canvas_item_add_polyline(to_canvas_item, _outline(inner), PackedColorArray([Color(ornament, 0.55)]), 1.0, true)
	for corner: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
		var origin := inner.position + inner.size * corner
		var dir := Vector2(1 if corner.x == 0 else -1, 1 if corner.y == 0 else -1)
		var bracket := PackedVector2Array([origin + Vector2(0, arm) * dir, origin, origin + Vector2(arm, 0) * dir])
		RenderingServer.canvas_item_add_polyline(to_canvas_item, bracket, PackedColorArray([ornament]), 1.6 if grade >= 1 else 1.2, true)
		var step := PackedVector2Array([origin + Vector2(3, arm * 0.62) * dir, origin + Vector2(3, 3) * dir, origin + Vector2(arm * 0.62, 3) * dir])
		RenderingServer.canvas_item_add_polyline(to_canvas_item, step, PackedColorArray([Color(ornament, 0.6)]), 0.8, true)
		if grade >= 1:
			var c := origin + Vector2(arm + 4, 0) * dir
			_diamond(to_canvas_item, c, 2.6)
			_diamond(to_canvas_item, origin + Vector2(0, arm + 4) * dir, 2.6)
		if grade >= 2:
			_curl(to_canvas_item, origin + Vector2(8, 8) * dir, dir * 0.38)

func _outline(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position])

func _diamond(item: RID, center: Vector2, radius: float) -> void:
	RenderingServer.canvas_item_add_polygon(item, PackedVector2Array([center + Vector2(-radius, 0), center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius)]), PackedColorArray([ornament]))

func _curl(item: RID, origin: Vector2, scale_value: Vector2) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		var t := float(i) / 31
		var angle := t * TAU * 1.25
		var radius := 11.0 * (1.0 - t) + 1
		points.append(origin + Vector2(cos(angle), sin(angle)) * radius * scale_value)
	RenderingServer.canvas_item_add_polyline(item, points, PackedColorArray([ornament]), 1.0, true)
