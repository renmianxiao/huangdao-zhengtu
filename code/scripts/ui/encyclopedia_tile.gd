extends Button
## One codex entry. Characters show an upper-body crop framed by rarity,
## monsters a cropped battle painting, relics and events an icon on a soft halo.
## Unrecorded entries stay readable but sink into ink; recorded ones carry a seal.
const CardColors=preload("res://code/scripts/ui/character_card_colors.gd")
const Paper=preload("res://code/scripts/ui/global_theme.gd")
const Items=preload("res://code/scripts/ui/item_presentation.gd")
const Art=preload("res://code/scripts/ui/map_ornament.gd")
const INK_BG:=Color("1f2324")
const PLATE:=Color(0.10,0.11,0.11,0.94)
const SEAL:=Color("a8392d")
const TIER_COLORS:={"普通":Color("7b8a90"),"精英":Color("8f7a9c"),"道中Boss":Color("c0703f"),"最终Boss":Color("c99a45")}
const PLATE_HEIGHT:=46.0

var entry_kind:="characters"
var entry_id:=""
var entry_name:=""
var caption:=""
var stamp:=""
var recorded:=false
var badge:=""
var texture: Texture2D
## Optional dimmed scene behind an icon (events without their own painting).
var backdrop: Texture2D
var selected:=false:
	set(value):
		selected=value
		queue_redraw()
static var _halo: GradientTexture2D

func _init() -> void:
	texture_filter=TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	focus_mode=FOCUS_ALL
	mouse_default_cursor_shape=CURSOR_POINTING_HAND
	clip_contents=true
	for mode: String in ["normal","hover","pressed","disabled","focus"]:
		add_theme_stylebox_override(mode,StyleBoxEmpty.new())
	for mode: String in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color","font_disabled_color"]:
		add_theme_color_override(mode,Color.TRANSPARENT)
	for signal_name in ["mouse_entered","mouse_exited","focus_entered","focus_exited","resized"]:
		connect(signal_name,queue_redraw)

func configure(kind: String,data: Dictionary) -> void:
	entry_kind=kind
	entry_id=str(data.get("id",""))
	entry_name=str(data.get("name",""))
	caption=str(data.get("caption",""))
	stamp=str(data.get("stamp",""))
	recorded=bool(data.get("recorded",false))
	badge=str(data.get("badge",""))
	texture=data.get("texture") as Texture2D
	backdrop=data.get("backdrop") as Texture2D
	text=entry_name
	tooltip_text="%s · %s"%[entry_name,caption]
	queue_redraw()

func _edge() -> Color:
	if entry_kind=="characters": return CardColors.ORNAMENTS[CardColors.tier(entry_id)]
	if entry_kind=="monsters": return TIER_COLORS.get(badge,Paper.OLD_GOLD)
	return Color("71634b")

func _draw() -> void:
	var w:=size.x; var h:=size.y
	if w<40 or h<40: return
	var body:=Rect2(Vector2.ZERO,size)
	draw_rect(body,INK_BG)
	var art:=Rect2(3,3,w-6,h-PLATE_HEIGHT-3)
	_draw_art(art)
	if not recorded:
		draw_rect(art,Color(0.07,0.08,0.08,0.24))
	# Name plate: heading face over a dark band, caption beneath.
	var plate:=Rect2(0,h-PLATE_HEIGHT,w,PLATE_HEIGHT)
	draw_rect(plate,PLATE)
	draw_line(plate.position,Vector2(w,plate.position.y),Color(_edge(),0.85),1.0,true)
	var heading:=Paper.heading_font(); var body_font:=Paper.body_font()
	_centered(heading,entry_name,plate.position.y+21,17,Paper.DARK_TEXT if recorded else Paper.DARK_MUTED)
	_centered(body_font,caption,plate.position.y+39,12,Paper.DARK_MUTED)
	if not badge.is_empty() and entry_kind=="monsters":
		var badge_width:=body_font.get_string_size(badge,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x+12
		draw_rect(Rect2(6,6,badge_width,19),Color(_edge(),0.92))
		draw_string(body_font,Vector2(12,20),badge,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("fff3dc"))
	if recorded and not stamp.is_empty():_draw_seal(Vector2(w-17,17))
	# Frame: rarity edge, gilt and bracketed when selected, warmer on hover or focus.
	var edge:=_edge()
	if selected:
		draw_rect(body.grow(-1),Paper.HOVER_GOLD,false,2.0)
		for corner: Vector2 in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,1)]:
			var origin:=Vector2(5,5)+(size-Vector2(10,10))*corner
			var dir:=Vector2(1 if corner.x==0 else -1,1 if corner.y==0 else -1)
			draw_polyline(PackedVector2Array([origin+Vector2(0,14)*dir,origin,origin+Vector2(14,0)*dir]),Paper.HOVER_GOLD,1.6,true)
	else:
		draw_rect(body.grow(-0.5),edge.lightened(0.25) if is_hovered() or has_focus() else edge,false,1.0)
		if entry_kind=="characters" and CardColors.tier(entry_id)==3:
			draw_rect(body.grow(-3.5),Color(edge,0.45),false,1.0)

func _draw_art(area: Rect2) -> void:
	if texture==null: return
	match entry_kind:
		"characters":
			var tier:=CardColors.tier(entry_id)
			draw_rect(area,CardColors.DARK[tier])
			_glow(area.get_center()+Vector2(0,area.size.y*0.1),area.size*1.3,CardColors.ORNAMENTS[tier],0.35)
			var portrait:=CardColors.portrait_region(entry_id,texture,area.size)
			draw_texture_rect_region(texture,CardColors.portrait_destination(portrait,area),portrait)
		"monsters":
			var source:=texture.get_size()
			var ratio:=area.size.x/maxf(1,area.size.y)
			var region_width:=minf(source.x,source.y*ratio)
			var region_height:=region_width/ratio
			draw_texture_rect_region(texture,area,Rect2((source.x-region_width)*0.5,0,region_width,region_height))
		_:
			if backdrop!=null:
				var scene:=backdrop.get_size()
				var region_height:=minf(scene.y,scene.x*area.size.y/area.size.x)
				draw_texture_rect_region(backdrop,area,Rect2(0,(scene.y-region_height)*0.45,scene.x,region_height),Color(0.50,0.48,0.46))
			_glow(area.get_center(),Vector2.ONE*minf(area.size.x,area.size.y)*1.2,Color("c99a45"),0.30)
			var side:=minf(area.size.x,area.size.y)*0.78
			var icon_size:=texture.get_size()
			if entry_kind=="relics":
				side=minf(area.size.x,area.size.y)*0.90
				Items.draw_icon(self,texture,Rect2(area.get_center()-Vector2.ONE*side*0.5,Vector2.ONE*side),true)
			elif icon_size.x>icon_size.y*1.3:
				# A wide scene painting fills the art well instead of floating as an icon.
				var ratio:=area.size.x/maxf(1.0,area.size.y)
				var region_width:=minf(icon_size.x,icon_size.y*ratio)
				var region_height:=region_width/ratio
				draw_texture_rect_region(texture,area,Rect2((icon_size.x-region_width)*0.5,(icon_size.y-region_height)*0.20,region_width,region_height))
			else:
				draw_texture_rect(texture,Rect2(area.get_center()-Vector2.ONE*side*0.5,Vector2.ONE*side),false)

func _draw_seal(center: Vector2) -> void:
	var r:=10.0
	draw_rect(Rect2(center-Vector2(r,r),Vector2(r,r)*2),Color(SEAL,0.92))
	draw_rect(Rect2(center-Vector2(r-2,r-2),Vector2(r-2,r-2)*2),Color("f3d6c2"),false,0.8)
	var glyph:=stamp.right(1)
	var font:=Paper.heading_font()
	var width:=font.get_string_size(glyph,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
	draw_string(font,center+Vector2(-width*0.5,5),glyph,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("fff1e0"))

func _glow(center: Vector2,extent: Vector2,color: Color,opacity: float) -> void:
	if _halo==null:
		var gradient:=Gradient.new()
		gradient.colors=PackedColorArray([Color(1,1,1,1),Color(1,1,1,0)])
		_halo=GradientTexture2D.new();_halo.gradient=gradient
		_halo.fill=GradientTexture2D.FILL_RADIAL;_halo.fill_from=Vector2(0.5,0.5);_halo.fill_to=Vector2(0.5,0.0)
	draw_texture_rect(_halo,Rect2(center-extent*0.5,extent),false,Color(color,opacity))

func _centered(font: Font,value: String,baseline: float,font_size: int,color: Color) -> void:
	if value.is_empty(): return
	var shown:=value
	var limit:=size.x-10
	while shown.length()>1 and font.get_string_size(shown,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>limit:
		shown=shown.left(shown.length()-2)+"…"
	var width:=font.get_string_size(shown,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	draw_string(font,Vector2((size.x-width)*0.5,baseline),shown,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
