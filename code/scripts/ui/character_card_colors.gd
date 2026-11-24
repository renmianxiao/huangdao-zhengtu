extends RefCounted
## Original recruitment price defines a permanent visual tier, including upgrades.
const Characters=preload("res://code/scripts/characters/character_catalog.gd")
const Paper=preload("res://code/scripts/ui/global_theme.gd")
const LIGHT={3:Color("dfc8a8"),1:Color("d6c9dc"),0:Color("c5d5df")}
const DARK={3:Color("493b2e"),1:Color("3e3748"),0:Color("303f49")}
const EDGES={3:Color("b8893a"),1:Color("867294"),0:Color("62869a")}
## Rarity reads from the frame: gilt curls for 3, bronze diamonds for 1, plain iron for 0.
const ORNAMENTS={3:Color("c99a45"),1:Color("8f7a9c"),0:Color("7b8a90")}
const GRADES={3:2,1:1,0:0}
const UPGRADED_LIGHT={3:Color("f6e2bb"),1:Color("eee0f2"),0:Color("e0edf5")}
const UPGRADED_EDGE=Color("b28b37")
static func tier(id:String) -> int:
	var cost:=int(Characters.RECRUIT_COSTS.get(id,0))
	return cost if cost in [1,3] else 0
static func background(id:String,dark:bool=false,upgraded:bool=false) -> Color:
	if id.is_empty():return Paper.PANEL
	if upgraded:return DARK[tier(id)].lightened(0.15) if dark else UPGRADED_LIGHT[tier(id)]
	return DARK[tier(id)] if dark else LIGHT[tier(id)]
static func edge(id:String,dark:bool=false,upgraded:bool=false) -> Color:
	if id.is_empty():return Paper.BORDER
	if upgraded:return UPGRADED_EDGE.lightened(0.28) if dark else UPGRADED_EDGE
	var color:Color=EDGES[tier(id)]
	return color.lightened(0.28) if dark else color
static func panel(control:Control,id:String,dark:bool=false,upgraded:bool=false) -> void:
	var original:=control.get_theme_stylebox("panel")
	var style:StyleBoxFlat=original.duplicate() if original is StyleBoxFlat else Paper.box(Paper.PANEL)
	style.bg_color=background(id,dark,upgraded);style.border_color=edge(id,dark,upgraded)
	style.set_border_width_all(2 if upgraded or tier(id)==3 else 1)
	_upgrade_glow(style,upgraded)
	control.add_theme_stylebox_override("panel",framed(style,id,dark))
static func button(control:Button,id:String,selected:bool=false,upgraded:bool=false) -> void:
	if id.is_empty():return
	for mode:String in ["normal","hover","pressed","disabled"]:
		var original:=control.get_theme_stylebox(mode)
		var style:StyleBoxFlat=original.duplicate() if original is StyleBoxFlat else Paper.box(Paper.PANEL)
		style.bg_color=background(id,false,upgraded).darkened(0.045 if mode in ["hover","pressed"] else 0.0)
		style.border_color=Color("ae915d") if selected else edge(id,false,upgraded);style.set_border_width_all((4 if selected else 2) if upgraded else (3 if selected else (2 if tier(id)==3 else 1)))
		_upgrade_glow(style,upgraded)
		control.add_theme_stylebox_override(mode,framed(style,id))

static func framed(style:StyleBoxFlat,id:String,dark:bool=false) -> StyleBox:
	if id.is_empty():return style
	var color:Color=ORNAMENTS[tier(id)]
	return preload("res://code/scripts/ui/ornate_box.gd").wrap(style,color.lightened(0.2) if dark else color,GRADES[tier(id)])

static func _upgrade_glow(style:StyleBoxFlat,upgraded:bool) -> void:
	style.shadow_color=Color(0.70,0.52,0.18,0.20) if upgraded else Color.TRANSPARENT
	style.shadow_size=5 if upgraded else 0
	style.shadow_offset=Vector2.ZERO

## A quiet silk surround is shared by the recruitment gallery and formation board.
static func gallery(control:Control) -> void:
	var background:=ColorRect.new()
	background.name="InkGallery"
	background.color=Color("252829")
	background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.add_child(background)
	control.move_child(background,0)
	if ResourceLoader.exists("res://art/ui/materials/ink_silk.png"):
		var silk:=TextureRect.new()
		silk.texture=load("res://art/ui/materials/ink_silk.png")
		silk.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		silk.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		silk.modulate=Color(1,1,1,0.24)
		silk.mouse_filter=Control.MOUSE_FILTER_IGNORE
		silk.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		background.add_child(silk)

## One audited composition model for recruitment, formation, codex and battle.
const Presentation=preload("res://code/scripts/ui/character_presentation.gd")

static func portrait_focus(id:String) -> Vector2:
	return Presentation.focus(id)

static func portrait_region(id:String,texture:Texture2D,destination:Vector2,mode:String="halfbody") -> Rect2:
	if texture==null:return Rect2()
	return Presentation.region(id,texture.get_size(),destination,mode)

static func portrait_destination(source:Rect2,area:Rect2,bottom_aligned:bool=false) -> Rect2:
	return Presentation.destination(source,area,bottom_aligned)