extends RefCounted
## Run the same pure commands on a snapshot; never emit live combat feedback.
const Battle=preload("res://code/scripts/battle.gd")
static func skill(state:Dictionary,id:String)->Dictionary:
 if not Battle.action_reason(state,id).is_empty():return {}
 return _result(state,Battle.act(state.duplicate(true),id))
static func end_turn(state:Dictionary)->Dictionary:
 if state.status!="playing":return {}
 return _result(state,Battle.end_round(state.duplicate(true)))
static func _result(before:Dictionary,after:Dictionary)->Dictionary:
 var incoming:=0
 var absorbed:=0
 var healing:=0
 for event:Dictionary in after.get("feedback",[]):
  if event.target=="team" and event.kind=="damage":incoming+=int(event.amount);absorbed+=int(event.absorbed)
  if event.target=="team" and event.kind=="heal":healing+=int(event.amount)
 return {"incoming":incoming,"absorbed":absorbed,"healing":healing,"after":after,"enemy_loss":int(before.enemy_hp)-int(after.enemy_hp),"hp_change":int(after.hp)-int(before.hp),"ap":int(after.ap),"shield":int(after.shield)}
static func describe(value:Dictionary,ending:bool=false)->String:
 if value.is_empty():return ""
 var after:Dictionary=value.after
 var parts:Array[String]=["回合结算预览" if ending else "施放预览"]
 if value.enemy_loss>0:parts.append("敌方生命 -%d"%value.enemy_loss)
 if ending:
  parts.append("承伤 %d / 挡下 %d / 回复 %d"%[value.incoming,value.absorbed,value.healing])
 if not ending and after.get("interrupted",false):parts.append("敌方行动已打断")
 if value.hp_change!=0:parts.append("我方生命 %+d"%value.hp_change)
 elif ending:parts.append("我方生命不变")
 parts.append("结算后 AP %d"%value.ap)
 if not ending and value.shield>0:parts.append("护盾 %d"%value.shield)
 if after.status=="won":parts.append("击败敌人")
 elif after.status=="lost":parts.append("我方战败")
 return " · ".join(parts)
