extends RefCounted
const EnemyAI=preload("res://code/scripts/combat/enemy_intelligence.gd")
const Numbers=preload("res://code/scripts/number_text.gd")
const Professions=preload("res://code/scripts/profession_names.gd")
const DEFAULT_ENEMY_HP := 1300 * preload("res://code/scripts/characters/enemy_catalog.gd").HP_MULTIPLIER
const Party = preload("res://code/scripts/party.gd")
const Catalog = preload("res://code/scripts/characters/character_catalog.gd")
const Effects = preload("res://code/scripts/combat/skill_effects.gd")
const Tactical = preload("res://code/scripts/combat/tactical_effects.gd")
const Attributes=preload("res://code/scripts/combat/attributes.gd")
const Growth=preload("res://code/scripts/characters/character_growth.gd")
const Relics=preload("res://code/scripts/relics/relic_battle.gd")
const Feedback = preload("res://code/scripts/combat/battle_feedback.gd")

## Pure battle rules. Each command returns a new state; rejected commands return
## the original state unchanged. The UI owns timing, never combat calculations.
const LEADERS: Array = Catalog.LEADERS
const SKILLS: Dictionary = Catalog.SKILLS
const BASE_AP_RECOVERY := 2
const PATTERNS: Array = [
	{"name": "横扫", "damage": 110, "hits": 1, "ward": 0, "interruptible": false},
	{"name": "铸铁壁垒", "damage": 0, "hits": 0, "ward": 150, "interruptible": false},
	{"name": "崩城重击", "damage": 220, "hits": 1, "ward": 0, "interruptible": true},
	{"name": "双连斩", "damage": 70, "hits": 2, "ward": 0, "interruptible": false},
]

static func create_battle(config: Dictionary = {}) -> Dictionary:
	var result := {
		"round": 1, "hp": 900, "max_hp": 900, "enemy_hp": DEFAULT_ENEMY_HP, "enemy_max": DEFAULT_ENEMY_HP,
		"ap": 4, "max_ap": 8, "shield": 0, "ward": 0, "poison": 0, "buff": 0,
		"poison_layers": [], "heals": 0, "used": {}, "interrupted": false, "enraged": false,
		"status": "playing", "actions": 0, "blocked": 0, "feedback": [],
		"previous_round_skills": {}, "round_skills": {}, "skill_uses": {}, "passive_battle_used": {}, "passive_round_used": {},
		"regen": {}, "counter": {}, "counter_used": false, "percent_guards": [], "flat_guard": 0,
		"discount": 0, "discount_granted": false, "ap_conversion_uses": 0, "ap_conversion_used": false,
		"buff_classes": [], "mark": {}, "carry_limit": 0, "delayed_buff": 0,
		"round_attackers": {}, "armor_removed": 0,
		"log": [{"text": "远征队抵达城门。守门巨像抬起了巨剑。", "type": "system", "round": 1}],
	}
	result.config = config.duplicate(true)
	result.hp = clampi(int(config.get("hp", 900)), 0, int(config.get("max_hp", 900)))
	result.max_hp = int(config.get("max_hp", 900))
	result.enemy_hp = int(config.get("enemy_hp", DEFAULT_ENEMY_HP))
	result.enemy_max = result.enemy_hp
	result.ap = clampi(4 + int(config.get("initial_ap", 0)), 0, 8)
	if config.has("party_slots"):
		var bonus: int = int(config.get("hp_bonus", maxi(0, int(config.max_hp) - Party.max_hp_for(config.party_slots, 0, Growth.upgrades(config))) if config.has("max_hp") else 0))
		result.health_num = int(config.get("health_num", result.hp))
		result.health_den = int(config.get("health_den", result.max_hp))
		result = Party.apply_layout(result, config.party_slots, bonus)
		result.swap_locked = false
		result.config.team = result.team.duplicate()
	elif not result.config.has("team"):
		result.config.team = Catalog.STARTER_IDS.duplicate()
	if config.has("enemy_name"):
		result.log[0].text = "远征队遭遇%s，准备战斗。" % config.enemy_name
	Relics.initialize(result)
	if config.has("enemy_start_hp"): result.enemy_hp = clampi(int(config.enemy_start_hp),1,maxi(1,result.enemy_max))
	result.ward += maxi(0,int(config.get("initial_ward",0)))
	result.shield += maxi(0,int(config.get("initial_shield",0)))
	if int(result.hp) == 0:
		result.status = "lost"
		_log(result, "远征队失去战斗能力。调整策略，再试一次。", "enemy")
	EnemyAI.lock_intent(result,PATTERNS)
	return result

static func swap_reason(state: Dictionary, front_index: int, back_index: int) -> String:
	if state.status != "playing": return "战斗已结束"
	if not state.has("party_slots"): return "未启用前后台"
	if state.get("swap_locked", false): return "本回合已行动，禁止换位"
	if front_index < 0 or front_index >= Party.FRONT_SIZE or back_index < Party.FRONT_SIZE or back_index >= Party.MAX_SIZE: return "请选择一个前台和一个后台槽"
	var capacity: int = state.config.get("slot_capacity", Party.MAX_SIZE)
	if front_index >= capacity or back_index >= capacity: return "槽位未解锁"
	if state.party_slots[front_index].is_empty() and state.party_slots[back_index].is_empty(): return "两个槽位均为空"
	var slots: Array = state.party_slots.duplicate()
	var hold: String = slots[front_index]
	slots[front_index] = slots[back_index]
	slots[back_index] = hold
	if Party.members(slots, 0, Party.FRONT_SIZE).is_empty(): return "前台至少保留一名角色"
	return ""

static func swap_slots(state: Dictionary, front_index: int, back_index: int) -> Dictionary:
	if not swap_reason(state, front_index, back_index).is_empty(): return state
	var slots: Array = state.party_slots.duplicate()
	var hold: String = slots[front_index]
	slots[front_index] = slots[back_index]
	slots[back_index] = hold
	var next: Dictionary = Party.apply_layout(state, slots, int(state.hp_bonus))
	next.config.party_slots = slots.duplicate()
	next.config.team = next.team.duplicate()
	Relics.after_swap(next)
	_log(next, "前台 %d 与后台 %d 换位，血量比例保持不变。" % [front_index + 1, back_index - 3], "system")
	return next

static func skill_cost(state: Dictionary, id: String) -> int:
	if not SKILLS.has(id):
		return 999999
	var skill: Dictionary = Attributes.skill(state,id)
	var cost := int(skill.cost)
	if state.get("previous_round_skills", {}).has(id): cost += 1
	if not skill.get("fixed_cost", false) and int(skill.cost) > 0:
		cost = maxi(0, cost - int(state.get("discount", 0)))
	return cost

static func intent(state: Dictionary) -> Dictionary:
	var result: Dictionary = PATTERNS[(int(state.round) - 1) % PATTERNS.size()].duplicate()
	if state.has("enemy_intent"):
		result=state.enemy_intent.duplicate(true)
	elif state.get("config", {}).has("patterns"):
		result = state.config.patterns[(int(state.round) - 1) % state.config.patterns.size()].duplicate()
	if not state.has("enemy_intent") and result.damage > 0 and state.enraged:
		result.damage += 30
	if result.hits == 0:
		result.text = str(result.get("text", "敌人获得 %d 护甲；可以积攒 AP" % result.ward)) if int(result.ward) > 0 else str(result.get("text", "敌人正在蓄势；可以积攒 AP"))
	else:
		result.text = "对部队造成 %d%s 伤害%s" % [result.damage, " × %d" % result.hits if result.hits > 1 else "", " · 可打断" if result.interruptible else ""]
		if result.get("piercing", false): result.text += " · 穿透护盾（减伤仍有效）"
	return result

static func skill_description(state: Dictionary,id: String) -> String:
	var source: Dictionary=preload("res://code/scripts/combat/damage_budget.gd").normalize(SKILLS.get(id,{}))
	if source.is_empty(): return "未知技能"
	var resolved:=Relics.preview_skill(state,id,Attributes.skill(state,id))
	var amounts: Array[String]=[]
	for effect: Dictionary in resolved.effects:
		var op: String=effect.op
		if op in ["damage","multi_damage","heal","shield","regen","counter","armor_remove","flat_guard"]:
			var kind: String={"damage":"伤害","multi_damage":"总伤害","heal":"治疗","shield":"护盾","regen":"每次再生","counter":"反击","armor_remove":"破甲","flat_guard":"减伤"}[op]
			amounts.append("%s %d" % [kind,int(effect.amount)])
	var summary: String=" / ".join(amounts) if not amounts.is_empty() else source.text
	var result: String=summary+"\n基础倍率："+source.text
	if Growth.is_upgraded(state,str(source.leader)): result+="\n角色已强化：攻击力与血量 +20%"
	var power:=Attributes.powers(state)
	if int(power.get("attack",0))>0: result+="\n攻击力强化 %s%%" % Numbers.integer(float(power.attack)/1.5)
	if int(power.get("heal",0))>0: result+="\n治疗效果强化 %s%%" % Numbers.integer(float(power.heal)/2.0)
	if int(power.get("shield",0))>0: result+="\n护盾效果强化 %s%%" % Numbers.integer(float(power.shield)/2.0)
	if int(power.get(id,0))>0: result+="\n技能训练：攻击/治疗增加攻击力的 %s%%，护盾增加自身血量的 %s%%" % [Numbers.integer(float(power[id])),Numbers.integer(float(power[id])/3.0)]
	result+="\n间隔使用：上回合使用则本回合 +1 AP；停用一回合恢复。当前额外费用：%d AP" % (1 if state.get("previous_round_skills",{}).has(id) else 0)
	if source.has("limit"): result+="\n本战剩余 %d 次" % maxi(0,int(source.limit)-int(state.skill_uses.get(id,0)))
	if not str(source.get("rules","")).is_empty(): result+="\n规则："+str(source.rules)
	return Professions.text(Numbers.description(result))

static func passive_description(state: Dictionary, id: String) -> String:
	var leader := Catalog.leader(id)
	var rule: Dictionary = leader.get("passive", {})
	if rule.is_empty(): return "无被动"
	return Professions.text(Numbers.description("%s（%s）：%s" % [rule.name, passive_status(state,id), rule.text]))

static func passive_status(state: Dictionary, id: String) -> String:
	var rule: Dictionary = Attributes.passive_rule(state,id)
	if rule.is_empty(): return "无被动"
	if not Effects.active_team(state).has(id):
		return "后台不生效" if state.get("back_team", []).has(id) else "未上阵不生效"
	if state.status != "playing": return "战斗已结束"
	var key: String = id + ":" + str(rule.kind)
	if state.get("passive_battle_used", {}).has(key): return "本战机会已用"
	if state.get("passive_round_used", {}).has(key): return "本轮机会已用"
	if not Effects.matches(rule.get("if", {}), Effects.snapshot(state,intent(state),0,id)): return "条件未满足"
	return "前台生效"

static func team_status_description(state: Dictionary) -> String:
	var notes: Array[String] = []
	if int(state.shield) > 0: notes.append("本轮护盾 %d" % state.shield)
	if int(state.buff) > 0:
		var classes: Array = state.get("buff_classes", [])
		var target := "主动攻击" if classes.is_empty() else "/".join(Professions.labels(classes)) + "主动攻击"
		notes.append("本轮下次%s +%d" % [target, state.buff])
	var mark: Dictionary = state.get("mark", {})
	if not mark.is_empty(): notes.append("破绽 +%d（供%s之外的队友下一击）" % [mark.amount, Catalog.leader(mark.owner).get("name", "施加者")])
	if int(state.get("carry_limit", 0)) > 0: notes.append("本轮留盾：剩余盾最多 %d 留到下一轮" % state.carry_limit)
	if int(state.get("delayed_buff", 0)) > 0: notes.append("下一轮待发增伤 +%d" % state.delayed_buff)
	var regen: Dictionary = state.get("regen", {})
	if not regen.is_empty(): notes.append("再生 %d HP × %d 次（敌方行动后）" % [regen.amount, regen.ticks])
	for guard: Dictionary in state.get("percent_guards", []): notes.append("本轮减伤 %d%%，剩余额度 %d" % [guard.percent, guard.budget])
	if int(state.get("flat_guard", 0)) > 0: notes.append("本轮下一命中段减伤 %d" % state.flat_guard)
	var counter: Dictionary = state.get("counter", {})
	if not counter.is_empty(): notes.append("本轮反击 %d（%s）" % [counter.amount, "已触发" if state.counter_used else "待护盾承伤"])
	if int(state.get("discount", 0)) > 0: notes.append("本轮下一收费技能 -%d AP" % state.discount)
	if int(state.get("ap_conversion_uses", 0)) > 0: notes.append("AP 转换剩余 %d 次" % maxi(0, 2 - int(state.ap_conversion_uses)))
	return "；".join(notes) if not notes.is_empty() else "暂无临时状态"

static func action_reason(state: Dictionary, id: String) -> String:
	if state.status != "playing":
		return "战斗已结束"
	if not SKILLS.has(id):
		return "未知技能"
	if state.has("front_team") and not state.front_team.has(SKILLS[id].leader):
		return "角色在后台" if state.back_team.has(SKILLS[id].leader) else "角色未上阵"
	if state.config.has("team") and not state.config.team.has(SKILLS[id].leader):
		return "角色未上阵"
	if state.used.has(SKILLS[id].leader):
		return "本轮已行动"
	if id == "break" and (not intent(state).interruptible or state.interrupted):
		return "当前行动不可打断"
	var skill: Dictionary = Attributes.skill(state,id)
	if skill.has("limit") and int(state.get("skill_uses", {}).get(id, 0)) >= int(skill.limit): return "本战次数已耗尽"
	if skill.get("ap_conversion", false):
		if int(state.get("ap_conversion_uses", 0)) >= 2: return "本战转换次数已耗尽"
		if state.get("ap_conversion_used", false): return "本轮已进行 AP 转换"
	if skill.has("requires") and not Effects.matches(skill.requires, Effects.snapshot(state, intent(state), skill_cost(state, id), str(skill.leader))): return "使用前提不满足"
	if state.ap < skill_cost(state, id):
		return "AP 不足"
	return ""

static func act(state: Dictionary, id: String) -> Dictionary:
	if not action_reason(state, id).is_empty():
		return state
	var next: Dictionary = state.duplicate(true)
	next.feedback = []
	var skill: Dictionary = Attributes.skill(state,id)
	var before: Dictionary = Effects.snapshot(state, intent(state), skill_cost(state, id), str(skill.leader))
	before.paid_ap = skill_cost(state,id)
	next.ap -= skill_cost(state, id)
	if not skill.get("fixed_cost", false) and int(skill.cost) > 0: next.discount = 0
	next.used[skill.leader] = true
	if next.has("party_slots"): next.swap_locked = true
	next.actions += 1
	next.skill_uses[id] = int(next.skill_uses.get(id, 0)) + 1
	next.round_skills[id] = true
	if skill.get("ap_conversion", false):
		next.ap_conversion_uses += 1
		next.ap_conversion_used = true
	Effects.resolve(next, id, skill, before)
	Effects.finish_victory(next)
	if next.has("party_slots") and next.hp != state.hp: Party.record_health(next)
	return next

static func end_round(state: Dictionary) -> Dictionary:
	if state.status != "playing":
		return state
	var next: Dictionary = state.duplicate(true)
	next.feedback = []
	# Snapshot the visible intent before poison, matching the browser prototype.
	# If poison triggers rage, the extra damage starts on the following round.
	var enemy_intent: Dictionary = intent(state)
	var hp_before_rest := int(next.hp)
	Relics.before_end_round(next)
	Feedback.emit(next, "heal", "team", int(next.hp) - hp_before_rest, {"name": "凝神蒲团"})
	if next.poison > 0:
		var damage: int = mini(int(next.enemy_hp), Attributes.poison_damage(next))
		next.enemy_hp -= damage
		Feedback.emit(next, "poison_tick", "enemy", damage, {"name": "毒素"}, 0, true)
		_log(next, "毒素发作：造成 %d 穿透伤害。" % damage, "poison")
		if next.enemy_hp == 0:
			next.status = "won"
			Effects.apply_victory_relic(next)
			if next.has("party_slots") and next.hp != state.hp: Party.record_health(next)
			Tactical.clear_finished(next)
			_log(next, "%s倒在毒雾中。战斗胜利！" % next.config.get("enemy_name", "巨像"), "win")
			return next
		if not next.enraged and next.enemy_hp <= next.enemy_max / 2:
			next.enraged = true
			_log(next, "%s进入狂怒：下一轮起每段攻击伤害 +30。" % next.config.get("enemy_name", "巨像"), "enemy")
	if next.interrupted:
		_log(next, "%s被打断，敌人无法行动。" % enemy_intent.name, "guard")
	elif int(enemy_intent.hits) == 0 and int(enemy_intent.ward) == 0:
		Feedback.emit(next, "enemy_action", "enemy", 0, {"source": "enemy", "name": enemy_intent.name}, 0, false, true)
		_log(next, "%s：%s。" % [enemy_intent.name, enemy_intent.text], "enemy")
	elif enemy_intent.ward > 0:
		next.ward += enemy_intent.ward
		Feedback.emit(next, "enemy_action", "enemy", int(enemy_intent.ward), {"source": "enemy", "name": enemy_intent.name})
		_log(next, "%s：获得 %d 护甲。" % [enemy_intent.name, enemy_intent.ward], "enemy")
	else:
		for hit in range(int(enemy_intent.hits)):
			var hit_result: Dictionary = Effects.enemy_hit(next, int(enemy_intent.damage), bool(enemy_intent.get("piercing", false)), {"source": "enemy", "name": enemy_intent.name})
			var absorbed: int = hit_result.absorbed
			var damage: int = hit_result.damage
			_log(next, "%s%s：部队失去 %d HP%s。" % [enemy_intent.name, "（%d/%d）" % [hit + 1, enemy_intent.hits] if enemy_intent.hits > 1 else "", damage, "，护盾抵挡 %d" % absorbed if absorbed > 0 else ""], "enemy")
			if next.hp == 0:
				next.status = "lost"
				Tactical.clear_finished(next)
				if next.has("party_slots"): Party.record_health(next)
				_log(next, "远征队失去战斗能力。调整策略，再试一次。", "enemy")
				return next
			Effects.after_enemy_hit(next, hit_result)
			if next.status != "playing":
				if next.has("party_slots") and next.hp != state.hp: Party.record_health(next)
				return next
	Effects.regenerate(next, enemy_intent)
	if next.has("party_slots"):
		if next.hp != state.hp: Party.record_health(next)
		next.swap_locked = false
	next.round += 1
	next.ap = mini(int(next.max_ap), int(next.ap) + BASE_AP_RECOVERY)
	next.previous_round_skills = next.round_skills.duplicate()
	next.round_skills = {}
	next.used = {}
	Tactical.finish_round(next)
	next.interrupted = false
	Effects.reset_round(next)
	var hp_before_next := int(next.hp)
	Relics.next_round(next)
	Feedback.emit(next, "heal", "team", int(next.hp) - hp_before_next, {"name": "百草香囊"})
	if next.has("party_slots") and next.hp != state.hp: Party.record_health(next)
	EnemyAI.lock_intent(next,PATTERNS)
	_log(next, "第 %d 回合开始，恢复 %d AP（上限 %d）。" % [next.round,BASE_AP_RECOVERY,next.max_ap])
	return next

static func _damage_enemy(state: Dictionary, amount: int) -> int:
	return Effects.damage_enemy(state, amount, false, false)

static func _log(state: Dictionary, text: String, type: String = "system") -> void:
	state.log.push_front({"text": text, "type": type, "round": state.round})
	if state.log.size() > 60:
		state.log.resize(60)





