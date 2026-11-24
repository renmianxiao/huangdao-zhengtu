extends RefCounted
## Presentation-only events in settlement order. Battle replaces this batch on
## every accepted command; rejected commands keep their original state identity.
static func emit(state: Dictionary, kind: String, target: String, amount: int, origin: Dictionary = {}, absorbed: int = 0, piercing: bool = false, allow_zero: bool = false) -> void:
	if amount <= 0 and absorbed <= 0 and not allow_zero: return
	if not state.has("feedback"): state.feedback = []
	state.feedback.append({
		"kind": kind, "target": target, "amount": maxi(0, amount),
		"absorbed": maxi(0, absorbed), "source": str(origin.get("source", "")),
		"skill": str(origin.get("skill", "")), "name": str(origin.get("name", "")),
		"piercing": piercing,
	})

static func shield_gain(state: Dictionary, before: int, origin: Dictionary) -> void:
	emit(state, "shield", "team", mini(int(state.max_hp), int(state.shield)) - before, origin)