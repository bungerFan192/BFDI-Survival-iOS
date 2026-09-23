extends Node2D

@export var cycle_length_sec: = 600.0
@export var transition_sec: = 30.0
@export var overscan_scale: = 1.4
@export var backmost_z_index: = -2
@export var drag_padding_px: = 600.0
@export var repeat_texture: = true

@onready var day: Sprite2D = $DaySky
@onready var night: Sprite2D = $NightSky
@onready var evil: Sprite2D = $EvilSky
@onready var yoyle: Sprite2D = $YoyleSky
@onready var space: Sprite2D = $SpaceSky
@onready var blacker: Sprite2D = $"../../CanvasLayer/Blacker"

@export var space_max_alpha: = 1.0
@export var space_start_progress: = 0.0
@export var space_end_progress: = 1.0
var _space_progress: = 0.0

var _use_evil_day: = false
var _last_day_alpha: = 1.0

@export var blacker_evil_alpha: = 1
@export var blacker_fade_sec: = 0.4
var _blacker_tween: Tween

const SERVER_ID: = 1
var _epoch_unix_s: float = 0.0
var is_night_now: bool = false
var _in_canvas_layer: = false
@onready var canvas_modulate: CanvasModulate = $"../../CanvasModulate"
@onready var mountainfar: Sprite2D = $"../../ParallaxBackground/Far/Mountain"
@onready var mountainnear: Sprite2D = $"../../ParallaxBackground/Near/Mountain"

var _in_evil: = false
var _in_yoyle: = false

var _space_visible: = false

@export var debug_print_space: = false
var _space_print_acc: = 0.0

enum DayVariant{NORMAL, EVIL, YOYLE}
var _day_variant: = DayVariant.NORMAL

const HOWITBEGINS: = preload("uid://b4mtd263nli0y")
const WALLPAPER: = preload("uid://c4c14n4ao1eyx")
const HITMAN: = preload("uid://8rvk61sdi651")
const RISING: = preload("uid://djoxac8la12us")
const CIPHER: = preload("uid://0250gs5kgwjt")

const DAY_MUSIC: = [HOWITBEGINS, WALLPAPER, CIPHER]
const NIGHT_MUSIC: = [HITMAN, RISING]
const EVIL_FOREST_MUSIC: = preload("uid://c03udg8vomspw")
const SPACE_MUSIC: = preload("uid://cbpjjil114xd5")

const BIOME_XFADE_SEC: = 0.75

func _play_space_music() -> void :
	if not music_enabled:
		return

	_music_started = true

	if _music_player == null or not is_instance_valid(_music_player):
		_setup_music_player()
		if _music_player == null:
			return


	if _music_player.stream == SPACE_MUSIC and _music_player.playing:
		return


	if _music_tween and _music_tween.is_running():
		_music_tween.kill()
	_fade_volume_to(music_volume_db_silent, BIOME_XFADE_SEC)
	_suppress_volume_for(BIOME_XFADE_SEC)
	get_tree().create_timer(BIOME_XFADE_SEC).timeout.connect( func():
		if not music_enabled or not _music_started:
			return
		if not _space_visible:
			_resume_best_background_music()
			return
		_last_track = SPACE_MUSIC
		_music_player.stream = SPACE_MUSIC
		_music_player.play()
		_fade_volume_to(music_volume_db_normal, BIOME_XFADE_SEC)
	)

func _play_evil_music() -> void :
	if not music_enabled:
		return
	_music_started = true

	if _music_player == null or not is_instance_valid(_music_player):
		_setup_music_player()
		if _music_player == null:
			return


	if _music_player.stream == EVIL_FOREST_MUSIC and _music_player.playing:
		return


	if _music_tween and _music_tween.is_running():
		_music_tween.kill()
	_fade_volume_to(music_volume_db_silent, BIOME_XFADE_SEC)
	_suppress_volume_for(BIOME_XFADE_SEC)
	get_tree().create_timer(BIOME_XFADE_SEC).timeout.connect( func():
		if not music_enabled or not _music_started:
			return
		if _space_visible:
			_play_space_music();return
		if not _in_evil:
			_resume_best_background_music();return
		_last_track = EVIL_FOREST_MUSIC
		_music_player.stream = EVIL_FOREST_MUSIC
		_music_player.play()
		_fade_volume_to(music_volume_db_normal, BIOME_XFADE_SEC)
	)


	_no_restart_until_unix_s = 0.0


func _resume_phase_music() -> void :
	if not music_enabled:
		return
	_music_started = true
	if _music_tween and _music_tween.is_running():
		_music_tween.kill()
	_fade_volume_to(music_volume_db_silent, BIOME_XFADE_SEC)
	_suppress_volume_for(BIOME_XFADE_SEC)
	get_tree().create_timer(BIOME_XFADE_SEC).timeout.connect( func():
		if not music_enabled or not _music_started:
			return
		if _space_visible:
			_play_space_music();return
		if _in_evil:
			_play_evil_music();return

		_play_random_from(_current_playlist_for_now(), true)
		_maybe_restore_volume()
	)

func _resume_best_background_music() -> void :

	if _space_visible:
		_play_space_music()
	elif _in_evil:
		_play_evil_music()
	else:
		_resume_phase_music()


func _is_night_phase_now() -> bool:
	if cycle_length_sec <= 0.0:
		return false
	var now_s: = float(Time.get_unix_time_from_system())
	var t: = fposmod(now_s - _epoch_unix_s, cycle_length_sec)
	var half: = cycle_length_sec * 0.5
	var fade = min(transition_sec, half)


	var a: = 1.0
	if t < half - fade:
		a = 1.0
	elif t < half:
		var k = (t - (half - fade)) / fade
		a = 1.0 - k
	elif t < cycle_length_sec - fade:
		a = 0.0
	else:
		var k2 = (t - (cycle_length_sec - fade)) / fade
		a = k2


	return a < 0.5

func _current_playlist_for_now() -> Array:
	return _current_playlist_for_phase(_is_night_phase_now())



var _music_player: AudioStreamPlayer
var _music_tween: Tween
var _last_track: AudioStream = null
var _music_started: = false



var _no_restart_until_unix_s: = 0.0


var _last_t: = 0.0
var _fired_day_to_night: = false
var _fired_night_to_day: = false


@export var music_volume_db_normal: = -20.0
@export var music_volume_db_silent: = -60.0


const FADE_OUT_SEC: = 30.0

const SWITCH_WARN_SEC: = 30.0

const NEXT_PHASE_DELAY_SEC: = 40.0

@export var fade_in_sec: = 0.0

var music_enabled: = true

var _music_gen: int = 0

const MUSIC_WATCHDOG_PERIOD: = 0.5
var _music_watchdog_acc: = 0.0

var _boot_music_hold_until_unix_s: = 0.0

func _bump_music_gen() -> void :
	_music_gen += 1
	_maybe_restore_volume()

func _maybe_restore_volume() -> void :
	if not music_enabled:
		return
	if _music_player == null or not is_instance_valid(_music_player):
		return
	var now_s: = float(Time.get_unix_time_from_system())
	if now_s < _suppress_volume_until_unix_s:
		return

	if now_s < _boot_music_hold_until_unix_s or not _music_started:
		return
	if _music_player.volume_db <= (music_volume_db_silent + 1.0):
		_fade_volume_to(music_volume_db_normal, 0.2)

var _suppress_volume_until_unix_s: = 0.0

func _suppress_volume_for(sec: float) -> void :
	var now_s: = float(Time.get_unix_time_from_system())
	_suppress_volume_until_unix_s = max(_suppress_volume_until_unix_s, now_s + max(sec, 0.0))

func _enforce_music_liveness() -> void :
	if not music_enabled:
		return
	var now_s: = float(Time.get_unix_time_from_system())

	if now_s < _boot_music_hold_until_unix_s or not _music_started:
		return
	if _music_player == null or not is_instance_valid(_music_player):
		_setup_music_player()
		if _music_player == null:
			return

	if not _music_player.playing:
		_resume_best_background_music()
		return

	var allow_lift: = (now_s >= _suppress_volume_until_unix_s)

	if _space_visible:
		if _music_player.stream != SPACE_MUSIC:
			_play_space_music()
		elif allow_lift:
			_maybe_restore_volume()
		return

	if _in_evil:
		if _music_player.stream != EVIL_FOREST_MUSIC:
			_play_evil_music()
		elif allow_lift:
			_maybe_restore_volume()
		return

	if allow_lift:
		_maybe_restore_volume()

func _ready() -> void :
	_in_canvas_layer = _detect_canvas_layer()

	add_to_group("sky_cycle")
	add_to_group("daynight")
	for s in [day, night, space]:
		s.z_as_relative = false
		s.z_index = backmost_z_index
		s.centered = true
		s.visible = true
		if repeat_texture:
			s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	space.z_index = backmost_z_index + 1
	if is_instance_valid(blacker):
		blacker.z_index = backmost_z_index + 2

	for s in [day, night, evil, yoyle, space, blacker]:
		s.z_as_relative = false
		s.z_index = backmost_z_index
		s.centered = true
		s.visible = true
		if repeat_texture:
			s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


	night.modulate = Color(1, 1, 1, 1)
	day.modulate = Color(1, 1, 1, 1)
	evil.modulate = Color(1, 1, 1, 0)
	yoyle.modulate = Color(1, 1, 1, 0)
	space.modulate = Color(1, 1, 1, 0)
	if is_instance_valid(blacker):
		var bc: = blacker.modulate
		blacker.modulate = Color(bc.r, bc.g, bc.b, 0.0)

	_scale_to_viewport()
	get_viewport().size_changed.connect(_scale_to_viewport)


	if multiplayer.is_server():
		_epoch_unix_s = float(Time.get_unix_time_from_system())
		rpc("cli_set_cycle_epoch", _epoch_unix_s)
	else:
		rpc_id(SERVER_ID, "srv_request_cycle_epoch")
	if _epoch_unix_s == 0.0:
		_epoch_unix_s = float(Time.get_unix_time_from_system())

	music_enabled = GameSession.music

	_setup_music_player()

	var now_s: = float(Time.get_unix_time_from_system())
	_boot_music_hold_until_unix_s = now_s + 10.0

	get_tree().create_timer(10.0).timeout.connect(_start_music_for_current_phase)

func _resolve_day_variant() -> DayVariant:

	if _in_yoyle:
		return DayVariant.YOYLE
	elif _in_evil:
		return DayVariant.EVIL
	return DayVariant.NORMAL

func _swap_active_day_sprite() -> void :
	_day_variant = _resolve_day_variant()

	var a = clamp(_last_day_alpha, 0.0, 1.0)

	var want_day: = (_day_variant == DayVariant.NORMAL)
	var want_evil: = (_day_variant == DayVariant.EVIL)
	var want_yoyle: = (_day_variant == DayVariant.YOYLE)

	day.modulate = Color(day.modulate.r, day.modulate.g, day.modulate.b, (a if want_day else 0.0))
	evil.modulate = Color(evil.modulate.r, evil.modulate.g, evil.modulate.b, (a if want_evil else 0.0))
	yoyle.modulate = Color(yoyle.modulate.r, yoyle.modulate.g, yoyle.modulate.b, (a if want_yoyle else 0.0))

func _set_blacker_alpha(a: float) -> void :
	if not is_instance_valid(blacker):
		return
	var bc: = blacker.modulate
	bc.a = clamp(a, 0.0, 1.0)
	blacker.modulate = bc

func _fade_blacker(to_alpha: float, dur: float) -> void :
	if not is_instance_valid(blacker):
		return
	if _blacker_tween and _blacker_tween.is_running():
		_blacker_tween.kill()
	_blacker_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_blacker_tween.tween_property(blacker, "modulate:a", clamp(to_alpha, 0.0, 1.0), max(dur, 0.0))

func _process(_dt: float) -> void :

	if _in_canvas_layer:
		position = get_viewport_rect().size * 0.5
	else:
		var cam: = get_viewport().get_camera_2d()
		if cam:
			global_position = cam.get_screen_center_position()

	if cycle_length_sec <= 0.0:
		return


	var now_s: = float(Time.get_unix_time_from_system())
	var t: = fposmod(now_s - _epoch_unix_s, cycle_length_sec)
	var half: = cycle_length_sec * 0.5
	var fade = min(transition_sec, half)

	var a: = 1.0
	if t < half - fade:
		a = 1.0
	elif t < half:
		var k = (t - (half - fade)) / fade
		a = 1.0 - k
	elif t < cycle_length_sec - fade:
		a = 0.0
	else:
		var k2 = (t - (cycle_length_sec - fade)) / fade
		a = k2

	_set_day_alpha(a)


	is_night_now = (t >= half)

	if t < _last_t:
		_fired_day_to_night = false
		_fired_night_to_day = false
	_no_restart_until_unix_s = max(_no_restart_until_unix_s, 0.0)


	var day_to_night_trigger_t = max(half - SWITCH_WARN_SEC, 0.0)
	if not _fired_day_to_night and _crossed(_last_t, t, day_to_night_trigger_t):
		_schedule_phase_transition(true)


	var night_to_day_trigger_t = max(cycle_length_sec - SWITCH_WARN_SEC, 0.0)
	if not _fired_night_to_day and _crossed(_last_t, t, night_to_day_trigger_t):
		_schedule_phase_transition(false)

	_last_t = t


	_music_watchdog_acc += _dt
	if _music_watchdog_acc >= MUSIC_WATCHDOG_PERIOD:
		_music_watchdog_acc = 0.0
		_enforce_music_liveness()



func set_music_enabled(flag: bool) -> void :
	music_enabled = flag
	_bump_music_gen()
	if not flag:
		if _music_tween and _music_tween.is_running():
			_music_tween.kill()
		if _music_player and is_instance_valid(_music_player):
			_music_player.stop()
			_music_player.stream = null
		_no_restart_until_unix_s = 0.0
	else:
		if _music_started:
			_resume_best_background_music()

func _setup_music_player() -> void :
	var found: = get_node_or_null("Music")
	if found is AudioStreamPlayer:
		_music_player = found
	else:
		_music_player = AudioStreamPlayer.new()
		_music_player.name = "Music"
		add_child(_music_player)

	_music_player.autoplay = false
	_music_player.bus = "Master"
	_music_player.volume_db = music_volume_db_silent

	if not _music_player.finished.is_connected(_on_music_finished):
		_music_player.finished.connect(_on_music_finished)

func _start_music_for_current_phase() -> void :
	if not music_enabled:
		return
	_music_started = true
	_bump_music_gen()

	if _space_visible:
		_play_space_music()
	elif _in_evil:
		_play_evil_music()
	else:
		_play_random_from(_current_playlist_for_now(), true)

func _current_playlist_for_phase(night: bool) -> Array:
	return NIGHT_MUSIC if night else DAY_MUSIC

func _pick_random_track(tracks: Array) -> AudioStream:
	if tracks.is_empty(): return null

	var candidates: = tracks.duplicate()
	if _last_track and candidates.size() > 1:
		candidates.erase(_last_track)
	return candidates[randi() % candidates.size()]

func _play_random_from(tracks: Array, fade_in: = false) -> void :
	if not _music_started or not music_enabled:
		return


	if _space_visible:

		if tracks != null and tracks.size() > 0:

			if tracks.size() != 1 or tracks[0] != SPACE_MUSIC:
				return


	if _in_evil and not _space_visible:

		return


	if _music_player == null or not is_instance_valid(_music_player):
		_setup_music_player()
		if _music_player == null:
			push_warning("Music player missing; cannot play.")
			return

	var next: = _pick_random_track(tracks)
	_last_track = next
	if next == null:
		return

	_music_player.stream = next
	if fade_in:
		_music_player.volume_db = music_volume_db_silent
		_music_player.play()
		_fade_volume_to(music_volume_db_normal, fade_in_sec)
	else:
		_music_player.volume_db = music_volume_db_normal
		_music_player.play()

func _on_music_finished() -> void :
	if not music_enabled:
		return
	if _space_visible:
		_bump_music_gen()
		_play_space_music()
		return
	if _in_evil:
		_bump_music_gen()
		_play_evil_music()
		return
	var now_s: = float(Time.get_unix_time_from_system())
	if now_s < _no_restart_until_unix_s:
		return
	_play_random_from(_current_playlist_for_now(), false)

func _fade_volume_to(target_db: float, dur: float) -> void :
	if _music_tween and _music_tween.is_running():
		_music_tween.kill()
	_music_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_music_tween.tween_property(_music_player, "volume_db", target_db, max(dur, 0.0))

func _crossed(prev_t: float, curr_t: float, threshold_t: float) -> bool:

	return (prev_t < threshold_t and curr_t >= threshold_t)

func _schedule_phase_transition(to_night: bool) -> void :

	if _in_evil:
		return

	if _space_visible:
		return


	var now_s: = float(Time.get_unix_time_from_system())
	if now_s < _boot_music_hold_until_unix_s or not _music_started:
		return

	if not music_enabled:
		return
	_no_restart_until_unix_s = now_s + NEXT_PHASE_DELAY_SEC
	_fade_volume_to(music_volume_db_silent, FADE_OUT_SEC)
	_suppress_volume_for(FADE_OUT_SEC + NEXT_PHASE_DELAY_SEC + 0.1)

	get_tree().create_timer(NEXT_PHASE_DELAY_SEC).timeout.connect( func():

		if not music_enabled or not _music_started:
			return
		if _space_visible:
			_play_space_music()
			return
		if _in_evil:
			_play_evil_music()
			return


		var playlist: = _current_playlist_for_now()
		_play_random_from(playlist, true)
		_no_restart_until_unix_s = 0.0
	)
	if to_night:
		_fired_day_to_night = true
	else:
		_fired_night_to_day = true






func set_in_evil_forest(flag: bool) -> void :
	if _in_evil == flag:
		if flag:
			_fade_blacker(blacker_evil_alpha, blacker_fade_sec)
		else:
			_fade_blacker(0.0, blacker_fade_sec)
		return

	_in_evil = flag
	_bump_music_gen()
	_swap_active_day_sprite()

	if _in_evil:
		_fade_blacker(blacker_evil_alpha, blacker_fade_sec)
		if not _space_visible:
			_play_evil_music()
	else:
		_fade_blacker(0.0, blacker_fade_sec)
		_bump_music_gen()
		_resume_best_background_music()

func set_in_yoyle_biome(flag: bool) -> void :
	if _in_yoyle == flag:
		return
	_in_yoyle = flag
	_swap_active_day_sprite()



func _set_day_alpha(a: float) -> void :
	_last_day_alpha = clamp(a, 0.0, 1.0)

	_swap_active_day_sprite()
	_update_canvas_modulate_from_day_alpha(_last_day_alpha)


func _update_canvas_modulate_from_day_alpha(a: float) -> void :
	var night_v: = 148.0 / 255.0
	var day_v: = 1.0
	var v = lerp(night_v, day_v, a)
	var col: = Color(v, v, v, 1.0)

	if is_instance_valid(canvas_modulate):
		canvas_modulate.color = col

	if is_instance_valid(mountainfar):
		var mf: = mountainfar.modulate
		mf = Color(col.r, col.g, col.b, mf.a)
		mountainfar.modulate = mf

	if is_instance_valid(mountainnear):
		var mn: = mountainnear.modulate
		mn = Color(col.r, col.g, col.b, mn.a)
		mountainnear.modulate = mn

	var bg: = get_tree().get_first_node_in_group("parallax_biome")
	if bg and bg.has_method("set_brightness_factor"):
		bg.call("set_brightness_factor", a)

func _scale_to_viewport() -> void :
	var screen: = get_viewport_rect().size

	var zoom: = Vector2.ONE
	if not _in_canvas_layer:
		var cam: = get_viewport().get_camera_2d()
		zoom = (cam.zoom if cam else Vector2.ONE)

	var visible: = Vector2(screen.x * zoom.x + 2.0 * drag_padding_px, 
		screen.y * zoom.y + 2.0 * drag_padding_px)


	for s in [day, night, evil, yoyle, space, blacker]:
		if s and s.texture:
			var ts = s.texture.get_size()
			var ss = max(visible.x / ts.x, visible.y / ts.y) * overscan_scale
			s.scale = Vector2(ss, ss)
			s.position = screen * 0.5


func set_space_progress(p: float) -> void :
	_space_progress = clamp(p, 0.0, 1.0)
	if debug_print_space:
		_space_print_acc += 1.0
		if _space_print_acc >= 15.0:
			_space_print_acc = 0.0
			print("sky.set_space_progress(", "%.3f" % _space_progress, ")")
	_update_space_alpha()

func _update_space_alpha() -> void :

	var denom = max(space_end_progress - space_start_progress, 0.0001)
	var k = (_space_progress - space_start_progress) / denom
	k = clamp(k, 0.0, 1.0)

	k = k * k * (3.0 - 2.0 * k)
	var a = clamp(k * space_max_alpha, 0.0, 1.0)

	if is_instance_valid(space):
		var m: = space.modulate
		space.modulate = Color(m.r, m.g, m.b, a)



	var was_visible: = _space_visible
	_space_visible = (a > 0.001)

	if _space_visible != was_visible:
		_bump_music_gen()
		if _space_visible:
			_play_space_music()
		else:
			_resume_best_background_music()


func _detect_canvas_layer() -> bool:
	var n: Node = self
	while n:
		if n is CanvasLayer:
			return true
		n = n.get_parent()
	return false


@rpc("any_peer", "call_local", "reliable")
func cli_set_cycle_epoch(epoch_unix_s: float) -> void :
	_epoch_unix_s = epoch_unix_s

@rpc("any_peer")
func srv_request_cycle_epoch() -> void :
	if not multiplayer.is_server(): return
	rpc_id(multiplayer.get_remote_sender_id(), "cli_set_cycle_epoch", _epoch_unix_s)


func set_cycle_length(len: float) -> void :
	cycle_length_sec = max(len, 0.1)

func set_cycle_epoch_from_server(epoch_server_sec: float, server_now_sec: float) -> void :

	var local_now: = float(Time.get_unix_time_from_system())
	var drift: = local_now - server_now_sec
	_epoch_unix_s = epoch_server_sec + drift
