extends RefCounted
const Catalog = preload("res://code/scripts/characters/character_catalog.gd")
const Tactical = preload("res://code/scripts/combat/tactical_effects.gd")
const Attributes=preload("res://code/scripts/combat/attributes.gd")
const Relics=preload("res://code/scripts/relics/relic_battle.gd")
const Feedback = preload("res://code/scripts/combat/battle_feedback.gd")

## Ordered effects mutate only the private state copy owned by Battle.
static func active_team(state: Dictionary) -> Array:
	return state.get("front_team", state.get("config", {}).get("team", Catalog.STARTER_IDS))

static func passive(state: Dictionary, id: String) -> Dictionary:
	if not active_team(state).has(id): return {}
	return Attributes.passive_rule(state,id)

static func snapshot(state: Dictionary, enemy_intent: Dictionary, paid: int = 0, actor: String = "") -> Dictionary:
	var result := {
		"hp": state.hp, "max_hp": state.max_hp,
		"enemy_hp": state.enemy_hp, "enemy_max": state.enemy_max,
		"ward": state.ward, "poison": state.poison, "shield": state.shield,
		"ap_after": int(state.ap) - paid,
		"intent_interruptible": enemy_intent.get("interruptible", false) and not state.interrupted,
		"intent_hits": int(enemy_intent.get("hits", 0)),
	}
	result.merge(Tactical.snapshot(state, actor))
	return result

static func matches(condition: Dictionary, before: Dictionary, context: Dictionary = {}) -> bool:
	for key: String in condition:
		var value: Variant = condition[key]
		match key:
			"team_hp_pct_lte":
				if int(before.hp) * 100 > int(before.max_hp) * int(value): return false
			"enemy_hp_pct_lte":
				if int(before.enemy_hp) * 100 > int(before.enemy_max) * int(value): return false
			"enemy_ward_min":
				if int(before.ward) < int(value): return false
			"enemy_ward_zero":
				if bool(value) and int(before.ward) != 0: return false
			"poison_min":
				if int(before.poison) < int(value): return false
			"poison_exact":
				if int(before.poison) != int(value): return false
			"shield_min":
				if int(before.shield) < int(value): return false
			"shield_exact":
				if int(before.shield) != int(value): return false
			"other_actions_min", "other_attacks_min", "other_mage_attacks_min", "other_warriors_min", "unacted_others_min", "armor_removed_min", "intent_hits_min":
				if int(before.get(key.trim_suffix("_min"), 0)) < int(value): return false
			"other_actions_exact", "intent_hits_exact":
				if int(before.get(key.trim_suffix("_exact"), 0)) != int(value): return false
			"ap_after_min":
				if int(before.ap_after) < int(value): return false
			"poison_spent_min":
				if int(context.get("poison_spent", 0)) < int(value): return false
			"intent_interruptible":
				if bool(value) and not before.intent_interruptible: return false
			_: return false
	return true

static func _trigger_key(id: String, kind: String) -> String:
	return id + ":" + kind

static func _round_trigger(state: Dictionary, id: String, kind: String) -> bool:
	var key := _trigger_key(id, kind)
	if state.passive_round_used.has(key): return false
	state.passive_round_used[key] = true
	return true

static func attack_bonus(state: Dictionary, id: String, before: Dictionary) -> int:
	var rule := passive(state, id)
	match str(rule.get("kind", "")):
		"first_attack":
			var key := _trigger_key(id, "first_attack")
			if not state.passive_battle_used.has(key):
				state.passive_battle_used[key] = true
				return int(rule.amount)
		"attack_if":
			if _round_trigger(state, id, "attack_if") and matches(rule.get("if", {}), before): return int(rule.amount)
	return 0

static func _own_bonus(state: Dictionary, id: String, kind: String, before: Dictionary) -> int:
	var rule := passive(state, id)
	if rule.get("kind", "") == kind and matches(rule.get("if", {}), before) and _round_trigger(state, id, kind):
		return int(rule.amount)
	return 0

static func resolve(state: Dictionary, skill_id: String, skill: Dictionary, before: Dictionary) -> void:
	var context := {"shield_spent": 0, "poison_spent": 0, "overheal": 0}
	var origin := {"source": str(skill.leader), "skill": skill_id, "name": str(skill.name)}
	var attack_boost := 0
	var attack_started := false
	var attack_percent := 0
	var healing_started := false
	var healing_percent := 0
	var power: Dictionary = state.config.get("upgrades", {})
	for effect: Dictionary in skill.get("effects", []):
		if not matches(effect.get("if", {}), before, context): continue
		var amount := int(effect.get("amount", 0))
		var precise_amount: float = effect.get("_precise_amount",amount)
		match str(effect.op):
			"damage", "multi_damage":
				if not attack_started:
					attack_started = true
					attack_percent = Relics.begin_attack(state,skill_id,skill,before)
					attack_boost = Tactical.consume_attack_bonus(state, str(skill.leader)) + attack_bonus(state, str(skill.leader), before)
				var upgrades := 0
				if effect.has("bonus_if") and matches(effect.bonus_if, before, context):
					amount += int(effect.get("bonus", 0))
					precise_amount += float(effect.get("_precise_bonus",effect.get("bonus",0)))
				var resource: Dictionary=effect.get("resource_bonus",{})
				if not resource.is_empty():
					var resource_amount := int(resource.cap_num)*mini(int(context.get(resource.resource,0)),int(resource.threshold))/(int(resource.cap_den)*maxi(1,int(resource.threshold)))
					amount += resource_amount
					precise_amount += float(resource.cap_num)*mini(int(context.get(resource.resource,0)),int(resource.threshold))/(int(resource.cap_den)*maxi(1,int(resource.threshold)))
				var scale: Dictionary = effect.get("scale_bonus", {})
				if not scale.is_empty():
					var scale_amount := mini(int(scale.get("cap", 999999)), (int(context.get(scale.get("resource", ""), 0)) / maxi(1, int(scale.get("divisor", 1)))) * maxi(1, int(scale.get("multiplier", 1))))
					amount += scale_amount
					precise_amount += scale_amount
				var piercing: bool = effect.get("piercing", false) or (effect.has("pierce_if") and not effect.pierce_if.is_empty() and matches(effect.pierce_if, before, context))
				var dealt := 0
				if effect.op == "multi_damage":
					var hits: int = maxi(1, int(effect.get("hits", 2)))
					var segment := amount / hits
					for i in range(hits):
						if int(state.enemy_hp) <= 0: break
						var hit_amount: int = segment if i < hits - 1 else amount - segment * (hits - 1)
						if attack_percent > 0:
							hit_amount = Relics.scale(precise_amount/hits+(attack_boost+upgrades if i == 0 else 0),attack_percent)
						elif i == 0: hit_amount += attack_boost + upgrades
						dealt += damage_enemy(state, hit_amount, piercing, false, origin)
				else:
					var incoming := Relics.scale(precise_amount+attack_boost+upgrades,attack_percent) if attack_percent > 0 else amount+attack_boost+upgrades
					dealt = damage_enemy(state, incoming, piercing, false, origin)
				attack_boost = 0
				state.round_attackers[str(skill.leader)] = true
				log_event(state, "%s：造成 %d%s伤害。" % [skill.name, dealt, " 穿透" if piercing else " "], "attack")
			"armor_remove":
				var removed := mini(int(state.ward), amount)
				state.ward -= removed
				state.armor_removed += removed
				Feedback.emit(state, "armor_break", "enemy", removed, origin)
				log_event(state, "%s：移除 %d 护甲。" % [skill.name, removed], "guard")
			"poison_add":
				var poison_before := int(state.poison)
				Attributes.add_poison(state,amount,int(effect.get("tick_amount",35)))
				Feedback.emit(state, "poison_add", "enemy", int(state.poison) - poison_before, origin)
				log_event(state, "敌人中毒 %d 层，每轮受到 %d 穿透护甲伤害。" % [state.poison, Attributes.poison_damage(state)], "poison")
			"poison_consume":
				var spent := Attributes.consume_poison(state,amount)
				context.poison_spent += spent
				Feedback.emit(state, "poison_consume", "enemy", spent, origin)
				if spent > 0:
					var rule := passive(state, str(skill.leader))
					if rule.get("kind", "") == "shield_after_poison_consumption" and _round_trigger(state, str(skill.leader), "shield_after_poison_consumption"):
						var shield_before_passive := int(state.shield)
						state.shield += int(rule.amount)
						Feedback.shield_gain(state, shield_before_passive, {"source": str(skill.leader), "skill": str(skill.leader) + ":passive", "name": rule.name})
						log_event(state, "%s：额外获得 %d 护盾。" % [rule.name, rule.amount], "guard")
			"shield_consume":
				var spent := mini(int(state.shield), amount)
				state.shield -= spent
				context.shield_spent += spent
			"heal":
				if not healing_started:
					healing_started = true
					healing_percent = Relics.begin_heal(state,str(skill.leader))
				var own_heal := _own_bonus(state, str(skill.leader), "own_heal_if", before)
				amount += own_heal
				precise_amount += own_heal
				var rule := passive(state, str(skill.leader))
				var first_heal := Tactical.first_heal_bonus(state, str(skill.leader), rule, matches(rule.get("if", {}), before))
				amount += first_heal
				precise_amount += first_heal
				if healing_percent > 0: amount = Relics.scale(precise_amount,healing_percent)
				var restored := heal(state, amount)
				Feedback.emit(state, "heal", "team", restored, origin)
				context.overheal = maxi(0, amount - restored)
				var shield_before_relic := int(state.shield)
				Relics.overheal(state,context.overheal)
				Feedback.shield_gain(state, shield_before_relic, {"source": str(skill.leader), "skill": skill_id, "name": "温玉佩"})
				var shield_before_passive := int(state.shield)
				Tactical.after_heal(state, str(skill.leader), rule, restored)
				Feedback.shield_gain(state, shield_before_passive, {"source": str(skill.leader), "skill": str(skill.leader) + ":passive", "name": str(rule.get("name", ""))})
				log_event(state, "%s：恢复 %d HP。" % [skill.name, restored], "heal")
			"shield":
				var own_shield := _own_bonus(state, str(skill.leader), "own_shield_if", before)
				amount += own_shield
				precise_amount += own_shield
				var shield_percent := Relics.shield_percent(state,str(skill.leader))
				if shield_percent > 0: amount = Relics.scale(precise_amount,shield_percent)
				var shield_before_skill := int(state.shield)
				state.shield += amount
				Feedback.shield_gain(state, shield_before_skill, origin)
				log_event(state, "%s：获得 %d 护盾。" % [skill.name, amount], "guard")
			"buff":
				var buff_before := int(state.buff)
				Tactical.set_buff(state, amount)
				Feedback.emit(state, "buff", "team", int(state.buff) - buff_before, origin)
			"mark", "class_buff", "carry_shield", "overheal", "delayed_buff":
				var shield_before_tactical := int(state.shield)
				var buff_before := int(state.buff)
				Tactical.apply(state, str(skill.leader), effect, context)
				Feedback.shield_gain(state, shield_before_tactical, origin)
				Feedback.emit(state, "buff", "team", int(state.buff) - buff_before, origin)
			"regen":
				var regen_percent := Relics.regen_percent(state,str(skill.leader))
				if regen_percent > 0: amount = Relics.scale(precise_amount,regen_percent)
				var current: Dictionary = state.get("regen", {})
				if current.is_empty() or amount >= int(current.amount):
					state.regen = {"amount": amount, "ticks": maxi(int(current.get("ticks", 0)), int(effect.ticks)), "source": origin.source, "skill": skill_id, "name": skill.name}
			"counter":
				if amount > int(state.get("counter", {}).get("amount", 0)):
					state.counter = {"amount": amount, "requires_shield_absorb": effect.get("requires_shield_absorb", true), "shield_before_min": int(effect.get("shield_before_min", 0)), "source": origin.source, "skill": skill_id, "name": skill.name}
			"percent_guard": state.percent_guards.append({"percent": int(effect.percent), "budget": int(effect.budget)})
			"flat_guard":
				amount += _own_bonus(state, str(skill.leader), "own_flat_guard_if", before)
				state.flat_guard = maxi(int(state.flat_guard), amount)
			"interrupt":
				if before.intent_interruptible:
					if not state.interrupted: Feedback.emit(state, "interrupt", "enemy", 0, origin, 0, false, true)
					state.interrupted = true
					log_event(state, "%s：打断本轮重击。" % skill.name, "guard")
			"ap_restore": state.ap = mini(int(state.max_ap), int(state.ap) + amount)
			"discount":
				if not state.discount_granted:
					state.discount_granted = true
					state.discount = amount
		state.shield=clampi(int(state.shield),0,int(state.max_hp))
	var enemy_hp_before_relic := int(state.enemy_hp)
	var ward_before_relic := int(state.ward)
	var shield_before_relic := int(state.shield)
	Relics.after_action(state,skill_id,skill,before,attack_started)
	var extra_damage := enemy_hp_before_relic - int(state.enemy_hp)
	var extra_absorbed := ward_before_relic - int(state.ward)
	if extra_damage > 0 or extra_absorbed > 0:
		Feedback.emit(state, "damage", "enemy", extra_damage, {"source": str(skill.leader), "skill": skill_id, "name": "余烬符"}, extra_absorbed)
	Feedback.shield_gain(state, shield_before_relic, {"source": str(skill.leader), "skill": skill_id, "name": "清音铜铃"})

static func heal(state: Dictionary, amount: int) -> int:
	var restored := mini(maxi(0, amount), maxi(0, int(state.max_hp) - int(state.hp)))
	state.hp += restored
	return restored

static func damage_enemy(state: Dictionary, amount: int, piercing: bool = false, finish: bool = true, origin: Dictionary = {}, kind: String = "damage") -> int:
	var was_alive := int(state.enemy_hp) > 0
	var absorbed := 0 if piercing else mini(int(state.ward), maxi(0, amount))
	state.ward -= absorbed
	var dealt := mini(int(state.enemy_hp), maxi(0, amount - absorbed))
	state.enemy_hp -= dealt
	if was_alive: Feedback.emit(state, kind, "enemy", dealt, origin, absorbed, piercing, true)
	if absorbed > 0: log_event(state, "敌人护甲吸收 %d 伤害。" % absorbed, "guard")
	if state.enemy_hp == 0:
		if finish: finish_victory(state)
	elif not state.enraged and int(state.enemy_hp) <= int(state.enemy_max) / 2:
		state.enraged = true
		log_event(state, "%s进入狂怒：%s每段攻击伤害 +30。" % [state.config.get("enemy_name", "巨像"),"下一次新预告起" if state.has("enemy_intent") else "之后"], "enemy")
	return dealt

static func finish_victory(state: Dictionary) -> void:
	if state.status == "playing" and int(state.enemy_hp) == 0:
		state.status = "won"
		apply_victory_relic(state)
		Tactical.clear_finished(state)
		log_event(state, "%s倒下。战斗胜利！" % state.config.get("enemy_name", "守门巨像"), "win")

static func apply_victory_relic(state: Dictionary) -> void:
	var hp_before := int(state.hp)
	Relics.victory(state)
	Feedback.emit(state, "heal", "team", int(state.hp) - hp_before, {"name": "止血布"})

static func _percent_saving(damage: int, percent: int) -> int:
	return damage - int(floor(float(damage) * (100 - clampi(percent, 0, 100)) / 100.0))

static func enemy_hit(state: Dictionary, incoming: int, piercing: bool = false, origin: Dictionary = {}) -> Dictionary:
	var shield_before := int(state.shield)
	var reduction := 0
	var selected := -1
	for id: String in active_team(state):
		var rule := passive(state, id)
		if rule.get("kind", "") == "percent_guard" and matches(rule.get("if", {}), Tactical.snapshot(state, id)): reduction = maxi(reduction, _percent_saving(incoming, int(rule.percent)))
	for i in range(state.percent_guards.size()):
		var guard: Dictionary = state.percent_guards[i]
		var saving := mini(maxi(0, int(guard.budget)), _percent_saving(incoming, int(guard.percent)))
		if saving > reduction:
			reduction = saving
			selected = i
	if selected >= 0: state.percent_guards[selected].budget -= reduction
	var damage := maxi(0, incoming - reduction)
	var flat := int(state.flat_guard)
	state.flat_guard = 0
	for id: String in active_team(state):
		var rule := passive(state, id)
		if rule.get("kind", "") == "flat_first_hit" and _round_trigger(state, id, "flat_first_hit") and matches(rule.get("if", {}), {"shield": shield_before}):
			flat = maxi(flat, int(rule.amount))
	damage = maxi(0, damage - flat)
	damage = Relics.incoming_damage(state,damage,shield_before)
	var absorbed := 0 if piercing else mini(int(state.shield), damage)
	state.shield -= absorbed
	state.blocked += absorbed
	var hp_damage := mini(int(state.hp), damage - absorbed)
	state.hp -= hp_damage
	var hit_origin := {"source": "enemy"}
	hit_origin.merge(origin, true)
	Feedback.emit(state, "damage", "team", hp_damage, hit_origin, absorbed, piercing, true)
	if state.hp == 0: state.status = "lost"
	else:
		var hp_before_relic := int(state.hp)
		Relics.after_enemy_damage(state,hp_damage)
		Feedback.emit(state, "heal", "team", int(state.hp) - hp_before_relic, {"name": "凤髓瓶"})
	return {"damage": hp_damage, "absorbed": absorbed, "shield_before": shield_before}

static func after_enemy_hit(state: Dictionary, hit: Dictionary) -> void:
	if state.status != "playing": return
	for id: String in active_team(state):
		var rule := passive(state, id)
		if rule.get("kind", "") == "after_shield_hp_damage" and int(hit.absorbed) >= int(rule.shield_min) and int(hit.damage) >= int(rule.hp_damage_min) and _round_trigger(state, id, "after_shield_hp_damage"):
			var restored := heal(state, int(rule.amount))
			Feedback.emit(state, "heal", "team", restored, {"source": id, "skill": id + ":passive", "name": rule.name})
			log_event(state, "%s：恢复 %d HP。" % [rule.name, restored], "heal")
	var counter: Dictionary = state.get("counter", {})
	if not counter.is_empty() and not state.counter_used and int(hit.get("shield_before", 0)) >= int(counter.get("shield_before_min", 0)) and (not counter.get("requires_shield_absorb", true) or int(hit.absorbed) > 0):
		state.counter_used = true
		var dealt := damage_enemy(state, int(counter.amount), false, false, counter, "counter")
		log_event(state, "返刃：造成 %d 反击伤害。" % dealt, "attack")
		finish_victory(state)

static func regenerate(state: Dictionary, enemy_intent: Dictionary) -> void:
	var regen: Dictionary = state.get("regen", {})
	if state.status != "playing" or regen.is_empty(): return
	var amount := int(regen.amount)
	var before := snapshot(state, enemy_intent)
	for id: String in active_team(state):
		var rule := passive(state, id)
		if rule.get("kind", "") == "regen_if" and matches(rule.get("if", {}), before): amount += int(rule.amount)
	var restored := heal(state, amount)
	Feedback.emit(state, "heal", "team", restored, regen)
	log_event(state, "再生：恢复 %d HP。" % restored, "heal")
	regen.ticks -= 1
	if int(regen.ticks) <= 0: state.regen = {}

static func reset_round(state: Dictionary) -> void:
	state.percent_guards = []
	state.flat_guard = 0
	state.counter = {}
	state.counter_used = false
	state.discount = 0
	state.discount_granted = false
	state.ap_conversion_used = false
	state.passive_round_used = {}

static func log_event(state: Dictionary, text: String, type: String = "system") -> void:
	state.log.push_front({"text": text, "type": type, "round": state.round})
	if state.log.size() > 60: state.log.resize(60)

