extends Control
signal sound_requested(cue: Dictionary, stage: String)
signal effects_cleared
## Transparent, self-contained battle feedback. All coordinates are local pixels.
## A batch may overlap the previous batch; its return value is the remaining tail.

const GOLD := Color("e8be69")
const WHITE_GOLD := Color("fff3d4")
const INK := Color("43382f")
const CYAN := Color("91e7e9")
const JADE := Color("79d7ae")
const PURPLE := Color("bf8cde")
const SILVER := Color("d6e5ef")
const MAX_EFFECTS := 48
const Paint=preload("res://code/scripts/ui/vfx_paint.gd")

class EffectCanvas extends Control:
	var cue: Dictionary = {}
	var phase := 0.0
	func _draw() -> void:
		if get_parent() != null:
			get_parent()._draw_effect(self, cue, phase)

var _effects: Array[Dictionary] = []

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	set_process(false)

func play(cues: Array, quick: bool = false) -> float:
	var accepted: Array[Dictionary] = []
	for value in cues:
		if value is Dictionary and not value.is_empty():
			accepted.append(value.duplicate(true))
			if accepted.size() >= MAX_EFFECTS:
				break
	if accepted.size()==1 and str(accepted[0].get("kind",""))=="cast":
		var op:=str(accepted[0].get("primary_op",""))
		accepted[0].cast_sound="guard" if op in ["percent_guard","flat_guard","counter","carry_shield"] else "buff"
	var speed := 0.5 if quick else 1.0
	var interval := minf(0.065, 0.61 / maxf(1.0, float(accepted.size() - 1))) * speed
	for index in range(accepted.size()):
		while _effects.size() >= MAX_EFFECTS:
			_retire(0)
		var cue := accepted[index]
		var area: Rect2 = cue.get("area", Rect2(Vector2.ZERO, size))
		if area.size.x <= 0.0 or area.size.y <= 0.0:
			area = Rect2(Vector2.ZERO, size.max(Vector2.ONE))
		cue["area"] = area
		cue["origin"] = cue.get("origin", area.get_center())
		cue["target"] = cue.get("target", area.get_center())
		_place_feedback_text(cue)
		var canvas := EffectCanvas.new()
		canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.clip_contents = true
		canvas.show_behind_parent = true
		canvas.position = area.position
		canvas.size = area.size
		canvas.cue = cue
		canvas.visible = index == 0
		add_child(canvas)
		var duration := (0.30 if str(cue.get("kind", "damage")) == "cast" else 0.62) * speed
		_effects.append({"cue": cue, "canvas": canvas, "age": -float(index) * interval, "duration": duration,"launch_played":false,"hit_played":false})
	if not _effects.is_empty():
		set_process(true)
		queue_redraw()
	return _remaining_duration()

func _place_feedback_text(cue: Dictionary) -> void:
	if str(cue.get("kind","")) == "cast": return
	var scale := _visual_scale()
	var width := maxf(135.0,float(str(cue.get("name","")).length())*22.0)*scale
	width=minf(width,maxf(1,size.x-28))
	var safe := Rect2(Vector2(12,12),(size-Vector2(24,24)).max(Vector2.ONE)).intersection(cue.area)
	width=minf(width,maxf(1,safe.size.x-4))
	var start: Vector2=cue.target
	var candidate := start
	var bounds := Rect2()
	# Reserve the entire text drift, including the second absorption line.
	for column in [0,-1,1,-2,2]:
		for row in range(5):
			candidate=start+Vector2(column*(width+8),-float(row)*94*scale)
			candidate.x=clampf(candidate.x,safe.position.x+width*0.5,safe.end.x-width*0.5)
			candidate.y=clampf(candidate.y,minf(safe.position.y+84*scale,safe.end.y-8*scale),safe.end.y-8*scale)
			bounds=Rect2(candidate-Vector2(width*0.5,82*scale),Vector2(width,84*scale))
			var occupied := false
			for existing in _effects:
				var other: Dictionary=existing.cue
				if other.has("text_bounds") and not other.get("hide_text",false) and bounds.grow(3*scale).intersects(other.text_bounds):
					occupied=true
					break
			if not occupied:
				cue.text_target=candidate
				cue.text_bounds=bounds
				return
	# Extreme bursts keep the newest labels readable and retain all geometry.
	for existing in _effects:
		var other: Dictionary=existing.cue
		if other.has("text_bounds") and bounds.intersects(other.text_bounds): other.hide_text=true
	cue.text_target=candidate
	cue.text_bounds=bounds

func clear_effects() -> void:
	effects_cleared.emit()
	for effect in _effects:
		var canvas = effect["canvas"]
		if is_instance_valid(canvas):
			remove_child(canvas)
			canvas.queue_free()
	_effects.clear()
	set_process(false)
	queue_redraw()

func is_active() -> bool:
	return not _effects.is_empty()

func _remaining_duration() -> float:
	var remaining := 0.0
	for effect in _effects:
		remaining = maxf(remaining, float(effect["duration"]) - float(effect["age"]))
	return remaining

func _retire(index: int) -> void:
	var canvas = _effects[index]["canvas"]
	if is_instance_valid(canvas):
		remove_child(canvas)
		canvas.queue_free()
	_effects.remove_at(index)

func _process(delta: float) -> void:
	for index in range(_effects.size() - 1, -1, -1):
		var effect := _effects[index]
		effect["age"] = float(effect["age"]) + delta
		if float(effect["age"]) >= float(effect["duration"]):
			_retire(index)
			continue
		var canvas: EffectCanvas = effect["canvas"]
		canvas.visible = float(effect["age"]) >= 0.0
		if canvas.visible:
			canvas.phase = float(effect["age"]) / float(effect["duration"])
			if not effect.launch_played:
				effect.launch_played=true
				sound_requested.emit(effect.cue,"launch")
			if not effect.hit_played and canvas.phase>=impact_phase(effect.cue):
				effect.hit_played=true
				sound_requested.emit(effect.cue,"hit")
			canvas.queue_redraw()
	queue_redraw()
	if _effects.is_empty():
		set_process(false)

func _draw() -> void:
	for effect in _effects:
		if float(effect["age"]) < 0.0:
			continue
		_draw_feedback(effect["cue"], float(effect["age"]) / float(effect["duration"]))

func _draw_effect(canvas: Control, cue: Dictionary, phase: float) -> void:
	var area: Rect2 = cue["area"]
	var target: Vector2 = cue["target"] - area.position
	var origin: Vector2 = cue["origin"] - area.position
	if str(cue.get("kind", "damage")) == "cast":
		var alpha := clampf(phase / 0.065, 0.0, 1.0) * pow(1.0 - phase, 0.65)
		_draw_cast(canvas, area.size, phase, alpha)
		return
	var visual_scale := _visual_scale()
	# Enlarge strokes around their target, preserving both missile endpoints.
	canvas.draw_set_transform(target, 0.0, Vector2.ONE * visual_scale)
	_draw_geometry(canvas, cue, phase, (origin - target) / visual_scale, Vector2.ZERO)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_geometry(canvas: Control, cue: Dictionary, phase: float, origin: Vector2, target: Vector2) -> void:
	var kind := str(cue.get("kind", "damage"))
	var family := str(cue.get("family", "impact"))
	var power := clampf(float(cue.get("power", 1.0)), 0.35, 2.0)
	var alpha := clampf(phase / 0.065, 0.0, 1.0) * pow(1.0 - phase, 0.65)
	var accent: Color = cue.get("accent", CYAN)
	var contact := impact_phase(cue)
	Paint.draw(canvas,cue,origin,target,phase,contact)
	# Keep the bright mark behind the same contact used by audio and damage text.
	# Travelling weapons retain their full timeline; stationary marks burst on contact.
	if kind == "damage" and family in ["slash", "impact", "arcane"]:
		if phase < contact:
			return
		phase = clampf((phase - contact) / (1.0 - contact), 0.0, 1.0)
		alpha = (1.0 - smoothstep(0.18, 1.0, phase)) * (0.7 + 0.3 * power / 2.0)
	match kind:
		"heal":
			_draw_heal(canvas, target, phase, alpha)
			return
		"shield":
			_draw_shield(canvas, target, phase, alpha)
			return
		"buff":
			_draw_buff(canvas, target, phase, alpha)
			return
		"armor_break":
			_draw_armor_break(canvas, target, phase, alpha)
			return
		"interrupt":
			_draw_interrupt(canvas, target, phase, alpha)
			return
		"poison_add", "poison_apply", "poison_consume", "poison_tick":
			_draw_poison(canvas, target, phase, alpha, kind)
			return
		"enemy_action":
			if family == "shield" or family == "guard":
				_draw_shield(canvas, target, phase, alpha)
			else:
				_draw_buff(canvas, target, phase, alpha)
			return
	match family:
		"slash": _draw_slash(canvas, target, phase, alpha, power)
		"thrust": _draw_thrust(canvas, origin, target, phase, alpha)
		"arrow": _draw_arrow(canvas, origin, target, phase, alpha)
		"needle": _draw_needles(canvas, origin, target, phase, alpha)
		"arcane": _draw_arcane(canvas, target, phase, alpha, accent)
		"poison": _draw_poison(canvas, target, phase, alpha, kind)
		"counter": _draw_counter(canvas, origin, target, phase, alpha)
		_: _draw_impact(canvas, target, phase, alpha, power)
	if bool(cue.get("piercing",false)) and kind in ["damage","counter"]:
		var direction := _direction(origin,target)
		var normal := direction.orthogonal()
		var extent := 34.0+phase*38.0
		canvas.draw_line(target-direction*extent,target+direction*extent,_tint(WHITE_GOLD,alpha*0.85),1.4,true)
		for side in [-1,1]:
			var point := target+direction*float(side)*extent
			canvas.draw_polyline(PackedVector2Array([point-direction*float(side)*7+normal*5,point,point-direction*float(side)*7-normal*5]),_tint(GOLD,alpha),1.3,true)


func _draw_slash(canvas: Control, target: Vector2, phase: float, alpha: float, power: float) -> void:
	if alpha < 0.015 or phase > 0.97:
		return
	var radius := 35.0 + 9.0 * power
	var start := -2.8 + (1.0 - pow(1.0 - phase, 2.4)) * 1.6
	var finish := start + 1.95 * (1.0 - smoothstep(0.7, 1.0, phase))
	var center := target + Vector2(-3, 5)
	var trail := _arc_points(center + Vector2(-3, 6), radius + 5, start - 0.3, finish - 0.12, Vector2(1.36, 0.67), -0.42)
	canvas.draw_polyline(trail, _tint(INK, alpha * 0.32), 5.0, true)
	canvas.draw_polyline(_arc_points(center, radius, start, finish, Vector2(1.36, 0.67), -0.42), _tint(GOLD, alpha * 0.22), 11.0, true)
	var ribbon := PackedVector2Array()
	var spine := _arc_points(center, radius, start, finish, Vector2(1.36, 0.67), -0.42)
	for index in range(spine.size()):
		ribbon.append(spine[index])
	for index in range(spine.size() - 2, 0, -1):
		var angle := lerpf(start, finish, float(index) / float(spine.size() - 1))
		var thickness := sin(float(index) / float(spine.size() - 1) * PI) * 5.5
		ribbon.append(center + (Vector2(cos(angle), sin(angle)) * Vector2(1.36, 0.67) * (radius - thickness)).rotated(-0.42))
	canvas.draw_colored_polygon(ribbon, _tint(GOLD, alpha * 0.9))
	canvas.draw_polyline(spine, _tint(WHITE_GOLD, alpha), 1.5, true)
	if phase < 0.73:
		_spark(canvas, spine[spine.size() - 1], 7.0 * (1.0 - phase), WHITE_GOLD, alpha)

func _draw_thrust(canvas: Control, origin: Vector2, target: Vector2, phase: float, alpha: float) -> void:
	var direction := _direction(origin, target)
	var normal := direction.orthogonal()
	var travel := pow(minf(phase / 0.32, 1.0), 1.35)
	alpha *= 1.0 - smoothstep(0.36, 0.78, phase)
	var head := origin.lerp(target, travel) + direction * 12.0
	var tail := head - direction * lerpf(78.0, 38.0, phase)
	canvas.draw_colored_polygon(PackedVector2Array([head + direction * 14, tail + normal * 4, tail - direction * 12, tail - normal * 4]), _tint(GOLD, alpha * 0.28))
	canvas.draw_line(tail, head, _tint(GOLD, alpha), 3.2, true)
	canvas.draw_line(tail + direction * 12, head + direction * 12, _tint(WHITE_GOLD, alpha), 1.2, true)
	if phase >= 0.32:
		_spark(canvas, target, 13.0 * (1.0 - phase), WHITE_GOLD, alpha)
		canvas.draw_line(target - normal * 15.0 * phase, target + normal * 15.0 * phase, _tint(GOLD, alpha * 0.5), 1, true)

func _draw_arrow(canvas: Control, origin: Vector2, target: Vector2, phase: float, alpha: float) -> void:
	var direction := _direction(origin, target)
	var normal := direction.orthogonal()
	var travel := minf(phase / 0.48, 1.0)
	var head := origin.lerp(target, pow(travel, 1.15))
	alpha *= 1.0 - smoothstep(0.52, 0.80, phase)
	var tail := head - direction * 42.0
	canvas.draw_line(origin.lerp(head, 0.35), tail, _tint(GOLD, alpha * 0.16), 1.2, true)
	canvas.draw_line(tail, head - direction * 6.0, _tint(GOLD, alpha), 2.2, true)
	canvas.draw_line(tail + normal * 1.0, head - direction * 9.0 + normal, _tint(WHITE_GOLD, alpha * 0.8), 0.7, true)
	canvas.draw_colored_polygon(PackedVector2Array([head + direction * 2, head - direction * 11 + normal * 5, head - direction * 7, head - direction * 11 - normal * 5]), _tint(WHITE_GOLD, alpha))
	for offset in [0.0, 5.0, 10.0]:
		var feather: Vector2 = tail + direction * offset
		canvas.draw_line(feather, feather - direction * 5 + normal * 5, _tint(GOLD, alpha * 0.8), 1.1, true)
		canvas.draw_line(feather, feather - direction * 5 - normal * 5, _tint(GOLD, alpha * 0.8), 1.1, true)
	if phase >= 0.48:
		_spark(canvas, target, (1.0 - phase) * 7.0, WHITE_GOLD, alpha)

func _draw_needles(canvas: Control, origin: Vector2, target: Vector2, phase: float, alpha: float) -> void:
	var direction := _direction(origin, target)
	var normal := direction.orthogonal()
	for index in range(3):
		var progress := clampf((phase - float(index) * 0.07) / 0.38, 0.0, 1.0)
		var offset := normal * float(index - 1) * 8.0
		var head := origin.lerp(target, pow(progress, 1.2)) + offset
		var trail_alpha := alpha * (1.0 - smoothstep(0.42 + float(index) * 0.07, 0.72 + float(index) * 0.07, phase))
		var tint := _tint(SILVER, trail_alpha * (0.85 if index == 1 else 0.6))
		canvas.draw_line(head - direction * 27, head, tint, 1.3, true)
		canvas.draw_line(head - direction * 36, head - direction * 29, _tint(SILVER, trail_alpha * 0.25), 0.7, true)
		_diamond(canvas, head, 1.7, tint)
	if phase >= 0.38:
		_spark(canvas, target, 5.0 * (1.0 - phase), SILVER, alpha)

func _draw_impact(canvas: Control, target: Vector2, phase: float, alpha: float, power: float) -> void:
	var heavy := power >= 1.2
	var radius := lerpf(5.0, 24.0 + power * 19.0, 1.0 - pow(1.0 - phase, 2.6))
	canvas.draw_polyline(_arc_points(target, radius, 0.0, TAU, Vector2(1, 0.64)), _tint(GOLD, alpha * 0.9), 2.3 if heavy else 1.4, true)
	canvas.draw_polyline(_arc_points(target, radius + 7.0, 0.3, PI + 0.8, Vector2(1, 0.64)), _tint(WHITE_GOLD, alpha * 0.36), 1, true)
	var count := 10 if heavy else 6
	for index in range(count):
		var direction := Vector2.from_angle(float(index) * TAU / float(count) + 0.24)
		var point := target + direction * (radius + 3 + phase * 15)
		canvas.draw_line(point, point + direction.rotated(0.25) * (4 + power * 3), _tint(GOLD, alpha * 0.85), 2.0 if heavy else 1.3, true)
	if phase < 0.35:
		_spark(canvas, target, 9 * (1 - phase / 0.35), WHITE_GOLD, alpha)

func _draw_arcane(canvas: Control, target: Vector2, phase: float, alpha: float, accent: Color) -> void:
	var radius := 23.0 + sin(phase * PI) * 6.0
	var rotation := -0.2 + phase * 0.35
	var rune := PackedVector2Array()
	for point in [Vector2(0, -1.25), Vector2(0.72, -0.9), Vector2(0.72, 0.85), Vector2(0, 1.22), Vector2(-0.72, 0.85), Vector2(-0.72, -0.9), Vector2(0, -1.25)]:
		rune.append(target + (point * radius).rotated(rotation))
	canvas.draw_polyline(rune, _tint(accent, alpha * 0.82), 1.6, true)
	var center := target + Vector2(0, -3)
	canvas.draw_polyline(PackedVector2Array([center + Vector2(-9,-7), center + Vector2(8,-7), center + Vector2(-5,3), center + Vector2(7,10)]), _tint(WHITE_GOLD, alpha * 0.95), 1.4, true)
	canvas.draw_line(center + Vector2(0,-13), center + Vector2(-1,14), _tint(accent, alpha), 1.4, true)
	for index in range(6):
		var direction := Vector2.from_angle(float(index) * TAU / 6.0 + phase * 0.3)
		var start := target + direction * (radius + 8)
		canvas.draw_line(start, start + direction * (6.0 + sin(phase * PI) * 15), _tint(accent, alpha * 0.7), 1.3, true)
		_diamond(canvas, start + direction * 19, 2.2, _tint(accent, alpha * 0.6))

func _draw_poison(canvas: Control, target: Vector2, phase: float, alpha: float, kind: String) -> void:
	var consume := kind == "poison_consume"
	var tick := kind == "poison_tick"
	var radius := lerpf(35.0, 12.0, phase) if consume else lerpf(15.0, 38.0, phase)
	if tick:
		radius = 16.0
	for index in range(7 if not tick else 4):
		var angle := float(index) * 2.39996 + phase * (1.2 if consume else 0.7)
		var direction := Vector2.from_angle(angle)
		var point := target + Vector2(direction.x * radius, direction.y * radius * 0.6 - phase * (24.0 if tick else 13.0))
		var tint := JADE if index % 3 == 0 else PURPLE
		canvas.draw_circle(point, (5.0 + float(index % 3) * 2.0) * (1.0 - phase * 0.3), _tint(tint, alpha * 0.075), true, -1, true)
		canvas.draw_arc(point, 4.0 + float(index % 3) * 2.0, 0.2, PI * 1.6, 16, _tint(tint, alpha * 0.43), 1.1, true)
		_diamond(canvas, point + Vector2(2, -5), 1.8, _tint(tint, alpha * 0.8))
	if consume:
		for index in range(5):
			var direction := Vector2.from_angle(float(index) * TAU / 5.0)
			canvas.draw_line(target + direction * (8 + phase * 5), target + direction * (20 + phase * 22), _tint(PURPLE, alpha * 0.7), 1.4, true)
	elif not tick:
		canvas.draw_polyline(_arc_points(target, radius, 0.2 + phase, PI + 0.5 + phase, Vector2(1, 0.55)), _tint(JADE, alpha * 0.5), 1.1, true)

func _draw_counter(canvas: Control, origin: Vector2, target: Vector2, phase: float, alpha: float) -> void:
	var direction := _direction(origin, target)
	var travel := minf(phase / 0.42, 1.0)
	var midpoint := origin.lerp(target, travel)
	midpoint += direction.orthogonal() * sin(travel * PI) * 37
	alpha *= 1.0 - smoothstep(0.46, 0.78, phase)
	var rotation := direction.angle() + phase * TAU * 1.2
	var blade := PackedVector2Array()
	for point in [Vector2(-21, -3), Vector2(8, -9), Vector2(23, 0), Vector2(6, 4), Vector2(-21, -3)]:
		blade.append(midpoint + point.rotated(rotation))
	canvas.draw_polyline(_arc_points(midpoint, 28, rotation - 1.3, rotation + 0.6), _tint(GOLD, alpha * 0.32), 2.8, true)
	canvas.draw_polyline(blade, _tint(GOLD, alpha), 2.1, true)
	canvas.draw_line(midpoint + Vector2(-16,-1).rotated(rotation), midpoint + Vector2(19,0).rotated(rotation), _tint(WHITE_GOLD, alpha), 1, true)
	if phase > 0.42:
		_spark(canvas, target, 9 * (1 - phase), GOLD, alpha)

func _draw_heal(canvas: Control, target: Vector2, phase: float, alpha: float) -> void:
	for index in range(7):
		var x := sin(float(index) * 2.4) * 25
		var rise := fmod(phase * 44.0 + float(index) * 8.0, 56.0)
		var point := target + Vector2(x, 17 - rise)
		_diamond(canvas, point, 2.3 + float(index % 2), _tint(JADE, alpha * 0.85))
		if index % 3 == 0:
			canvas.draw_line(point + Vector2(-4,0), point + Vector2(4,0), _tint(WHITE_GOLD, alpha * 0.8), 1, true)
			canvas.draw_line(point + Vector2(0,-4), point + Vector2(0,4), _tint(WHITE_GOLD, alpha * 0.8), 1, true)
	canvas.draw_polyline(_arc_points(target + Vector2(0,11), 20 + phase * 12, 0.1, PI - 0.1, Vector2(1,0.4)), _tint(JADE, alpha * 0.5), 1.3, true)

func _draw_shield(canvas: Control, target: Vector2, phase: float, alpha: float) -> void:
	var scale := 0.88 + sin(phase * PI) * 0.12
	var points := PackedVector2Array()
	for point in [Vector2(0,-28),Vector2(23,-18),Vector2(18,12),Vector2(0,29),Vector2(-18,12),Vector2(-23,-18),Vector2(0,-28)]:
		points.append(target + point * scale)
	canvas.draw_polyline(points, _tint(GOLD, alpha * 0.9), 1.8, true)
	canvas.draw_polyline(_arc_points(target, 35 + phase * 9, -2.9, -0.2, Vector2(1,0.85)), _tint(GOLD, alpha * 0.48), 1.1, true)
	canvas.draw_line(target + Vector2(0,-17), target + Vector2(0,13), _tint(WHITE_GOLD, alpha * 0.7), 1, true)
	canvas.draw_line(target + Vector2(-9,-6), target + Vector2(9,-6), _tint(WHITE_GOLD, alpha * 0.7), 1, true)
	for index in range(3):
		var point := target + Vector2.from_angle(float(index) * TAU / 3 + phase) * 36
		_diamond(canvas, point, 2.0, _tint(WHITE_GOLD, alpha * 0.8))

func _draw_buff(canvas: Control, target: Vector2, phase: float, alpha: float) -> void:
	var center := target + Vector2(0, 8 - phase * 29)
	for index in range(3):
		var y := float(index) * 13
		canvas.draw_polyline(PackedVector2Array([center + Vector2(-11,y + 3), center + Vector2(0,y - 5), center + Vector2(11,y + 3)]), _tint(GOLD, alpha * (1.0 - float(index) * 0.2)), 1.8, true)
	canvas.draw_line(center + Vector2(0,-16), center + Vector2(0,30), _tint(WHITE_GOLD, alpha * 0.6), 1, true)
	for side in [-1, 1]:
		_diamond(canvas, center + Vector2(float(side) * 23, 11 + sin(phase * PI) * 5), 2.8, _tint(GOLD, alpha * 0.8))

func _draw_armor_break(canvas: Control, target: Vector2, phase: float, alpha: float) -> void:
	for side in [-1, 1]:
		var offset := Vector2(float(side) * phase * 23, phase * 9)
		var points := PackedVector2Array([target + offset + Vector2(float(side) * 3,-25), target + offset + Vector2(float(side) * 23,-16), target + offset + Vector2(float(side) * 17,12), target + offset + Vector2(float(side) * 5,23)])
		canvas.draw_polyline(points, _tint(GOLD, alpha * 0.8), 1.6, true)
	var crack := PackedVector2Array([target + Vector2(3,-24),target + Vector2(-5,-8),target + Vector2(5,-2),target + Vector2(-5,10),target + Vector2(1,24)])
	canvas.draw_polyline(crack, _tint(WHITE_GOLD, alpha), 1.5, true)
	for index in range(7):
		var direction := Vector2.from_angle(float(index) * 2.39996)
		var point := target + direction * (18 + phase * 30)
		canvas.draw_line(point, point + direction.rotated(0.6) * 5, _tint(GOLD, alpha * 0.85), 1.7, true)

func _draw_interrupt(canvas: Control, target: Vector2, phase: float, alpha: float) -> void:
	var color := Color("d98e78")
	for index in range(4):
		var angle := float(index) * PI * 0.5 + 0.15
		var offset := Vector2.from_angle(angle + 0.6) * phase * 16
		canvas.draw_polyline(_arc_points(target + offset, 25, angle, angle + 0.92), _tint(color, alpha * 0.85), 1.7, true)
	canvas.draw_line(target + Vector2(-19,19), target + Vector2(18,-20), _tint(WHITE_GOLD, alpha), 2.1, true)
	for side in [-1,1]:
		var center := target + Vector2(float(side) * (5 + phase * 13), -float(side) * phase * 10)
		canvas.draw_polyline(PackedVector2Array([center + Vector2(-6,-12),center + Vector2(4,-4),center + Vector2(-2,5),center + Vector2(7,13)]), _tint(color, alpha * 0.75), 1.3, true)

func _draw_cast(canvas: Control, dimensions: Vector2, phase: float, alpha: float) -> void:
	var inset := 3.0
	var rect := Rect2(Vector2.ONE * inset, (dimensions - Vector2.ONE * inset * 2).max(Vector2.ONE))
	canvas.draw_rect(rect, _tint(GOLD, alpha * 0.48), false, 1.1, true)
	var length := minf(20.0, minf(dimensions.x, dimensions.y) * 0.2)
	for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		var xsign := 1.0 if corner.x == rect.position.x else -1.0
		var ysign := 1.0 if corner.y == rect.position.y else -1.0
		canvas.draw_line(corner, corner + Vector2(xsign * length,0), _tint(WHITE_GOLD, alpha), 1.8, true)
		canvas.draw_line(corner, corner + Vector2(0,ysign * length), _tint(GOLD, alpha), 1.8, true)
	var sparkle := Vector2(lerpf(rect.position.x, rect.end.x, phase), rect.position.y)
	_spark(canvas, sparkle, 4.0, WHITE_GOLD, alpha)

static func impact_phase(cue: Dictionary) -> float:
	if str(cue.get("kind","")) == "cast": return 0.0
	if str(cue.get("kind","")) == "counter": return 0.42
	if str(cue.get("kind","")) != "damage": return 0.12
	match str(cue.get("family","")):
		"arrow": return 0.48
		"needle": return 0.38
		"thrust": return 0.32
		"arcane": return 0.25
		"slash": return 0.18
	return 0.12

func _draw_feedback(cue: Dictionary, phase: float) -> void:
	if cue.get("hide_text",false): return
	var kind := str(cue.get("kind", "damage"))
	var amount := maxi(0, int(cue.get("amount", 0)))
	var absorbed := maxi(0, int(cue.get("absorbed", 0)))
	var color := WHITE_GOLD
	var text := ""
	var font_size := 27
	match kind:
		"cast":
			text = str(cue.get("name", ""))
			font_size = 16
			color = GOLD
		"heal":
			text = "+%d" % amount
			color = JADE
		"shield":
			text = "护盾 +%d" % amount
			font_size = 21
			color = GOLD
		"poison_add", "poison_apply":
			text = "毒 +%d" % amount
			font_size = 20
			color = JADE
		"poison_consume":
			text = "爆毒 -%d" % amount
			font_size = 22
			color = PURPLE
		"poison_tick":
			text = "-%d" % amount
			font_size = 24
			color = PURPLE
		"armor_break":
			text = "破甲 -%d" % amount
			font_size = 21
			color = GOLD
		"interrupt":
			text = "打断"
			font_size = 21
			color = Color("e8b09b")
		"buff", "enemy_action":
			text = str(cue.get("name", "强化"))
			font_size = 20
			color = GOLD
		"counter":
			text = "反击 -%d" % amount
			font_size = 23
		_:
			text = "-%d" % amount if amount > 0 else ("格挡" if absorbed > 0 else "0")
			if bool(cue.get("heavy",false)) and amount > 0:
				font_size = 38
				color = Color("ffd36b")
	if text.is_empty():
		return
	if bool(cue.get("piercing",false)) and kind in ["damage","counter"]: text="穿透 "+text
	var text_phase:=clampf((phase-impact_phase(cue))/maxf(0.01,1-impact_phase(cue)),0,1)
	var alpha := clampf(text_phase / 0.10, 0.0, 1.0) * (1.0 - smoothstep(0.68, 1.0, text_phase))
	var visual_scale := _visual_scale()
	var punch := 0.35 if bool(cue.get("heavy",false)) else 0.08
	font_size = maxi(12, roundi(float(font_size) * visual_scale*(1+punch*exp(-text_phase*12))))
	var target: Vector2 = cue.get("text_target",cue["target"])
	var point := target + Vector2(0, (-25 - text_phase * 25) * visual_scale)
	if kind == "cast":
		var area: Rect2 = cue["area"]
		point = Vector2(area.get_center().x, area.position.y - (8 + phase * 7) * visual_scale)
	_draw_safe_text(text, point, font_size, _tint(color, alpha))
	if absorbed > 0 and kind in ["damage", "counter", "poison_tick", "poison_consume"]:
		_draw_safe_text(("护甲 -%d" if str(cue.get("side", "team")) == "enemy" else "护盾 -%d") % absorbed, point + Vector2(0, 23 * visual_scale), maxi(12, roundi(16 * visual_scale)), _tint(GOLD, alpha * 0.95))

func _draw_safe_text(text: String, center: Vector2, font_size: int, color: Color) -> void:
	var font := get_theme_default_font()
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var safe_size := size.max(Vector2(80, 60))
	var point := Vector2(clampf(center.x - width * 0.5, 14.0, maxf(14.0, safe_size.x - width - 14)), clampf(center.y, float(font_size) + 10, maxf(float(font_size) + 10, safe_size.y - 14)))
	draw_string_outline(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, maxi(2, roundi(4 * _visual_scale())), _tint(Color("282522"), color.a * 0.85))
	draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _visual_scale() -> float:
	return clampf(minf(size.x / 1280.0, size.y / 720.0), 0.78, 1.5)

func _arc_points(center: Vector2, radius: float, start: float, finish: float, stretch: Vector2 = Vector2.ONE, rotation: float = 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(29):
		var angle := lerpf(start, finish, float(index) / 28.0)
		points.append(center + (Vector2(cos(angle), sin(angle)) * radius * stretch).rotated(rotation))
	return points

func _direction(origin: Vector2, target: Vector2) -> Vector2:
	return (target - origin).normalized() if origin.distance_squared_to(target) > 0.1 else Vector2.RIGHT

func _tint(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, clampf(alpha * color.a, 0.0, 1.0))

func _diamond(canvas: Control, center: Vector2, radius: float, color: Color) -> void:
	if radius < 0.3 or color.a < 0.01:
		return
	canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0,-radius),center + Vector2(radius * 0.65,0),center + Vector2(0,radius),center + Vector2(-radius * 0.65,0)]), color)

func _spark(canvas: Control, center: Vector2, radius: float, color: Color, alpha: float) -> void:
	canvas.draw_line(center - Vector2(radius,0), center + Vector2(radius,0), _tint(color, alpha), 1.1, true)
	canvas.draw_line(center - Vector2(0,radius), center + Vector2(0,radius), _tint(color, alpha), 1.1, true)
	_diamond(canvas, center, minf(radius * 0.35, 3.3), _tint(color, alpha))
