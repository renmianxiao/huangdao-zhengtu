extends RefCounted
const Numbers=preload("res://code/scripts/number_text.gd")
const DamageBudget=preload("res://code/scripts/combat/damage_budget.gd")
const Catalog=preload("res://code/scripts/characters/character_catalog.gd")
const Growth=preload("res://code/scripts/characters/character_growth.gd")
const RelicStats=preload("res://code/scripts/relics/relic_stats.gd")
const Relics=preload("res://code/scripts/relics/relic_catalog.gd")

static func powers(state: Dictionary) -> Dictionary:
	return state.get("config",state).get("upgrades",{})

static func hp_for(id: String, bonus: int=0, character_upgrades: Dictionary={}) -> int:
	var growth: int=Growth.multiplier_numerator({"character_upgrades":character_upgrades},id)
	return int(Catalog.ROLE_HP.get(id,0)) * (600+maxi(0,bonus)) * growth / 3000

static func stats(state: Dictionary,id: String) -> Dictionary:
	var p:=powers(state)
	var bonus: int=state.get("hp_bonus",state.get("config",{}).get("hp_bonus",0))
	var growth: int=Growth.multiplier_numerator(state,id)
	var attack_factor := (150+int(p.get("attack",0)))*100 + 150*RelicStats.attribute_percent(state,id,"attack")
	var hp_factor := (600+bonus)*100 + 600*RelicStats.attribute_percent(state,id,"max_hp")
	return {"attack":float(Catalog.ROLE_ATTACK.get(id,0))*attack_factor*growth/75000.0,"max_hp":float(Catalog.ROLE_HP.get(id,0))*hp_factor*growth/300000.0}

static func display(number: float) -> String:
	return Numbers.integer(number)

static func value(state: Dictionary,id: String, scaling: Dictionary, op: String="",training: int=0) -> int:
	var parts:=fraction(state,id,scaling,op,training)
	return int(parts[0])/maxi(1,int(parts[1]))

static func fraction(state: Dictionary,id: String, scaling: Dictionary, op: String="",training: int=0) -> Array:
	var basis: String="max_hp" if scaling.get("basis","")=="actor_max_hp" else "attack"
	var base: int=Catalog.ROLE_HP.get(id,0) if basis=="max_hp" else Catalog.ROLE_ATTACK.get(id,0)
	var bonus: int=state.get("hp_bonus",state.get("config",{}).get("hp_bonus",0))
	var attribute_factor: int=(600+bonus) if basis=="max_hp" else (150+int(powers(state).get("attack",0)))
	var attribute_denominator: int=600 if basis=="max_hp" else 150
	attribute_factor = attribute_factor*100+attribute_denominator*RelicStats.attribute_percent(state,id,basis)
	attribute_denominator *= 100
	var numerator: int=scaling.get("numerator",int(round(float(scaling.get("coefficient",0))*100)))
	var denominator: int=scaling.get("denominator",100)
	if training>0: numerator+=training/3 if basis=="max_hp" else training
	var factor:=200
	if op in ["heal","regen"]: factor+=int(powers(state).get("heal",0))
	if op in ["shield","overheal"]: factor+=int(powers(state).get("shield",0))
	return [base*attribute_factor*numerator*factor*Growth.multiplier_numerator(state,id),maxi(1,denominator)*attribute_denominator*200*5]

static func materialize(state: Dictionary,id: String,data: Variant,training: int=0) -> Variant:
	if data is Array:
		var result: Array=[]
		for entry in data: result.append(materialize(state,id,entry,training))
		return result
	if not data is Dictionary: return data
	if data.has("basis"): return value(state,id,data)
	var result: Dictionary={}
	for key in data:
		if key in ["scaling","bonus_scaling","budget_scaling","tick_scaling","resource_bonus"]: continue
		result[key]=materialize(state,id,data[key],training)
	var op: String=str(data.get("op",""))
	if op.is_empty():
		if data.get("kind","") in ["own_heal_if","regen_if","first_heal_if","after_shield_hp_damage"]: op="heal"
		if data.get("kind","") in ["own_shield_if","first_heal_shield","shield_after_poison_consumption"]: op="shield"
	if data.has("scaling"):
		var skill_training := training if op in ["damage","multi_damage","heal","regen","shield"] else 0
		result.amount=value(state,id,data.scaling,op,skill_training)
		if not Relics.ids(state).is_empty() and op in ["damage","multi_damage","heal","shield","regen"]:
			var precise := fraction(state,id,data.scaling,op,skill_training)
			result._precise_amount = float(precise[0])/maxi(1,int(precise[1]))
	if data.has("bonus_scaling"):
		result.bonus=value(state,id,data.bonus_scaling)
		if not Relics.ids(state).is_empty():
			var precise := fraction(state,id,data.bonus_scaling)
			result._precise_bonus = float(precise[0])/maxi(1,int(precise[1]))
	if data.has("budget_scaling"): result.budget=value(state,id,data.budget_scaling)
	if data.has("tick_scaling"): result.tick_amount=value(state,id,data.tick_scaling)
	if data.has("resource_bonus"):
		var b: Dictionary=data.resource_bonus
		var parts:=fraction(state,id,b)
		result.resource_bonus={"resource":b.resource,"cap_num":parts[0],"cap_den":parts[1],"threshold":value(state,id,b.resource_full_threshold)}
	return result

static func skill(state: Dictionary,id: String) -> Dictionary:
	var source: Dictionary=DamageBudget.normalize(Catalog.SKILLS.get(id,{}))
	if source.is_empty(): return {}
	return materialize(state,str(source.leader),source,int(powers(state).get(id,0)))

static func passive_rule(state: Dictionary,id: String) -> Dictionary:
	return materialize(state,id,Catalog.leader(id).get("passive",{}))

static func sync_poison(state: Dictionary) -> void:
	if not state.has("poison_layers"): state.poison_layers=[]
	while state.poison_layers.size()>int(state.poison): state.poison_layers.pop_back()
	while state.poison_layers.size()<int(state.poison): state.poison_layers.append(35)

static func add_poison(state: Dictionary,count: int,amount: int) -> void:
	sync_poison(state)
	for i in range(mini(count,3-state.poison_layers.size())): state.poison_layers.append(amount)
	state.poison=state.poison_layers.size()

static func consume_poison(state: Dictionary,count: int) -> int:
	sync_poison(state)
	var spent:=mini(count,state.poison_layers.size())
	for i in range(spent): state.poison_layers.pop_front()
	state.poison=state.poison_layers.size()
	return spent

static func poison_damage(state: Dictionary) -> int:
	var total:=0
	if state.get("poison_layers",[]).size()!=int(state.poison): total = int(state.poison)*35
	else:
		for amount in state.get("poison_layers",[]): total+=int(amount)
	if Relics.has(state,"poison_cup") and total > 0: total = maxi(1,total*125/100)
	return total

