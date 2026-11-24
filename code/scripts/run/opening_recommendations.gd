extends RefCounted
## Optional guidance uses the ordinary invitation sequence and prices.
const Characters=preload("res://code/scripts/characters/character_catalog.gd")
const TEAMS={"steady":["budget_warrior_01","budget_shield_01","budget_healer_01"],"arcane":["mage_01","free_shield_01","free_healer_01"]}
static func current(state:Dictionary)->String:
 var opening:Dictionary=state.get("opening",{})
 var team:Array=TEAMS.get(str(opening.get("bundle","")),[])
 var index:int=int(opening.get("index",0))
 return str(team[index]) if state.get("phase","")=="opening" and index>=0 and index<team.size() else ""
static func describe(bundle:String)->String:
 var parts:Array[String]=[]
 for id:String in TEAMS.get(bundle,[]):parts.append("%s（%d）"%[Characters.leader(id).name,int(Characters.RECRUIT_COSTS[id])])
 return "推荐："+" / ".join(parts)+"，合计3声望。" if not parts.is_empty() else ""
