extends HBoxContainer
const Professions=preload("res://code/scripts/profession_names.gd")
const Catalog = preload("res://code/scripts/relics/relic_catalog.gd")
const Items = preload("res://code/scripts/ui/item_presentation.gd")
var ids: Array = []
func configure(state: Dictionary) -> void:
	name = "RelicDrops"
	for child in get_children():
		remove_child(child)
		child.queue_free()
	ids = state.get("last_relic_drops",[]).duplicate()
	visible = not ids.is_empty()
	add_theme_constant_override("separation",10)
	if not visible: return
	var title := Label.new()
	title.text = "获得藏品"
	add_child(title)
	for id: String in ids:
		var item := Catalog.definition(id)
		var icon := TextureRect.new()
		icon.texture_filter=TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		icon.custom_minimum_size = Vector2(44,44)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = Items.texture_for(str(item.icon),44)
		icon.tooltip_text = Professions.text(str(item.effect))
		add_child(icon)
		var caption := Label.new()
		caption.text = "%s（%d金）" % [item.name,item.price]
		caption.tooltip_text = Professions.text(str(item.effect))
		add_child(caption)
