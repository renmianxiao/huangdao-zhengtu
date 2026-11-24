extends RefCounted
## Decide once at turn start. Reads and player actions never consume randomness.
const STYLES={
 "wandering_puppet":"balanced","gate_patrol":"bastion","bamboo_swordsman":"duelist","mountain_crossbowman":"sniper","broken_fist_puppet":"berserker",
 "red_sand_guard":"duelist","sun_spearman":"balanced","bronze_crossbow_puppet":"sniper","incense_sorcerer":"occult","stone_brute":"bastion",
 "broken_sword_puppet":"duelist","chain_jailer":"berserker","iron_shield_guard":"bastion","repeating_crossbow":"sniper","seal_sorcerer":"occult",
 "dusk_assassin":"sniper","blood_swordsman":"berserker","lantern_soulguide":"occult","fallen_banner_spirit":"commander","dusk_crow_machine":"sniper",
 "ghost_armored_guard":"bastion","moon_sword_spirit":"duelist","black_lantern_sorcerer":"occult","qi_devouring_machine":"berserker","gate_stone_guard":"bastion",
 "armored_executor":"berserker","bronze_shield_captain":"bastion","red_furnace_commander":"commander","flame_machine_beast":"berserker","black_iron_sword_guard":"duelist","prison_stone_beast":"bastion","red_robed_judge":"occult","night_commander":"commander","black_gate_executioner":"commander","dual_blade_guardian":"duelist",
 "iron_commander":"commander","puppet_master":"puppeteer","soul_judge":"occult","gate_colossus":"commander"
}
const PROFILES={
 "balanced":{"name":"攻守游斗","weights":{"attack":5,"multi":4,"pierce":4,"guard":3,"rest":2,"heavy":5},"low":["attack","multi"],"text":"普通攻击与防守穿插；半血后更偏向连续进攻。"},
 "bastion":{"name":"重甲守势","weights":{"attack":4,"multi":3,"pierce":3,"guard":7,"rest":2,"heavy":5},"low":["guard"],"text":"偏向补甲与重击；护甲充足时减少补甲，半血后更重视防守。"},
 "duelist":{"name":"连刃游斗","weights":{"attack":4,"multi":8,"pierce":3,"guard":2,"rest":3,"heavy":5},"low":["multi"],"text":"偏向连击，穿插架势与重招；半血后更常使用连击。"},
 "sniper":{"name":"远袭穿插","weights":{"attack":5,"multi":5,"pierce":8,"guard":2,"rest":4,"heavy":6},"low":["pierce"],"text":"偏向远程连射与穿透；半血后更常使用穿透攻击。"},
 "occult":{"name":"术印变招","weights":{"attack":3,"multi":3,"pierce":7,"guard":4,"rest":4,"heavy":7},"low":["pierce","heavy"],"text":"穿透、术印防守与蓄势交替；半血后更偏向穿透与重招。"},
 "berserker":{"name":"血战猛攻","weights":{"attack":7,"multi":7,"pierce":5,"guard":2,"rest":2,"heavy":8},"low":["attack","multi","pierce","heavy"],"text":"偏向主动进攻；半血后继续提高攻击招式的选择权重。"},
 "commander":{"name":"战阵压制","weights":{"attack":5,"multi":5,"pierce":4,"guard":5,"rest":3,"heavy":9},"low":["multi","heavy"],"text":"准备后较常接重招；半血后更偏向连击与重招。"},
 "puppeteer":{"name":"千机牵制","weights":{"attack":3,"multi":8,"pierce":4,"guard":5,"rest":5,"heavy":8},"low":["multi","heavy"],"text":"以多段攻击穿插机关防守与收丝；半血后加大多段压制。"}
}
static func profile(id:String)->Dictionary:
 return PROFILES[STYLES[id]].duplicate(true) if STYLES.has(id) else {}
static func description(id:String)->String:
 var data:=profile(id)
 if data.is_empty():return ""
 return "%s：%s\n重招须接在防守或蓄势动作之后，两次重招至少间隔4回合；重招后转入防守或休整。同一招不会连续使用，防守与蓄势也不会连续出现。当前预告在回合开始时锁定。"%[data.name,data.text]
static func _kind(pattern:Dictionary)->String:
 if bool(pattern.get("interruptible",false)):return "heavy"
 if int(pattern.hits)==0:return "guard" if int(pattern.ward)>0 else "rest"
 if pattern.get("piercing",false):return "pierce"
 return "multi" if int(pattern.hits)>1 else "attack"
static func lock_intent(state:Dictionary,fallback:Array)->void:
 var config:Dictionary=state.get("config",{})
 var data:=profile(str(config.get("enemy_id","")))
 if data.is_empty() or state.status!="playing":return
 var patterns:Array=config.get("patterns",fallback)
 if patterns.is_empty():patterns=fallback
 var previous:Dictionary=state.get("enemy_ai",{})
 var last:int=int(previous.get("current_index",-1))
 var last_heavy:int=int(previous.get("last_heavy_round",-99))
 var prior:Dictionary=patterns[last] if last>=0 and last<patterns.size() else {}
 var setup:bool=not prior.is_empty() and int(prior.hits)==0
 var recovery:bool=not prior.is_empty() and bool(prior.interruptible)
 var candidates:Array[int]=[];var weights:Array[int]=[];var total:=0
 for i in range(patterns.size()):
  var pattern:Dictionary=patterns[i]
  var kind:=_kind(pattern)
  if i==last:continue
  if kind=="heavy" and (not setup or int(state.round)-last_heavy<4):continue
  if recovery and int(pattern.hits)>0:continue
  if setup and int(pattern.hits)==0:continue
  var weight:int=int(data.weights.get(kind,1))
  if int(state.enemy_hp)*2<=int(state.enemy_max) and data.low.has(kind):weight*=2
  if kind=="guard":
   if int(state.ward)>=maxi(1,int(state.enemy_max)*12/100):weight=maxi(1,weight/4)
   elif int(state.ward)==0 and int(state.round)>1:weight+=2
  candidates.append(i);weights.append(weight);total+=weight
 # Each production enemy has both an ordinary attack and a preparation move.
 if candidates.is_empty():return
 var ai_seed:int=int(config.get("ai_seed",0))
 var rng:=RandomNumberGenerator.new()
 rng.seed=("%d:%s:%d:enemy-intent"%[ai_seed,str(config.enemy_id),int(state.round)]).hash()
 var roll:=rng.randi_range(1,total)
 var selected:int=candidates[0]
 for j in range(candidates.size()):
  roll-=weights[j]
  if roll<=0:selected=candidates[j];break
 var chosen:Dictionary=patterns[selected].duplicate(true)
 if int(chosen.damage)>0 and state.enraged:chosen.damage+=30
 state.enemy_intent=chosen
 state.enemy_ai={"current_index":selected,"last_heavy_round":int(state.round) if bool(chosen.interruptible) else last_heavy}
