extends RefCounted
const Characters = preload("res://code/scripts/characters/character_catalog.gd")
const Professions=preload("res://code/scripts/profession_names.gd")
const CLASSES := ["刺客型", "战士型", "盾牌型", "奶妈型", "法师型", "辅助型"]
static func empty_inventory() -> Dictionary:
	var inventory := {}
	for category: String in CLASSES: inventory[category] = 0
	return inventory
static func profession(id: String) -> String:
	var value: String = Characters.leader(id).get("class", "")
	return "刺客型" if value == "游侠型" else value
static func count(run: Dictionary, category: String) -> int:
	return maxi(0, int(run.get("recruit_orders", {}).get(category, 0)))
static func award(run: Dictionary, node_id: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = (str(run.seed) + ":order:" + node_id).hash()
	var category: String = CLASSES[rng.randi_range(0, CLASSES.size() - 1)]
	run.recruit_orders = run.get("recruit_orders", empty_inventory()).duplicate()
	run.recruit_orders = empty_inventory()
	run.pending_recruit_order = category
	run.last_recruit_order = category
static func summary(run: Dictionary) -> String:
	var parts: Array[String] = []
	for category: String in CLASSES:
		parts.append("%s %d" % [Professions.label(category), count(run, category)])
	return "召集令：" + " · ".join(parts)
