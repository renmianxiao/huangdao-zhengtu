extends Control
## Enemy framing and transparent stage compositing; original PNGs stay untouched.
const Presentation = preload("res://code/scripts/ui/enemy_presentation.gd")
const CardColors = preload("res://code/scripts/ui/character_card_colors.gd")
const STAGE_SHADER := """
shader_type canvas_item;
uniform vec2 stage_offset = vec2(0.0);
uniform vec2 stage_scale = vec2(1.0);
uniform float side_feather = 0.055;
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	vec2 stage_uv = stage_offset + UV * stage_scale;
	float side = smoothstep(0.0, side_feather, UV.x) * (1.0 - smoothstep(1.0 - side_feather, 1.0, UV.x));
	float low = 1.0 - smoothstep(0.64, 0.98, stage_uv.y);
	c.a *= side * low;
	COLOR = c;
}
"""
var portrait_mode := false
var character_id := ""
var enemy_id := "":
	set(value):
		enemy_id = value
		queue_redraw()
var texture: Texture2D:
	set(value):
		texture=value
		queue_redraw()
var _shade: GradientTexture2D
func _ready() -> void:
	clip_contents=true
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	if portrait_mode: return
	var shader := Shader.new()
	shader.code = STAGE_SHADER
	material = ShaderMaterial.new()
	material.shader = shader
	_shade = GradientTexture2D.new()
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([Color(0.06,0.06,0.07,0.0), Color(0.06,0.06,0.07,0.36), Color(0.06,0.06,0.07,0.78)])
	_shade.gradient = gradient
	_shade.fill_from = Vector2(0, 0); _shade.fill_to = Vector2(0, 1)
	# Shade the band that carries intent, effects and health bars.
	var band := TextureRect.new()
	band.texture = _shade
	band.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	band.stretch_mode = TextureRect.STRETCH_SCALE
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.anchor_top = 0.64; band.anchor_right = 1.0; band.anchor_bottom = 1.0
	add_child(band)

func artwork_rect() -> Rect2:
	if texture==null or size.x<=0 or size.y<=0: return Rect2()
	var source:=texture.get_size()
	if portrait_mode:
		var region := CardColors.portrait_region(character_id, texture, size)
		return CardColors.portrait_destination(region, Rect2(Vector2.ZERO, size))
	var profile := Presentation.profile(enemy_id)
	var focus: Rect2 = profile.focus
	var top := size.y * float(profile.top)
	var scale_factor := maxf(size.y * 0.98 / source.y, size.x * float(profile.width) / source.x)
	# Keep the focal face entirely above the lower veil at every supported aspect.
	scale_factor = minf(scale_factor, (size.y * 0.63 - top) / (source.y * focus.end.y))
	var shown:=source*scale_factor
	var left := size.x * 0.54 - focus.get_center().x * shown.x
	return Rect2(Vector2(left, top), shown)

func focal_rect() -> Rect2:
	var rect := artwork_rect()
	var focus: Rect2 = Presentation.profile(enemy_id).focus
	return Rect2(rect.position + focus.position * rect.size, focus.size * rect.size)

func _draw() -> void:
	if texture==null or size.x<=0 or size.y<=0: return
	var rect := artwork_rect()
	if portrait_mode:
		var region := CardColors.portrait_region(character_id, texture, size)
		draw_texture_rect_region(texture, rect, region)
		return
	if material is ShaderMaterial:
		material.set_shader_parameter("stage_offset", rect.position / size)
		material.set_shader_parameter("stage_scale", rect.size / size)
		material.set_shader_parameter("side_feather", Presentation.profile(enemy_id).side_feather)
	draw_texture_rect(texture,rect,false)
