extends RefCounted
## Independent node-seeded draws: replaying a battle never rerolls loot.
const Seeds = preload("res://code/scripts/run/run_catalog.gd")
const Pool = preload("res://code/scripts/relics/relic_pool.gd")
const ORDINARY_CHANCE := 10
const BOSS_EXTRA_CHANCE := 50

static func _rng(state: Dictionary, purpose: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = Seeds.seed_for(int(state.seed),str(state.current_node),"loot-"+purpose)
	return rng

static func _pick(state: Dictionary, purpose: String, price: int = 0, excluded: Array = []) -> String:
	var candidates := Pool.candidates(state,price,excluded)
	if candidates.is_empty() and price > 0: candidates = Pool.candidates(state,0,excluded)
	if candidates.is_empty(): return ""
	return str(candidates[_rng(state,purpose).randi_range(0,candidates.size()-1)])

static func roll(state: Dictionary, kind: String) -> Array:
	var result: Array = []
	if not kind in ["battle","elite","midboss","boss"]: return result
	if kind == "battle" and _rng(state,"ordinary-chance").randi_range(0,99) >= ORDINARY_CHANCE: return result
	var boss: bool = kind in ["midboss","boss"]
	var first := _pick(state,"primary",16 if boss else 0)
	if not first.is_empty(): result.append(first)
	if boss and _rng(state,"boss-extra-chance").randi_range(0,99) < BOSS_EXTRA_CHANCE:
		var extra := _pick(state,"extra",0,result)
		if not extra.is_empty(): result.append(extra)
	return result

