extends Control
const Recommendations=preload("res://code/scripts/run/opening_recommendations.gd")
const Professions=preload("res://code/scripts/profession_names.gd")
signal confirmed(bundle_id:String)
signal canceled
const Rules=preload("res://code/scripts/run/opening_rules.gd")
const Paper=preload("res://code/scripts/ui/global_theme.gd")
const ORDER_ART={"刺客型":"assassin","战士型":"warrior","盾牌型":"guardian","奶妈型":"healer","法师型":"mage","辅助型":"support"}
var state:Dictionary={}
var card_buttons:Dictionary={}
var order_icons:Array[TextureRect]=[]
var selected_id:=""
var confirm_button:Button
var cancel_button:Button
var card_scroll:ScrollContainer
var card_grid:GridContainer
var selection_label:Label
var _submitted:=false
func _ready() -> void:
	theme=Paper.make(17)
	var page:=VBoxContainer.new()
	page.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	page.add_theme_constant_override("separation",12)
	add_child(page)
	var heading:=HBoxContainer.new();page.add_child(heading)
	var title:=_label(heading,"结伴入江湖",30)
	title.size_flags_horizontal=SIZE_EXPAND_FILL
	var resources:=_label(heading,"等级 1    声望 3    卡槽 3",21)
	resources.add_theme_color_override("font_color",Paper.GOLD)
	var hint:=_label(page,"选择一组召集令，再招募三位同行角色。三次招募共用3声望，未用完的声望保留。",16)
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hint.custom_minimum_size.x=1
	card_scroll=ScrollContainer.new()
	card_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	card_scroll.size_flags_vertical=SIZE_EXPAND_FILL
	page.add_child(card_scroll)
	card_grid=GridContainer.new()
	card_grid.size_flags_horizontal=SIZE_EXPAND_FILL
	card_grid.add_theme_constant_override("h_separation",12)
	card_grid.add_theme_constant_override("v_separation",12)
	card_scroll.add_child(card_grid)
	var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",12);page.add_child(footer)
	selection_label=_label(footer,"请选择召集令组合",16)
	selection_label.size_flags_horizontal=SIZE_EXPAND_FILL
	selection_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;selection_label.custom_minimum_size.x=1
	cancel_button=Button.new();cancel_button.text="返回";cancel_button.custom_minimum_size=Vector2(120,48)
	cancel_button.pressed.connect(func():canceled.emit());footer.add_child(cancel_button)
	confirm_button=Button.new();confirm_button.text="确认组合，开始招募";confirm_button.custom_minimum_size=Vector2(224,48)
	Paper.primary(confirm_button);confirm_button.disabled=true
	confirm_button.pressed.connect(_confirm);footer.add_child(confirm_button)
	resized.connect(_layout)
	if not state.is_empty():configure(state)
func _label(parent:Node,value:String,font_size:int) -> Label:
	var label:=Label.new();label.text=value;label.add_theme_font_size_override("font_size",font_size)
	label.mouse_filter=MOUSE_FILTER_IGNORE
	parent.add_child(label);return label
func configure(run:Dictionary) -> void:
	state=run.duplicate(true)
	if not is_node_ready():return
	for child in card_grid.get_children():card_grid.remove_child(child);child.queue_free()
	card_buttons.clear();order_icons.clear();selected_id="";_submitted=false;confirm_button.disabled=true
	selection_label.text="请选择召集令组合"
	for bundle:Dictionary in Rules.choices(state):
		var card:=Button.new();card.clip_contents=true;card.mouse_default_cursor_shape=CURSOR_POINTING_HAND
		card.pressed.connect(select_bundle.bind(bundle.id))
		card_grid.add_child(card);card_buttons[bundle.id]=card
		var box:=VBoxContainer.new();box.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		box.offset_left=8;box.offset_right=-8;box.offset_top=8;box.offset_bottom=-8
		box.mouse_filter=MOUSE_FILTER_IGNORE;card.add_child(box)
		var title:=_label(box,bundle.name,22);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var caption:=_label(box,("推荐 · " if Recommendations.TEAMS.has(bundle.id) else "")+bundle.text,13);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_color_override("font_color",Paper.MUTED)
		var spacer:=Control.new();spacer.size_flags_vertical=SIZE_EXPAND_FILL;box.add_child(spacer)
		var icons:=HBoxContainer.new();icons.alignment=BoxContainer.ALIGNMENT_CENTER
		icons.add_theme_constant_override("separation",8);icons.mouse_filter=MOUSE_FILTER_IGNORE;box.add_child(icons)
		for category:String in bundle.orders:
			var column:=VBoxContainer.new();column.mouse_filter=MOUSE_FILTER_IGNORE;icons.add_child(column)
			var icon:=TextureRect.new();icon.texture=load("res://art/resources/order_%s.png"%ORDER_ART[category])
			icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size=Vector2(46,46);icon.mouse_filter=MOUSE_FILTER_IGNORE;column.add_child(icon);order_icons.append(icon)
			var name_label:=_label(column,Professions.label(category),14);name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var bottom_spacer:=Control.new();bottom_spacer.size_flags_vertical=SIZE_EXPAND_FILL;box.add_child(bottom_spacer)
	_refresh_styles();_layout.call_deferred()
func select_bundle(id:String) -> void:
	if _submitted or not card_buttons.has(id):return
	selected_id=id;confirm_button.disabled=false
	for bundle:Dictionary in Rules.choices(state):
		if bundle.id==id:
			selection_label.text="已选："+bundle.name
			var recommendation:String=Recommendations.describe(id)
			if not recommendation.is_empty():selection_label.text+="\n"+recommendation
	_refresh_styles()
func _refresh_styles() -> void:
	for id:String in card_buttons:
		for mode:String in ["normal","hover","pressed","focus"]:
			var picked:=id==selected_id
			var style:=Paper.box(Color("eadbc0") if picked or mode in ["hover","pressed"] else Color("f8f2e7"),Paper.RED if picked else Paper.BORDER)
			style.set_border_width_all(2 if picked else 1)
			card_buttons[id].add_theme_stylebox_override(mode,Paper.ornate(style,false,2 if picked else 0))
func _layout() -> void:
	if card_scroll==null:return
	card_grid.columns=4 if size.x>=760 else 2
	var width:=floorf((maxf(1,size.x)-16-12*(card_grid.columns-1))/card_grid.columns)
	var rows:=ceili(float(card_buttons.size())/card_grid.columns)
	var height:=maxf(170,floorf((size.y-148-12*(rows-1))/rows))
	var icon_size:=clampf((width-48)/3.0,46,128)
	for icon:TextureRect in order_icons:icon.custom_minimum_size=Vector2(icon_size,icon_size)
	for card:Button in card_buttons.values():card.custom_minimum_size=Vector2(maxf(160,width),height)
func _confirm() -> void:
	if _submitted or selected_id.is_empty():return
	_submitted=true;confirm_button.disabled=true
	confirmed.emit(selected_id)
