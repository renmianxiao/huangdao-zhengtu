extends RefCounted
const Enemies = preload("res://code/scripts/characters/enemy_catalog.gd")
const Characters = preload("res://code/scripts/characters/character_catalog.gd")

const UPGRADE_NAMES := {"attack": "全队攻击力 +10%", "shield": "护盾效果 +10%", "heal": "治疗效果 +10%", "max_hp": "全队血量属性 +10%", "initial_ap": "开战 AP +1"}
const UPGRADE_KEYS := ["attack", "shield", "heal", "max_hp", "initial_ap", "slots"]
const NODE_NAMES := {"battle": "普通战斗", "elite": "精英战斗", "event": "未知事件", "shop": "商店", "camp": "营地", "midboss": "道中 Boss", "boss": "最终 Boss"}
const RECRUIT_COSTS: Dictionary = Characters.RECRUIT_COSTS
const BATTLE_GOLD := {"battle":2,"elite":5,"midboss":15,"boss":15}

static func seed_for(seed: int, node_id: String, purpose: String) -> int:
	var value: int = seed & 0x7fffffff
	for byte: int in (node_id + ":" + purpose).to_utf8_buffer():
		value = (value * 31 + byte) & 0x7fffffff
	return value

static func encounter(kind: String, row: int, seed: int, node_id: String) -> Dictionary:
	if kind == "boss":
		return {"id": "gate_colossus", "name": "最终 Boss · 守门巨像", "floor": 5, "tier": "boss", "hp": Enemies.scaled_hp(1800), "patterns": []}
	if kind == "midboss":
		var boss_index := seed_for(seed, node_id, "midboss") % Enemies.MIDBOSSES.size()
		var boss: Dictionary = Enemies.MIDBOSSES[boss_index].duplicate(true)
		boss.hp = Enemies.scaled_hp(int(boss.hp))
		boss.patterns=Enemies.scaled_attack_patterns(boss.patterns,int(boss.floor))
		return boss
	var floor_number := clampi(1 + floori(float(row - 1) / 6.0), 1, 5)
	var tier := "elite" if kind == "elite" else "battle"
	var enemies := Enemies.pool(floor_number, tier)
	var index := seed_for(seed, node_id, "enemy") % enemies.size()
	var enemy: Dictionary = enemies[index].duplicate(true)
	# Light within-floor growth, keeping each floor's enemies at similar difficulty.
	var local_step := clampi(row - (floor_number - 1) * 6 - 1, 0, 5)
	enemy.hp += local_step * 5
	enemy.hp = Enemies.scaled_hp(int(enemy.hp))
	for pattern: Dictionary in enemy.patterns:
		if int(pattern.damage) > 0: pattern.damage += local_step
	enemy.patterns=Enemies.scaled_attack_patterns(enemy.patterns,int(enemy.floor))
	return enemy

static func upgrade_name(key: String, scale: int = 1) -> String:
	if key == "slots": return "角色槽位 +1（最多 8 槽）"
	if key == "initial_ap": return "开战 AP +%d" % scale
	if key == "max_hp": return "全队血量属性 +%d%%" % (10 * scale)
	if key == "attack": return "全队攻击力 +%d%%" % (10 * scale)
	if key == "shield": return "护盾效果 +%d%%" % (10 * scale)
	if key == "heal": return "治疗效果 +%d%%" % (10 * scale)
	return key


