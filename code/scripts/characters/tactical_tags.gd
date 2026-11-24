extends RefCounted
const Characters=preload("res://code/scripts/characters/character_catalog.gd")
const Budget=preload("res://code/scripts/combat/damage_budget.gd")
const FILTERS=["直伤","爆发","持续伤害","反击","破甲","续航","护盾","减伤","打断","增伤","AP调度"]
static func for_character(id:String)->Array[String]:
 var leader:Dictionary=Characters.leader(id)
 var found:Dictionary={}
 for skill_id in leader.get("skills",[]):
  var skill:Dictionary=Budget.normalize(Characters.SKILLS[skill_id])
  for effect:Dictionary in skill.get("effects",[]):
   var op:String=effect.op
   var tag:String={"damage":"直伤","multi_damage":"直伤","poison_add":"持续伤害","poison_consume":"持续伤害","counter":"反击","armor_remove":"破甲","heal":"续航","regen":"续航","overheal":"护盾","shield":"护盾","carry_shield":"护盾","percent_guard":"减伤","flat_guard":"减伤","interrupt":"打断","buff":"增伤","class_buff":"增伤","delayed_buff":"增伤","mark":"增伤","ap_restore":"AP调度","discount":"AP调度"}.get(op,"")
   if not tag.is_empty():found[tag]=true
   if op in ["damage","multi_damage"] and int(skill.cost)>=3:found["爆发"]=true
 var passive:Dictionary=leader.get("passive",{})
 var kind:String=str(passive.get("kind",""))
 var passive_tags:Dictionary={"attack_if":["直伤"],"first_attack":["直伤"],"flat_first_hit":["减伤"],"percent_guard":["减伤"],"after_shield_hp_damage":["续航"],"shield_after_poison_consumption":["护盾"],"own_heal_if":["续航"],"own_flat_guard_if":["减伤"],"first_heal_if":["续航"],"own_shield_if":["护盾"],"regen_if":["续航"],"first_heal_shield":["护盾"]}
 for tag:String in passive_tags.get(kind,[]):found[tag]=true
 var result:Array[String]=[]
 for tag:String in FILTERS:
  if found.has(tag):result.append(tag)
 return result
static func matches(id:String,tier:int,tag:String)->bool:
 return (tier<0 or int(Characters.RECRUIT_COSTS[id])==tier) and (tag.is_empty() or for_character(id).has(tag))
