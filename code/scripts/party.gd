extends RefCounted
const Characters = preload("res://code/scripts/characters/character_catalog.gd")
const Attributes=preload("res://code/scripts/combat/attributes.gd")
const Growth=preload("res://code/scripts/characters/character_growth.gd")
const Relics=preload("res://code/scripts/relics/relic_catalog.gd")

## Slots 0..3 are front, 4..7 are back. Only front cards contribute HP.
const FRONT_SIZE := 4
const MAX_SIZE := 8
const ROLE_HP: Dictionary = Characters.ROLE_HP

static func slots_for(team: Array) -> Array:
	var slots: Array = ["", "", "", "", "", "", "", ""]
	for i in range(mini(MAX_SIZE, team.size())): slots[i] = team[i]
	return slots

static func members(slots: Array, first: int = 0, last: int = MAX_SIZE) -> Array:
	var result: Array = []
	for i in range(first, mini(last, slots.size())):
		if ROLE_HP.has(slots[i]) and not result.has(slots[i]): result.append(slots[i])
	return result

static func max_hp_for(slots: Array, bonus: int = 0, character_upgrades: Dictionary = {}, relic_ids: Array = []) -> int:
	if not relic_ids.is_empty():
		var context := {"party_slots":slots,"hp_bonus":bonus,"character_upgrades":character_upgrades,"relics":relic_ids}
		var life := 0.0
		var has_life_bonus := false
		for id: String in members(slots,0,FRONT_SIZE):
			life += float(Attributes.stats(context,id).max_hp)
			has_life_bonus = has_life_bonus or Attributes.RelicStats.attribute_percent(context,id,"max_hp") > 0
		if has_life_bonus: return floori(life+0.0000001)
	var total: int = 0
	for id: String in members(slots, 0, FRONT_SIZE): total += Attributes.hp_for(id,bonus,character_upgrades)
	return total

static func max_hp_for_state(state: Dictionary, slots: Array = [], bonus: int = -1) -> int:
	if slots.is_empty(): slots = state.get("party_slots",slots_for(state.get("team",[])))
	if bonus < 0: bonus = int(state.get("hp_bonus",state.get("config",{}).get("hp_bonus",0)))
	return max_hp_for(slots,bonus,Growth.upgrades(state),Relics.ids(state))

static func record_health(state: Dictionary) -> void:
	state.health_num = int(state.hp)
	state.health_den = maxi(1, int(state.max_hp))

static func apply_layout(state: Dictionary, slots: Array, bonus: int) -> Dictionary:
	var next: Dictionary = state.duplicate(true)
	# Keep the fraction from the last real damage/heal, not rounded display HP.
	var numerator: int = int(next.get("health_num", next.hp))
	var denominator: int = maxi(1, int(next.get("health_den", next.max_hp)))
	next.party_slots = slots.duplicate()
	next.team = members(slots)
	next.front_team = members(slots, 0, FRONT_SIZE)
	next.back_team = members(slots, FRONT_SIZE, MAX_SIZE)
	next.hp_bonus = bonus
	next.max_hp = maxi(1, max_hp_for_state(next,slots,bonus))
	next.health_num = numerator
	next.health_den = denominator
	next.hp = clampi(int(floor(float(numerator) * next.max_hp / denominator)), 1 if numerator > 0 else 0, next.max_hp)
	if next.has("shield"): next.shield=clampi(int(next.shield),0,int(next.max_hp))
	return next

