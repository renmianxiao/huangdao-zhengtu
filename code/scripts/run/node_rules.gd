extends RefCounted
const Events = preload("res://code/scripts/run/event_rules.gd")
const Camp = preload("res://code/scripts/run/camp_rules.gd")
const Catalog = preload("res://code/scripts/run/run_catalog.gd")
const Run = preload("res://code/scripts/run/run_rules.gd")
const Party = preload("res://code/scripts/party.gd")
const Characters = preload("res://code/scripts/characters/character_catalog.gd")
const RelicRun = preload("res://code/scripts/relics/relic_run.gd")
const RelicShop = preload("res://code/scripts/relics/relic_shop.gd")

static func prepare(run: Dictionary) -> Dictionary:
	if run.phase != "node": return run
	if not run.node_state.is_empty(): return RelicShop.refresh(run)
	var next: Dictionary = run.duplicate(true)
	var node: Dictionary = Run.current_node(next)
	var rng := RandomNumberGenerator.new()
	rng.seed = Catalog.seed_for(next.seed, node.id, "contents")
	var keys: Array = Catalog.UPGRADE_KEYS.duplicate()
	if next.slot_capacity >= Run.MAX_SLOTS: keys.erase("slots")
	for i in range(keys.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var hold = keys[i]
		keys[i] = keys[j]
		keys[j] = hold
	if node.type == "camp":
		next.node_state = Camp.prepare(next)
	elif node.type == "shop":
		next.node_state = {"bought": []}
		RelicShop.initialize(next)
	elif node.type == "event":
		next.node_state = Events.prepare(next)
		if next.seen_events.has(next.node_state.event): next.seen_events = []
		next.seen_events.append(next.node_state.event)
	else:
		next.node_state = {"ready": true}
	return next

static func _upgrade(run: Dictionary, key: String, scale: int = 1) -> void:
	if key == "slots":
		run.slot_capacity = mini(Run.MAX_SLOTS, int(run.slot_capacity) + 1)
	elif key == "max_hp":
		run.hp_bonus += 60 * scale
		run.merge(Party.apply_layout(run,run.party_slots,int(run.hp_bonus)),true)
	else:
		var amount := scale * (15 if key == "attack" else (20 if key in ["shield", "heal"] else 1))
		run.upgrades[key] = int(run.upgrades.get(key, 0)) + amount
		if key == "initial_ap":
			run.upgrades[key] = mini(4, run.upgrades[key])

static func _complete(run: Dictionary) -> void:
	Run.complete_node(run)

static func continue_after_battle(run: Dictionary) -> Dictionary:
	if run.phase != "reward": return run
	return Run.leave_loot(run)

static func choose_camp(run: Dictionary, action: String, character_id: String = "") -> Dictionary:
	if not Camp.is_camp(run) or not Camp.valid_node_state(run): return run
	var mode: String = run.node_state.camp_mode
	if mode == "upgrade":
		if action == "upgrade" and not character_id.is_empty(): return Run.upgrade_character(run,character_id)
		if action != "back": return run
		var back := run.duplicate(true)
		back.node_state.camp_mode = "choose"
		return back
	if mode != "choose" or not run.node_state.camp_options.has(action): return run
	var next := run.duplicate(true)
	match action:
		"renown": next.renown += 2
		"slots":
			if next.slot_capacity >= Run.MAX_SLOTS: return run
			next.slot_capacity += 1
		"rest":
			next.hp = next.max_hp
			Party.record_health(next)
		"upgrade":
			if Camp.upgrade_candidates(next).is_empty(): return run
			next.node_state.camp_mode = "upgrade"
			return next
		"orders":
			next.node_state.camp_mode = "orders"
			next.pending_recruit_order = next.node_state.camp_orders[0]
			next.summon_active = true
			return next
		"relic":
			next = Run.grant_relic(next,str(next.node_state.camp_relic))
		_: return run
	_complete(next)
	return next

static func buy(run: Dictionary, item_id: String) -> Dictionary:
	if item_id=="refresh":return RelicShop.reroll(run)
	if item_id!="heal" or run.phase!="node" or Run.current_node(run).type!="shop" or run.node_state.is_empty() or run.node_state.bought.has("heal"):return run
	if run.gold<16 or run.hp>=run.max_hp:return run
	var next:=run.duplicate(true)
	next.gold-=16
	next.hp=mini(next.max_hp,int(next.hp)+floori(next.max_hp*0.5))
	Party.record_health(next)
	next.node_state.bought.append("heal")
	return next

static func leave_shop(run: Dictionary) -> Dictionary:
	if run.phase != "node" or Run.current_node(run).type != "shop":
		return run
	var next: Dictionary = run.duplicate(true)
	_complete(next)
	return next

static func buy_relic(run: Dictionary, index: int, expected_id: String) -> Dictionary:
	return RelicShop.buy(run,index,expected_id)

static func choose_event(run: Dictionary, option_id: String, source_id: String = "", target_id: String = "") -> Dictionary:
	var next := Events.choose(run,option_id,source_id,target_id)
	if next == run: return run
	if next.node_state.mode == "done": _complete(next)
	elif next.node_state.mode == "battle": return Run.start_event_battle(next)
	return next

