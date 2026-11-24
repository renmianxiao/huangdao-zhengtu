extends RefCounted
const Statistics=preload("res://code/scripts/run/run_statistics.gd")
const Professions=preload("res://code/scripts/profession_names.gd")
const Events = preload("res://code/scripts/run/event_rules.gd")
const Camp = preload("res://code/scripts/run/camp_rules.gd")
const Map = preload("res://code/scripts/run/map_generator.gd")
const Catalog = preload("res://code/scripts/run/run_catalog.gd")
const Battle = preload("res://code/scripts/battle.gd")
const Party = preload("res://code/scripts/party.gd")
const Progress = preload("res://code/scripts/run/progression.gd")
const Characters = preload("res://code/scripts/characters/character_catalog.gd")
const Orders = preload("res://code/scripts/run/recruit_orders.gd")
const Growth = preload("res://code/scripts/characters/character_growth.gd")
const Relics = preload("res://code/scripts/relics/relic_catalog.gd")
const RelicRun = preload("res://code/scripts/relics/relic_run.gd")
const RelicDrops = preload("res://code/scripts/relics/relic_drops.gd")
const Opening=preload("res://code/scripts/run/opening_rules.gd")
const STARTING_SLOTS := 3
const MAX_SLOTS := 8

static func create_run(seed: int) -> Dictionary:
	var run: Dictionary = {"seed": seed, "map": Map.generate(seed), "phase": "map", "current_node": "", "completed": [], "hp": 900, "max_hp": 900, "gold": 0, "upgrades": {}, "battles": 0, "character_upgrades": {}, "encounter": {}, "node_state": {}, "slot_capacity": STARTING_SLOTS, "roster": ["knight", "ranger", "guardian", "healer"], "team": ["knight", "ranger", "guardian"], "party_slots": ["knight", "ranger", "guardian", "", "", "", "", ""], "front_team": ["knight", "ranger", "guardian"], "back_team": [], "hp_bonus": 0, "health_num": 900, "health_den": 900}
	run.run_seconds = 0.0
	run.earned_gold = 0
	run.battle_wins = {"battle":0,"elite":0,"midboss":0,"boss":0}
	run.opening = {}
	run.recruit_orders = Orders.empty_inventory()
	run.last_recruit_order = ""
	run.pending_recruit_order = ""
	run.relics = []
	run.seen_events = []
	run.relic_progress = {"floor":1,"counts":{}}
	run.last_battle_gold = 0
	run.last_relic_drops = []
	run.pending_loot = []
	run.summon_active = false
	run.loot_resolved = true
	run.merge({"level": 1, "experience": 0, "total_experience": 0, "renown": 0, "last_progression": {}})
	return run

## Player entry; create_run remains the base state used by simulations and node tests.
static func create_opening_run(seed: int) -> Dictionary:
	return Opening.begin(create_run(seed))

static func opening_choices(run: Dictionary) -> Array:
	return Opening.choices(run)

static func choose_opening_bundle(run: Dictionary, id: String) -> Dictionary:
	return Opening.choose(run,id)

static func recruit_reason(run: Dictionary, id: String) -> String:
	var reason := _order_reason(run,id)
	if not reason.is_empty(): return reason
	if run.roster.has(id): return "已招募"
	if run.renown < recruit_cost(run,id): return "声望不足"
	return ""

static func recruit_cost(run: Dictionary, id: String) -> int:
	return RelicRun.recruit_cost(run,int(Catalog.RECRUIT_COSTS.get(id,999999)))

static func upgrade_cost(run: Dictionary, id: String) -> int:
	return 0 if Camp.free_upgrade_active(run) else RelicRun.upgrade_cost(run,Growth.upgrade_cost(id))

static func grant_relic(run: Dictionary, id: String) -> Dictionary:
	if run.phase == "battle" or Relics.definition(id).is_empty() or Relics.has(run,id): return run
	var next := run.duplicate(true)
	next.relics = Relics.ids(run).duplicate()
	next.relics.append(id)
	return Party.apply_layout(next,next.party_slots,int(next.hp_bonus))

static func _order_reason(run: Dictionary, id: String) -> String:
	if not Catalog.RECRUIT_COSTS.has(id): return "角色不存在"
	if Opening.recruiting(run):
		return "" if Orders.profession(id)==run.pending_recruit_order else "本次为%s召集令" % Professions.label(str(run.pending_recruit_order))
	if (not run.phase in ["reward", "won"] and not Camp.orders_active(run)) or not run.get("summon_active",false) or str(run.get("pending_recruit_order", "")).is_empty(): return "只能使用当前召集令"
	if run.current_node.is_empty(): return "开局免费选择三名角色"
	if Orders.profession(id) != run.pending_recruit_order: return "本次为%s召集令" % Professions.label(str(run.pending_recruit_order))
	return ""

static func complete_node(run: Dictionary) -> void:
	if not run.completed.has(run.current_node):
		run.completed.append(run.current_node)
		RelicRun.on_node_completed(run,current_node(run))
	_return_to_map(run)

## Floor changes settle once when leaving the last node, before map/cinematic saves.
static func _return_to_map(run: Dictionary) -> void:
	var previous_floor := map_floor(run)
	run.phase = "map"
	run.node_state = {}
	if map_floor(run) > previous_floor:
		run.hp = mini(int(run.max_hp), int(run.hp) + floori(int(run.max_hp) * 0.25))
		Party.record_health(run)

static func _consume_order(run: Dictionary) -> void:
	var camp_order := Camp.orders_active(run)
	if camp_order:
		run.node_state.camp_order_index += 1
		if run.node_state.camp_order_index < 3:
			run.pending_recruit_order = run.node_state.camp_orders[run.node_state.camp_order_index]
			return
	run.pending_recruit_order = ""
	run.summon_active = false
	run.recruit_orders = Orders.empty_inventory()
	if camp_order: complete_node(run)

static func recruit(run: Dictionary, id: String) -> Dictionary:
	if not recruit_reason(run, id).is_empty(): return run
	var next: Dictionary = run.duplicate(true)
	next.renown -= recruit_cost(run,id)
	next.roster.append(id)
	RelicRun.on_recruit(next,int(Catalog.RECRUIT_COSTS[id]))
	if Opening.recruiting(next): return Opening.recruited(next,id)
	_consume_order(next)
	return next

static func upgrade_reason(run: Dictionary, id: String) -> String:
	if Camp.free_upgrade_active(run):
		if not run.roster.has(id): return "尚未招募该角色"
		if Growth.is_upgraded(run,id): return "本局已强化，不能再次强化"
		return ""
	var reason := _order_reason(run,id)
	if not reason.is_empty(): return reason
	if not run.roster.has(id): return "尚未招募该角色"
	if Growth.is_upgraded(run,id): return "本局已强化，不能再次强化"
	if run.renown < upgrade_cost(run,id): return "声望不足"
	return ""

static func upgrade_character(run: Dictionary, id: String) -> Dictionary:
	if not upgrade_reason(run,id).is_empty(): return run
	var next := run.duplicate(true)
	next.character_upgrades[id] = true
	if Camp.free_upgrade_active(run):
		complete_node(next)
	else:
		next.renown -= upgrade_cost(run,id)
		RelicRun.on_upgrade(next,Growth.upgrade_cost(id))
		_consume_order(next)
	return Party.apply_layout(next,next.party_slots,int(next.hp_bonus))

static func skip_recruit_order(run: Dictionary) -> Dictionary:
	if (not run.phase in ["reward", "won"] and not Camp.orders_active(run)) or not run.get("summon_active",false) or str(run.get("pending_recruit_order", "")).is_empty(): return run
	var next := run.duplicate(true)
	_consume_order(next)
	return next

static func _loot_open(run: Dictionary) -> bool:
	if not run.phase in ["reward","won"] or run.get("loot_resolved",true) or run.get("summon_active",false): return false
	var node := current_node(run)
	return not node.is_empty() and (node.type in ["battle","elite","midboss","boss"] or Events.is_battle(run)) and run.completed.has(node.id)

static func claim_loot(run: Dictionary, id: String) -> Dictionary:
	if not _loot_open(run): return run
	for index in range(run.pending_loot.size()):
		var item: Dictionary = run.pending_loot[index]
		if item.id != id or item.claimed: continue
		var next := run.duplicate(true)
		next.pending_loot[index].claimed = true
		match str(item.kind):
			"gold": Statistics.gain_gold(next,int(item.amount))
			"renown": next.renown += int(item.amount)
			"slots": next.slot_capacity = mini(MAX_SLOTS,int(next.slot_capacity)+int(item.amount))
			"order":
				next.pending_recruit_order = str(item.ref)
				next.summon_active = true
			"relic": next = grant_relic(next,str(item.ref))
			_: return run
		return next
	return run

static func claim_direct_loot(run:Dictionary)->Dictionary:
	if not _loot_open(run):return run
	var next:Dictionary=run
	for item:Dictionary in run.pending_loot:
		if not item.claimed and item.kind in ["gold","renown","slots","relic"]:
			next=claim_loot(next,str(item.id))
	return next

static func leave_loot(run: Dictionary) -> Dictionary:
	if not _loot_open(run): return run
	var next := run.duplicate(true)
	next.pending_loot = []
	next.pending_recruit_order = ""
	next.recruit_orders = Orders.empty_inventory()
	next.summon_active = false
	next.loot_resolved = true
	if next.phase == "reward": _return_to_map(next)
	next.node_state = {}
	return next

static func _loot_item(kind: String, amount: int = 1, ref: String = "") -> Dictionary:
	return {"id":"relic:"+ref if kind == "relic" else kind,"kind":kind,"amount":amount,"ref":ref,"claimed":false}

static func open_formation(run: Dictionary) -> Dictionary:
	if run.phase != "map": return run
	var next: Dictionary = run.duplicate(true)
	next.phase = "formation"
	next.formation_origin = "map"
	next.draft_team = next.team.duplicate()
	next.draft_slots = next.party_slots.duplicate()
	return next

static func toggle_member(run: Dictionary, id: String) -> Dictionary:
	if run.phase != "formation" or not run.roster.has(id): return run
	if not run.draft_team.has(id) and run.draft_team.size() >= run.slot_capacity: return run
	var next: Dictionary = run.duplicate(true)
	if next.draft_team.has(id):
		next.draft_slots[next.draft_slots.find(id)] = ""
	else:
		for i in range(next.slot_capacity):
			if next.draft_slots[i].is_empty():
				next.draft_slots[i] = id
				break
	next.draft_team = Party.members(next.draft_slots)
	return next

## A draft-only move: active cards swap, reserves replace, -1 returns to roster.
static func place_formation_member(run: Dictionary, id: String, target: int) -> Dictionary:
	if run.phase != "formation" or not run.roster.has(id) or target < -1 or target >= int(run.slot_capacity): return run
	var source: int = run.draft_slots.find(id)
	if source == target or (source < 0 and target == -1): return run
	var next: Dictionary = run.duplicate(true)
	if target == -1:
		next.draft_slots[source] = ""
	else:
		if source >= 0: next.draft_slots[source] = next.draft_slots[target]
		next.draft_slots[target] = id
	next.draft_team = Party.members(next.draft_slots)
	return next

static func swap_formation_slots(run: Dictionary, front_index: int, back_index: int) -> Dictionary:
	if run.phase != "formation" or front_index < 0 or front_index >= Party.FRONT_SIZE or back_index < Party.FRONT_SIZE or back_index >= MAX_SLOTS: return run
	if front_index >= run.slot_capacity or back_index >= run.slot_capacity: return run
	var next: Dictionary = run.duplicate(true)
	var hold: String = next.draft_slots[front_index]
	next.draft_slots[front_index] = next.draft_slots[back_index]
	next.draft_slots[back_index] = hold
	next.draft_team = Party.members(next.draft_slots)
	return next

static func confirm_team(run: Dictionary) -> Dictionary:
	if run.phase != "formation" or run.draft_team.is_empty() or run.draft_team.size() > run.slot_capacity: return run
	if run.current_node.is_empty() and run.draft_team.size() != STARTING_SLOTS: return run
	for index in range(run.draft_slots.size()):
		var id: String = run.draft_slots[index]
		if id.is_empty(): continue
		if index >= run.slot_capacity or not Party.ROLE_HP.has(id) or not run.roster.has(id): return run
	if Party.members(run.draft_slots) != run.draft_team: return run
	if Party.members(run.draft_slots, 0, Party.FRONT_SIZE).is_empty(): return run
	var next: Dictionary = Party.apply_layout(run, run.draft_slots, int(run.hp_bonus))
	next.erase("draft_team")
	next.erase("draft_slots")
	next.phase = "map"
	next.erase("formation_origin")
	if Opening.ready(run): next.opening={}
	return next

static func cancel_formation(run: Dictionary, allow_before_first_node: bool = false) -> Dictionary:
	if Opening.active(run) or run.phase != "formation" or (run.current_node.is_empty() and not allow_before_first_node): return run
	var next: Dictionary = run.duplicate(true)
	next.erase("draft_team")
	next.erase("draft_slots")
	next.phase = "map"
	next.erase("formation_origin")
	return next

static func current_node(run: Dictionary) -> Dictionary:
	for node: Dictionary in run.map.nodes:
		if node.id == run.current_node:
			return node
	return {}

static func enter_node(run: Dictionary, id: String) -> Dictionary:
	if run.phase != "map" or not Map.reachable(run.map, run.current_node).has(id) or run.completed.has(id):
		return run
	var next: Dictionary = run.duplicate(true)
	if run.current_node.is_empty():
		next.roster = next.team.duplicate()
	next.current_node = id
	next.last_relic_drops = []
	next.pending_loot = []
	next.pending_recruit_order = ""
	next.recruit_orders = Orders.empty_inventory()
	next.summon_active = false
	next.loot_resolved = true
	var node: Dictionary = current_node(next)
	next.node_state = {}
	if node.type in ["battle", "elite", "midboss", "boss"]:
		var enemy: Dictionary = Catalog.encounter(node.type, node.row, next.seed, id)
		_start_encounter(next,enemy)
	else:
		next.phase = "node"
	RelicRun.on_node_entered(next,node)
	return next

static func _start_encounter(next: Dictionary, enemy_data: Dictionary, special: Dictionary = {}) -> void:
	var enemy := enemy_data.duplicate(true)
	if enemy.patterns.is_empty():enemy.patterns=Catalog.Enemies.scaled_attack_patterns(Battle.PATTERNS,int(enemy.floor))
	if not special.is_empty():
		enemy.hp = Catalog.Enemies.percent_hp(int(enemy.hp),int(special.hp))
		enemy.name = "%s · %s" % [preload("res://code/scripts/run/event_catalog.gd").EVENTS[next.node_state.event].title,enemy.name]
		for pattern: Dictionary in enemy.patterns:
			if int(pattern.damage)>0: pattern.damage = ceili(pattern.damage * int(special.attack) / 100.0)
	var config := {"hp": next.hp, "max_hp": next.max_hp, "enemy_hp": enemy.hp, "initial_ap": int(next.upgrades.get("initial_ap", 0)), "upgrades": next.upgrades.duplicate(true), "character_upgrades": next.character_upgrades.duplicate(true), "enemy_name": enemy.name, "enemy_id": enemy.id, "enemy_floor": enemy.floor, "team": next.team.duplicate(), "slot_capacity": next.slot_capacity, "party_slots": next.party_slots.duplicate(), "hp_bonus": next.hp_bonus, "health_num": next.health_num, "health_den": next.health_den}
	config.ai_seed=Catalog.seed_for(int(next.seed),str(next.current_node),"enemy-actions")
	config.relics = Relics.ids(next).duplicate()
	if not enemy.patterns.is_empty(): config.patterns = enemy.patterns
	if not special.is_empty():
		config.enemy_start_hp = Catalog.Enemies.percent_hp(int(enemy.hp),int(special.start))
		config.initial_ward = ceili(enemy.hp * int(special.enemy_guard) / 100.0)
		config.initial_shield = ceili(next.max_hp * int(special.team_guard) / 100.0)
	next.encounter = Battle.create_battle(config)
	next.phase = "battle"

static func start_event_battle(run: Dictionary) -> Dictionary:
	if run.phase != "node": return run
	var special := Events.battle_spec(run)
	if special.is_empty(): return run
	var next := run.duplicate(true)
	var node := current_node(next)
	_start_encounter(next,Catalog.encounter(str(special.kind),int(node.row),int(next.seed),str(node.id)),special)
	return next

static func finish_battle(run: Dictionary, result: Dictionary) -> Dictionary:
	if run.phase != "battle" or not result.status in ["won", "lost"]:
		return run
	var next: Dictionary = run.duplicate(true)
	next.encounter = result.duplicate(true)
	next.hp = clampi(int(result.hp), 0, int(result.max_hp))
	next.max_hp = int(result.max_hp)
	if result.has("party_slots"):
		next.party_slots = result.party_slots.duplicate()
		next.team = result.team.duplicate()
		next.front_team = result.front_team.duplicate()
		next.back_team = result.back_team.duplicate()
		next.health_num = result.health_num
		next.health_den = result.health_den
	else: Party.record_health(next)
	next.battles += 1
	next.last_relic_drops = []
	next.pending_loot = []
	next.pending_recruit_order = ""
	next.recruit_orders = Orders.empty_inventory()
	next.summon_active = false
	next.loot_resolved = true
	if result.status == "lost":
		next.last_battle_gold = 0
		next.last_progression = {}
		next.last_recruit_order = ""
		next.phase = "lost"
		return next
	var node: Dictionary = current_node(next)
	var special := Events.battle_spec(run) if Events.is_battle(run) else {}
	var kind: String = str(special.kind) if not special.is_empty() else str(node.type)
	next.battle_wins[kind] = int(next.battle_wins.get(kind,0)) + 1
	next.completed.append(node.id)
	Orders.award(next, str(node.id))
	next = Progress.award_victory(next, kind)
	var relic_reward := RelicRun.victory_rewards(next,kind,int(result.get("last_player_ap",result.get("ap",0))))
	next.gold += int(Catalog.BATTLE_GOLD.get(kind,0)) + int(relic_reward.gold) + int(special.get("bonus",0))
	next.renown += int(relic_reward.renown)
	RelicRun.on_node_completed(next,node)
	var designated: Array = []
	var replace_drop := int(special.get("relic",0))>0
	if replace_drop:
		var gift: Dictionary = run.node_state.data.combat_reward
		if str(gift.id).is_empty(): next.gold += int(gift.price)
		else: designated.append(str(gift.id))
	next.last_progression = {"experience":int(next.total_experience)-int(run.total_experience),"from_level":int(run.level),"to_level":int(next.level),"renown":int(next.renown)-int(run.renown)-int(relic_reward.renown),"slots":int(next.slot_capacity)-int(run.slot_capacity)}
	next.last_battle_gold = int(next.gold)-int(run.gold)
	var earned_renown := int(next.renown)-int(run.renown)
	var earned_slots := int(next.slot_capacity)-int(run.slot_capacity)
	# Experience and levels settle now; all other gains wait in this battle's snapshot.
	next.gold = run.gold
	next.earned_gold = run.earned_gold
	next.renown = run.renown
	next.slot_capacity = run.slot_capacity
	if next.last_battle_gold > 0: next.pending_loot.append(_loot_item("gold",int(next.last_battle_gold)))
	if earned_renown > 0: next.pending_loot.append(_loot_item("renown",earned_renown))
	if earned_slots > 0: next.pending_loot.append(_loot_item("slots",earned_slots))
	next.pending_loot.append(_loot_item("order",1,str(next.last_recruit_order)))
	next.pending_recruit_order = ""
	next.loot_resolved = false
	if node.type == "boss":
		next.phase = "won"
	else:
		next.phase = "reward"
	# Roll after settling existing effects; acquiring a new relic never reruns settlement.
	next.last_relic_drops = designated if replace_drop else RelicDrops.roll(next,kind)
	for id: String in next.last_relic_drops:
		next.pending_loot.append(_loot_item("relic",1,id))
	return next

static func map_floor(run: Dictionary) -> int:
	var node: Dictionary = current_node(run)
	if node.is_empty(): return 1
	var value: int = node.floor
	if run.phase in ["map", "formation"] and node.floor_row == Map.ROWS_PER_FLOOR and run.completed.has(node.id):
		value = mini(Map.FLOOR_COUNT, value + 1)
	return value

static func abandon(run: Dictionary) -> Dictionary:
	if run.phase in ["won", "lost", "abandoned"]:
		return run
	var next: Dictionary = run.duplicate(true)
	next.phase = "abandoned"
	next.pending_recruit_order = ""
	next.pending_loot = []
	next.summon_active = false
	next.loot_resolved = true
	next.recruit_orders = Orders.empty_inventory()
	return next


