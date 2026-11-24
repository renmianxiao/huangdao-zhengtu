extends TextureRect
## TextureRect-compatible object display, with an independent noninteractive plinth.
const Presentation=preload("res://code/scripts/ui/item_presentation.gd")
const Paper=preload("res://code/scripts/ui/global_theme.gd")
var _plate:Control
var _art_path:=""
var _display_path:=""

class Plate extends Control:
	var empty_stamp:=false
	func _draw()->void:
		Presentation.draw_plate(self,Rect2(Vector2.ZERO,size))
		if empty_stamp:
			var font:=Paper.heading_font()
			var caption:="售罄"
			var font_size:=clampi(int(minf(size.x,size.y)*0.25),16,28)
			var width:=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
			draw_string(font,Vector2((size.x-width)*0.5,size.y*0.5+font_size*0.35),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Paper.MUTED)

func _init()->void:
	texture_filter=TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	expand_mode=EXPAND_IGNORE_SIZE
	stretch_mode=STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter=MOUSE_FILTER_IGNORE
	_plate=Plate.new();_plate.mouse_filter=MOUSE_FILTER_IGNORE;_plate.show_behind_parent=true
	_plate.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_plate)
	resized.connect(_plate.queue_redraw)
	resized.connect(_update_texture)

func set_art(path:String)->void:
	_art_path=path
	_display_path=""
	texture=null
	_update_texture()
	_plate.empty_stamp=false
	_plate.queue_redraw()

func _update_texture()->void:
	if _art_path.is_empty():return
	var selected:=Presentation.path_for(_art_path,maxf(size.x,size.y))
	if selected==_display_path:return
	_display_path=selected
	texture=Presentation.texture_for(selected)

func show_sold()->void:
	_art_path=""
	_display_path=""
	texture=null
	_plate.empty_stamp=true
	_plate.queue_redraw()
