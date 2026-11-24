extends RefCounted
## Cached framing and size-appropriate art for relics and reward objects.
const Bounds=preload("res://code/scripts/ui/item_bounds.gd")
const SMALL_ICON_MAX_SIDE:=96.0
static var _textures:Dictionary={}
static var _small_paths:Dictionary={}

static func region(path:String,source_size:Vector2)->Rect2:
	var whole:=Rect2(Vector2.ZERO,source_size)
	var key:=path.trim_prefix("res://art/").get_basename()
	var measured:Rect2=Bounds.BOUNDS.get(key,whole)
	return measured.grow(maxf(measured.size.x,measured.size.y)*0.055).intersection(whole)

static func path_for(path:String,max_display_side:float=0.0)->String:
	if max_display_side<=0.0 or max_display_side>SMALL_ICON_MAX_SIDE:return path
	if not path.begins_with("res://art/relics/") or path.begins_with("res://art/relics/small/"):return path
	if not _small_paths.has(path):
		var candidate:=path.get_base_dir()+"/small/"+path.get_file()
		_small_paths[path]=candidate if ResourceLoader.exists(candidate) else path
	return str(_small_paths[path])

static func texture_for(path:String,max_display_side:float=0.0)->Texture2D:
	path=path_for(path,max_display_side)
	if path.is_empty() or not ResourceLoader.exists(path):return null
	if _textures.has(path):return _textures[path]
	var source:=load(path) as Texture2D
	if source==null:return null
	var framed:=AtlasTexture.new()
	framed.atlas=source;framed.region=region(path,source.get_size());framed.filter_clip=true
	_textures[path]=framed
	return framed

static func draw_plate(canvas:CanvasItem,area:Rect2,dark:bool=false)->void:
	var side:=minf(area.size.x,area.size.y)
	if side<20:return
	var center:=area.get_center()
	var bronze:=Color("ae915d") if dark else Color("b3a184")
	canvas.draw_circle(center,side*0.46,Color(0.72,0.56,0.28,0.08) if dark else Color(0.55,0.42,0.24,0.06),true,-1,true)
	canvas.draw_arc(center,side*0.46,0,TAU,64,Color(bronze,0.38),0.8,true)
	canvas.draw_arc(center,side*0.42,PI*0.12,PI*0.88,24,Color(bronze,0.24),0.7,true)
	# A short pedestal rule anchors tall tokens as well as broad books and weapons.
	var y:=center.y+side*0.43
	canvas.draw_line(Vector2(center.x-side*0.27,y),Vector2(center.x+side*0.27,y),Color(bronze,0.5),0.9,true)
	canvas.draw_circle(Vector2(center.x,y),1.6,bronze,true,-1,true)

static func draw_icon(canvas:CanvasItem,source:Texture2D,area:Rect2,dark:bool=false)->void:
	if source==null:return
	draw_plate(canvas,area,dark)
	var selected:=path_for(source.resource_path,maxf(area.size.x,area.size.y))
	if not selected.is_empty() and selected!=source.resource_path:
		var framed:=texture_for(selected) as AtlasTexture
		if framed!=null:source=framed.atlas
	var crop:=region(source.resource_path,source.get_size())
	var well:=area.grow(-minf(area.size.x,area.size.y)*0.065)
	var scale_value:=minf(well.size.x/crop.size.x,well.size.y/crop.size.y)
	var extent:=crop.size*scale_value
	canvas.draw_texture_rect_region(source,Rect2(well.get_center()-extent*0.5,extent),crop)
