extends RefCounted
const Relics = preload("res://code/scripts/relics/relic_catalog.gd")
const Characters = preload("res://code/scripts/characters/character_catalog.gd")

static func front(state: Dictionary) -> Array:
	if state.has("party_slots"):
		var ids: Array = []
		for i in range(mini(4,state.party_slots.size())):
			var id: String = state.party_slots[i]
			if not id.is_empty() and Characters.ROLE_HP.has(id): ids.append(id)
		return ids
	return state.get("front_team",state.get("config",state).get("team",Characters.STARTER_IDS))

static func attribute_percent(state: Dictionary, id: String, basis: String) -> int:
	var percent := 0
	if basis == "attack" and Relics.has(state,"whetstone"): percent += 8
	if basis == "max_hp" and Relics.has(state,"heart_mirror"): percent += 10
	var active := front(state)
	if active.size() != 4 or not active.has(id): return percent
	if Relics.has(state,"four_symbols_chart"): percent += 15 if basis == "max_hp" else 5
	if Relics.has(state,"concord_jade"):
		var classes: Array = []
		for member: String in active:
			var profession: String = Characters.leader(member).get("class","")
			if not classes.has(profession): classes.append(profession)
		if classes.size() == 4: percent += 12
	return percent

