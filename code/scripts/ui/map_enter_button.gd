extends Button
const Art = preload("res://code/scripts/ui/map_ornament.gd")
func _ready() -> void:
	for mode in ["normal","hover","pressed","disabled","focus"]:
		add_theme_stylebox_override(mode,StyleBoxEmpty.new())
	for mode in ["font_color","font_disabled_color","font_hover_color","font_hover_pressed_color","font_pressed_color","font_focus_color"]:
		add_theme_color_override(mode,Color.TRANSPARENT)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
func _draw() -> void:
	var w := size.x
	var h := size.y
	var outer := PackedVector2Array([Vector2(17,0.5),Vector2(w-17,0.5),Vector2(w-10,9),Vector2(w-0.5,9),Vector2(w-0.5,h-9),Vector2(w-10,h-9),Vector2(w-17,h-0.5),Vector2(17,h-0.5),Vector2(10,h-9),Vector2(0.5,h-9),Vector2(0.5,9),Vector2(10,9),Vector2(17,0.5)])
	draw_colored_polygon(outer,Color("d7bb82"))
	draw_polyline(outer,Color("99784a"),1.2,true)
	var inner := PackedVector2Array()
	for point: Vector2 in outer: inner.append((point-size/2)*Vector2((w-10)/w,(h-10)/h)+size/2)
	var color := Color("aa4637") if is_hovered() else Color("92372c")
	if button_pressed: color=Color("792b24")
	if disabled: color=Color("897868")
	draw_colored_polygon(inner,color)
	draw_polyline(inner,Color("f1d3a0"),1,true)
	for side in [-1,1]:
		var x := 30.0 if side==-1 else w-30
		for y in [19.0,h-19]:
			Art.curl(self,Vector2(x,y),Vector2(side*0.72,0.60),Color("cfad70"))
		Art.diamond(self,Vector2(x-13*side,h/2),4,Color("cfad70"))
		var points := PackedVector2Array([Vector2(x+side*7,14),Vector2(x+side*17,20),Vector2(x+side*10,25),Vector2(x+side*19,30)])
		draw_polyline(points,Color("cfad70"),0.8,true)
	if has_focus(): draw_rect(Rect2(Vector2.ZERO,size).grow(-1),Color("f2ce85"),false,2,true)
	var font := get_theme_default_font()
	var font_size := 30
	var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	draw_string(font,Vector2((w-width)/2,h/2+10),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("ffe08a") if is_hovered() and not disabled else Color("fff1d6"))
