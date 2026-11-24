extends Control
## Cached scene painting; menu text remains independent and fully editable.
var _scene: Texture2D
var _shade: GradientTexture2D

func _ready() -> void:
	mouse_filter=MOUSE_FILTER_IGNORE
	_scene=load("res://art/cinematics/floor_1.png")
	_shade=GradientTexture2D.new()
	var gradient:=Gradient.new()
	gradient.offsets=PackedFloat32Array([0.0,0.4,0.72,1.0])
	gradient.colors=PackedColorArray([Color(0.08,0.10,0.11,0.98),Color(0.08,0.10,0.11,0.84),Color(0.08,0.10,0.11,0.24),Color(0.08,0.10,0.11,0.15)])
	_shade.gradient=gradient
	_shade.fill_from=Vector2.ZERO;_shade.fill_to=Vector2.RIGHT
	resized.connect(queue_redraw)

func _draw() -> void:
	if _scene==null:return
	var extent:=_scene.get_size()*maxf(size.x/_scene.get_width(),size.y/_scene.get_height())
	draw_texture_rect(_scene,Rect2((size-extent)/2.0,extent),false)
	draw_texture_rect(_shade,Rect2(Vector2.ZERO,size),false)
	draw_line(Vector2(24,24),Vector2(size.x-24,24),Color("ae915d"),1,true)
	draw_line(Vector2(24,size.y-24),Vector2(size.x-24,size.y-24),Color("ae915d"),1,true)
