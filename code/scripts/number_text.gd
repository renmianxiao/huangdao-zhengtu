extends RefCounted
## Presentation only: gameplay values retain their original precision.
static var _decimals: RegEx

static func integer(value: float) -> String:
	return str(roundi(value))

static func description(text: String) -> String:
	if _decimals == null:
		_decimals = RegEx.new()
		_decimals.compile("[0-9]+\\.[0-9]+")
	var matches := _decimals.search_all(text)
	# Replace backwards so offsets and rich-text markup remain intact.
	for index in range(matches.size() - 1, -1, -1):
		var found: RegExMatch = matches[index]
		var start := found.get_start()
		var end := found.get_end()
		var value := float(found.get_string())
		var shown := integer(value)
		if start > 0 and text.substr(start - 1, 1) == "×":
			start -= 1
			shown = "的%s%%" % integer(value * 100.0)
		elif text.substr(end, 1) == "倍":
			end += 1
			shown = "%s%%" % integer(value * 100.0)
		text = text.substr(0, start) + shown + text.substr(end)
	return text
