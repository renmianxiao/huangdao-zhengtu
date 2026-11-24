extends RefCounted
## Plain damage uses its catalog AP cost; fatigue and discounts never alter it.
const SKILL_KEYS=["leader","name","cost","type","text","rules","effects"]
const EFFECT_KEYS=["op","scaling","hits"]
const SCALING_KEYS=["basis","coefficient","numerator","denominator"]
static func is_plain(skill: Dictionary) -> bool:
	if not skill.get("cost") is int or skill.cost<0 or not skill.get("effects") is Array or skill.effects.is_empty():return false
	if not str(skill.get("rules","")).is_empty():return false
	for key in skill:
		if not key in SKILL_KEYS:return false
	for value in skill.effects:
		if not value is Dictionary or not value.get("op","") in ["damage","multi_damage"]:return false
		for key in value:
			if not key in EFFECT_KEYS:return false
		if not value.get("scaling") is Dictionary:return false
		var scaling: Dictionary=value.scaling
		if scaling.get("basis","")!="actor_attack" or int(scaling.get("denominator",100))<=0:return false
		for key in scaling:
			if not key in SCALING_KEYS:return false
		if _coefficient(scaling)<=0:return false
	return true
static func _coefficient(scaling: Dictionary) -> float:
	return float(scaling.get("numerator",roundi(float(scaling.get("coefficient",0))*100)))/float(scaling.get("denominator",100))
static func numerator(base_ap: int) -> int:
	return 100 if base_ap==0 else base_ap*100+50
static func normalize(skill: Dictionary) -> Dictionary:
	if not is_plain(skill):return skill
	var next:=skill.duplicate(true);var total:=0.0;var hits:=0
	for effect: Dictionary in skill.effects:
		total+=_coefficient(effect.scaling)
		hits+=maxi(1,int(effect.get("hits",2))) if effect.op=="multi_damage" else 1
	var budget:=numerator(int(skill.cost));var remaining:=budget
	for index in range(next.effects.size()):
		var effect: Dictionary=next.effects[index]
		var amount:=remaining if index==next.effects.size()-1 else clampi(roundi(float(budget)*_coefficient(effect.scaling)/total),0,remaining)
		remaining-=amount
		effect.scaling={"basis":"actor_attack","coefficient":float(amount)/100.0,"numerator":amount,"denominator":100}
	var shown:=str(budget/100) if budget%100==0 else "%.1f"%(float(budget)/100.0)
	next.text=("造成自身攻击力×%s伤害。"%shown) if hits==1 else ("分%d段造成总计自身攻击力×%s伤害。"%[hits,shown])
	return next
