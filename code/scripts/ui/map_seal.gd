extends Button
const Art=preload("res://code/scripts/ui/map_ornament.gd")
var kind := "battle"
var caption := ""
var selected := false
var visited := false
func _draw() -> void:
	var center:=Vector2(size.x/2,30)
	var rim:=Color("c6a572")
	var fill:=Color("a13e32") if selected else Color("554b3d")
	if kind=="elite" and not selected: fill=Color("7e4235")
	if disabled and not visited: fill=Color("706759")
	if selected or not disabled: draw_circle(center,32,Color("d1ac65"),false,1.5,true)
	if has_focus(): draw_circle(center,35,Color("a13e32"),false,1,true)
	draw_circle(center,28,fill,true,-1,true)
	for radius in [27.0,29.5]: draw_circle(center,radius,rim,false,0.9,true)
	Art.icon(self,kind,center,19)
	if selected:
		for side in [-1,1]:
			Art.diamond(self,center+Vector2(side*36,0),3,rim)
	var font:=get_theme_default_font()
	var color:=Color("493f31") if not disabled or visited else Color("8c8271")
	var caption_width:=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x
	draw_string(font,Vector2((size.x-caption_width)/2,78),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,17,color)
	if visited: draw_circle(center+Vector2(22,22),4,Color("78917a"),true,-1,true)
