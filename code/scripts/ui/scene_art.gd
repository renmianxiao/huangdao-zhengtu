extends RefCounted
## Where node pages find their scenery. Dedicated paintings dropped into
## art/scenes/ win automatically; otherwise the floor's cinematic stands in.
##   art/scenes/camp.png, art/scenes/shop.png
##   art/scenes/events/<event id>.png, then art/scenes/events/<category>.png

static func illustration(kind: String, event_id: String = "", category: String = "") -> String:
	var candidates: Array[String] = []
	if kind == "event":
		if event_id.is_valid_identifier(): candidates.append("res://art/scenes/events/%s.png" % event_id)
		if category.is_valid_identifier(): candidates.append("res://art/scenes/events/%s.png" % category)
	elif kind.is_valid_identifier():
		candidates.append("res://art/scenes/%s.png" % kind)
	for path in candidates:
		if ResourceLoader.exists(path): return path
	return ""

static func backdrop(kind: String, floor_number: int, event_id: String = "", category: String = "") -> String:
	var dedicated := illustration(kind, event_id, category)
	return dedicated if not dedicated.is_empty() else "res://art/cinematics/floor_%d.png" % clampi(floor_number, 1, 5)

## Each event has its own emblem (art/events/<id>.svg, drawn by
## code/tools/build_event_emblems.py), set over the floor cinematic whose place
## best matches its story until a dedicated painting replaces both.
const EVENT_SCENES := {
	"purse": 3, "apothecary": 2, "village": 1, "gamble": 5, "merchant": 1, "exchange": 5,
	"inscription": 3, "cache": 5, "bounty": 1, "escort": 4, "guardian": 4, "wounded": 2}

static func event_emblem(event_id: String, fallback: String) -> String:
	var path := "res://art/events/%s.svg" % event_id
	return path if event_id.is_valid_identifier() and ResourceLoader.exists(path) else fallback

static func event_scene(event_id: String) -> String:
	return "res://art/cinematics/floor_%d.png" % int(EVENT_SCENES.get(event_id, 1))
