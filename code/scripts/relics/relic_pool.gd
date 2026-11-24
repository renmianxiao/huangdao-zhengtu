extends RefCounted
## Shared acquisition eligibility for shop stock and battle loot.
const Catalog = preload("res://code/scripts/relics/relic_catalog.gd")
const Resources = preload("res://code/scripts/relics/relic_run.gd")
const EXPERIENCE_ONLY := ["study_notes","travel_notebook","tactics_scroll","cinnabar_commentary"]

static func eligible(state: Dictionary, id: String) -> bool:
	if Catalog.definition(id).is_empty() or Catalog.has(state,id): return false
	if int(state.get("level",1)) >= 10 and id in EXPERIENCE_ONLY: return false
	if int(Resources.current_node(state).get("floor",1)) >= 5 and id == "escort_pass": return false
	return true

static func candidates(state: Dictionary, price: int = 0, excluded: Array = []) -> Array:
	var result: Array = []
	for item: Dictionary in Catalog.ITEMS:
		if (price == 0 or int(item.price) == price) and not excluded.has(item.id) and eligible(state,str(item.id)):
			result.append(str(item.id))
	return result

