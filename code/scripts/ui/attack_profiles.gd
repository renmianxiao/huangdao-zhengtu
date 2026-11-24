extends RefCounted

## Presentation only: family selects a shape, power scales its visual emphasis.
## Damage, penetration, poison application, and hit counts stay in combat logic.
const Catalog = preload("res://code/scripts/characters/character_catalog.gd")
const POISON_ACCENT := Color("#92c76a")
const ARCANE_ACCENT := Color("#a8c9eb")
const FLAME_ACCENT := Color("#f1a04c")

# Every current direct attack has an explicit weapon/spell choice. Similar rules
# do not imply similar weapons: mirror needles are spells; flying nails are steel.
# Values are [family, visual power], with light taps near 0.7 and finishers 1.4.
const SKILL_PROFILES := {
	"slash": ["slash", 0.8],
	"burst": ["slash", 1.4],
	"shot": ["arrow", 0.95],
	"toxin": ["arrow", 0.85],
	"break": ["impact", 1.1],
	"assassin_01_b": ["thrust", 0.95],
	"assassin_02_a": ["thrust", 0.85],
	"assassin_02_b": ["thrust", 1.15],
	"assassin_03_a": ["needle", 0.75],
	"assassin_03_b": ["needle", 0.95],
	"assassin_04_b": ["slash", 1.35],
	"assassin_05_a": ["slash", 1.0],
	"assassin_05_b": ["slash", 1.4],
	"warrior_01_b": ["slash", 1.1],
	"warrior_02_a": ["slash", 0.95],
	"warrior_02_b": ["slash", 1.2],
	"warrior_03_a": ["impact", 0.75],
	"warrior_03_b": ["impact", 1.25],
	"warrior_04_a": ["thrust", 0.7],
	"warrior_05_a": ["thrust", 1.0],
	"warrior_05_b": ["thrust", 1.4],
	"shield_04_b": ["impact", 1.0],
	"mage_01_a": ["arcane", 0.7],
	"mage_02_a": ["arcane", 0.95],
	"mage_02_b": ["arcane", 1.4],
	"mage_03_b": ["poison", 1.05],
	"mage_04_a": ["arcane", 0.7],
	"mage_04_b": ["arcane", 1.2],
	"mage_05_b": ["arcane", 1.1],
	"support_03_a": ["impact", 0.75],
	"budget_assassin_01_b": ["thrust", 0.95],
	"budget_assassin_02_a": ["thrust", 0.85],
	"budget_assassin_02_b": ["thrust", 1.15],
	"budget_assassin_03_a": ["needle", 0.75],
	"budget_assassin_03_b": ["thrust", 0.95],
	"budget_assassin_04_b": ["slash", 1.35],
	"budget_assassin_05_a": ["slash", 1.0],
	"budget_assassin_05_b": ["slash", 1.4],
	"budget_warrior_01_b": ["slash", 1.1],
	"budget_warrior_02_a": ["impact", 0.95],
	"budget_warrior_02_b": ["impact", 1.2],
	"budget_warrior_03_a": ["impact", 0.75],
	"budget_warrior_03_b": ["impact", 1.25],
	"budget_warrior_04_a": ["thrust", 0.7],
	"budget_warrior_05_a": ["thrust", 1.0],
	"budget_warrior_05_b": ["thrust", 1.4],
	"budget_shield_04_b": ["impact", 1.0],
	"budget_mage_01_a": ["arcane", 0.7],
	"budget_mage_02_a": ["arcane", 0.95],
	"budget_mage_02_b": ["arcane", 1.4],
	"budget_mage_03_b": ["poison", 1.05],
	"budget_mage_04_a": ["arcane", 0.7],
	"budget_mage_04_b": ["arcane", 1.2],
	"budget_mage_05_b": ["arcane", 1.1],
	"budget_support_03_a": ["impact", 0.75],
	"free_assassin_01_b": ["thrust", 0.95],
	"free_assassin_02_a": ["needle", 0.75],
	"free_assassin_02_b": ["needle", 0.95],
	"free_assassin_03_a": ["slash", 0.7],
	"free_assassin_03_b": ["slash", 1.4],
	"free_warrior_01_a": ["slash", 0.7],
	"free_warrior_01_b": ["slash", 1.1],
	"free_warrior_02_a": ["impact", 0.95],
	"free_warrior_02_b": ["impact", 1.2],
	"free_warrior_03_a": ["impact", 0.75],
	"free_warrior_03_b": ["impact", 1.25],
	"free_warrior_04_a": ["thrust", 0.7],
	"free_mage_01_a": ["arcane", 0.7],
	"free_mage_01_b": ["arcane", 1.15],
	"free_mage_02_a": ["arcane", 0.95],
	"free_mage_02_b": ["arcane", 1.4],
	"free_mage_03_a": ["arcane", 0.7],
	"free_mage_03_b": ["arcane", 1.2],
	"free_support_02_a": ["impact", 0.7],
}

# Ambiguous action names inherit their known weapon, never their piercing flag.
const ENEMY_FAMILY_OVERRIDES := {
	"赤砂断首": "slash",
	"暮色绝杀": "slash",
	"残旗横扫": "thrust",
	"幽门重击": "thrust",
	"月影穿心": "slash",
	"夜袭破阵": "slash",
	"玄门断刑": "slash",
	"扫阵": "slash",
	"阴阳双判": "arcane",
}

const CLASS_FAMILIES := {
	"战士型": "slash", "刺客型": "thrust", "游侠型": "arrow",
	"盾牌型": "impact", "法师型": "arcane", "辅助型": "impact", "奶妈型": "impact",
}

static func for_skill(id: String) -> Dictionary:
	var skill: Dictionary = Catalog.SKILLS.get(id, {})
	var effects: Array = skill.get("effects", [])
	var primary_op := str(effects[0].get("op", "")) if not effects.is_empty() else ""
	if not Catalog.is_attack_skill(id):
		return {"family": "support", "power": 0.7, "primary_op": primary_op}
	var profile: Dictionary
	if SKILL_PROFILES.has(id):
		var entry: Array = SKILL_PROFILES[id]
		profile = _profile(str(entry[0]), float(entry[1]))
	else:
		# Future catalog entries still get a useful class-based presentation until
		# their deliberate weapon profile is added above.
		var owner: Dictionary = Catalog.leader(str(skill.get("leader", "")))
		profile = _profile(str(CLASS_FAMILIES.get(owner.get("class", ""), "impact")), 0.95)
	for effect: Dictionary in effects:
		if effect.get("op", "") == "poison_add":
			profile.accent = POISON_ACCENT
	return profile

static func for_enemy(pattern: Dictionary) -> Dictionary:
	var damage := int(pattern.get("damage", 0))
	var hits := int(pattern.get("hits", 0))
	if damage <= 0 or hits <= 0:
		return {"family": "support", "power": 0.7, "primary_op": "shield" if int(pattern.get("ward", 0)) > 0 else "prepare"}
	var action_name := str(pattern.get("name", ""))
	var family := str(ENEMY_FAMILY_OVERRIDES.get(action_name, ""))
	if family.is_empty():
		family = _enemy_weapon_family(action_name)
	var power := clampf(0.7 + float(damage) * 0.002 + float(maxi(hits - 1, 0)) * 0.075 + (0.12 if pattern.get("interruptible", false) else 0.0), 0.7, 1.4)
	var profile := _profile(family, power)
	# Flame is a color treatment for actions named with fire. It adds no element
	# or status to the game and leaves physical flame claws as physical slashes.
	if _contains_any(action_name, ["火", "焰", "炎", "焚", "燃", "灼"]):
		profile.accent = FLAME_ACCENT
	return profile

static func _profile(family: String, power: float) -> Dictionary:
	var profile := {"family": family, "power": power}
	if family == "arcane":
		profile.accent = ARCANE_ACCENT
	elif family == "poison":
		profile.accent = POISON_ACCENT
	return profile

static func _enemy_weapon_family(action_name: String) -> String:
	if _contains_any(action_name, ["钉", "针"]):
		return "needle"
	if _contains_any(action_name, ["弩", "箭", "矢", "齐射", "全匣"]):
		return "arrow"
	if _contains_any(action_name, ["符", "印", "灯", "咒", "焰", "焚", "爆燃", "灼", "香灰", "判笔"]):
		return "arcane"
	if _contains_any(action_name, ["拳", "掌", "盾", "撞", "锤", "链", "柱", "重压", "重坠", "扑", "咬", "牙", "压制"]):
		return "impact"
	if _contains_any(action_name, ["矛", "戟", "刺", "枪", "槊", "喙"]):
		return "thrust"
	if _contains_any(action_name, ["刀", "斩", "剑", "刃", "劈", "砍", "爪"]):
		return "slash"
	return "impact"

static func _contains_any(value: String, tokens: Array) -> bool:
	for token: String in tokens:
		if value.contains(token):
			return true
	return false
