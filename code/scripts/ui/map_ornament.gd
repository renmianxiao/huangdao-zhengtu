extends RefCounted
const GOLD = Color("ad8b56")
const LIGHT = Color("dbc18c")

static func curl(canvas: CanvasItem, origin: Vector2, scale_value: Vector2, color: Color = GOLD) -> void:
	var points := PackedVector2Array()
	for i in range(48):
		var t := float(i)/47
		var angle := t * TAU * 1.25
		var radius := 11.0 * (1.0-t) + 1
		points.append(origin + Vector2(cos(angle),sin(angle))*radius*scale_value)
	canvas.draw_polyline(points,color,1.1,true)

static func frame(canvas: CanvasItem, rect: Rect2, color: Color = GOLD) -> void:
	canvas.draw_rect(rect,color,false,1)
	canvas.draw_rect(rect.grow(-4),Color(color,0.5),false,0.7)
	for corner: Vector2 in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,1)]:
		var origin := rect.position + rect.size*corner
		var sign_value := Vector2(1 if corner.x==0 else -1,1 if corner.y==0 else -1)
		var points := PackedVector2Array([origin+Vector2(0,22)*sign_value,origin+Vector2(7,22)*sign_value,origin+Vector2(7,8)*sign_value,origin+Vector2(22,8)*sign_value,origin+Vector2(22,0)*sign_value])
		canvas.draw_polyline(points,color,1,true)
		curl(canvas,origin+Vector2(13,14)*sign_value,sign_value*0.4,color)

static func diamond(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	canvas.draw_polyline(PackedVector2Array([center+Vector2(-radius,0),center+Vector2(0,-radius),center+Vector2(radius,0),center+Vector2(0,radius),center+Vector2(-radius,0)]),color,1,true)

static func divider(canvas: CanvasItem, center: Vector2, half_width: float) -> void:
	canvas.draw_line(center+Vector2(-half_width,0),center+Vector2(-13,0),GOLD,0.8,true)
	canvas.draw_line(center+Vector2(13,0),center+Vector2(half_width,0),GOLD,0.8,true)
	diamond(canvas,center,5,GOLD)
	for sign_value in [-1,1]:
		canvas.draw_circle(center+Vector2(sign_value*10,0),1.5,GOLD,true,-1,true)

static func boss(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array([Vector2(-0.85,-0.8),Vector2(-0.70,-0.12),Vector2(-0.55,-0.52),Vector2(-0.25,-0.72),Vector2(0,-0.93),Vector2(0.25,-0.72),Vector2(0.55,-0.52),Vector2(0.70,-0.12),Vector2(0.85,-0.8),Vector2(0.96,0.18),Vector2(0.63,0.4),Vector2(0.40,0.77),Vector2(0,1),Vector2(-0.4,0.77),Vector2(-0.63,0.4),Vector2(-0.96,0.18)])
	for i in range(points.size()): points[i]=center+points[i]*radius
	canvas.draw_colored_polygon(points,color)
	for sign_value in [-1,1]:
		canvas.draw_line(center+Vector2(sign_value*0.20,-0.05)*radius,center+Vector2(sign_value*0.60,-0.24)*radius,Color("f1d6a3"),2,true)
	canvas.draw_polyline(PackedVector2Array([center+Vector2(-0.22,0.38)*radius,center+Vector2(0,0.55)*radius,center+Vector2(0.22,0.38)*radius]),Color("f1d6a3"),1.5,true)

static func swords(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	var ivory := Color("f6edd8")
	for sign_value in [-1,1]:
		var direction := Vector2(sign_value,-1).normalized()
		var cross := Vector2(-direction.y,direction.x)
		canvas.draw_colored_polygon(PackedVector2Array([center-direction*radius*0.5-cross*radius*0.10,center+direction*radius*0.60-cross*radius*0.1,center+direction*radius*0.88,center+direction*radius*0.60+cross*radius*0.1,center-direction*radius*0.5+cross*radius*0.10]),ivory)
		canvas.draw_line(center-direction*radius*0.55-cross*radius*0.25,center-direction*radius*0.55+cross*radius*0.25,ivory,3,true)
		canvas.draw_line(center-direction*radius*0.55,center-direction*radius*0.9,ivory,5,true)
		canvas.draw_line(center-direction*radius*0.35,center+direction*radius*0.55,Color("bfb39a"),1,true)

static func _shape(canvas: CanvasItem, center: Vector2, radius: float, points: PackedVector2Array, color: Color) -> void:
	var output:=PackedVector2Array()
	for p: Vector2 in points: output.append(center+p*radius)
	canvas.draw_colored_polygon(output,color)

static func _stroke(canvas: CanvasItem, center: Vector2, radius: float, points: PackedVector2Array, color: Color, width: float=0.075) -> void:
	var output:=PackedVector2Array()
	for p: Vector2 in points: output.append(center+p*radius)
	canvas.draw_polyline(output,color,maxf(1,radius*width),true)

static func icon(canvas: CanvasItem, kind: String, center: Vector2, radius: float, color: Color=Color("f6edd8")) -> void:
	match kind:
		"battle", "elite":
			swords(canvas,center,radius)
			if kind=="elite":
				for side in [-1,1]:
					_stroke(canvas,center,radius,PackedVector2Array([Vector2(side*0.8,-0.65),Vector2(side*1.0,-0.1),Vector2(side*0.8,0.65)]),LIGHT,0.05)
		"midboss", "boss": boss(canvas,center,radius*0.9,Color("bd5942"))
		"event":
			var font: Font=canvas.get_theme_default_font()
			var font_size:=int(radius*2)
			var width:=font.get_string_size("？",HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
			canvas.draw_string(font,center+Vector2(-width/2,radius*0.72),"？",HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
		"shop":
			# Pavilion with a swept roof, pillars and raised stone steps.
			_shape(canvas,center,radius,PackedVector2Array([Vector2(-0.98,-0.27),Vector2(-0.57,-0.44),Vector2(-0.14,-0.83),Vector2(0,-1),Vector2(0.14,-0.83),Vector2(0.57,-0.44),Vector2(0.98,-0.27),Vector2(0.65,-0.16),Vector2(-0.65,-0.16)]),color)
			for side in [-1,1]:
				_stroke(canvas,center,radius,PackedVector2Array([Vector2(side*0.55,-0.10),Vector2(side*0.55,0.7)]),color,0.1)
			_stroke(canvas,center,radius,PackedVector2Array([Vector2(-0.9,0.8),Vector2(0.9,0.8)]),color,0.12)
			_stroke(canvas,center,radius,PackedVector2Array([Vector2(-0.75,0.65),Vector2(0.75,0.65)]),color,0.07)
			_stroke(canvas,center,radius,PackedVector2Array([Vector2(-0.14,0.6),Vector2(-0.14,0.1),Vector2(0.14,0.1),Vector2(0.14,0.6)]),color,0.06)
		"camp":
			_shape(canvas,center,radius,PackedVector2Array([Vector2(-0.7,0.27),Vector2(-0.76,-0.04),Vector2(-0.44,-0.66),Vector2(-0.38,-0.15),Vector2(-0.09,-0.5),Vector2(0.06,-1),Vector2(0.28,-0.43),Vector2(0.59,-0.74),Vector2(0.72,-0.2),Vector2(0.66,0.23),Vector2(0.4,0.55),Vector2(0,0.65),Vector2(-0.43,0.5)]),color)
			_shape(canvas,center,radius,PackedVector2Array([Vector2(-0.21,0.30),Vector2(0.08,-0.22),Vector2(0.27,0.19),Vector2(0.09,0.47)]),Color("8c7552"))
			for side in [-1,1]:
				_stroke(canvas,center,radius,PackedVector2Array([Vector2(-0.86,side*0.14+0.82),Vector2(0.86,-side*0.14+0.82)]),color,0.10)
		"team":
			for offset: Vector2 in [Vector2(-0.62,-0.20),Vector2(0.62,-0.20),Vector2(0,-0.43)]:
				canvas.draw_circle(center+offset*radius,radius*0.23,color,true,-1,true)
				_shape(canvas,center+offset*radius,radius,PackedVector2Array([Vector2(-0.34,0.43),Vector2(-0.29,0.21),Vector2(0,0.11),Vector2(0.29,0.21),Vector2(0.34,0.43),Vector2(0.34,0.91),Vector2(-0.34,0.91)]),color)
		"menu":
			for row in [-1,0,1]:
				canvas.draw_circle(center+Vector2(-0.57,row*0.47)*radius,radius*0.07,color,true,-1,true)
				_stroke(canvas,center,radius,PackedVector2Array([Vector2(-0.30,row*0.47),Vector2(0.62,row*0.47)]),color,0.1)
