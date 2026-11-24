extends RefCounted
const Statistics=preload("res://code/scripts/run/run_statistics.gd")
const Catalog=preload("res://code/scripts/run/event_catalog.gd")
const Seeds=preload("res://code/scripts/run/run_catalog.gd")
const Relics=preload("res://code/scripts/relics/relic_catalog.gd")
const Resources=preload("res://code/scripts/relics/relic_run.gd")
const Pool=preload("res://code/scripts/relics/relic_pool.gd")
const Party=preload("res://code/scripts/party.gd")
static func category(id: String) -> String:return str(Catalog.EVENTS.get(id,{}).get("category",""))
static func rng(state: Dictionary,purpose: String) -> RandomNumberGenerator:
	var random:=RandomNumberGenerator.new();random.seed=Seeds.seed_for(int(state.seed),str(state.current_node),"event-"+purpose);return random
static func available(state: Dictionary) -> Array:
	var all: Array=[];var unseen: Array=[]
	for id: String in Catalog.EVENTS:
		if id=="guardian" and int(Resources.current_node(state).get("floor",1))==1:continue
		all.append(id)
		if not state.get("seen_events",[]).has(id):unseen.append(id)
	return unseen if not unseen.is_empty() else all
static func prepare(state: Dictionary) -> Dictionary:
	var candidates:=available(state);var groups: Dictionary={};var total:=0
	for group: String in Catalog.WEIGHTS:
		var members: Array=[]
		for id: String in candidates:
			if category(id)==group:members.append(id)
		if not members.is_empty():groups[group]=members;total+=int(Catalog.WEIGHTS[group])
	var random:=rng(state,"selection");var roll:=random.randi_range(0,total-1)
	for group: String in groups:
		roll-=int(Catalog.WEIGHTS[group])
		if roll<0:return build(state,str(groups[group][random.randi_range(0,groups[group].size()-1)]))
	return {}
static func draw(state: Dictionary,price: int,count: int,purpose: String) -> Array:
	var candidates:=Pool.candidates(state,price);var result: Array=[];var random:=rng(state,purpose)
	for i in range(count):
		if candidates.is_empty():
			result.append({"key":"gold:%d"%price,"id":"","price":price});break
		var index:=random.randi_range(0,candidates.size()-1);var id: String=candidates.pop_at(index)
		result.append({"key":id,"id":id,"price":price})
	return result
static func build(state: Dictionary,id: String) -> Dictionary:
	if not Catalog.EVENTS.has(id):return {}
	var data:={}
	match id:
		"purse":data.gold=rng(state,id).randi_range(4,6)
		"gamble":data.win=rng(state,id).randi_range(0,99)<60
		"merchant":data.offer8=draw(state,8,1,id+"8")[0];data.offer12=draw(state,12,1,id+"12")[0]
		"inscription","wounded":data.offer12=draw(state,12,1,id+"12")[0]
		"escort","guardian":data.combat_reward=draw(state,int(Catalog.FIGHTS[id].relic),1,"combat-relic")[0]
		"cache":data.offers8=draw(state,8,2,id)
		"exchange":
			data.swaps={}
			for source: String in Relics.ids(state):
				var price:=int(Relics.definition(source).price)
				data.swaps[source]={"same":draw(state,price,2,id+source),"higher":draw(state,price+4,2,id+source+"higher") if price<16 else []}
	return {"event":id,"mode":"choice","data":data,"source":"","higher":false,"outcome":"","battle_choice":""}
static func reward_valid(value: Variant,price: int) -> bool:
	if not value is Dictionary or value.size()!=3 or not value.get("key") is String or not value.get("id") is String or not value.get("price") is int or value.price!=price:return false
	if value.id.is_empty():return value.key=="gold:%d"%price
	return value.key==value.id and Relics.definition(value.id).get("price",0)==price
static func rewards_valid(values: Variant,price: int) -> bool:
	if not values is Array or values.is_empty() or values.size()>2:return false
	var seen:={}
	for value in values:
		if not reward_valid(value,price) or seen.has(value.key):return false
		seen[value.key]=true
	return true
static func valid(state: Dictionary) -> bool:
	var value: Variant=state.get("node_state")
	if not value is Dictionary or value.size()!=7:return false
	if not value.get("event") is String or not Catalog.EVENTS.has(value.event):return false
	if Resources.current_node(state).get("type","")!="event":return false
	if value.event=="guardian" and int(Resources.current_node(state).floor)==1:return false
	if not value.get("mode") in ["choice","exchange","result","battle"] or not value.get("data") is Dictionary:return false
	if not value.get("source") is String or not value.get("higher") is bool or not value.get("outcome") is String or value.outcome.length()>4096 or not value.get("battle_choice") is String:return false
	var data: Dictionary=value.data
	if data.has("awarded"):
		if value.mode!="result" or not data.awarded is Array or data.awarded.is_empty() or data.awarded.size()>2:return false
		for gift in data.awarded:
			if not gift is Dictionary or not gift.get("price") is int or not gift.price in [8,12,16] or not reward_valid(gift,int(gift.price)):return false
	match str(value.event):
		"purse":
			if not data.get("gold") is int or data.gold<4 or data.gold>6:return false
		"gamble":
			if not data.get("win") is bool:return false
		"merchant":
			if not reward_valid(data.get("offer8"),8) or not reward_valid(data.get("offer12"),12):return false
		"inscription","wounded":
			if not reward_valid(data.get("offer12"),12):return false
		"escort","guardian":
			if not reward_valid(data.get("combat_reward"),int(Catalog.FIGHTS[value.event].relic)):return false
		"cache":
			if not rewards_valid(data.get("offers8"),8):return false
		"exchange":
			if not data.get("swaps") is Dictionary or data.swaps.size()>50:return false
			for source in data.swaps:
				var relic:=Relics.definition(str(source))
				if relic.is_empty() or not data.swaps[source] is Dictionary:return false
				var offers: Dictionary=data.swaps[source];var price:=int(relic.price)
				if not rewards_valid(offers.get("same"),price) or not offers.get("higher") is Array:return false
				if price<16 and not rewards_valid(offers.higher,price+4):return false
				if price==16 and not offers.higher.is_empty():return false
	if value.mode=="exchange" and (value.event!="exchange" or not Relics.has(state,value.source) or not data.swaps.has(value.source)):return false
	if value.mode=="exchange" and value.higher and int(Relics.definition(value.source).price)>=16:return false
	if value.mode=="battle" and (not Catalog.FIGHTS.has(value.event) or value.battle_choice!="fight"):return false
	return true
static func is_battle(state: Dictionary) -> bool:
	return state.get("phase","") in ["battle","reward","lost"] and valid(state) and state.node_state.mode=="battle"
static func battle_spec(state: Dictionary) -> Dictionary:
	return Catalog.FIGHTS.get(str(state.node_state.get("event","")),{}).duplicate(true) if valid(state) and state.node_state.mode=="battle" else {}
static func describe(reward: Dictionary) -> String:
	if str(reward.id).is_empty():return "无可用同档藏品，改为获得 %d 金币"%int(reward.price)
	var item:=Relics.definition(reward.id)
	return "「%s」 · %d金币档\n%s"%[item.name,item.price,item.effect]
static func _target(state: Dictionary,key: String) -> Dictionary:
	var data: Dictionary=state.node_state
	if not data.data.get("swaps",{}).has(data.source):return {}
	var list: Array=data.data.swaps[data.source].higher if data.higher else data.data.swaps[data.source].same
	for item: Dictionary in list:
		if item.key==key:return item
	return {}
static func reason(state: Dictionary,action: String,source: String="",target: String="") -> String:
	if state.get("phase","")!="node" or not valid(state) or state.completed.has(state.current_node):return "当前事件不可操作"
	var node: Dictionary=state.node_state;var id: String=node.event
	if action=="continue":return "" if node.mode=="result" else "尚未处理事件"
	if node.mode=="result" or node.mode=="battle":return "事件已经处理"
	if action=="back":return "" if node.mode=="exchange" else "未选择置换方式"
	if node.mode=="exchange":
		if action!="swap" or source!=node.source:return "请确认当前置换"
		var item:=_target(state,target)
		if item.is_empty():return "请选择一份置换结果"
		if node.higher and state.gold<3:return "金币不足"
		return "" if str(item.id).is_empty() or Pool.eligible(state,item.id) else "藏品已持有或无法获得"
	if action=="leave":return ""
	if id=="exchange":
		if not action in ["same","higher"] or not Relics.has(state,source) or not node.data.swaps.has(source):return "请选择持有的藏品"
		if action=="higher" and int(Relics.definition(source).price)==16:return "已是最高档位"
		if action=="higher" and state.gold<3:return "金币不足"
		return ""
	if not Catalog.EVENTS[id].actions.has(action):return "无此选项"
	var cost:=0
	if id=="apothecary":
		cost=4
		if state.hp>=state.max_hp:return "生命已满"
	elif id=="village":cost=4 if action=="donate4" else 2
	elif id=="gamble":cost=3
	elif id=="merchant":cost=6 if action=="buy8" else 9
	elif id=="escort":cost=2
	elif id=="wounded" and action=="heal":cost=6
	if id=="cache" and action=="gift1" and node.data.offers8.size()<2:return "没有第二份藏品"
	var gift: Dictionary={}
	if id=="merchant":gift=node.data.offer8 if action=="buy8" else node.data.offer12
	elif id=="inscription" or (id=="wounded" and action=="heal"):gift=node.data.offer12
	elif id=="cache" and action in ["gift0","gift1"]:gift=node.data.offers8[0 if action=="gift0" else 1]
	if not gift.is_empty() and not str(gift.id).is_empty() and not Pool.eligible(state,gift.id):return "藏品已持有或无法获得"
	if state.gold<cost:return "金币不足"
	if id=="inscription" and state.hp<=ceili(state.max_hp*.15):return "生命不足，参悟会导致战败"
	return ""
static func _grant(state: Dictionary,reward: Dictionary) -> Dictionary:
	state.node_state.data.awarded=[reward.duplicate(true)]
	if str(reward.id).is_empty():Statistics.gain_gold(state,int(reward.price));return state
	state.relics=Relics.ids(state);state.relics.append(str(reward.id))
	return Party.apply_layout(state,state.party_slots,int(state.hp_bonus))
static func choose(state: Dictionary,action: String,source: String="",target: String="") -> Dictionary:
	if not reason(state,action,source,target).is_empty():return state
	var next:=state.duplicate(true);var node: Dictionary=next.node_state;var id: String=node.event
	if action in ["leave","continue"]:node.mode="done";return next
	if action=="back":node.mode="choice";node.source="";node.higher=false;return next
	if id=="exchange":
		if action in ["same","higher"]:node.mode="exchange";node.source=source;node.higher=action=="higher";return next
		var item:=_target(next,target);next.relics=Relics.ids(next);next.relics.erase(source)
		if node.higher:next.gold-=3
		next=_grant(next,item);next=Party.apply_layout(next,next.party_slots,int(next.hp_bonus))
		next.node_state.outcome="交出「%s」%s。\n获得：%s"%[Relics.definition(source).name,"，支付3金币" if node.higher else "",describe(item)]
	elif action=="fight":
		next.gold-=int(Catalog.FIGHTS[id].cost);node.mode="battle";node.battle_choice="fight";return next
	else:
		match id:
			"purse":
				if action=="take":Statistics.gain_gold(next,int(node.data.gold));node.outcome="收下钱囊，获得 %d 金币。"%int(node.data.gold)
				else:next.renown+=2;node.outcome="失主郑重道谢，声望 +2。"
			"apothecary":
				next.gold-=4;var before: int=next.hp;next.hp=mini(next.max_hp,next.hp+floori(next.max_hp*.5));Party.record_health(next)
				node.outcome="支付4金币，恢复 %d 生命。"%(next.hp-before)
			"village":
				next.gold-=4 if action=="donate4" else 2;next.renown+=3 if action=="donate4" else 1
				node.outcome="乡邻感激相助，获得 %d 声望。"%(3 if action=="donate4" else 1)
			"gamble":
				next.gold-=3
				if node.data.win:Statistics.gain_gold(next,7)
				node.outcome="押注3金币，拿回7金币，净赚4金币。" if node.data.win else "押注落空，失去3金币。"
			"merchant","inscription","cache","wounded":
				var item: Dictionary={};var prefix:=""
				if id=="merchant":
					var cost:=6 if action=="buy8" else 9;next.gold-=cost;item=node.data.offer8 if action=="buy8" else node.data.offer12;prefix="支付 %d 金币。\n"%cost
				elif id=="inscription":
					var cost:=ceili(next.max_hp*.15);next.hp-=cost;Party.record_health(next);item=node.data.offer12;prefix="参悟损失 %d 生命。\n"%cost
				elif id=="wounded":next.gold-=6;item=node.data.offer12;prefix="支付6金币救治高手。\n"
				elif action=="cash":Statistics.gain_gold(next,5);node.outcome="取走碎银，获得5金币。"
				else:
					var index:=0 if action=="gift0" else 1
					if index>=node.data.offers8.size():return state
					item=node.data.offers8[index]
				if not item.is_empty():next=_grant(next,item);next.node_state.outcome=prefix+"获得："+describe(item)
	next.node_state.mode="result"
	return next