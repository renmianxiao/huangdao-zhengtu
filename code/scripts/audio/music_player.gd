extends Node
## Persistent, two-voice music crossfades; scene refreshes never restart a song.
signal settings_changed
const BUS="Music"
const TRACKS={"menu":"res://audio/music/menu.ogg","morning":"res://audio/music/morning.ogg","battle":"res://audio/music/battle.ogg","boss":"res://audio/music/boss.ogg","victory":"res://audio/music/victory.ogg","defeat":"res://audio/music/defeat.ogg"}
const ONE_SHOTS=["victory","defeat"]
var players: Array[AudioStreamPlayer]=[]
var active_index:=0
var current_track:=""
var _shutting_down:=false
var _pending_track:=""
var _last_start_ms:=-1000
var _tracks: Dictionary={}
var _volume:=35.0
var _muted:=false
var _fade_elapsed:=1.0
var _fade_duration:=1.0
var _outgoing_gain:=0.0
var _duck_hold:=0.0
var _duck_db:=0.0
var _cinematic_count:=0
var _cinematic_duck_db:=0.0

func _ready() -> void:
	var config:=ConfigFile.new()
	if config.load("user://audio.cfg")==OK:
		var value: Variant=config.get_value("music","volume",35.0)
		if typeof(value) in [TYPE_INT,TYPE_FLOAT]:_volume=clampf(float(value),0,100)
		var muted: Variant=config.get_value("music","muted",false)
		if muted is bool:_muted=muted
	if AudioServer.get_bus_index(BUS)<0:
		AudioServer.add_bus()
		var index:=AudioServer.bus_count-1
		AudioServer.set_bus_name(index,BUS);AudioServer.set_bus_send(index,"Master")
	# Protect the final mix when both music and effects are set to maximum.
	var master_limited:=false
	for i in range(AudioServer.get_bus_effect_count(0)):
		if AudioServer.get_bus_effect(0,i) is AudioEffectLimiter:master_limited=true
	if not master_limited:
		var limiter:=AudioEffectLimiter.new()
		limiter.threshold_db=-0.8;limiter.ceiling_db=-0.8
		AudioServer.add_bus_effect(0,limiter)
	for i in range(2):
		var player:=AudioStreamPlayer.new()
		player.bus=BUS;player.max_polyphony=1
		player.playback_type=AudioServer.PLAYBACK_TYPE_STREAM
		add_child(player);players.append(player)
	_apply_bus();set_process(false)

func request_track(id: String) -> void:
	if _shutting_down or not TRACKS.has(id):return
	if id==current_track:
		_pending_track=""
		return
	if id==_pending_track:return
	_pending_track=id
	set_process(true)

func _start_requested_track() -> void:
	if _shutting_down or _pending_track.is_empty():return
	var id:=_pending_track
	_pending_track=""
	if not _tracks.has(id):
		if not ResourceLoader.exists(TRACKS[id],"AudioStreamOggVorbis"):
			push_warning("Music unavailable; keeping current track: "+str(TRACKS[id]))
			return
		var stream=load(TRACKS[id]) as AudioStreamOggVorbis
		if stream==null:
			push_warning("Music could not be loaded; keeping current track: "+str(TRACKS[id]))
			return
		stream.loop=not id in ONE_SHOTS
		stream.loop_offset=0.0
		_tracks[id]=stream
	var previous:=active_index
	var incoming_index:=1-active_index
	var incoming:=players[incoming_index]
	_stop_voice(incoming_index)
	# Short result cues retain their attack while the previous song fades away.
	incoming.stream=_tracks[id];incoming.volume_db=0 if id in ONE_SHOTS else -80
	incoming.play()
	if not incoming.playing:
		_stop_voice(incoming_index)
		push_warning("Music could not start; keeping current track: "+str(TRACKS[id]))
		return
	active_index=incoming_index
	current_track=id
	_last_start_ms=Time.get_ticks_msec()
	_outgoing_gain=db_to_linear(players[previous].volume_db) if players[previous].playing else 0.0
	_fade_duration=0.12 if id in ONE_SHOTS else 1.0
	_fade_elapsed=0.0;set_process(true)

func for_phase(phase: String, battle_kind: String = "") -> void:
	match phase:
		"battle":request_track("boss" if battle_kind in ["midboss","boss"] else "battle")
		"reward","won":request_track("victory")
		"lost":request_track("defeat")
		"menu","abandoned":request_track("menu")
		_:request_track("morning")

func _process(delta: float) -> void:
	# Consume only the latest scene request, after the previous voice reached the mixer.
	if not _pending_track.is_empty() and Time.get_ticks_msec()-_last_start_ms>=120:
		_start_requested_track()
	if _fade_elapsed<1.0:
		_fade_elapsed=minf(1.0,_fade_elapsed+delta/_fade_duration)
		var incoming:=1.0 if current_track in ONE_SHOTS else sin(_fade_elapsed*PI*0.5)
		var outgoing:=_outgoing_gain*cos(_fade_elapsed*PI*0.5)
		players[active_index].volume_db=linear_to_db(maxf(0.0001,incoming))
		players[1-active_index].volume_db=linear_to_db(maxf(0.0001,outgoing))
		if _fade_elapsed>=1.0:
			_stop_voice(1-active_index)
	_duck_hold=maxf(0,_duck_hold-delta)
	var target:=-3.0 if _duck_hold>0 else 0.0
	var speed:=0.04 if target<0 else 0.3
	_duck_db=lerpf(_duck_db,target,1-exp(-delta/speed))
	var cinematic_target := -36.0 if _cinematic_count > 0 else 0.0
	_cinematic_duck_db = lerpf(_cinematic_duck_db, cinematic_target, 1 - exp(-delta / 0.3))
	_apply_bus()

func begin_cinematic() -> void:
	_cinematic_count += 1
	# Suppress the song before the cinematic's first sound reaches the mixer.
	_cinematic_duck_db = -36.0
	_apply_bus()
	set_process(true)

func end_cinematic() -> void:
	if _cinematic_count == 0:return
	_cinematic_count -= 1
	set_process(true)

func duck() -> void:
	if not current_track.is_empty() and not _muted:_duck_hold=0.22

func _stop_voice(index: int) -> void:
	players[index].stop();players[index].stream=null

func stop_all() -> void:
	for index in range(players.size()):_stop_voice(index)
	_pending_track="";current_track="";_fade_elapsed=1.0;_duck_hold=0;_duck_db=0
	_cinematic_duck_db = -36.0 if _cinematic_count > 0 else 0.0
	_apply_bus();set_process(false)

func shutdown() -> void:
	_shutting_down=true
	_pending_track=""
	var remaining:=maxf(0.0,(120-(Time.get_ticks_msec()-_last_start_ms))/1000.0)
	if remaining>0:
		get_tree().create_timer(remaining).timeout.connect(stop_all)
	else:stop_all()

func set_volume(value: float) -> void:
	_volume=clampf(value,0,100)
	_apply_bus();_save_settings();settings_changed.emit()
func get_volume() -> float:return _volume
func set_muted(value: bool) -> void:
	_muted=value;_apply_bus();_save_settings();settings_changed.emit()
func is_muted() -> bool:return _muted
func _save_settings() -> void:
	var config:=ConfigFile.new();config.load("user://audio.cfg")
	config.set_value("music","volume",_volume);config.set_value("music","muted",_muted)
	config.save("user://audio.cfg")
func _apply_bus() -> void:
	var bus:=AudioServer.get_bus_index(BUS)
	if bus<0:return
	AudioServer.set_bus_volume_db(bus,(linear_to_db(_volume/100.0) if _volume>0 else -80.0)+_duck_db+_cinematic_duck_db)
	AudioServer.set_bus_mute(bus,_muted)
func _exit_tree() -> void:
	stop_all();_tracks.clear()
