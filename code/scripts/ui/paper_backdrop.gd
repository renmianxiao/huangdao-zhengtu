extends Control
const Art=preload("res://code/scripts/ui/map_ornament.gd")
const PaperStyle=preload("res://code/scripts/ui/global_theme.gd")
var show_frame := true
var dark := false
var _silk: Texture2D
static var _veil: GradientTexture2D
## Optional floor painting washed into the paper, so node pages sit in the place they belong to.
var scene: Texture2D:
	set(value):
		scene=value
		queue_redraw()
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	_silk=load("res://art/ui/materials/ink_silk.png" if dark else "res://art/ui/materials/light_silk.png")
	resized.connect(queue_redraw)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),PaperStyle.DARK if dark else PaperStyle.PAPER)
	if scene != null: draw_scene_wash(self,scene,Rect2(Vector2.ZERO,size),PaperStyle.DARK if dark else PaperStyle.PAPER)
	if _silk != null: draw_texture_rect(_silk,Rect2(Vector2.ZERO,size),false,Color(1,1,1,0.24 if dark else 0.22))
	if show_frame and size.x>30 and size.y>30:
		draw_rect(Rect2(Vector2(8,8),size-Vector2(16,16)),PaperStyle.OLD_GOLD if dark else PaperStyle.BORDER,false,1)


## Cover-fit painting under a paper veil that is lighter at the top, where the scene reads, and denser behind content.
static func draw_scene_wash(canvas: CanvasItem, painting: Texture2D, rect: Rect2, paper: Color, strength: float=1.0) -> void:
	var extent:=painting.get_size()*maxf(rect.size.x/painting.get_width(),rect.size.y/painting.get_height())
	canvas.draw_texture_rect(painting,Rect2(rect.position+(rect.size-extent)/2.0,extent),false,Color(1,1,1,0.55*strength))
	if _veil==null:
		_veil=GradientTexture2D.new()
		var gradient:=Gradient.new()
		gradient.colors=PackedColorArray([Color(1,1,1,0.42),Color(1,1,1,0.80)])
		_veil.gradient=gradient
		_veil.fill_from=Vector2.ZERO;_veil.fill_to=Vector2(0,1)
	canvas.draw_texture_rect(_veil,rect,false,paper)
