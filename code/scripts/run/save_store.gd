extends RefCounted
const Events = preload("res://code/scripts/run/event_rules.gd")
const EventCatalog = preload("res://code/scripts/run/event_catalog.gd")
const Camp = preload("res://code/scripts/run/camp_rules.gd")
const Run = preload("res://code/scripts/run/run_rules.gd")
const Party = preload("res://code/scripts/party.gd")
const Catalog = preload("res://code/scripts/run/run_catalog.gd")
const Characters = preload("res://code/scripts/characters/character_catalog.gd")
const Orders = preload("res://code/scripts/run/recruit_orders.gd")
const Relics = preload("res://code/scripts/relics/relic_catalog.gd")
const RelicRun = preload("res://code/scripts/relics/relic_run.gd")
const RelicShop = preload("res://code/scripts/relics/relic_shop.gd")
const Opening=preload("res://code/scripts/run/opening_rules.gd")
const VERSION := 11
const ROOT := "user://saves"
const PHASES := ["opening","formation","map","node","reward","won","lost","abandoned"]
const MAX_BYTES := 4194304

static func path_for(slot: int, directory: String = ROOT) -> String:
	return directory.path_join("slot_%d.json" % slot)

static func occupied(slot: int, directory: String = ROOT) -> bool:
	return FileAccess.file_exists(path_for(slot,directory)) or FileAccess.file_exists(path_for(slot,directory)+".bak")

static func validate(state: Variant) -> bool:
	if not state is Dictionary: return false
	if state.has("rewards"): return false
	for key: String in Run.create_run(0):
		if not state.has(key): return false
	if not (state.run_seconds is float or state.run_seconds is int) or not is_finite(float(state.run_seconds)) or state.run_seconds < 0: return false
	if not state.earned_gold is int or state.earned_gold < 0: return false
	if not state.battle_wins is Dictionary: return false
	for kind in ["battle","elite","midboss","boss"]:
		if not state.battle_wins.get(kind) is int or state.battle_wins[kind] < 0: return false
	if not _relics_valid(state): return false
	if not state.phase is String or not state.phase in PHASES: return false
	for key in ["seed","hp","max_hp","gold","battles","slot_capacity","hp_bonus","health_num","health_den","level","experience","total_experience","renown","last_battle_gold"]:
		if not state[key] is int: return false
	if state.last_battle_gold < 0: return false
	if state.hp < 0 or state.max_hp < 1 or state.hp > state.max_hp or state.gold < 0 or state.renown < 0: return false
	if state.slot_capacity < 3 or state.slot_capacity > 8 or state.level < 1 or state.level > 10: return false
	if state.health_den < 1 or state.health_num < 0 or state.health_num > state.health_den: return false
	if state.hp_bonus < 0 or state.experience < 0 or state.total_experience < 0 or state.battles < 0: return false
	for key in ["upgrades","character_upgrades","encounter","node_state","last_progression","recruit_orders"]:
		if not state[key] is Dictionary: return false
	for key in ["roster","team","party_slots","front_team","back_team","completed","seen_events"]:
		if not state[key] is Array: return false
	if state.seen_events.size()>12: return false
	var seen_event_ids := {}
	for id in state.seen_events:
		if not id is String or not EventCatalog.EVENTS.has(id) or seen_event_ids.has(id): return false
		seen_event_ids[id]=true
	var roster_ids := {}
	for id in state.roster:
		if not id is String or not Characters.ROLE_HP.has(id) or roster_ids.has(id): return false
		roster_ids[id] = true
	for id in state.character_upgrades:
		if not id is String or not roster_ids.has(id) or not state.character_upgrades[id] is bool or not state.character_upgrades[id]: return false
	if not _slots_valid(state.party_slots,state.roster,int(state.slot_capacity)): return false
	if state.team != Party.members(state.party_slots) or state.front_team != Party.members(state.party_slots,0,4) or state.back_team != Party.members(state.party_slots,4,8): return false
	if not state.current_node is String or not state.pending_recruit_order is String or not state.last_recruit_order is String: return false
	if not state.summon_active is bool or not state.loot_resolved is bool: return false
	if not Opening.valid(state): return false
	if (state.front_team.is_empty() and not (Opening.active(state) and state.opening.index==0)) or state.max_hp != maxi(1,Party.max_hp_for_state(state)): return false
	if state.phase == "formation":
		if not state.get("draft_team") is Array or not _slots_valid(state.get("draft_slots"),state.roster,int(state.slot_capacity)): return false
		if state.draft_team != Party.members(state.draft_slots): return false
	for key in state.upgrades:
		if not key is String or not state.upgrades[key] is int or state.upgrades[key] < 0: return false
	if not state.pending_recruit_order.is_empty() and not state.pending_recruit_order in Orders.CLASSES: return false
	if not state.last_recruit_order.is_empty() and not state.last_recruit_order in Orders.CLASSES: return false
	if not state.map is Dictionary or not state.map.get("nodes") is Array or state.map.nodes.is_empty() or state.map.nodes.size() > 200: return false
	var node_ids := {}
	for node in state.map.nodes:
		if not node is Dictionary: return false
		for key in ["id","row","floor","floor_row","column","type","next"]:
			if not node.has(key): return false
		if not node.id is String or not node.type in ["battle","elite","midboss","boss","camp","shop","event"] or not node.next is Array: return false
		for key in ["row","floor","floor_row","column"]:
			if not node[key] is int: return false
		if node.floor < 1 or node.floor > 5 or node.floor_row < 1 or node.floor_row > 6 or node.row < 1 or node.row > 30 or node.column < 0 or node.column > 2 or node_ids.has(node.id): return false
		node_ids[node.id] = true
	for node in state.map.nodes:
		for id in node.next:
			if not id is String or not node_ids.has(id): return false
	if not state.current_node.is_empty() and not node_ids.has(state.current_node): return false
	for id in state.completed:
		if not id is String or not node_ids.has(id): return false
	if state.has("cinematic_floor") and (not state.cinematic_floor is int or state.cinematic_floor<0 or state.cinematic_floor>Run.map_floor(state)): return false
	var current := Run.current_node(state)
	if not state.pending_recruit_order.is_empty() and not state.phase in ["reward","won"] and not Camp.orders_active(state) and not Opening.recruiting(state): return false
	if state.phase in ["node","reward","won","lost"] and current.is_empty(): return false
	if current.get("type","")=="event" and state.phase in ["node","reward","lost"]:
		if not Events.valid(state) or not state.seen_events.has(state.node_state.event): return false
	if state.phase == "reward":
		if (not current.type in ["battle","elite","midboss"] and not Events.is_battle(state)) or not state.completed.has(current.id): return false
	if state.phase == "won" and (current.type != "boss" or not state.completed.has(current.id)): return false
	if state.phase == "node":
		match str(current.type):
			"shop":
				if not RelicShop.valid_stock(state): return false
				if not state.node_state.get("bought") is Array or state.node_state.bought.size()>1:return false
				for item in state.node_state.bought:
					if item!="heal":return false
			"event":
				if not Events.valid(state) or state.node_state.mode=="battle": return false
			"camp":
				if not Camp.valid_node_state(state): return false
			_: return false
	if not state.last_progression.is_empty():
		for key in ["experience","from_level","to_level","renown","slots"]:
			if not state.last_progression.get(key) is int: return false
	return _loot_valid(state)

static func _relics_valid(state: Dictionary) -> bool:
	if not state.get("relics") is Array or state.relics.size() > Relics.ITEMS.size(): return false
	var seen := {}
	for id in state.relics:
		if not id is String or seen.has(id) or Relics.definition(id).is_empty(): return false
		seen[id] = true
	if not state.get("last_relic_drops") is Array or state.last_relic_drops.size() > 2: return false
	var drops := {}
	for id in state.last_relic_drops:
		if not id is String or Relics.definition(id).is_empty() or drops.has(id): return false
		drops[id] = true
	if not state.get("relic_progress") is Dictionary: return false
	var progress: Dictionary = state.relic_progress
	if progress.size() != 2 or not progress.get("floor") is int or progress.floor < 1 or progress.floor > 5 or not progress.get("counts") is Dictionary: return false
	for key in progress.counts:
		if not key is String or not RelicRun.COUNT_LIMITS.has(key): return false
		var value = progress.counts[key]
		if not value is int or value < 0 or value > int(RelicRun.COUNT_LIMITS[key]): return false
	return state.get("last_battle_gold") is int

static func _loot_valid(state: Dictionary) -> bool:
	if not state.pending_loot is Array or state.pending_loot.size() > 6: return false
	if not state.summon_active is bool or not state.loot_resolved is bool: return false
	if state.recruit_orders.size() != Orders.CLASSES.size(): return false
	for category: String in Orders.CLASSES:
		if not state.recruit_orders.get(category) is int or state.recruit_orders[category] != 0: return false
	if Opening.active(state): return state.loot_resolved and state.pending_loot.is_empty() and Opening.valid(state)
	if Camp.orders_active(state):
		return state.loot_resolved and state.pending_loot.is_empty() and Camp.valid_node_state(state)
	if state.loot_resolved:
		return state.pending_loot.is_empty() and not state.summon_active and state.pending_recruit_order.is_empty() and state.phase != "reward"
	if not state.phase in ["reward","won"] or state.pending_loot.is_empty(): return false
	if state.last_progression.is_empty(): return false
	var ids := {}
	var relic_ids: Array = []
	var order: Dictionary = {}
	var renown_amount := 0
	var slots_amount := 0
	for item in state.pending_loot:
		if not item is Dictionary or item.size() != 5: return false
		for key in ["id","kind","ref"]:
			if not item.get(key) is String: return false
		if not item.get("claimed") is bool or not item.get("amount") is int or item.amount <= 0: return false
		if not item.kind in ["gold","renown","slots","order","relic"] or ids.has(item.id): return false
		ids[item.id] = true
		if item.kind == "relic":
			if item.id != "relic:"+item.ref or item.amount != 1 or Relics.definition(item.ref).is_empty(): return false
			if state.relics.has(item.ref) != item.claimed: return false
			relic_ids.append(item.ref)
		else:
			if item.id != item.kind: return false
			if item.kind == "order":
				if item.amount != 1 or not item.ref in Orders.CLASSES or item.ref != state.last_recruit_order: return false
				order = item
			else:
				if not item.ref.is_empty(): return false
				if item.kind == "gold" and item.amount != state.last_battle_gold: return false
				if item.kind == "slots" and (item.amount > 2 or (not item.claimed and state.slot_capacity + item.amount > Run.MAX_SLOTS)): return false
				if item.kind == "renown": renown_amount = item.amount
				if item.kind == "slots": slots_amount = item.amount
	if order.is_empty() or relic_ids != state.last_relic_drops: return false
	if state.last_battle_gold > 0 and not ids.has("gold"): return false
	if slots_amount != state.last_progression.slots: return false
	var extra_renown := 1 if state.relics.has("chivalry_invitation") and not state.last_relic_drops.has("chivalry_invitation") else 0
	if renown_amount < state.last_progression.renown or renown_amount > state.last_progression.renown + extra_renown: return false
	if state.summon_active:
		return order.claimed and state.pending_recruit_order == order.ref
	return state.pending_recruit_order.is_empty()

static func _slots_valid(slots: Variant, roster: Array, capacity: int) -> bool:
	if not slots is Array or slots.size() != 8: return false
	var seen := {}
	for i in range(8):
		var id = slots[i]
		if not id is String: return false
		if id.is_empty(): continue
		if i >= capacity or not roster.has(id) or seen.has(id): return false
		seen[id] = true
	return true

static func _read(path: String, slot: int) -> Dictionary:
	if not FileAccess.file_exists(path): return {"ok":false,"message":"空存档"}
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES: return {"ok":false,"message":"无法读取存档"}
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	if error != OK or not json.data is Dictionary: return {"ok":false,"message":"存档文件损坏"}
	var envelope: Dictionary = json.data
	if envelope.get("format") != "mist-expedition-save" or envelope.get("version") != VERSION or envelope.get("slot") != slot: return {"ok":false,"message":"存档版本或槽位不兼容"}
	if not envelope.get("payload") is String or not envelope.get("sha256") is String or not envelope.get("saved_at") is String: return {"ok":false,"message":"存档文件损坏"}
	var data := Marshalls.base64_to_raw(envelope.payload)
	if data.size() < 4 or data.size() > MAX_BYTES or data.hex_encode().sha256_text() != envelope.sha256: return {"ok":false,"message":"存档校验失败"}
	var state = bytes_to_var(data)
	if not validate(state): return {"ok":false,"message":"存档内容无效"}
	return {"ok":true,"state":state,"saved_at":envelope.saved_at,"recovered":false}

static func load_slot(slot: int, directory: String = ROOT) -> Dictionary:
	if slot < 1 or slot > 3: return {"ok":false,"message":"存档槽不存在"}
	var primary := _read(path_for(slot,directory),slot)
	if primary.ok: return primary
	var backup := _read(path_for(slot,directory)+".bak",slot)
	if backup.ok:
		backup.recovered = true
		return backup
	return primary

## Include interrupted writes so unreadable and orphaned files can be cleared.
static func has_files(slot: int, directory: String = ROOT) -> bool:
	if slot < 1 or slot > 3: return false
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(path_for(slot,directory)+suffix): return true
	return false

static func delete_slot(slot: int, directory: String = ROOT) -> Dictionary:
	if slot < 1 or slot > 3: return {"ok":false,"message":"存档槽不存在"}
	# Remove recovery files first; a failed cleanup leaves the primary available.
	for suffix in [".tmp", ".bak.tmp", ".bak", ""]:
		var path := ProjectSettings.globalize_path(path_for(slot,directory)+suffix)
		if FileAccess.file_exists(path) and DirAccess.remove_absolute(path) != OK:
			return {"ok":false,"message":"无法删除存档文件，请检查文件权限后重试"}
	return {"ok":true,"message":"已删除存档"}

static func write(slot: int, state: Dictionary, directory: String = ROOT) -> Dictionary:
	if slot < 1 or slot > 3: return {"ok":false,"message":"存档槽不存在"}
	if not validate(state): return {"ok":false,"message":"当前状态不能保存（战斗中不更新存档）"}
	var folder := ProjectSettings.globalize_path(directory)
	var probe := folder
	while not DirAccess.dir_exists_absolute(probe):
		if FileAccess.file_exists(probe): return {"ok":false,"message":"存档目录被同名文件占用"}
		var parent := probe.get_base_dir()
		if parent == probe or parent.is_empty(): break
		probe = parent
	if DirAccess.make_dir_recursive_absolute(folder) != OK: return {"ok":false,"message":"无法创建存档目录"}
	var path := ProjectSettings.globalize_path(path_for(slot,directory))
	var data := var_to_bytes(state)
	var envelope := {"format":"mist-expedition-save","version":VERSION,"slot":slot,"saved_at":Time.get_datetime_string_from_system(),"payload":Marshalls.raw_to_base64(data),"sha256":data.hex_encode().sha256_text()}
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null: return {"ok":false,"message":"无法写入存档"}
	file.store_string(JSON.stringify(envelope))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or not _read(path+".tmp",slot).ok: return {"ok":false,"message":"存档写入校验失败，旧存档保持不变"}
	if _read(path,slot).ok:
		if DirAccess.copy_absolute(path,path+".bak.tmp") != OK or DirAccess.rename_absolute(path+".bak.tmp",path+".bak") != OK:
			return {"ok":false,"message":"无法更新存档备份，旧存档保持不变"}
	if DirAccess.rename_absolute(path+".tmp",path) != OK: return {"ok":false,"message":"无法替换存档，旧存档保持不变"}
	return {"ok":true,"message":"已保存"}

static func summary(result: Dictionary) -> String:
	if not result.ok: return str(result.get("message","无法读取"))
	var state: Dictionary = result.state
	var phase: String = "战后召集" if state.summon_active else ("战利品待领取" if not state.loot_resolved else {"formation":"编队中","map":"路线选择","node":"节点处理中","reward":"战后结算","won":"已通关","lost":"已失败","abandoned":"已放弃"}.get(state.phase,state.phase))
	if Opening.active(state): phase="开局编队" if Opening.ready(state) else ("选择开局召集令" if state.opening.bundle.is_empty() else "开局招募 %d/3" % [state.opening.index+1])
	var current := Run.current_node(state)
	var node_text := "起点" if current.is_empty() or int(current.get("floor",0)) != Run.map_floor(state) else "节点%d/6" % int(current.floor_row)
	var names: Array[String] = []
	for id: String in state.front_team: names.append(Characters.leader(id).name)
	return "%s · 第%d/5层 · %s · 等级%d · 已完成%d个节点\n%s\n%s%s" % [phase,Run.map_floor(state),node_text,state.level,state.completed.size()," / ".join(names),result.saved_at," · 可从备份恢复" if result.recovered else ""]




