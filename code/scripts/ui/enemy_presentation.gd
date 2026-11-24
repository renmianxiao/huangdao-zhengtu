extends RefCounted
## Art direction only. Normalized focal boxes were checked against all 39 PNGs.
## A named boss can still have a group painting: preserve its accompanying figures.
## Values describe the central head/face, not a gameplay target or hit box.
const PROFILES := {
	"armored_executor": ["group", Rect2(0.43, 0.07, 0.17, 0.30)],
	"bamboo_swordsman": ["group", Rect2(0.42, 0.15, 0.17, 0.31)],
	"black_gate_executioner": ["group", Rect2(0.42, 0.07, 0.18, 0.30)],
	"black_iron_sword_guard": ["group", Rect2(0.40, 0.07, 0.19, 0.29)],
	"black_lantern_sorcerer": ["group", Rect2(0.41, 0.14, 0.16, 0.29)],
	"blood_swordsman": ["group", Rect2(0.42, 0.16, 0.16, 0.28)],
	"broken_fist_puppet": ["group", Rect2(0.41, 0.08, 0.17, 0.30)],
	"broken_sword_puppet": ["group", Rect2(0.44, 0.11, 0.16, 0.30)],
	"bronze_crossbow_puppet": ["group", Rect2(0.425, 0.10, 0.145, 0.29)],
	"bronze_shield_captain": ["group", Rect2(0.47, 0.15, 0.085, 0.18)],
	"chain_jailer": ["group", Rect2(0.40, 0.13, 0.16, 0.30)],
	"dual_blade_guardian": ["group", Rect2(0.43, 0.10, 0.17, 0.29)],
	"dusk_assassin": ["group", Rect2(0.43, 0.21, 0.17, 0.25)],
	"dusk_crow_machine": ["group", Rect2(0.39, 0.23, 0.20, 0.27)],
	"fallen_banner_spirit": ["group", Rect2(0.43, 0.16, 0.17, 0.28)],
	"flame_machine_beast": ["group", Rect2(0.38, 0.12, 0.22, 0.32)],
	"gate_colossus": ["solo", Rect2(0.48, 0.07, 0.19, 0.30)],
	"gate_patrol": ["group", Rect2(0.42, 0.10, 0.17, 0.28)],
	"gate_stone_guard": ["group", Rect2(0.42, 0.12, 0.19, 0.30)],
	"ghost_armored_guard": ["group", Rect2(0.43, 0.09, 0.18, 0.30)],
	"incense_sorcerer": ["group", Rect2(0.41, 0.15, 0.16, 0.29)],
	"iron_commander": ["solo", Rect2(0.465, 0.09, 0.10, 0.19)],
	"iron_shield_guard": ["group", Rect2(0.43, 0.09, 0.17, 0.29)],
	"lantern_soulguide": ["group", Rect2(0.41, 0.12, 0.18, 0.30)],
	"moon_sword_spirit": ["group", Rect2(0.41, 0.21, 0.17, 0.26)],
	"mountain_crossbowman": ["group", Rect2(0.39, 0.10, 0.21, 0.31)],
	"night_commander": ["solo", Rect2(0.41, 0.07, 0.18, 0.31)],
	"prison_stone_beast": ["group", Rect2(0.43, 0.10, 0.19, 0.33)],
	"puppet_master": ["solo", Rect2(0.48, 0.10, 0.19, 0.34)],
	"qi_devouring_machine": ["group", Rect2(0.39, 0.20, 0.24, 0.32)],
	"red_furnace_commander": ["group", Rect2(0.44, 0.06, 0.19, 0.30)],
	"red_robed_judge": ["solo", Rect2(0.39, 0.07, 0.19, 0.29)],
	"red_sand_guard": ["group", Rect2(0.42, 0.16, 0.16, 0.29)],
	"repeating_crossbow": ["group", Rect2(0.41, 0.15, 0.20, 0.32)],
	"seal_sorcerer": ["group", Rect2(0.41, 0.13, 0.17, 0.30)],
	"soul_judge": ["solo", Rect2(0.46, 0.16, 0.19, 0.30)],
	"stone_brute": ["group", Rect2(0.40, 0.10, 0.20, 0.33)],
	"sun_spearman": ["group", Rect2(0.43, 0.13, 0.17, 0.29)],
	"wandering_puppet": ["group", Rect2(0.42, 0.20, 0.18, 0.30)],
}

static func profile(enemy_id: String) -> Dictionary:
	var entry: Array = PROFILES.get(enemy_id, ["group", Rect2(0.40, 0.12, 0.20, 0.32)])
	var group := str(entry[0]) == "group"
	return {
		"composition": entry[0], "focus": entry[1],
		"width": 0.82 if group else 0.72,
		"side_feather": 0.055 if group else 0.10,
		"top": 0.035 if group else 0.018,
	}
