extends RefCounted
const Catalog = preload("res://code/scripts/characters/character_catalog.gd")
const Relics = preload("res://code/scripts/relics/relic_battle.gd")

## Shared tactical statuses; Battle owns the private mutable state.
static func front(state: Dictionary) -> Array:
	return state.get("front_team", state.get("config", {}).get("team", Catalog.STARTER_IDS))

static func snapshot(state: Dictionary, actor: String = "") -> Dictionary:
	var others := 0
	var attacks := 0
	var mage_attacks := 0
	var warriors := 0
	var unacted := 0
	for id: String in front(state):
		if id == actor: continue
		var member := Catalog.leader(id)
		if member.get("class", "") == "战士型": warriors += 1
		if state.used.has(id): others += 1
		else: unacted += 1
		if state.get("round_attackers", {}).has(id):
			attacks += 1
			if member.get("class", "") == "法师型": mage_attacks += 1
	return {"other_actions": others, "other_attacks": attacks, "other_mage_attacks": mage_attacks, "other_warriors": warriors, "unacted_others": unacted, "armor_removed": int(state.get("armor_removed", 0))}

static func set_buff(state: Dictionary, amount: int, classes: Array = []) -> void:
	if amount > int(state.buff):
		state.buff = amount
		state.buff_classes = classes.duplicate()

static func consume_attack_bonus(state: Dictionary, actor: String) -> int:
	var classes: Array = state.get("buff_classes", [])
	var applicable: bool = classes.is_empty() or classes.has(Catalog.leader(actor).get("class", ""))
	var bonus := 0
	if applicable:
		bonus = int(state.buff)
		state.buff = 0
		state.buff_classes = []
	var mark: Dictionary = state.get("mark", {})
	if not mark.is_empty() and mark.owner != actor:
		bonus = maxi(bonus, int(mark.amount))
		state.mark = {}
	return bonus

static func apply(state: Dictionary, actor: String, effect: Dictionary, context: Dictionary) -> void:
	var amount := int(effect.get("amount", 0))
	match str(effect.op):
		"mark":
			if amount > int(state.get("mark", {}).get("amount", 0)): state.mark = {"amount": amount, "owner": actor}
		"class_buff": set_buff(state, amount, effect.get("classes", []))
		"carry_shield": state.carry_limit = maxi(int(state.get("carry_limit", 0)), amount)
		"overheal": state.shield += mini(amount, int(context.get("overheal", 0)))
		"delayed_buff": state.delayed_buff = maxi(int(state.get("delayed_buff", 0)), amount)

static func finish_round(state: Dictionary) -> void:
	var saved := Relics.retained_shield(state,mini(int(state.shield), int(state.get("carry_limit", 0))))
	var delayed := int(state.get("delayed_buff", 0))
	state.shield = saved
	state.buff = 0
	state.buff_classes = []
	state.mark = {}
	state.carry_limit = 0
	state.delayed_buff = 0
	state.round_attackers = {}
	state.armor_removed = 0
	if delayed > 0: set_buff(state, delayed)

static func clear_finished(state: Dictionary) -> void:
	if state.status == "playing": return
	state.mark = {}
	state.buff_classes = []
	state.carry_limit = 0
	state.delayed_buff = 0

static func first_heal_bonus(state: Dictionary, actor: String, passive: Dictionary, matches_condition: bool) -> int:
	if passive.get("kind", "") != "first_heal_if": return 0
	var key := actor + ":first_heal_if"
	if state.passive_battle_used.has(key): return 0
	state.passive_battle_used[key] = true
	return int(passive.amount) if matches_condition else 0

static func after_heal(state: Dictionary, actor: String, passive: Dictionary, restored: int) -> void:
	if passive.get("kind", "") != "first_heal_shield": return
	var key := actor + ":first_heal_shield"
	if state.passive_battle_used.has(key): return
	state.passive_battle_used[key] = true
	if restored > 0: state.shield += int(passive.amount)
