extends Node
## One-shot combat foley. The pool and shared bus bound dense multi-hit playback.
signal settings_changed
const BUS="CombatSFX"
const CLIPS=["sword_swing","thrust_whizz","bow_release","needle_whizz","heavy_swing","arcane_cast","counter_return","slash_hit","thrust_hit","arrow_hit","needle_hit","impact_hit","arcane_hit","poison_hit","poison_apply","poison_burst","poison_tick","guard","armor_break","heal","buff","interrupt","charge"]
static var _settings_loaded:=false
static var _volume:=65.0
static var _muted:=false
var players: Array[AudioStreamPlayer]=[]
var _clips: Dictionary={}
var _last_played: Dictionary={}
var _variants: Dictionary={}

func _ready() -> void:
	_load_settings()
	var bus:=AudioServer.get_bus_index(BUS)
	if bus<0:
		AudioServer.add_bus()
		bus=AudioServer.bus_count-1
		AudioServer.set_bus_name(bus,BUS)
		AudioServer.set_bus_send(bus,"Master")
		var limiter:=AudioEffectLimiter.new()
		limiter.threshold_db=-4.0
		limiter.ceiling_db=-1.0
		AudioServer.add_bus_effect(bus,limiter)
	_apply_bus()
	for id: String in CLIPS:
		var clip=load("res://audio/combat/"+id+".wav") as AudioStream
		if clip!=null:_clips[id]=clip
	for i in range(8):
		var player:=AudioStreamPlayer.new()
		player.bus=BUS
		player.max_polyphony=1
		player.playback_type=AudioServer.PLAYBACK_TYPE_STREAM
		add_child(player)
		players.append(player)

func _exit_tree() -> void:
	stop_all()

static func sound_id(cue: Dictionary, stage: String) -> String:
	var kind:=str(cue.get("kind",""))
	var family:=str(cue.get("family","impact"))
	if stage=="launch":
		if kind=="cast":return str(cue.get("cast_sound",""))
		if kind not in ["damage","counter"]:return ""
		if kind=="counter" or family=="counter":return "counter_return"
		return {"slash":"sword_swing","thrust":"thrust_whizz","arrow":"bow_release","needle":"needle_whizz","impact":"heavy_swing","arcane":"arcane_cast"}.get(family,"")
	if stage!="hit":return ""
	match kind:
		"cast":return ""
		"heal":return "heal" if int(cue.get("amount",0))>0 else ""
		"shield":return "guard"
		"buff":return "buff"
		"armor_break":return "armor_break"
		"interrupt":return "interrupt"
		"poison_add","poison_apply":return "poison_apply"
		"poison_consume":return "poison_burst"
		"poison_tick":return "poison_tick"
		"enemy_action":return "guard" if family=="shield" else "charge"
		"damage","counter":
			if int(cue.get("amount",0))<=0:
				return "guard" if int(cue.get("absorbed",0))>0 else ""
			if kind=="counter":return "slash_hit"
			return {"slash":"slash_hit","thrust":"thrust_hit","arrow":"arrow_hit","needle":"needle_hit","impact":"impact_hit","arcane":"arcane_hit","poison":"poison_hit","counter":"slash_hit"}.get(family,"impact_hit")
	return ""

func play_cue(cue: Dictionary, stage: String) -> bool:
	var id:=sound_id(cue,stage)
	var played:=play_sound(id,str(cue.get("side","team")),stage)
	if played and stage=="hit" and id in ["impact_hit","arcane_hit","armor_break","interrupt"]:
		var music:=get_node_or_null("/root/Music")
		if music!=null:music.duck()
	return played

func play_sound(id: String, side: String="team", stage: String="hit") -> bool:
	if _muted or _volume<=0 or not _clips.has(id):return false
	var now:=Time.get_ticks_usec()
	if _last_played.has(id) and now-int(_last_played[id])<24000:return false
	var available: AudioStreamPlayer
	var active:=0
	for player in players:
		if player.playing:active+=1
		elif available==null:available=player
	# Leave two voices for the actual impact; never cut a waveform mid-hit.
	if available==null or (stage=="launch" and active>=6):return false
	var variation:=int(_variants.get(id,0))
	_variants[id]=variation+1
	available.stream=_clips[id]
	available.pitch_scale=[0.985,1.0,1.015][variation%3]
	available.volume_db=(-9.0 if stage=="launch" else -5.0)-maxf(0,active-2)*0.65
	if id in ["poison_tick","needle_hit","heal","buff"]:available.volume_db-=2.0
	if side=="team" and stage=="hit":available.volume_db-=0.8
	available.play()
	_last_played[id]=now
	return true

func stop_all() -> void:
	for player in players:
		player.stop()
		player.stream=null
	_last_played.clear()

func set_volume(value: float) -> void:
	_volume=clampf(value,0,100)
	if _volume<=0:stop_all()
	_apply_bus();_save_settings();settings_changed.emit()

func get_volume() -> float:return _volume

func set_muted(value: bool) -> void:
	_muted=value
	if value:stop_all()
	_apply_bus();_save_settings();settings_changed.emit()

func is_muted() -> bool:return _muted

static func _load_settings() -> void:
	if _settings_loaded:return
	_settings_loaded=true
	var config:=ConfigFile.new()
	if config.load("user://audio.cfg")!=OK:return
	var value: Variant=config.get_value("combat","volume",65.0)
	if typeof(value) in [TYPE_INT,TYPE_FLOAT]:_volume=clampf(float(value),0,100)
	var muted: Variant=config.get_value("combat","muted",false)
	if muted is bool:_muted=muted

static func _save_settings() -> void:
	var config:=ConfigFile.new()
	config.load("user://audio.cfg")
	config.set_value("combat","volume",_volume)
	config.set_value("combat","muted",_muted)
	config.save("user://audio.cfg")

static func _apply_bus() -> void:
	var bus:=AudioServer.get_bus_index(BUS)
	if bus<0:return
	AudioServer.set_bus_volume_db(bus,linear_to_db(_volume/100.0) if _volume>0 else -80.0)
	AudioServer.set_bus_mute(bus,_muted)