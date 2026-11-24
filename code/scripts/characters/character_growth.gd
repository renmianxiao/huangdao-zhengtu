extends RefCounted
const Catalog = preload("res://code/scripts/characters/character_catalog.gd")

static func upgrades(state: Dictionary) -> Dictionary:
	return state.get("character_upgrades", state.get("config", {}).get("character_upgrades", {}))

static func is_upgraded(state: Dictionary, id: String) -> bool:
	return Catalog.RECRUIT_COSTS.has(id) and upgrades(state).get(id, false) == true

static func upgrade_cost(id: String) -> int:
	return {3: 2, 1: 1, 0: 0}.get(int(Catalog.RECRUIT_COSTS.get(id, -1)), 999999)

static func multiplier_numerator(state: Dictionary, id: String) -> int:
	return 6 if is_upgraded(state, id) else 5
