extends Control
## The codex detail stage. Characters stand full-length beside their notes,
## monsters fill the stage with notes over a dark lower veil, relics and events
## float on a halo. The info column is a child placed by layout_info().
signal art_clicked
const CardColors=preload("res://code/scripts/ui/character_card_colors.gd")
const Paper=preload("res://code/scripts/ui/global_theme.gd")
const Items=preload("res://code/scripts/ui/item_presentation.gd")
var mode:="characters"
var entry_id:=""
var texture: Texture2D
var backdrop: Texture2D
var info: VBoxContainer
static var _halo: GradientTexture2D
static var _veil: GradientTexture2D

func _init() -> void:
	texture_filter=TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	clip_contents=true
	mouse_filter=MOUSE_FILTER_STOP
	mouse_default_cursor_shape=CURSOR_POINTING_HAND
	tooltip_text="点击放大立绘"
	info=VBoxContainer.new()
	info.add_theme_constant_override("separation",6)
	info.mouse_filter=MOUSE_FILTER_PASS
	add_child(info)
	resized.connect(layout_info)
	gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			art_clicked.emit();accept_event())

func show_entry(kind: String,id: String,art: Texture2D,scene: Texture2D=null) -> void:
	mode=kind;entry_id=id;texture=art;backdrop=scene
	layout_info();queue_redraw()

func _art_rect() -> Rect2:
	match mode:
		"characters": return Rect2(0,0,size.x*0.46,size.y)
		"monsters": return Rect2(Vector2.ZERO,size)
		_: return Rect2(0,0,size.x*0.38,size.y)

func layout_info() -> void:
	if info==null: return
	if mode=="monsters":
		var height:=minf(size.y*0.46,info.get_combined_minimum_size().y+24)
		info.position=Vector2(20,size.y-height);info.size=Vector2(size.x-40,height-12)
	else:
		var left:=_art_rect().end.x+8
		info.position=Vector2(left,18);info.size=Vector2(maxf(40,size.x-left-18),size.y-30)

func _draw() -> void:
	var stage:=Rect2(Vector2.ZERO,size)
	var accent:Color=CardColors.ORNAMENTS[CardColors.tier(entry_id)] if mode=="characters" else Paper.OLD_GOLD
	draw_rect(stage,CardColors.DARK[CardColors.tier(entry_id)].darkened(0.25) if mode=="characters" else Color("1b1f20"))
	if texture==null: return
	var area:=_art_rect()
	match mode:
		"characters":
			_glow(area.get_center()+Vector2(0,area.size.y*0.05),Vector2(area.size.x*1.5,area.size.y*1.1),accent,0.42)
			_contain(area.grow(-10))
			# Ground shadow and a gilt rule separating portrait from notes.
			draw_line(Vector2(area.end.x,22),Vector2(area.end.x,size.y-22),Color(accent,0.55),1.0,true)
		"monsters":
			var source:=texture.get_size()
			var scale_value:=maxf(size.x/source.x,size.y/source.y)
			var shown:=source*scale_value
			draw_texture_rect(texture,Rect2(Vector2((size.x-shown.x)*0.5,0),shown),false)
			_lower_veil(info.position.y-60)
		_:
			if backdrop!=null:
				var scene:=backdrop.get_size()
				var scale_value:=maxf(size.x/scene.x,size.y/scene.y)
				var shown:=scene*scale_value
				draw_texture_rect(backdrop,Rect2((size-shown)*0.5,shown),false,Color(0.42,0.40,0.38))
				_lower_veil(0)
			_glow(area.get_center(),Vector2.ONE*minf(area.size.x,area.size.y)*1.4,Color("c99a45"),0.32)
			var icon_size:=texture.get_size()
			if mode=="relics":
				var side:=minf(area.size.x,area.size.y)*0.88
				Items.draw_icon(self,texture,Rect2(area.get_center()-Vector2.ONE*side*0.5,Vector2.ONE*side),true)
			elif icon_size.x>icon_size.y*1.3:
				# A landscape must fit inside the tall detail well without sampling outside the PNG.
				var extent:=icon_size*minf(area.size.x/icon_size.x,area.size.y/icon_size.y)
				draw_texture_rect(texture,Rect2(area.get_center()-extent*0.5,extent),false)
			else:
				var side:=minf(area.size.x,area.size.y)*0.74
				draw_texture_rect(texture,Rect2(area.get_center()-Vector2.ONE*side*0.5,Vector2.ONE*side),false)
			draw_line(Vector2(area.end.x,22),Vector2(area.end.x,size.y-22),Color(Paper.OLD_GOLD,0.55),1.0,true)

func _contain(area: Rect2) -> void:
	var source:=CardColors.portrait_region(entry_id,texture,area.size,"fullbody")
	draw_texture_rect_region(texture,CardColors.portrait_destination(source,area,true),source)

func _lower_veil(top: float) -> void:
	if _veil==null:
		var gradient:=Gradient.new()
		gradient.offsets=PackedFloat32Array([0.0,0.35,1.0])
		gradient.colors=PackedColorArray([Color(0.08,0.09,0.09,0.0),Color(0.08,0.09,0.09,0.78),Color(0.08,0.09,0.09,0.96)])
		_veil=GradientTexture2D.new();_veil.gradient=gradient
		_veil.fill_from=Vector2.ZERO;_veil.fill_to=Vector2(0,1)
	draw_texture_rect(_veil,Rect2(0,maxf(0,top),size.x,size.y-maxf(0,top)),false)

func _glow(center: Vector2,extent: Vector2,color: Color,opacity: float) -> void:
	if _halo==null:
		var gradient:=Gradient.new()
		gradient.colors=PackedColorArray([Color(1,1,1,1),Color(1,1,1,0)])
		_halo=GradientTexture2D.new();_halo.gradient=gradient
		_halo.fill=GradientTexture2D.FILL_RADIAL;_halo.fill_from=Vector2(0.5,0.5);_halo.fill_to=Vector2(0.5,0.0)
	draw_texture_rect(_halo,Rect2(center-extent*0.5,extent),false,Color(color,opacity))
