extends RefCounted
## Relic event rules never invoke skill resolution: additional effects cannot recurse.
const Relics = preload("res://code/scripts/relics/relic_catalog.gd")
const Attributes = preload("res://code/scripts/combat/attributes.gd")
const Characters = preload("res://code/scripts/characters/character_catalog.gd")

static func initialize(state: Dictionary) -> void:
	state.relic_round = {}
	state.relic_battle = {}
	state.max_ap = 10 if Relics.has(state,"cosmos_pouch") else 8
	state.ap = clampi(4+int(state.get("config",{}).get("initial_ap",0)),0,int(state.max_ap))
	if Relics.has(state,"black_tortoise_seal"): add_shield(state,percent_value(state.max_hp,12),"玄武铜印")

static func percent_value(value: float, percent: int) -> int:
	return maxi(1,floori(value*percent/100.0+0.0000001)) if value > 0 and percent > 0 else 0

static func scale(value: float, percent: int) -> int:
	return maxi(1,floori(value*(100+percent)/100.0+0.0000001)) if value > 0 else 0

static func has_direct(skill: Dictionary) -> bool:
	for effect: Dictionary in skill.get("effects",[]):
		if effect.get("op","") in ["damage","multi_damage"] and float(effect.get("amount",0)) > 0: return true
	return false

static func segments(skill: Dictionary) -> int:
	var count := 0
	for effect: Dictionary in skill.get("effects",[]):
		if effect.get("op","") == "damage": count += 1
		elif effect.get("op","") == "multi_damage": count += maxi(1,int(effect.get("hits",2)))
	return count

static func attack_percent(state: Dictionary, skill_id: String, skill: Dictionary, before: Dictionary) -> int:
	var actor: String = skill.leader
	var profession: String = Characters.leader(actor).get("class","")
	var round_used: Dictionary = state.get("relic_round",{})
	var pct := 0
	if Relics.has(state,"long_arm_bracer") and profession == "战士型": pct += 12
	if Relics.has(state,"bamboo_talisman") and profession == "法师型": pct += 12
	if Relics.has(state,"willow_needles") and profession == "刺客型" and not round_used.get("willow",false): pct += 15
	if Relics.has(state,"bamboo_scabbard") and int(state.round) == 1: pct += 15
	if Relics.has(state,"armor_piercing_awl") and int(before.get("ward",state.ward)) > 0: pct += 20
	if Relics.has(state,"repeating_crossbow") and segments(skill) >= 2: pct += 10
	if Relics.has(state,"primordial_pages") and not state.get("previous_round_skills",{}).has(skill_id) and not round_used.get("pages",false): pct += 18
	if Relics.has(state,"wind_sword_tassel") and not str(round_used.get("wind_owner","")).is_empty() and str(round_used.wind_owner) != actor: pct += 20
	if Relics.has(state,"linked_clasp") and int(round_used.get("linked_uses",0)) < 2 and not str(round_used.get("linked_actor","")).is_empty() and str(round_used.linked_actor) != actor: pct += 12
	var attackers: Array = round_used.get("attackers",[])
	if Relics.has(state,"seven_star_disc") and not round_used.get("seven",false) and attackers.size() == 2 and not attackers.has(actor): pct += 40
	return pct

static func begin_attack(state: Dictionary, skill_id: String, skill: Dictionary, before: Dictionary) -> int:
	var pct := attack_percent(state,skill_id,skill,before)
	var used: Dictionary = state.relic_round
	var actor: String = skill.leader
	if Relics.has(state,"willow_needles") and Characters.leader(actor).get("class","") == "刺客型": used.willow = true
	if Relics.has(state,"primordial_pages") and not state.get("previous_round_skills",{}).has(skill_id): used.pages = true
	if Relics.has(state,"wind_sword_tassel") and not str(used.get("wind_owner","")).is_empty() and used.wind_owner != actor: used.wind_owner = ""
	if Relics.has(state,"linked_clasp"):
		var previous: String = used.get("linked_actor","")
		if not previous.is_empty() and previous != actor and int(used.get("linked_uses",0)) < 2:
			used.linked_uses = int(used.get("linked_uses",0))+1
			used.linked_actor = ""
		else: used.linked_actor = actor
	if Relics.has(state,"seven_star_disc"):
		var actors: Array = used.get("attackers",[])
		if actors.size() == 2 and not actors.has(actor): used.seven = true
	if not used.has("attackers"): used.attackers = []
	if not used.attackers.has(actor): used.attackers.append(actor)
	return pct

static func heal_percent(state: Dictionary, actor: String) -> int:
	var pct := regen_percent(state,actor)
	var used: Dictionary = state.get("relic_round",{})
	var healers: Array = used.get("healers",[])
	if Relics.has(state,"twin_blossom_knot") and healers.size() == 1 and not healers.has(actor) and not used.get("twin",false): pct += 25
	return pct

static func regen_percent(state: Dictionary, actor: String) -> int:
	return 15 if Relics.has(state,"jade_pestle") and Characters.leader(actor).get("class","") == "奶妈型" else 0

static func begin_heal(state: Dictionary, actor: String) -> int:
	var pct := heal_percent(state,actor)
	var used: Dictionary = state.relic_round
	if not used.has("healers"): used.healers = []
	if not used.healers.has(actor):
		if Relics.has(state,"twin_blossom_knot") and used.healers.size() == 1: used.twin = true
		used.healers.append(actor)
	return pct

static func shield_percent(state: Dictionary, actor: String) -> int:
	return 15 if Relics.has(state,"rattan_charm") and Characters.leader(actor).get("class","") == "盾牌型" else 0

static func overheal(state: Dictionary, amount: float) -> void:
	if not Relics.has(state,"warm_jade") or amount <= 0: return
	var cap := percent_value(state.max_hp,10)
	var used: int = state.relic_round.get("warm_shield",0)
	var extra := mini(maxi(0,cap-used),percent_value(amount,25))
	if extra <= 0: return
	state.relic_round.warm_shield = used+extra
	add_shield(state,extra,"温玉佩")

static func after_action(state: Dictionary, skill_id: String, skill: Dictionary, before: Dictionary, attacked: bool) -> void:
	var used: Dictionary = state.relic_round
	var actor: String = skill.leader
	if attacked:
		if Relics.has(state,"wind_sword_tassel") and not used.get("wind_started",false):
			used.wind_started = true; used.wind_owner = actor
		if Relics.has(state,"hidden_blade_case") and not used.get("refund",false) and int(state.relic_battle.get("refunds",0)) < 2 and not state.get("previous_round_skills",{}).has(skill_id) and int(before.get("paid_ap",0)) >= 2:
			used.refund = true
			state.relic_battle.refunds = int(state.relic_battle.get("refunds",0))+1
			var restored := mini(1,int(state.max_ap)-int(state.ap))
			state.ap += restored
			note(state,"藏锋剑匣：返还 %d AP。" % restored)
		if Relics.has(state,"ember_talisman") and Characters.leader(actor).get("class","") == "法师型" and not state.relic_battle.get("ember",false):
			state.relic_battle.ember = true
			if int(state.enemy_hp) > 0:
				var incoming := percent_value(Attributes.stats(state,actor).attack,60)
				var absorbed := mini(int(state.ward),incoming)
				state.ward -= absorbed
				var dealt := mini(int(state.enemy_hp),incoming-absorbed)
				state.enemy_hp -= dealt
				note(state,"余烬符：追加 %d 伤害，护甲抵挡 %d。" % [dealt,absorbed])
				if state.enemy_hp > 0 and not state.enraged and int(state.enemy_hp) <= int(state.enemy_max)/2:
					state.enraged = true
					note(state,"%s进入狂怒：之后每段攻击伤害 +30。" % state.config.get("enemy_name","巨像"))
	elif Relics.has(state,"clear_bell") and not has_direct(skill) and Characters.leader(actor).get("class","") == "辅助型" and not used.get("bell",false):
		used.bell = true
		add_shield(state,percent_value(Attributes.stats(state,actor).max_hp,4),"清音铜铃")

static func after_swap(state: Dictionary) -> void:
	if Relics.has(state,"formation_flag") and not state.relic_round.get("swap",false):
		state.relic_round.swap = true
		add_shield(state,percent_value(state.max_hp,3),"换阵旗")

static func before_end_round(state: Dictionary) -> void:
	if Relics.has(state,"meditation_mat") and state.get("round_skills",{}).is_empty() and int(state.relic_battle.get("meditations",0)) < 2:
		state.relic_battle.meditations = int(state.relic_battle.get("meditations",0))+1
		restore(state,percent_value(state.max_hp,6),"凝神蒲团")

static func next_round(state: Dictionary) -> void:
	state.relic_round = {}
	if int(state.round) == 3 and Relics.has(state,"herbal_sachet") and not state.relic_battle.get("sachet",false):
		state.relic_battle.sachet = true
		restore(state,percent_value(state.max_hp,8),"百草香囊")
	if int(state.round) == 5 and Relics.has(state,"origin_pill_tray") and not state.relic_battle.get("pill",false):
		state.relic_battle.pill = true
		var restored := mini(1,int(state.max_ap)-int(state.ap))
		state.ap += restored
		note(state,"归元丹盘：恢复 %d AP。" % restored)

static func incoming_damage(state: Dictionary, damage: int, shield_before: int) -> int:
	if Relics.has(state,"iron_clasp") and shield_before > 0: damage = maxi(0,floori(damage*0.9))
	if Relics.has(state,"dragon_scale_guard") and not state.relic_battle.get("dragon",false):
		var cap := percent_value(state.max_hp,25)
		if damage > cap:
			state.relic_battle.dragon = true
			note(state,"龙鳞护手：本段伤害限制为 %d。" % cap)
			damage = cap
	return damage

static func after_enemy_damage(state: Dictionary, _hp_damage: int) -> void:
	if Relics.has(state,"phoenix_marrow") and int(state.hp) > 0 and int(state.hp)*100 <= int(state.max_hp)*30 and not state.relic_battle.get("phoenix",false):
		state.relic_battle.phoenix = true
		restore(state,percent_value(state.max_hp,15),"凤髓瓶")

static func retained_shield(state: Dictionary, ordinary: int) -> int:
	if not Relics.has(state,"black_tortoise_seal"): return ordinary
	var retained := mini(floori(int(state.shield)*0.4),percent_value(state.max_hp,12))
	return maxi(ordinary,retained)

static func victory(state: Dictionary) -> void:
	if not Relics.has(state,"hemostatic_cloth") or state.relic_battle.get("victory",false): return
	state.relic_battle.victory = true
	restore(state,percent_value(state.max_hp,3),"止血布")

static func add_shield(state: Dictionary, amount: int, title: String) -> void:
	var gained := mini(maxi(0,amount),maxi(0,int(state.max_hp)-int(state.shield)))
	state.shield += gained
	if gained > 0: note(state,"%s：获得 %d 护盾。" % [title,gained])

static func restore(state: Dictionary, amount: int, title: String) -> void:
	var restored := mini(maxi(0,amount),maxi(0,int(state.max_hp)-int(state.hp)))
	state.hp += restored
	if restored > 0: note(state,"%s：恢复 %d HP。" % [title,restored])

static func note(state: Dictionary, text: String) -> void:
	state.log.push_front({"text":text,"type":"relic","round":state.round})
	if state.log.size() > 60: state.log.resize(60)

static func preview_skill(state: Dictionary, skill_id: String, skill: Dictionary) -> Dictionary:
	var preview := skill.duplicate(true)
	var before := {"ward":state.get("ward",0)}
	var direct_pct := attack_percent(state,skill_id,skill,before)
	var heal_pct := heal_percent(state,str(skill.leader))
	var shield_pct := shield_percent(state,str(skill.leader))
	for effect: Dictionary in preview.get("effects",[]):
		var op: String = effect.get("op","")
		var pct := direct_pct if op in ["damage","multi_damage"] else (heal_pct if op == "heal" else (shield_pct if op == "shield" else 0))
		if op == "regen": pct = regen_percent(state,str(skill.leader))
		if pct > 0:
			var precise: float = effect.get("_precise_amount",effect.get("amount",0))
			effect.amount = scale(precise,pct)
	return preview

