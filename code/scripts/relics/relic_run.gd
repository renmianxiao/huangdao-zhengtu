extends RefCounted
const Statistics=preload("res://code/scripts/run/run_statistics.gd")
const Catalog = preload("res://code/scripts/relics/relic_catalog.gd")
const Progress = preload("res://code/scripts/run/progression.gd")
const COUNT_LIMITS := {"merchant_ledger":1,"travel_notebook":1,"escort_pass":1,"thrift_copper":1,"recommendation_token":1,"teaching_manual":1,"pearl_contract":2,"camp_supply":1,"chivalry_invitation":2,"guild_contract":1,"recruitment_register":1,"legacy_case":1}

static func current_node(state: Dictionary) -> Dictionary:
	for node: Dictionary in state.get("map",{}).get("nodes",[]):
		if str(node.id) == str(state.get("current_node","")): return node
	return {}

static func floor_for(state: Dictionary) -> int:
	var node := current_node(state)
	if node.is_empty(): return 1
	var value := int(node.floor)
	if state.get("phase","") in ["map","formation"] and int(node.floor_row) == 6 and state.get("completed",[]).has(node.id): value = mini(5,value+1)
	return value

static func sync_floor(state: Dictionary, floor_number: int = -1) -> void:
	var active := floor_for(state) if floor_number < 1 else floor_number
	if not state.has("relic_progress") or int(state.relic_progress.get("floor",0)) != active:
		state.relic_progress = {"floor":active,"counts":{}}

static func count(state: Dictionary, id: String) -> int:
	var progress: Dictionary = state.get("relic_progress",{})
	if int(progress.get("floor",0)) != floor_for(state): return 0
	return int(progress.get("counts",{}).get(id,0))

static func available(state: Dictionary, id: String) -> bool:
	return Catalog.has(state,id) and count(state,id) < int(COUNT_LIMITS.get(id,1))

static func consume(state: Dictionary, id: String) -> void:
	sync_floor(state)
	state.relic_progress.counts[id] = mini(int(COUNT_LIMITS.get(id,1)),int(state.relic_progress.counts.get(id,0))+1)

static func recruit_cost(state: Dictionary, original_cost: int) -> int:
	return maxi(0,original_cost-(1 if original_cost > 0 and available(state,"recommendation_token") else 0))

static func upgrade_cost(state: Dictionary, original_cost: int) -> int:
	return maxi(0,original_cost-(1 if original_cost > 0 and available(state,"teaching_manual") else 0))

static func on_recruit(state: Dictionary, original_cost: int) -> void:
	if original_cost > 0 and available(state,"recommendation_token"): consume(state,"recommendation_token")
	if original_cost == 3 and available(state,"recruitment_register"):
		consume(state,"recruitment_register")
		state.renown += 1
	if original_cost == 0 and available(state,"pearl_contract"):
		consume(state,"pearl_contract")
		Statistics.gain_gold(state,2)

static func on_upgrade(state: Dictionary, original_cost: int) -> void:
	if original_cost <= 0: return
	if available(state,"teaching_manual"): consume(state,"teaching_manual")
	if available(state,"legacy_case"):
		consume(state,"legacy_case")
		Statistics.gain_gold(state,2)
		state.renown += 1

static func victory_rewards(state: Dictionary, kind: String, remaining_ap: int) -> Dictionary:
	sync_floor(state)
	var gold := 0
	var renown := 0
	if kind == "battle" and Catalog.has(state,"silver_purse"): gold += 1
	if kind in ["battle","elite"] and Catalog.has(state,"fortune_abacus"): gold += 2
	if kind == "elite" and Catalog.has(state,"iron_abacus"): gold += 2
	if kind == "elite" and remaining_ap >= 2 and available(state,"thrift_copper"):
		consume(state,"thrift_copper")
		gold += 2
	if available(state,"chivalry_invitation"):
		consume(state,"chivalry_invitation")
		renown += 1
	return {"gold":gold,"renown":renown}

static func on_node_entered(state: Dictionary, node: Dictionary) -> void:
	sync_floor(state,int(node.floor))
	if str(node.type) == "shop" and available(state,"guild_contract"):
		consume(state,"guild_contract")
		Statistics.gain_gold(state,3)

static func on_node_completed(state: Dictionary, node: Dictionary) -> void:
	sync_floor(state,int(node.floor))
	var experience := 0
	if str(node.type) == "event" and available(state,"travel_notebook"):
		consume(state,"travel_notebook")
		experience += 4
	if str(node.type) == "camp" and available(state,"camp_supply"):
		consume(state,"camp_supply")
		Statistics.gain_gold(state,2)
		experience += 4
	if int(node.floor_row) == 6 and int(node.floor) < 5 and available(state,"escort_pass"):
		consume(state,"escort_pass")
		Statistics.gain_gold(state,3)
	if experience > 0: state.merge(Progress.award_experience(state,experience),true)

# These hooks are ready for future relic sales. Existing shop services never call them.
static func shop_price(state: Dictionary, base_price: int) -> int:
	if not _is_shop(state): return maxi(0,base_price)
	return maxi(0,base_price-(1 if base_price > 0 and available(state,"merchant_ledger") else 0))

static func on_relic_purchase(state: Dictionary, base_price: int) -> void:
	if _is_shop(state) and base_price > 0 and available(state,"merchant_ledger"): consume(state,"merchant_ledger")

static func _is_shop(state: Dictionary) -> bool:
	return str(state.get("phase","")) == "node" and str(current_node(state).get("type","")) == "shop"
