extends RefCounted
## The reference uses compact gold enamel squares, with a readable black silhouette.
static var _textures: Dictionary = {}

static func for_class(role_class: String) -> Texture2D:
	var kind := "sword"
	if "游侠" in role_class or role_class.to_lower() in ["ranger", "archer"]:
		kind = "bow"
	elif "刺客" in role_class or role_class.to_lower() == "assassin":
		kind = "dagger"
	elif "盾" in role_class or role_class == "守卫" or role_class.to_lower() in ["guardian", "shield"]:
		kind = "shield"
	elif "奶妈" in role_class or "治疗" in role_class or role_class == "医师" or role_class.to_lower() == "healer":
		kind = "heart"
	elif "法师" in role_class or role_class == "方士" or role_class.to_lower() == "mage":
		kind = "flame"
	elif "辅助" in role_class or role_class == "谋士" or role_class.to_lower() == "support":
		kind = "fan"
	return _texture(kind)

static func for_skill(skill: Dictionary) -> Texture2D:
	if skill.get("type", "") == "passive": return passive()
	for operation in skill.get("effects", []):
		if not operation is Dictionary: continue
		match str(operation.get("op", "")):
			"damage", "multi_damage": return _texture(_attack_kind(skill))
			"heal", "overheal", "regen": return _texture("heart")
			"shield", "flat_guard", "percent_guard", "carry_shield", "counter": return _texture("shield")
			"poison_add", "poison_consume": return _texture("flame")
			"buff", "class_buff", "delayed_buff", "discount", "ap_restore", "mark": return _texture("fan")
	if skill.has("damage"): return _texture(_attack_kind(skill))
	if skill.has("heal"): return _texture("heart")
	if skill.has("shield"): return _texture("shield")
	return _texture(_attack_kind(skill))

static func passive() -> Texture2D:
	return _texture("passive")

static func help() -> Texture2D:
	return _texture("help")

static func _attack_kind(skill: Dictionary) -> String:
	var owner := str(skill.get("leader", "")).to_lower()
	if owner == "ranger" or "archer" in owner: return "bow"
	if "mage" in owner: return "flame"
	if "assassin" in owner: return "dagger"
	return "sword"

static func _texture(kind: String) -> Texture2D:
	if _textures.has(kind): return _textures[kind]
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><defs><linearGradient id="gold" x1="0" y1="0" x2=".3" y2="1"><stop stop-color="#ffeb63"/><stop offset=".6" stop-color="#ffd523"/><stop offset="1" stop-color="#e6a900"/></linearGradient></defs><rect x=".5" y=".5" width="31" height="31" rx="1.2" fill="#3b2c10" stroke="#8c6721"/><rect x="1.5" y="1.5" width="29" height="29" rx=".6" fill="url(#gold)" stroke="#ffe579"/><path d="M3 11V3H12 M29 22V29H21" fill="none" stroke="#fff0a5" stroke-opacity=".65" stroke-width=".8"/><g fill="#08100f" stroke-linecap="round" stroke-linejoin="round">' + _silhouette(kind) + '</g></svg>'
	var image := Image.new()
	var result := image.load_svg_from_string(svg, 2.0)
	if result != OK: return null
	var texture := ImageTexture.create_from_image(image)
	_textures[kind] = texture
	return texture

static func _silhouette(kind: String) -> String:
	match kind:
		"sword":
			return '<path d="M7 4L16 5L21 16L17 20L7 11Z"/><path d="M15 17L18 14L28 25L25 28Z"/><path d="M13 22L22 13" fill="none" stroke="#08100f" stroke-width="3.5"/><path d="M8 5L16 14" fill="none" stroke="#ffd52c" stroke-width="1.3"/>'
		"dagger":
			return '<path d="M25 4L23 16L17 21L12 16Z"/><path d="M13 16L7 24L10 27L18 19Z"/><path d="M9 15L19 25" fill="none" stroke="#08100f" stroke-width="3"/><path d="M24 6L16 17" fill="none" stroke="#ffd52c" stroke-width="1.2"/>'
		"bow":
			return '<path d="M8 4Q30 16 8 28M8 4L15 16L8 28" fill="none" stroke="#08100f" stroke-width="2.2"/><path d="M4 24L25 7M20 7L26 6L25 12" fill="none" stroke="#08100f" stroke-width="2.2"/><path d="M4 21L7 24L7 28" fill="none" stroke="#08100f" stroke-width="1.7"/>'
		"shield":
			return '<path d="M16 3L27 7L26 18Q25 25 16 29Q7 25 6 18L5 7Z"/><path d="M16 6L23 9L22 18Q21 22 16 25Z" fill="#ffd52c"/><path d="M16 6V25" fill="none" stroke="#ffd52c" stroke-width="1.2"/>'
		"heart":
			return '<path d="M16 28C12 23 4 18 4 11C4 4 12 1 16 8C20 1 28 4 28 11C28 18 20 23 16 28Z"/>'
		"flame":
			return '<path d="M16 3C19 11 11 12 16 17C17 12 23 11 23 6C30 17 28 28 17 29C6 29 3 19 9 11C8 18 11 17 11 19C9 11 17 9 16 3Z"/><path d="M16 19C19 22 19 24 17 27C12 27 12 23 16 19Z" fill="#ffd52c"/>'
		"fan":
			return '<path d="M16 27L3 13Q16 -3 29 13Z"/><path d="M16 26L8 11M16 26L13 8M16 26L19 8M16 26L25 11" fill="none" stroke="#ffd52c" stroke-width="1"/><circle cx="16" cy="27" r="2"/>'
		"passive":
			return '<path d="M24 10A10 10 0 1 0 26 19" fill="none" stroke="#08100f" stroke-width="3"/><path d="M24 3L26 12L17 11Z"/><path d="M15 8L12 17L17 17L14 25L22 14L17 14L20 8Z"/>'
		"help":
			return '<path d="M10 11C10 4 24 4 23 12C22 16 16 16 16 21" fill="none" stroke="#08100f" stroke-width="4"/><circle cx="16" cy="26" r="2.2"/>'
	return ''
