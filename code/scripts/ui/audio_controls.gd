extends VBoxContainer
## Paper-menu controls; audio preferences are separate from the three run slots.
var volume_slider: HSlider
var mute_button: CheckButton
var volume_label: Label
var title_label: Label
var _audio: Node
func _ready() -> void:
	add_theme_constant_override("separation",8)
	custom_minimum_size=Vector2(280,95)
	var row:=HBoxContainer.new();add_child(row)
	title_label=Label.new();title_label.text="战斗音效";title_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(title_label)
	volume_label=Label.new();row.add_child(volume_label)
	volume_slider=HSlider.new()
	volume_slider.min_value=0;volume_slider.max_value=100;volume_slider.step=5
	volume_slider.custom_minimum_size.y=26
	volume_slider.tooltip_text="调整战斗音效音量"
	add_child(volume_slider)
	for key in ["slider","grabber_area","grabber_area_highlight"]:
		var style:=StyleBoxFlat.new()
		style.bg_color=Color("d7c9ae") if key=="slider" else Color("b78e4b")
		style.content_margin_top=3;style.content_margin_bottom=3
		style.set_corner_radius_all(3)
		volume_slider.add_theme_stylebox_override(key,style)
	var image:=Image.new()
	image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18"><circle cx="9" cy="9" r="7" fill="#d6ad64" stroke="#80613e" stroke-width="1.5"/><circle cx="9" cy="9" r="3" fill="#fff4d4"/></svg>')
	var knob:=ImageTexture.create_from_image(image)
	volume_slider.add_theme_icon_override("grabber",knob)
	volume_slider.add_theme_icon_override("grabber_highlight",knob)
	mute_button=CheckButton.new();mute_button.text="静音";mute_button.custom_minimum_size.y=32;add_child(mute_button)
	volume_slider.value_changed.connect(func(value: float): if _audio!=null:_audio.set_volume(value))
	mute_button.toggled.connect(func(value: bool): if _audio!=null:_audio.set_muted(value))

func setup(audio: Node, label_text: String="战斗音效") -> void:
	_audio=audio
	title_label.text=label_text
	volume_slider.tooltip_text=label_text+"音量"
	_audio.settings_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	volume_slider.set_value_no_signal(_audio.get_volume())
	mute_button.set_pressed_no_signal(_audio.is_muted())
	volume_label.text="%d%%"%int(_audio.get_volume())