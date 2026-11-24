extends RefCounted
## Only actual receipts count. Pending battle loot is not an owned resource.
static func gain_gold(state:Dictionary,amount:int)->void:
 state.gold+=amount
 state.earned_gold=int(state.get("earned_gold",0))+maxi(0,amount)
