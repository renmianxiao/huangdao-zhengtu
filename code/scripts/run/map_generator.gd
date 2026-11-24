extends RefCounted

const FLOOR_COUNT := 5
const ROWS_PER_FLOOR := 6
const TOTAL_ROWS := FLOOR_COUNT * ROWS_PER_FLOOR

static func generate(seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var nodes: Array = []
	for row in range(1, TOTAL_ROWS + 1):
		var floor_number := 1 + floori(float(row - 1) / ROWS_PER_FLOOR)
		var floor_row := (row - 1) % ROWS_PER_FLOOR + 1
		var lateral := {0: [], 1: [], 2: []}
		if floor_row < ROWS_PER_FLOOR - 1:
			for boundary in range(2):
				# One direction per boundary avoids opposite crossing diagonals.
				var origin: int = boundary if rng.randf() < 0.5 else boundary + 1
				var enabled: bool = rng.randf() < 0.55
				if floor_row == 1: origin = 1; enabled = true
				if floor_row == 2 and boundary == 0: origin = 0; enabled = true
				if floor_row == 3 and boundary == 1: origin = 2; enabled = true
				if enabled: lateral[origin].append(boundary + 1 if origin == boundary else boundary)
		var columns: Array = [1] if floor_row == ROWS_PER_FLOOR else [0, 1, 2]
		for column: int in columns:
			var kind := "battle"
			if floor_row == ROWS_PER_FLOOR:
				kind = "shop" if floor_number == 1 else ("midboss" if floor_number == 3 else ("boss" if floor_number == 5 else "battle"))
			elif floor_row > 2:
				var roll := rng.randi_range(0, 99)
				kind = "battle" if roll < 70 else ("event" if roll < 90 else "elite")
			var next: Array[String] = []
			if floor_row == ROWS_PER_FLOOR:
				if floor_number < FLOOR_COUNT:
					for next_column in range(3): next.append("r%dc%d" % [row + 1, next_column])
			elif floor_row == ROWS_PER_FLOOR - 1:
				next.append("r%dc1" % (row + 1))
			else:
				next.append("r%dc%d" % [row + 1, column])
				for destination: int in lateral[column]: next.append("r%dc%d" % [row + 1, destination])
			nodes.append({"id": "r%dc%d" % [row, column], "row": row, "floor": floor_number, "floor_row": floor_row, "column": column, "type": kind, "next": next})
	_assign_random_services(nodes, rng)
	return {"seed": seed, "floor_count": FLOOR_COUNT, "rows_per_floor": ROWS_PER_FLOOR, "nodes": nodes}

# Shop and camp budgets are independent. Each type uses distinct interior rows.
static func _assign_random_services(nodes: Array, rng: RandomNumberGenerator) -> void:
	for floor_number in range(2, FLOOR_COUNT + 1):
		for kind: String in ["shop", "camp"]:
			var roll := rng.randi_range(0, 99)
			var count := 0 if roll < 5 else (1 if roll < 95 else 2)
			var available_rows: Array = [2, 3, 4, 5]
			for i in range(count):
				var row_index := rng.randi_range(0, available_rows.size() - 1)
				var floor_row: int = available_rows.pop_at(row_index)
				var candidates: Array[Dictionary] = []
				for node: Dictionary in nodes:
					if node.floor == floor_number and node.floor_row == floor_row and not node.type in ["shop", "camp"]:
						candidates.append(node)
				# At most one shop already occupies the row, leaving two usable nodes.
				var selected: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
				selected.type = kind

static func reachable(map: Dictionary, current_id: String) -> Array[String]:
	if current_id.is_empty():
		var starts: Array[String] = []
		for node: Dictionary in map.nodes:
			if node.row == 1: starts.append(node.id)
		return starts
	for node: Dictionary in map.nodes:
		if node.id == current_id: return node.next.duplicate()
	return []
