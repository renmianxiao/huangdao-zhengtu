extends RefCounted
## Public names only; rule keys remain distinct so renaming never changes combat.
const TITLES := ["侠客", "守卫", "方士", "谋士", "医师", "刺客"]
const NAMES := {"战士型":"侠客", "盾牌型":"守卫", "法师型":"方士", "辅助型":"谋士", "奶妈型":"医师", "刺客型":"刺客", "游侠型":"刺客", "战士":"侠客", "盾牌":"守卫", "法师":"方士", "辅助":"谋士", "奶妈":"医师", "游侠":"刺客"}

static func label(value: String) -> String:
	return NAMES.get(value, value)

static func labels(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		var shown := label(str(value))
		if not result.has(shown): result.append(shown)
	return result

static func text(value: String) -> String:
	for old: String in NAMES:
		if old.ends_with("型"): value = value.replace(old, NAMES[old])
	# Unqualified references to people are professions; shields and support effects
	# can also be ordinary game concepts and keep their wording outside role labels.
	for old: String in ["战士", "法师", "奶妈", "游侠"]:
		value = value.replace(old, NAMES[old])
	value = value.replace("辅助职业", "谋士职业").replace("辅助角色", "谋士角色")
	for title: String in TITLES:
		for separator: String in ["/", "／", "、"]:
			value = value.replace(title + separator + title, title)
	return value
