extends Control
## Quiet scene window: preserve aspect and focus the camp equipment, not the sky.
var texture:Texture2D
var focus_y:=0.80
func _ready()->void:
	clip_contents=true;mouse_filter=MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw()->void:
	if texture==null or size.x<=0 or size.y<=0:return
	var extent:=texture.get_size()*maxf(size.x/texture.get_width(),size.y/texture.get_height())
	var origin:=Vector2((size.x-extent.x)*0.5,(size.y-extent.y)*focus_y)
	draw_texture_rect(texture,Rect2(origin,extent),false)
