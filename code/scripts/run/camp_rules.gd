extends RefCounted
## Stable camp offers and context shared by rewards, recruitment, UI and saves.
const Seeds=preload("res://code/scripts/run/run_catalog.gd")
const Growth=preload("res://code/scripts/characters/character_growth.gd")
const Orders=preload("res://code/scripts/run/recruit_orders.gd")
const Resources=preload("res://code/scripts/relics/relic_run.gd")
const Pool=preload("res://code/scripts/relics/relic_pool.gd")
const ACTIONS=["renown","slots","rest","upgrade","orders","relic"]
const TITLES={"renown":"获得 2 声望","slots":"获得 1 卡槽","rest":"恢复所有生命值","upgrade":"免费强化任意角色","orders":"获得三张随机召集令","relic":"获得一件藏品"}
const DETAILS={"renown":"声望 +2，可用于后续招募或强化。","slots":"队伍卡槽 +1，上限 8 格。","rest":"恢复前台共享生命至最大值。","upgrade":"选择一名已招募且尚未强化的角色，攻击与血量 +20%，不消耗声望或召集令。","orders":"随机获得三张职业召集令，在营地依次使用或跳过；招募与强化费用沿用现有规则。","relic":"获得一件尚未持有的随机藏品。"}
static func is_camp(state: Dictionary) -> bool:
	return state.get("phase","")=="node" and Resources.current_node(state).get("type","")=="camp" and not state.get("completed",[]).has(state.get("current_node",""))
static func free_upgrade_active(state: Dictionary) -> bool:
	return is_camp(state) and state.get("node_state",{}).get("camp_mode","")=="upgrade" and state.node_state.get("camp_options",[]).has("upgrade") and valid_node_state(state)
static func orders_active(state: Dictionary) -> bool:
	return is_camp(state) and state.get("node_state",{}).get("camp_mode","")=="orders" and state.node_state.get("camp_options",[]).has("orders") and valid_node_state(state)
static func upgrade_candidates(state: Dictionary) -> Array:
	var result: Array=[]
	for id in state.roster:
		if not Growth.is_upgraded(state,id):result.append(id)
	return result
static func prepare(state: Dictionary) -> Dictionary:
	var rng:=RandomNumberGenerator.new()
	rng.seed=Seeds.seed_for(int(state.seed),str(state.current_node),"camp-offers")
	var candidates: Array=["renown","orders"]
	if int(state.hp)<int(state.max_hp):candidates.append("rest")
	if int(state.slot_capacity)<8:candidates.append("slots")
	if not upgrade_candidates(state).is_empty():candidates.append("upgrade")
	var relics:=Pool.candidates(state)
	if not relics.is_empty():candidates.append("relic")
	for i in range(candidates.size()-1,0,-1):
		var j:=rng.randi_range(0,i)
		var held=candidates[i];candidates[i]=candidates[j];candidates[j]=held
	var draws: Array=[]
	for i in range(3):draws.append(Orders.CLASSES[rng.randi_range(0,Orders.CLASSES.size()-1)])
	var relic: String="" if relics.is_empty() else str(relics[rng.randi_range(0,relics.size()-1)])
	return {"camp_options":candidates.slice(0,3),"camp_mode":"choose","camp_orders":draws,"camp_order_index":0,"camp_relic":relic}
static func valid_node_state(state: Dictionary) -> bool:
	if not is_camp(state):return false
	var data: Dictionary=state.node_state
	if data.size()!=5 or not data.get("camp_options") is Array or data.camp_options.size()<2 or data.camp_options.size()>3:return false
	var seen:={}
	for action in data.camp_options:
		if not action is String or not action in ACTIONS or seen.has(action):return false
		seen[action]=true
	if not data.get("camp_mode") in ["choose","upgrade","orders"]:return false
	if not data.get("camp_orders") is Array or data.camp_orders.size()!=3:return false
	for category in data.camp_orders:
		if not category is String or not category in Orders.CLASSES:return false
	if not data.get("camp_order_index") is int or data.camp_order_index<0 or data.camp_order_index>2:return false
	if not data.get("camp_relic") is String:return false
	if data.camp_options.has("relic") and not Pool.eligible(state,data.camp_relic):return false
	if data.camp_mode=="upgrade":
		if not data.camp_options.has("upgrade") or upgrade_candidates(state).is_empty():return false
	if data.camp_mode=="orders":
		return data.camp_options.has("orders") and state.get("summon_active",false) and state.get("pending_recruit_order","")==data.camp_orders[data.camp_order_index]
	return data.camp_order_index==0 and not state.get("summon_active",false) and state.get("pending_recruit_order","").is_empty()