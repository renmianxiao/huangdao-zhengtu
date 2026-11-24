extends RefCounted

const Party = preload("res://code/scripts/party.gd")
const Relics = preload("res://code/scripts/relics/relic_catalog.gd")
const MAX_LEVEL := 10
const LEVEL_XP := [20, 40, 70, 75, 85, 95, 105, 115, 130]

const RENOWN_PER_LEVEL := 3
const SLOT_LEVELS := [4, 8]
const VICTORY_XP := {"battle": 20, "elite": 40, "midboss": 80, "boss": 100}

static func xp_to_next(level: int) -> int:
	return 0 if level >= MAX_LEVEL else int(LEVEL_XP[clampi(level,1,MAX_LEVEL-1)-1])

static func award_victory(run: Dictionary, kind: String) -> Dictionary:
	if not VICTORY_XP.has(kind): return run
	var earned: int = VICTORY_XP[kind]
	var bonus := (20 if Relics.has(run,"study_notes") else 0) + (30 if kind == "elite" and Relics.has(run,"tactics_scroll") else 0)
	return award_experience(run,maxi(1,floori(float(earned)*(100+bonus)/100.0)))

static func award_experience(run: Dictionary, earned: int) -> Dictionary:
	if earned <= 0: return run
	var next: Dictionary = run.duplicate(true)
	next.experience += earned
	next.total_experience += earned
	next.last_progression = {"experience": earned, "from_level": next.level, "to_level": next.level, "renown": 0, "slots": 0}
	while next.level < MAX_LEVEL and next.experience >= xp_to_next(int(next.level)):
		next.experience -= xp_to_next(int(next.level))
		next.level += 1
		var renown := RENOWN_PER_LEVEL + (1 if Relics.has(next,"cinnabar_commentary") else 0)
		next.renown += renown
		next.last_progression.renown += renown
		if SLOT_LEVELS.has(next.level):
			var previous_slots: int = next.slot_capacity
			next.slot_capacity = mini(Party.MAX_SIZE, previous_slots + 1)
			next.last_progression.slots += next.slot_capacity - previous_slots
	next.last_progression.to_level = next.level
	return next

