extends RefCounted
const Orders=preload("res://code/scripts/run/recruit_orders.gd")
const Characters=preload("res://code/scripts/characters/character_catalog.gd")
const Party=preload("res://code/scripts/party.gd")
const BUNDLES := [
	{"id":"steady","name":"稳扎稳打","orders":["战士型","盾牌型","奶妈型"],"text":"攻守相济，稳步前行"},
	{"id":"assault","name":"锋刃突袭","orders":["刺客型","战士型","辅助型"],"text":"短兵快攻，先发制人"},
	{"id":"arcane","name":"术法攻坚","orders":["法师型","盾牌型","奶妈型"],"text":"坚盾护法，持续攻坚"},
	{"id":"chain","name":"疾攻连携","orders":["刺客型","法师型","辅助型"],"text":"奇招配合，灵活制敌"},
	{"id":"wander","name":"游斗续战","orders":["刺客型","奶妈型","辅助型"],"text":"游走周旋，续力再战"},
	{"id":"iron","name":"铁阵推进","orders":["战士型","盾牌型","辅助型"],"text":"列阵压进，护持锋刃"},
	{"id":"fusion","name":"刀法合流","orders":["战士型","法师型","奶妈型"],"text":"兵术兼备，进退有度"},
	{"id":"random","name":"随缘入世","orders":[],"text":"三种随机职业，本局固定"}
]
static func active(run:Dictionary) -> bool:
	return run.get("opening") is Dictionary and not run.opening.is_empty()
static func recruiting(run:Dictionary) -> bool:
	return active(run) and run.phase=="opening" and not str(run.opening.get("bundle","")).is_empty() and int(run.opening.get("index",0))<3
static func ready(run:Dictionary) -> bool:
	return active(run) and run.phase=="formation" and int(run.opening.get("index",0))==3
static func begin(base:Dictionary) -> Dictionary:
	var next:=base.duplicate(true)
	next.merge({"phase":"opening","level":1,"experience":0,"total_experience":0,"renown":3,"roster":[],"team":[],"front_team":[],"back_team":[],"party_slots":Party.slots_for([]),"hp":1,"max_hp":1,"health_num":1,"health_den":1,"opening":{"bundle":"","orders":[],"index":0}},true)
	return next
static func choices(run:Dictionary) -> Array:
	var choices:=BUNDLES.duplicate(true)
	var random_orders:Array=Orders.CLASSES.duplicate()
	var rng:=RandomNumberGenerator.new()
	rng.seed=(str(run.seed)+":opening-orders").hash()
	for i in range(random_orders.size()-1,0,-1):
		var j:=rng.randi_range(0,i)
		var held:String=random_orders[i]
		random_orders[i]=random_orders[j];random_orders[j]=held
	choices[7].orders=random_orders.slice(0,3)
	return choices
static func choose(run:Dictionary,id:String) -> Dictionary:
	if not active(run) or run.phase!="opening" or not run.opening.bundle.is_empty() or run.opening.index!=0: return run
	for bundle:Dictionary in choices(run):
		if bundle.id!=id: continue
		var next:=run.duplicate(true)
		next.opening={"bundle":id,"orders":bundle.orders.duplicate(),"index":0}
		next.pending_recruit_order=bundle.orders[0]
		next.summon_active=true
		return next
	return run
static func back(run:Dictionary) -> Dictionary:
	if not recruiting(run) or run.opening.index!=0: return run
	var next:=run.duplicate(true)
	next.opening={"bundle":"","orders":[],"index":0}
	next.pending_recruit_order="";next.summon_active=false
	return next
static func recruited(run:Dictionary,id:String) -> Dictionary:
	var next:=run.duplicate(true)
	var index:int=next.opening.index
	next.party_slots[index]=id
	next=Party.apply_layout(next,next.party_slots,0)
	next.opening.index=index+1
	if next.opening.index==3:
		next.phase="formation";next.summon_active=false;next.pending_recruit_order=""
		next.draft_team=next.team.duplicate();next.draft_slots=next.party_slots.duplicate()
		next.formation_origin="opening"
	else: next.pending_recruit_order=next.opening.orders[next.opening.index]
	return next
static func valid(run:Dictionary) -> bool:
	if not run.get("opening") is Dictionary:return false
	if not active(run): return run.opening.is_empty() and run.phase!="opening"
	var data:Dictionary=run.opening
	if data.size()!=3 or not data.get("bundle") is String or not data.get("orders") is Array or not data.get("index") is int: return false
	if data.index<0 or data.index>3 or run.phase!=("formation" if data.index==3 else "opening"): return false
	if run.current_node!="" or not run.completed.is_empty() or run.battles!=0 or run.level!=1 or run.experience!=0 or run.total_experience!=0 or run.gold!=0 or run.slot_capacity!=3 or run.hp_bonus!=0: return false
	if not run.relics.is_empty() or not run.upgrades.is_empty() or not run.character_upgrades.is_empty(): return false
	if run.roster.size()!=data.index or run.team!=run.roster or run.party_slots!=Party.slots_for(run.roster): return false
	var spent:=0
	for i in range(run.roster.size()):
		var id:String=run.roster[i]
		if not Characters.RECRUIT_COSTS.has(id) or data.orders.size()!=3 or Orders.profession(id)!=data.orders[i]: return false
		spent+=int(Characters.RECRUIT_COSTS[id])
	if run.renown!=3-spent or run.hp!=run.max_hp or run.health_num!=run.health_den: return false
	if data.bundle.is_empty(): return data.index==0 and data.orders.is_empty() and not run.summon_active and run.pending_recruit_order.is_empty()
	var matched:=false
	for choice:Dictionary in choices(run):
		if choice.id==data.bundle and choice.orders==data.orders: matched=true
	if not matched: return false
	return (not run.summon_active and run.pending_recruit_order.is_empty()) if data.index==3 else (run.summon_active and run.pending_recruit_order==data.orders[data.index])
