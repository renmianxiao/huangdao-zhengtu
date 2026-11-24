extends RefCounted
## Fixed eight-slot stock; all randomness is keyed by the saved draw counter.
const Catalog = preload("res://code/scripts/relics/relic_catalog.gd")
const Resources = preload("res://code/scripts/relics/relic_run.gd")
const Run = preload("res://code/scripts/run/run_rules.gd")
const Seeds = preload("res://code/scripts/run/run_catalog.gd")
const Pool = preload("res://code/scripts/relics/relic_pool.gd")
const SIZE := 8
const MINIMUMS := {8:3,12:1,16:1}

static func eligible(state: Dictionary, id: String) -> bool:
	return Pool.eligible(state,id)

static func initialize(state: Dictionary) -> void:
	state.node_state.relic_stock = []
	state.node_state.relic_roll = 0
	state.node_state.shop_refreshes = 0
	_draw_stock(state)

static func _draw_stock(state: Dictionary) -> void:
	state.node_state.relic_stock = []
	for price in [8,8,8,12,16,0,0,0]:
		state.node_state.relic_stock.append({"id":"","price":price if price > 0 else 8})
		var index: int = state.node_state.relic_stock.size()-1
		_fill(state,index,int(price))

	state.node_state.relic_offers = state.node_state.relic_stock.map(func(slot): return str(slot.id))

static func _pool(state: Dictionary, price: int = 0) -> Array:
	var shown := {}
	for slot: Dictionary in state.node_state.get("relic_stock",[]):
		if not str(slot.id).is_empty(): shown[slot.id] = true
	return Pool.candidates(state,price,shown.keys())

static func _fill(state: Dictionary, index: int, preferred: int) -> void:
	var counts := {8:0,12:0,16:0}
	for slot: Dictionary in state.node_state.relic_stock:
		if not str(slot.id).is_empty(): counts[int(slot.price)] += 1
	var candidates: Array = []
	for price in [8,12,16]:
		if int(counts[price]) < int(MINIMUMS[price]):
			candidates = _pool(state,price)
			if not candidates.is_empty(): break
	if candidates.is_empty() and preferred > 0: candidates = _pool(state,preferred)
	if candidates.is_empty(): candidates = _pool(state)
	if candidates.is_empty(): return
	var roll: int = state.node_state.relic_roll
	var rng := RandomNumberGenerator.new()
	rng.seed = Seeds.seed_for(int(state.seed),str(state.current_node),"relic-stock-%d" % roll)
	var id: String = candidates[rng.randi_range(0,candidates.size()-1)]
	state.node_state.relic_stock[index] = {"id":id,"price":int(Catalog.definition(id).price)}
	state.node_state.relic_roll = roll+1

## Viewing or loading only clears offers that became ineligible; it never refills.
static func refresh(state: Dictionary) -> Dictionary:
	if not _is_shop(state) or not state.node_state.get("relic_stock") is Array: return state
	var next:=state.duplicate(true)
	for slot:Dictionary in next.node_state.relic_stock:
		if not str(slot.id).is_empty() and not eligible(next,str(slot.id)):slot.id=""
	return state if next.node_state==state.node_state else next

static func refresh_price(state: Dictionary) -> int:
	return int(state.node_state.get("shop_refreshes",0))*4

static func refresh_reason(state: Dictionary) -> String:
	if not _is_shop(state):return "当前不在商店"
	if int(state.node_state.get("shop_refreshes",0))>=4:return "刷新次数已用尽"
	if Pool.candidates(state).is_empty():return "暂无可售藏品"
	if int(state.gold)<refresh_price(state):return "金币不足"
	return ""

static func reroll(state: Dictionary) -> Dictionary:
	if not refresh_reason(state).is_empty():return state
	var next:=state.duplicate(true)
	next.gold-=refresh_price(state)
	next.node_state.shop_refreshes+=1
	_draw_stock(next)
	return next

static func purchase_reason(state: Dictionary, index: int, expected_id: String) -> String:
	if not _is_shop(state) or not state.node_state.get("relic_stock") is Array: return "当前不在商店"
	if index < 0 or index >= SIZE or state.node_state.relic_stock.size() != SIZE: return "栏位不存在"
	var slot: Dictionary = state.node_state.relic_stock[index]
	if str(slot.id).is_empty(): return "售罄"
	if expected_id != str(slot.id): return "商品已更新"
	if not eligible(state,expected_id): return "该藏品已持有或无法再生效"
	if state.gold < Resources.shop_price(state,int(slot.price)): return "金币不足"
	return ""

static func buy(state: Dictionary, index: int, expected_id: String) -> Dictionary:
	if not purchase_reason(state,index,expected_id).is_empty(): return state
	var next := state.duplicate(true)
	var base_price: int = next.node_state.relic_stock[index].price
	next.gold -= Resources.shop_price(state,base_price)
	# Consume only an already-owned discount; buying the ledger leaves its first use.
	Resources.on_relic_purchase(next,base_price)
	next = Run.grant_relic(next,expected_id)
	next.node_state.relic_stock[index].id = ""
	return refresh(next)

static func _is_shop(state: Dictionary) -> bool:
	return str(state.get("phase","")) == "node" and str(Resources.current_node(state).get("type","")) == "shop"

static func valid_stock(state: Dictionary) -> bool:
	var data:Dictionary=state.node_state
	if not data.get("shop_refreshes") is int or data.shop_refreshes<0 or data.shop_refreshes>4:return false
	if not data.get("relic_stock") is Array or data.relic_stock.size()!=SIZE or not data.get("relic_roll") is int or data.relic_roll<0:return false
	if not data.get("relic_offers") is Array or data.relic_offers.size()!=SIZE:return false
	var shown:Dictionary={};var counts:Dictionary={8:0,12:0,16:0};var available:Dictionary={8:0,12:0,16:0};var total:=0
	for i in range(SIZE):
		var slot=data.relic_stock[i]
		var offer=data.relic_offers[i]
		if not slot is Dictionary or slot.size()!=2 or not slot.get("id") is String or not slot.get("price") is int or not MINIMUMS.has(slot.price) or not offer is String:return false
		if offer.is_empty():
			if not slot.id.is_empty():return false
			continue
		var definition:=Catalog.definition(offer)
		if definition.is_empty() or shown.has(offer) or int(definition.price)!=slot.price:return false
		if slot.id!=(offer if eligible(state,offer) else ""):return false
		shown[offer]=true;counts[slot.price]+=1
	for item:Dictionary in Catalog.ITEMS:
		if eligible(state,str(item.id)) or shown.has(item.id):available[int(item.price)]+=1;total+=1
	if shown.size()!=mini(SIZE,total):return false
	for price in [8,12,16]:
		if counts[price]<mini(int(available[price]),int(MINIMUMS[price])):return false
	return true
