extends Button
const Art=preload("res://code/scripts/ui/map_ornament.gd")
var kind := "battle"
var caption := ""
var is_action := false
func _ready() -> void:
	text=caption
	mouse_filter=Control.MOUSE_FILTER_STOP if is_action else Control.MOUSE_FILTER_IGNORE
	focus_mode=Control.FOCUS_ALL if is_action else Control.FOCUS_NONE
	for mode in ["normal","hover","pressed","disabled","focus"]: add_theme_stylebox_override(mode,StyleBoxEmpty.new())
	for mode in ["font_color","font_disabled_color","font_hover_color","font_hover_pressed_color","font_pressed_color","font_focus_color"]: add_theme_color_override(mode,Color.TRANSPARENT)
	if is_action:
		mouse_entered.connect(queue_redraw); mouse_exited.connect(queue_redraw)
		focus_entered.connect(queue_redraw); focus_exited.connect(queue_redraw)
func _draw() -> void:
	var center:=Vector2(25,size.y/2)
	var fill:=Color("7c3d32") if kind=="elite" else Color("534a3d")
	if is_hovered() and is_action: fill=Color("796246")
	draw_circle(center,20,fill,true,-1,true)
	for radius in [19.0,21.5]: draw_circle(center,radius,Art.GOLD,false,0.8,true)
	Art.icon(self,kind,center,13)
	var font:=get_theme_default_font()
	draw_string(font,Vector2(54,size.y/2+7),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("e8decc"))
	if has_focus(): draw_rect(Rect2(Vector2.ZERO,size).grow(-1),Art.GOLD,false,1,true)
