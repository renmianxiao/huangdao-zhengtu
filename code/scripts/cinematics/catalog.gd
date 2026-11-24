extends RefCounted
const Run=preload("res://code/scripts/run/run_rules.gd")
const DURATION:=4.0
const SCENES=[
{"title":"晨门启程","time":"上午","background":"res://art/cinematics/floor_1.png","foreground":"res://art/cinematics/doors.png","audio":"res://art/cinematics/floor_1.wav"},
{"title":"竹径渡溪","time":"正午","background":"res://art/cinematics/floor_2.png","foreground":"res://art/cinematics/bamboo.png","audio":"res://art/cinematics/floor_2.wav"},
{"title":"山隘越关","time":"下午","background":"res://art/cinematics/floor_3.png","foreground":"res://art/cinematics/pine.png","audio":"res://art/cinematics/floor_3.wav"},
{"title":"暮野临城","time":"傍晚","background":"res://art/cinematics/floor_4.png","foreground":"res://art/cinematics/banners.png","audio":"res://art/cinematics/floor_4.wav"},
{"title":"夜入敌门","time":"夜晚","background":"res://art/cinematics/floor_5.png","foreground":"res://art/cinematics/doors.png","audio":"res://art/cinematics/floor_5.wav"}]

# Independent transition artwork leaves the map and save-slot illustrations intact.
const TRANSITIONS = [
	{
		"background": "res://art/cinematics/ink/floor_1.png",
		"audio": "res://art/cinematics/ink/floor_1.wav",
		"reveal_origin": Vector2(0.5, 0.48), "full_radius": 1.34,
		"light_position": Vector2(0.377, 0.382),
		"light_color": Color(1.0, 0.86, 0.60),
		"fog_color": Color(0.96, 0.942, 0.896),
		"light_strength": 0.12, "ray_strength": 0.45,
	},
	{
		"background": "res://art/cinematics/ink/floor_2.png",
		"audio": "res://art/cinematics/ink/floor_2.wav",
		"reveal_origin": Vector2(0.50, 0.55), "full_radius": 0.0,
		"light_position": Vector2(0.65, 0.22),
		"light_color": Color(1.0, 0.93, 0.78),
		"fog_color": Color(0.934, 0.955, 0.912),
		"light_strength": 0.045, "ray_strength": 0.12,
	},
	{
		"background": "res://art/cinematics/ink/floor_3.png",
		"audio": "res://art/cinematics/ink/floor_3.wav",
		"reveal_origin": Vector2(0.40, 0.52), "full_radius": 0.0,
		"light_position": Vector2(0.72, 0.25),
		"light_color": Color(1.0, 0.88, 0.69),
		"fog_color": Color(0.956, 0.932, 0.877),
		"light_strength": 0.075, "ray_strength": 0.25,
	},
	{
		"background": "res://art/cinematics/ink/floor_4.png",
		"audio": "res://art/cinematics/ink/floor_4.wav",
		"reveal_origin": Vector2(0.53, 0.53), "full_radius": 0.0,
		"light_position": Vector2(0.67, 0.34),
		"light_color": Color(1.0, 0.77, 0.67),
		"fog_color": Color(0.959, 0.907, 0.862),
		"light_strength": 0.08, "ray_strength": 0.20,
	},
	{
		"background": "res://art/cinematics/ink/floor_5.png",
		"audio": "res://art/cinematics/ink/floor_5.wav",
		"reveal_origin": Vector2(0.56, 0.46), "full_radius": 0.0,
		"light_position": Vector2(0.73, 0.21),
		"light_color": Color(0.77, 0.84, 0.94),
		"fog_color": Color(0.80, 0.845, 0.88),
		"light_strength": 0.045, "ray_strength": 0.0,
	},
]
static func pending_floor(state: Dictionary) -> int:
	if state.get("phase","")!="map":return 0
	var floor_number:=Run.map_floor(state)
	return floor_number if floor_number>int(state.get("cinematic_floor",floor_number)) else 0
static func acknowledge(state: Dictionary) -> Dictionary:
	var floor_number:=pending_floor(state)
	if floor_number==0:return state
	var next:=state.duplicate(true);next.cinematic_floor=floor_number;return next
static func frame(_floor_number: int, seconds: float) -> Dictionary:
	var t := clampf(seconds, 0, DURATION)
	return {
		"reveal": smoothstep(0.05, 3.4, t),
		"zoom": lerpf(1.0, 1.045, smoothstep(0.5, 6.6, t)),
		"strength": smoothstep(1.0, 3.0, t),
		"ending": smoothstep(3.8, 4.0, t),
		"elapsed": t,
	}
