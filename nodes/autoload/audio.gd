extends Node

@export var se_bank_ui: SEBank = preload("uid://4g4x10mll12q")
@export var se_bank_misc: SEBank = preload("uid://cnltqtio46hnh")
@export var bgm_bank: BGMBank = preload("uid://dmtgkl6yehllw")
@export var bgs_bank: BGSBank = preload("uid://cy5nbwaiutylt")

var is_sound_canceled: bool

var bgm_player_a: AudioStreamPlayer
var bgm_player_b: AudioStreamPlayer
var active_bgm_player: AudioStreamPlayer
var current_bgm: BGM

var bgs_player_a: AudioStreamPlayer
var bgs_player_b: AudioStreamPlayer
var active_bgs_player: AudioStreamPlayer
var current_bgs: BGS

var me_player: AudioStreamPlayer

func _ready() -> void:
	bgm_player_a = AudioStreamPlayer.new()
	bgm_player_b = AudioStreamPlayer.new()
	bgs_player_a = AudioStreamPlayer.new()
	bgs_player_b = AudioStreamPlayer.new()
	me_player = AudioStreamPlayer.new()
	add_child(bgm_player_a)
	add_child(bgm_player_b)
	add_child(bgs_player_a)
	add_child(bgs_player_b)
	add_child(me_player)
	active_bgm_player = bgm_player_a
	active_bgs_player = bgs_player_a

func play_bgm(bgm: BGM, crossfade: float = 1.0) -> void:
	if current_bgm == bgm:
		return
	current_bgm = bgm

	var old_player := active_bgm_player
	active_bgm_player = bgm_player_b if old_player == bgm_player_a else bgm_player_a
	var new_player := active_bgm_player

	if old_player.playing:
		var fade_out := create_tween()
		fade_out.tween_property(old_player, "volume_db", -80.0, crossfade)
		fade_out.tween_callback(old_player.stop)

	new_player.bus = bgm.bus
	new_player.pitch_scale = bgm.pitch_scale
	new_player.volume_db = -80.0
	var fade_in := create_tween()
	fade_in.tween_property(new_player, "volume_db", bgm.volume_db, crossfade)

	if bgm.intro_stream != null:
		new_player.stream = bgm.intro_stream
		new_player.play()
		new_player.finished.connect(func(): _start_loop(new_player, bgm), CONNECT_ONE_SHOT)
	else:
		_start_loop(new_player, bgm)

func stop_bgm(fade: float = 1.0) -> void:
	current_bgm = null
	if active_bgm_player.playing:
		var tween := create_tween()
		tween.tween_property(active_bgm_player, "volume_db", -80.0, fade)
		tween.tween_callback(active_bgm_player.stop)

func _start_loop(player: AudioStreamPlayer, bgm: BGM) -> void:
	if current_bgm != bgm:
		return
	player.stream = bgm.stream
	player.play()
	player.finished.connect(func(): _replay(player, bgm), CONNECT_ONE_SHOT)

func _replay(player: AudioStreamPlayer, bgm: BGM) -> void:
	if current_bgm != bgm:
		return
	player.play()
	player.finished.connect(func(): _replay(player, bgm), CONNECT_ONE_SHOT)

func play_se(se: SE, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var se_player := AudioStreamPlayer.new()
	se_player.bus = se.bus
	se_player.stream = se.stream
	se_player.volume_db = se.volume_db if volume_db == 0.0 else volume_db
	se_player.pitch_scale = se.pitch_scale if pitch_scale == 1.0 else pitch_scale
	add_child(se_player)
	se_player.play()
	await se_player.finished
	se_player.queue_free()

## This function is used to cancel sounds played by UIButton when exiting or entering focus. Use Audio.cancel_sound() on the UIButton object to deny the sound.
func cancel_sound() -> void:
	is_sound_canceled = true
	await get_tree().process_frame
	is_sound_canceled = false

## Play spatial sound effect at specific position in the 2D world.
## Good for quick events in the map.
func play_se_2d(se: SE, global_pos: Vector2, parent: Node = null) -> void:
	var se_player := AudioStreamPlayer2D.new()
	se_player.stream = se.stream
	se_player.bus = se.bus
	se_player.volume_db = se.volume_db
	se_player.pitch_scale = se.pitch_scale
	se_player.global_position = global_pos
	if parent == null:
		parent = get_tree().current_scene

	parent.add_child(se_player)

	se_player.play()

	se_player.finished.connect(se_player.queue_free)

func play_bgs(bgs: BGS, fade: float = 1.0) -> void:
	if current_bgs == bgs:
		return
	current_bgs = bgs

	var old_player := active_bgs_player
	active_bgs_player = bgs_player_b if old_player == bgs_player_a else bgs_player_a
	var new_player := active_bgs_player

	if old_player.playing:
		var fade_out := create_tween()
		fade_out.tween_property(old_player, "volume_db", -80.0, fade)
		fade_out.tween_callback(old_player.stop)

	new_player.bus = bgs.bus
	new_player.pitch_scale = bgs.pitch_scale
	new_player.stream = bgs.stream
	new_player.volume_db = -80.0
	new_player.play()

	var fade_in := create_tween()
	fade_in.tween_property(new_player, "volume_db", bgs.volume_db, fade)

	new_player.finished.connect(func(): _replay_bgs(new_player, bgs), CONNECT_ONE_SHOT)

func _replay_bgs(player: AudioStreamPlayer, bgs: BGS) -> void:
	if current_bgs != bgs:
		return
	player.play()
	player.finished.connect(func(): _replay_bgs(player, bgs), CONNECT_ONE_SHOT)

func stop_bgs(fade: float = 1.0) -> void:
	current_bgs = null
	if active_bgs_player.playing:
		var t := create_tween()
		t.tween_property(active_bgs_player, "volume_db", -80.0, fade)
		t.tween_callback(active_bgs_player.stop)

# ME: toca uma vez, abaixa o BGM, restaura ao terminar
func play_me(me: ME, duck_db: float = -15.0, fade: float = 0.2) -> void:
	if me_player.playing:
		return  # ignora se já tem um ME tocando (comportamento RPG Maker)
	
	# Ducking via BUS (evita conflito com tweens do player de BGM)
	var bus_idx := AudioServer.get_bus_index(active_bgm_player.bus)
	var bus_vol := AudioServer.get_bus_volume_db(bus_idx)
	var t_in := create_tween()
	t_in.tween_method(
		func(v): AudioServer.set_bus_volume_db(bus_idx, v),
		bus_vol, bus_vol + duck_db, fade
	)
	
	me_player.stream = me.stream
	me_player.bus = me.bus
	me_player.volume_db = me.volume_db
	me_player.play()
	await me_player.finished
	
	var t_out := create_tween()
	t_out.tween_method(
		func(v): AudioServer.set_bus_volume_db(bus_idx, v),
		bus_vol + duck_db, bus_vol, fade
	)
