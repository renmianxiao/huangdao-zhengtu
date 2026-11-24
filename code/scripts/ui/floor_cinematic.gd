extends Control

signal finished(skipped: bool)

const Catalog = preload("res://code/scripts/cinematics/catalog.gd")
const SFX = preload("res://code/scripts/audio/combat_audio.gd")
const PAPER_SHADER = preload("res://code/shaders/cinematics/paper.gdshader")
const INK_SHADER = preload("res://code/shaders/cinematics/ink_reveal.gdshader")
const ATMOSPHERE_SHADER = preload("res://code/shaders/cinematics/atmosphere.gdshader")

var autoplay := true
var floor_number := 1
var elapsed := 0.0
var stopped := false
var audio_player: AudioStreamPlayer
var skip_button: Button
var paper: ColorRect
var background: TextureRect
var atmosphere: ColorRect
var _paper_material: ShaderMaterial
var _ink_material: ShaderMaterial
var _atmosphere_material: ShaderMaterial
var _music: Node
var _holds_music_duck := false


func setup(value: int) -> void:
	floor_number = clampi(value, 1, 5)


func _ready() -> void:
	name = "FloorCinematic"
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var info: Dictionary = Catalog.TRANSITIONS[floor_number - 1]

	_paper_material = ShaderMaterial.new()
	_paper_material.shader = PAPER_SHADER
	paper = ColorRect.new()
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.material = _paper_material
	add_child(paper)

	_ink_material = ShaderMaterial.new()
	_ink_material.shader = INK_SHADER
	_ink_material.set_shader_parameter("origin", info.reveal_origin)
	_ink_material.set_shader_parameter("full_radius", info.full_radius)
	_ink_material.set_shader_parameter("desaturate", 0.12)
	background = TextureRect.new()
	background.texture = load(info.background)
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.material = _ink_material
	add_child(background)

	_atmosphere_material = ShaderMaterial.new()
	_atmosphere_material.shader = ATMOSPHERE_SHADER
	for parameter in ["light_position", "light_color", "fog_color", "light_strength", "ray_strength"]:
		_atmosphere_material.set_shader_parameter(parameter, info[parameter])
	atmosphere = ColorRect.new()
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	atmosphere.material = _atmosphere_material
	add_child(atmosphere)

	skip_button = Button.new()
	skip_button.text = "跳过  ·  空格 / 右键"
	skip_button.custom_minimum_size = Vector2(200, 42)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(.06, .07, .09, .48)
	box.border_color = Color(.83, .75, .58, .55)
	box.set_border_width_all(1)
	box.content_margin_left = 14
	box.content_margin_right = 14
	for kind in ["normal", "hover", "pressed", "focus"]:
		skip_button.add_theme_stylebox_override(kind, box)
	skip_button.add_theme_color_override("font_color", Color("eaddbe"))
	skip_button.add_theme_font_size_override("font_size", 17)
	skip_button.pressed.connect(skip)
	add_child(skip_button)

	if AudioServer.get_bus_index(SFX.BUS) < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, SFX.BUS)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
		var limiter := AudioEffectLimiter.new()
		limiter.threshold_db = -4.0
		limiter.ceiling_db = -1.0
		AudioServer.add_bus_effect(AudioServer.get_bus_index(SFX.BUS), limiter)
		SFX._load_settings()
		SFX._apply_bus()
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = SFX.BUS
	audio_player.stream = load(info.audio)
	add_child(audio_player)
	if autoplay and not stopped:
		_music = get_node_or_null("/root/Music")
		if is_instance_valid(_music):
			_music.begin_cinematic()
			_holds_music_duck = true
		audio_player.play()
	resized.connect(_paint)
	_paint()
	set_process(autoplay and not stopped)


func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	if stopped:
		return
	seek(elapsed + maxf(0, delta))
	if elapsed >= Catalog.DURATION:
		_finish(false)


func seek(seconds: float) -> void:
	elapsed = clampf(seconds, 0, Catalog.DURATION)
	if is_node_ready():
		_paint()


func _paint() -> void:
	if not is_instance_valid(background):
		return
	var frame := Catalog.frame(floor_number, elapsed)
	var aspect := Vector2(size.x / maxf(1.0, size.y), 1.0)
	paper.size = size
	_paper_material.set_shader_parameter("canvas_size", size)
	background.size = size
	background.scale = Vector2.ONE * float(frame.zoom)
	background.position = size * 0.5 * (1.0 - float(frame.zoom))
	_ink_material.set_shader_parameter("aspect", aspect)
	_ink_material.set_shader_parameter("reveal", frame.reveal)
	atmosphere.size = size
	_atmosphere_material.set_shader_parameter("aspect", aspect)
	_atmosphere_material.set_shader_parameter("clock_seconds", elapsed)
	_atmosphere_material.set_shader_parameter("strength", frame.strength)
	_atmosphere_material.set_shader_parameter("ending", frame.ending)
	skip_button.position = Vector2(maxf(12, size.x - 242), maxf(12, size.y - 68))
	skip_button.size = Vector2(200, 42)


func skip() -> bool:
	if stopped or elapsed < .35:
		return false
	_finish(true)
	return true


func _finish(skipped: bool) -> void:
	if stopped:
		return
	cancel()
	finished.emit(skipped)


func cancel() -> void:
	stopped = true
	set_process(false)
	if is_instance_valid(audio_player):
		audio_player.stop()
		audio_player.stream = null
	if _holds_music_duck:
		_holds_music_duck = false
		if is_instance_valid(_music):
			_music.end_cinematic()
	_music = null


func _exit_tree() -> void:
	cancel()


func _input(event: InputEvent) -> void:
	if stopped:
		return
	if event is InputEventKey:
		if event.keycode == KEY_F11:
			return
		get_viewport().set_input_as_handled()
		if event.pressed and not event.echo and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
			skip()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		if event.pressed:
			skip()
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_START]):
			skip()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		accept_event()
