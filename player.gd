extends CharacterBody2D


const WALK_SPEED: = 200.0
const RUN_SPEED: = 500.0
const JUMP_VELOCITY: = -700.0


const SAFE_MARGIN_PX: = 0.3
const STEP_HEIGHT: = 6
const STEP_COOLDOWN: = 0.08
const JUMP_BUFFER: = 0.14
const COYOTE_TIME: = 0.12
const FLOOR_SNAP: = 6.0

var _jump_buffer_t: = 0.0
var _coyote_t: = 0.0
var _step_cool_t: = 0.0

var _base_scale: = Vector2.ONE

var _awaiting_jump_finish: = false
var _snap_suspended: = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var falling: AudioStreamPlayer2D = $falling
@onready var hit: AudioStreamPlayer2D = $hit
@onready var hitfall: AudioStreamPlayer2D = $hitfall
@onready var swim: AudioStreamPlayer2D = $swim
@onready var tile_map_layer: TileMapLayer = $"../TileMapLayer"
@onready var pop: AudioStreamPlayer2D = $pop
@onready var cam: Camera2D = $Camera2D
@onready var _sky: = get_tree().get_first_node_in_group("daynight")
@onready var item: Sprite2D = $Item
var _item_base_pos: = Vector2.ZERO
var _last_flip_h: = false
var _held_item_id: int = 0


var _space_base_y: = INF
var _space_full_y: = INF
var _space_cfg_ok: = false
var _space_cfg_refresh_accum: = 0.0

func _apply_facing(left: bool) -> void :
	if animated_sprite_2d.flip_h == left:
		return

	animated_sprite_2d.flip_h = left


	for collider in get_children():
		if collider is CollisionShape2D:
			var cs: = collider as CollisionShape2D
			cs.position.x = - cs.position.x


	var held: = get_node_or_null("Item") as Sprite2D
	if held:
		held.flip_h = left


		var dir: = -1.0 if left else 1.0
		held.position.x = abs(held.position.x) * dir

func _notify_facing_changed(left: bool) -> void :
	var w: = get_tree().get_first_node_in_group("world")
	if w == null:
		return


	if multiplayer.is_server():
		if w.has_method("srv_set_player_facing"):
			w.srv_set_player_facing(multiplayer.get_unique_id(), left)
	else:
		if w.has_method("srv_set_player_facing"):
			w.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER, "srv_set_player_facing", multiplayer.get_unique_id(), left)

func set_held_item_visual(item_id: int) -> void :
	_held_item_id = item_id

	if not is_instance_valid(item):
		return

	if item_id == 0:
		item.visible = false
		return

	var world: = get_tree().get_first_node_in_group("world")
	if world == null:
		item.visible = false
		return

	var tex: Texture2D = null


	if world.has_method("_pickup_texture_for_item"):
		tex = world._pickup_texture_for_item(item_id)

	if tex == null:
		item.visible = false
		return

	item.texture = tex
	item.visible = true

func _update_item_flip_from_sprite() -> void :
	if not is_instance_valid(item):
		return
	if _item_base_pos == Vector2.ZERO:
		_item_base_pos = item.position

	var sign: = -1.0 if animated_sprite_2d.flip_h else 1.0
	item.position.x = abs(_item_base_pos.x) * sign

	item.flip_h = animated_sprite_2d.flip_h


var _asset_cache: = {}
const ASSET_CACHE_MAX: = 48

func _res(path: String) -> Resource:
	if path == "" or path == null:
		return null
	if _asset_cache.has(path):
		return _asset_cache[path]
	var r: = load(path)
	if r != null:
		_asset_cache[path] = r
		if _asset_cache.size() > ASSET_CACHE_MAX:

			var keys = _asset_cache.keys()
			var active_path = animated_sprite_2d.frames.resource_path if animated_sprite_2d.frames else ""
			for k in keys:
				if k != active_path and k not in [LEAFY_PATH, FIREY_PATH, COINY_PATH, PIN_PATH, GOLFBALL_PATH, TENNISBALL_PATH, PENCIL_PATH, MATCH_PATH, NEEDLE_PATH, PEN_PATH, ICECUBE_PATH, TEARDROP_PATH, ROCKY_PATH, FLOWER_PATH, BUBBLE_PATH, SNOWBALL_PATH, BLOCKY_PATH, WOODY_PATH, ERASER_PATH, SPONGY_PATH]:
					_asset_cache.erase(k)
					break
	return r

func _tex(path: String) -> Texture2D:
	return _res(path) as Texture2D

func _audio(path: String) -> AudioStream:
	return _res(path) as AudioStream

const PATH_ENTER_WATER: = [
	"res://sounds/water/Entering_water1.ogg", 
	"res://sounds/water/Entering_water2.ogg", 
	"res://sounds/water/Entering_water3.ogg"
]

const PATH_EXIT_WATER: = [
	"res://sounds/water/Exiting_water1.ogg", 
	"res://sounds/water/Exiting_water2.ogg", 
	"res://sounds/water/Exiting_water3.ogg"
]


const GRASS_COORDS: = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(4, 1), Vector2i(4, 3), Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), \
Vector2i(3, 4), Vector2i(3, 5), Vector2i(0, 6), Vector2i(6, 0), Vector2i(5, 1), Vector2i(6, 1), Vector2i(5, 2), Vector2i(6, 2), Vector2i(6, 3), Vector2i(6, 4), \
Vector2i(5, 5), Vector2i(0, 9)]
const STONE_COORDS: = [Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(5, 0), Vector2i(6, 5), Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(4, 6), \
Vector2i(5, 6), Vector2i(6, 6), Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7), Vector2i(6, 7), Vector2i(7, 0), Vector2i(7, 1), Vector2i(7, 2), Vector2i(7, 3), \
Vector2i(7, 4), Vector2i(7, 5), Vector2i(7, 6), Vector2i(7, 7), Vector2i(8, 0), Vector2i(8, 1), Vector2i(8, 2), Vector2i(8, 3), Vector2i(8, 5), Vector2i(8, 6), Vector2i(8, 7), Vector2i(0, 8), \
Vector2i(1, 8), Vector2i(2, 8), Vector2i(3, 8), Vector2i(4, 8), Vector2i(5, 8), Vector2i(9, 0), Vector2i(9, 1), Vector2i(9, 2), Vector2i(9, 3), Vector2i(9, 4)]
const WOOD_COORDS: = [Vector2i(3, 1), Vector2i(0, 2), Vector2i(3, 3), Vector2i(5, 3), Vector2i(5, 4), Vector2i(8, 4), Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)]
const SNOW_COORDS: = [Vector2i(4, 2), Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3)]
const SAND_COORDS: = [Vector2i(4, 4), Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5)]
const GRAVEL_COORDS: = [Vector2i(0, 1)]

const PATH_GRASS_HITS: = [
	"res://sounds/grass/Grass_hit1.ogg", 
	"res://sounds/grass/Grass_hit2.ogg", 
	"res://sounds/grass/Grass_hit3.ogg", 
	"res://sounds/grass/Grass_hit4.ogg", 
	"res://sounds/grass/Grass_hit5.ogg", 
	"res://sounds/grass/Grass_hit6.ogg", 
]
const PATH_GRASS_JUMPS: = [
	"res://sounds/grass/Grass_jump1.wav", 
	"res://sounds/grass/Grass_jump2.wav", 
	"res://sounds/grass/Grass_jump3.wav", 
	"res://sounds/grass/Grass_jump4.wav", 
]

const PATH_STONE_HITS: = [
	"res://sounds/stone/Stone_hit1.ogg", 
	"res://sounds/stone/Stone_hit2.ogg", 
	"res://sounds/stone/Stone_hit3.ogg", 
	"res://sounds/stone/Stone_hit4.ogg", 
	"res://sounds/stone/Stone_hit5.ogg", 
	"res://sounds/stone/Stone_hit6.ogg", 
]
const PATH_STONE_JUMPS: = [
	"res://sounds/stone/Stone_jump1.wav", 
	"res://sounds/stone/Stone_jump2.wav", 
	"res://sounds/stone/Stone_jump3.wav", 
	"res://sounds/stone/Stone_jump4.wav", 
]

const PATH_WOOD_HITS: = [
	"res://sounds/wood/Wood_hit1.ogg", 
	"res://sounds/wood/Wood_hit2.ogg", 
	"res://sounds/wood/Wood_hit3.ogg", 
	"res://sounds/wood/Wood_hit4.ogg", 
	"res://sounds/wood/Wood_hit5.ogg", 
	"res://sounds/wood/Wood_hit6.ogg", 
]
const PATH_WOOD_JUMPS: = [
	"res://sounds/wood/Wood_jump1.wav", 
	"res://sounds/wood/Wood_jump2.wav", 
	"res://sounds/wood/Wood_jump3.wav", 
	"res://sounds/wood/Wood_jump4.wav", 
]

const PATH_SNOW_HITS: = [
	"res://sounds/snow/Snow_dig1.ogg", 
	"res://sounds/snow/Snow_dig2.ogg", 
	"res://sounds/snow/Snow_dig3.ogg", 
	"res://sounds/snow/Snow_dig4.ogg"
]
const PATH_SNOW_JUMPS: = [
	"res://sounds/snow/Snow_jump1.wav.mp3", 
	"res://sounds/snow/Snow_jump2.wav.mp3", 
	"res://sounds/snow/Snow_jump3.wav.mp3", 
	"res://sounds/snow/Snow_jump4.wav.mp3"
]

const PATH_SAND_HITS: = [
	"res://sounds/sand/Sand_hit1.ogg.mp3", 
	"res://sounds/sand/Sand_hit2.ogg.mp3", 
	"res://sounds/sand/Sand_hit3.ogg.mp3", 
	"res://sounds/sand/Sand_hit4.ogg.mp3", 
	"res://sounds/sand/Sand_hit5.ogg.mp3"
]
const PATH_SAND_JUMPS: = [
	"res://sounds/sand/Sand_jump1.wav.mp3", 
	"res://sounds/sand/Sand_jump2.wav.mp3", 
	"res://sounds/sand/Sand_jump3.wav.mp3", 
	"res://sounds/sand/Sand_jump4.wav.mp3"
]

const PATH_GRAVEL_HITS: = [
	"res://sounds/gravel/Gravel_hit1.ogg", 
	"res://sounds/gravel/Gravel_hit2.ogg", 
	"res://sounds/gravel/Gravel_hit3.ogg", 
	"res://sounds/gravel/Gravel_hit4.ogg"
]

const PATH_GRAVEL_JUMP: = [
	"res://sounds/gravel/Gravel_jump1.wav.mp3", 
	"res://sounds/gravel/Gravel_jump2.wav.mp3", 
	"res://sounds/gravel/Gravel_jump3.wav.mp3", 
	"res://sounds/gravel/Gravel_jump4.wav.mp3"
]

const PATH_HIT: = "res://sounds/hit.wav"
const PATH_SLAP_1: = "res://sounds/slap1.wav"
const PATH_SLAP_2: = "res://sounds/slap2.wav"
const PATH_SLAP_3: = "res://sounds/slap3.wav"
const PATH_SLAP_4: = "res://sounds/slap4.wav"

const PATH_DAMAGE_1: = "res://sounds/Player_hurt1.ogg.mp3"
const PATH_DAMAGE_2: = "res://sounds/Player_hurt2.ogg.mp3"
const PATH_DAMAGE_3: = "res://sounds/Player_hurt3.ogg"
const PATH_WATER_DAMAGE_1: = "res://sounds/Player_hurt_drowning1.ogg"
const PATH_WATER_DAMAGE_2: = "res://sounds/Player_hurt_drowning2.ogg"
const PATH_WATER_DAMAGE_3: = "res://sounds/Player_hurt_drowning3.ogg"
const PATH_WATER_DAMAGE_4: = "res://sounds/Player_hurt_drowning4.ogg"

const PATH_SWIMMING: = [
	"res://sounds/water/Swim5.ogg.mp3", 
	"res://sounds/water/Swim6.ogg.mp3", 
	"res://sounds/water/Swim7.ogg.mp3", 
	"res://sounds/water/Swim8.ogg.mp3", 
	"res://sounds/water/Swim9.ogg.mp3", 
	"res://sounds/water/Swim10.ogg.mp3", 
	"res://sounds/water/Swim11.ogg.mp3", 
	"res://sounds/water/Swim12.ogg.mp3", 
	"res://sounds/water/Swim13.ogg.mp3", 
	"res://sounds/water/Swim14.ogg.mp3", 
	"res://sounds/water/Swim15.ogg.mp3", 
	"res://sounds/water/Swim16.ogg.mp3", 
	"res://sounds/water/Swim17.ogg.mp3", 
	"res://sounds/water/Swim18.ogg.mp3"
]

const PATH_FALL_DAMAGE_SMALL_OGG = "res://sounds/Fall_damage_small.ogg.mp3"
const PATH_FALL_DAMAGE_BIG_OGG = "res://sounds/Fall_damage_big.ogg.mp3"

const GRASS_HITS: = PATH_GRASS_HITS
const STONE_HITS: = PATH_STONE_HITS
const WOOD_HITS: = PATH_WOOD_HITS
const SNOW_HITS: = PATH_SNOW_HITS
const SAND_HITS: = PATH_SAND_HITS
const GRAVEL_HITS: = PATH_GRAVEL_HITS

const GRASS_JUMPS: = PATH_GRASS_JUMPS
const STONE_JUMPS: = PATH_STONE_JUMPS
const WOOD_JUMPS: = PATH_WOOD_JUMPS
const SNOW_JUMPS: = PATH_SNOW_JUMPS
const SAND_JUMPS: = PATH_SAND_JUMPS
const GRAVEL_JUMPS: = PATH_GRAVEL_JUMP

const MIN_STEP_SPEED: = 45.0
const WALK_STEP_INTERVAL: = 0.38
const RUN_STEP_INTERVAL: = 0.27
var _step_timer: = 0.0
var _prev_on_floor: = false
var _was_moving: = false
const FEET_SAMPLE_OFFSET: = 22.0

const SWIM_MIN_SPEED: = 200.0
const SWIM_STROKE_INTERVAL: = 0.75
var _swim_timer: = 0.0
var _swim_active: = false


const ACCEL_GROUND: = 3600.0
const DECEL_GROUND: = 4200.0
const ACCEL_AIR: = 2200.0
const DECEL_AIR: = 2000.0
const TURN_BOOST: = 1.7

const UP_GRAVITY_MULT: = 1.0
const JUMP_CUT_MULT: = 2.0
const DOWN_GRAVITY_MULT: = 1.6
const APEX_THRESHOLD: = 55.0
const APEX_ACCEL_BONUS: = 900.0
const MAX_FALL_SPEED: = 1400.0

var _last_surface_kind: StringName = &"grass"

@onready var footsteps: AudioStreamPlayer2D = $footsteps
@onready var water: AudioStreamPlayer2D = $water
@onready var underwater: AudioStreamPlayer2D = $underwater
@onready var burst: AudioStreamPlayer2D = $burst
@onready var save: AudioStreamPlayer2D = $save
@onready var prohibited: Sprite2D = $"../CanvasLayer/SpriteAnchor/Prohibited"

var _was_on_floor_for_audio: = false

func _broadcast_step_sfx(surface_kind: StringName, pos: Vector2) -> void :
	var candidates: Array = []
	match String(surface_kind):
		"grass": candidates = GRASS_HITS
		"stone": candidates = STONE_HITS
		"wood": candidates = WOOD_HITS
		"snow": candidates = SNOW_HITS
		"sand": candidates = SAND_HITS
		"gravel": candidates = GRAVEL_HITS
		_: candidates = GRASS_HITS
	if candidates.is_empty(): return
	var path: = String(candidates[randi() % candidates.size()])
	var world: = get_tree().get_first_node_in_group("world")
	if world == null: return
	var vol: = -6.0
	var pid: = multiplayer.get_unique_id()
	if multiplayer.is_server():
		world._server_broadcast_player_sfx(pid, world.SFX_KIND_STEP, path, pos, vol)
	else:
		world.rpc_id(1, "srv_request_player_sfx", world.SFX_KIND_STEP, path, pos, vol)

func _broadcast_jump_sfx(surface_kind: StringName, pos: Vector2) -> void :
	var candidates: Array = []
	match String(surface_kind):
		"grass": candidates = GRASS_JUMPS
		"stone": candidates = STONE_JUMPS
		"wood": candidates = WOOD_JUMPS
		"snow": candidates = SNOW_JUMPS
		"sand": candidates = SAND_JUMPS
		"gravel": candidates = GRAVEL_JUMPS
		_: candidates = GRASS_JUMPS
	if candidates.is_empty(): return
	var path: = String(candidates[randi() % candidates.size()])
	var world: = get_tree().get_first_node_in_group("world")
	if world == null: return
	var vol: = -3.0
	var pid: = multiplayer.get_unique_id()
	if multiplayer.is_server():
		world._server_broadcast_player_sfx(pid, world.SFX_KIND_JUMP, path, pos, vol)
	else:
		world.rpc_id(1, "srv_request_player_sfx", world.SFX_KIND_JUMP, path, pos, vol)

func _broadcast_hit_sfx(path: String, pos: Vector2, loud: = false) -> void :
	if path == "": return
	var world: = get_tree().get_first_node_in_group("world")
	if world == null: return
	var vol: = (2.0 if loud else 0.0)
	var pid: = multiplayer.get_unique_id()
	if multiplayer.is_server():
		world._server_broadcast_player_sfx(pid, world.SFX_KIND_HIT, path, pos, vol)
	else:
		world.rpc_id(1, "srv_request_player_sfx", world.SFX_KIND_HIT, path, pos, vol)



const AOU_IFRAMES: = 0.75
const AOU_REGEN_SECS: = 20.0
var _aou_iframe_t: = 0.0

func _aou_selected_and_consume() -> bool:

	var world: = get_tree().get_first_node_in_group("world")
	var hotbar: = get_tree().get_first_node_in_group("hotbar")
	if world == null or hotbar == null:
		return false


	var selected_id: = 0
	if hotbar.has_method("get_selected_item_id"):
		selected_id = int(hotbar.call("get_selected_item_id"))


	var item_aou: = 0

	if world.has_method("get_item_aou_id"):
		item_aou = int(world.call("get_item_aou_id"))
	else:

		var v = world.get("ITEM_AOU")
		if typeof(v) == TYPE_INT:
			item_aou = int(v)




	if item_aou == 0 or selected_id != item_aou:
		return false


	if hotbar.has_method("consume_selected"):
		var took: = int(hotbar.call("consume_selected", 1))
		return took > 0
	return false

const AOU_CONSUME_ON_REPLAY: = true


func _is_aou_fx_active() -> bool:
	if save == null or not save.playing:
		return false
	var world: = get_tree().get_first_node_in_group("world")
	return world and world.has_method("is_aou_anim_active") and bool(world.call("is_aou_anim_active"))

func _would_hit_be_lethal(amount: int) -> bool:
	var remaining = max(0, amount)

	if absorption > 0 and remaining > 0:
		remaining -= min(remaining, absorption)

	return (health - remaining) <= 0

func _maybe_replay_aou_if_lethal(amount: int) -> void :

	if _aou_iframe_t > 0.0 or not _is_aou_fx_active():
		return

	if not _would_hit_be_lethal(amount):
		return

	var world: = get_tree().get_first_node_in_group("world")


	if not AOU_CONSUME_ON_REPLAY:
		return

	var did_consume: = _aou_selected_and_consume()
	if not did_consume:
		return


	health = 1
	_update_hearts_ui()
	_aou_iframe_t = AOU_IFRAMES
	add_absorption(4)


	if AOU_REGEN_SECS > 0.0:
		if _regen_effect_active:
			_regen_effect_time = max(_regen_effect_time, AOU_REGEN_SECS)
		else:
			start_regeneration(AOU_REGEN_SECS)


	if save:
		save.stop();save.play()
	if world and world.has_method("rpc_play_aou_animation_local"):
		world.rpc_play_aou_animation_local(true)
	if world and save.stream:
		var path: = String(save.stream.resource_path)
		if path != "":
			var pos: = global_position
			var vol: = 4.0
			var pid: = multiplayer.get_unique_id()
			if multiplayer.is_server():
				world._server_broadcast_player_sfx(pid, world.SFX_KIND_AOU, path, pos, vol)
			else:
				world.rpc_id(1, "srv_request_player_sfx", world.SFX_KIND_AOU, path, pos, vol)

func _trigger_aou_save() -> void :
	health = 1
	_update_hearts_ui()
	_aou_iframe_t = AOU_IFRAMES
	_hurt_active = false
	_state = AnimState.IDLE
	_set_falling_audio(false)
	_punch_camera_zoom()
	add_absorption(4)


	if AOU_REGEN_SECS > 0.0:
		if _regen_effect_active:
			_regen_effect_time = max(_regen_effect_time, AOU_REGEN_SECS)
		else:
			start_regeneration(AOU_REGEN_SECS)

	if save:
		if save.playing: save.stop()
		save.play()
	var world: = get_tree().get_first_node_in_group("world")
	if world and world.has_method("rpc_play_aou_animation_local"):
		world.rpc_play_aou_animation_local(true)
	if world and save.stream:
		var path: = String(save.stream.resource_path)
		if path != "":
			var pos: = global_position
			var vol: = 4.0
			var pid: = multiplayer.get_unique_id()
			if multiplayer.is_server():
				world._server_broadcast_player_sfx(pid, world.SFX_KIND_AOU, path, pos, vol)
			else:
				world.rpc_id(1, "srv_request_player_sfx", world.SFX_KIND_AOU, path, pos, vol)

	if world:
		var pos: = global_position
		if multiplayer.is_server():
			world.srv_spawn_aou_particles(pos)
		else:
			world.rpc_id(1, "srv_spawn_aou_particles", pos)


const USE_EXHAUSTION: = true
const EXH_THRESHOLD: = 4.0


const EXH_PER_METER_WALK: = 0.01
const EXH_PER_METER_SPRINT: = 0.1
const EXH_PER_JUMP: = 0.05
const EXH_PER_SPRINT_JUMP: = 0.2
const EXH_PER_ATTACK: = 0.1
const EXH_PER_MINE: = 0.005
const EXH_PER_DAMAGE_HALF_HEART: = 0.1
const EXH_PER_REGEN_HALF_HEART: = 6.0

var _cam_zoom_base: = Vector2.ONE
var _cam_zoom_tween: Tween

const CAM_ZOOM_HURT: = Vector2(1.1, 1.1)
const CAM_ZOOM_IN_TIME: = 0.06
const CAM_ZOOM_OUT_TIME: = 0.22

const ABYSS_Y: = 13000.0
const ABYSS_TICK_SEC: = 0.5
var _abyss_accum: = 0.0
var _abyss_inside: = false

var _input_locked: = false

@onready var fireyglow: PointLight2D = $FireyGlow

var exhaustion: float = 0.0


var _g_up: = 1700.0
var _g_down: = 1700.0
var _jump_v0: = 700.0


const WATER_ENTER_THRESHOLD: = 0.25
const WATER_SWIM_THRESHOLD: = 0.5
const WATER_BUOYANCY_GRAV: = 420.0
const WATER_ASCEND_SPEED: = 260.0
const WATER_DRAG_X: = 0.9
const WATER_EXIT_BOOST_VY: = -720.0
const WATER_PROBE_WIDTH_PX: = 14.0
const WATER_PROBE_TOP_PX: = -24.0
const WATER_PROBE_BOTTOM_PX: = 28.0
const WATER_PROBE_STEPS: = 7
const HURT_WATER_DURATION: = 0.4
var _hurt_time_left: = 0.0

var _just_exited_water: = false
var _pending_exit_pop: = false
var _exit_pop_vy: = WATER_EXIT_BOOST_VY

var _suspend_hurt_airborne: = false


const WATER_COORDS: = [Vector2i(4, 5)]

var _in_water: = false
var _submerged_frac: = 0.0
var _touched_water_in_air: = false


const UW_FALL_MIN_FRAME: = 0
const UW_FALL_MAX_FRAME: = 16
const UW_FALL_FPS: = 24.0

var _uw_fall_active: = false
var _uw_fall_frame_f: = 0.0
var _uw_fall_accum: = 0.0


@export var FALL_MULT_TARGET: = 1.6

func _cell_at_point_to_map(pt_world: Vector2) -> Vector2i:
	if tile_map_layer == null:
		return Vector2i(-1, -1)
	return tile_map_layer.local_to_map(tile_map_layer.to_local(pt_world))

func _is_water_cell(cell: Vector2i) -> bool:
	if tile_map_layer == null: return false
	if tile_map_layer.get_cell_source_id(cell) == -1: return false
	return tile_map_layer.get_cell_atlas_coords(cell) in WATER_COORDS

func _drive_underwater_fall_anim(delta: float) -> void :
	if _eating_active:
		return
	if animated_sprite_2d.animation != "fall":
		animated_sprite_2d.play("fall")

	if animated_sprite_2d.is_playing():
		animated_sprite_2d.stop()
	animated_sprite_2d.speed_scale = 0.0


	if not _uw_fall_active:
		_uw_fall_active = true
		_uw_fall_frame_f = float(clamp(animated_sprite_2d.frame, UW_FALL_MIN_FRAME, UW_FALL_MAX_FRAME))
		_uw_fall_accum = 0.0



	var dir: = (-1.0 if ( not _input_locked and Input.is_action_pressed("jump")) else 1.0)



	if (dir > 0.0 and int(_uw_fall_frame_f) >= UW_FALL_MAX_FRAME)\
	or (dir < 0.0 and int(_uw_fall_frame_f) <= UW_FALL_MIN_FRAME):
		animated_sprite_2d.frame = int(_uw_fall_frame_f)
		return


	_uw_fall_accum += delta * UW_FALL_FPS
	while _uw_fall_accum >= 1.0:
		_uw_fall_accum -= 1.0
		_uw_fall_frame_f += dir
		_uw_fall_frame_f = clamp(_uw_fall_frame_f, float(UW_FALL_MIN_FRAME), float(UW_FALL_MAX_FRAME))


	animated_sprite_2d.frame = int(_uw_fall_frame_f)

func _reset_uw_fall_anim() -> void :
	_uw_fall_active = false
	_uw_fall_accum = 0.0
	animated_sprite_2d.speed_scale = 1.0

func _measure_submergence() -> float:

	if tile_map_layer == null: return 0.0
	var top: = global_position + Vector2(0.0, WATER_PROBE_TOP_PX)
	var bottom: = global_position + Vector2(0.0, WATER_PROBE_BOTTOM_PX)
	var hits: = 0
	for i in WATER_PROBE_STEPS:
		var t: = float(i) / float(max(1, WATER_PROBE_STEPS - 1))
		var y = lerp(top.y, bottom.y, t)

		var left: = global_position.x - WATER_PROBE_WIDTH_PX * 0.5
		var right: = global_position.x + WATER_PROBE_WIDTH_PX * 0.5
		var cells: = [
			_cell_at_point_to_map(Vector2(left, y)), 
			_cell_at_point_to_map(Vector2(global_position.x, y)), 
			_cell_at_point_to_map(Vector2(right, y)), 
		]
		var any_water: = false
		for c in cells:
			if _is_water_cell(c):
				any_water = true
				break
		if any_water:
			hits += 1
	return float(hits) / float(WATER_PROBE_STEPS)

func _play_water_enter() -> void :
	if water:
		water.stream = _pick_random_stream(PATH_ENTER_WATER)
		if water.stream: water.play()

func _play_water_exit() -> void :
	if water:
		water.stream = _pick_random_stream(PATH_EXIT_WATER)
		if water.stream: water.play()

func _retune_jump_keep_same_HT() -> void :

	var g_def: float = ProjectSettings.get_setting("physics/2d/default_gravity")
	var up_mult: = UP_GRAVITY_MULT
	var down_mult_current: = DOWN_GRAVITY_MULT
	var v0: = - JUMP_VELOCITY

	var g_up_old: = g_def * up_mult
	var H: = (v0 * v0) / (2.0 * g_up_old)
	var T_up: = v0 / g_up_old
	var T_down: = sqrt(2.0 * H / (g_def * down_mult_current))
	var T: = T_up + T_down


	var r = max(1.0, FALL_MULT_TARGET)




	var sqrt_g_up: = sqrt(2.0 * H) * (1.0 + 1.0 / sqrt(r)) / T
	_g_up = sqrt_g_up * sqrt_g_up
	_g_down = _g_up * r


	_jump_v0 = sqrt(2.0 * _g_up * H)

func _add_exhaustion(amount: float) -> void :
	if not USE_EXHAUSTION or amount <= 0.0:
		return
	exhaustion += amount


	while exhaustion >= EXH_THRESHOLD:
		exhaustion -= EXH_THRESHOLD
		if saturation > 0.0:
			var take = min(1.0, saturation)
			saturation -= take
			_refresh_shake_flags_from_values()
		elif hunger > 0:
			_set_hunger(hunger - 1)

func _play_step_hit(running: bool) -> void :
	var banks: = _surface_banks()
	var stream: = _pick_random_stream(banks["hits"])
	if stream == null or footsteps == null: return
	footsteps.stream = stream
	footsteps.pitch_scale = 1.4 if running else 1.0
	footsteps.play()

func _play_jump_one_shot(running: bool) -> void :
	var banks: = _surface_banks()
	var stream: = _pick_random_stream(banks["jumps"])
	if stream == null or footsteps == null: return
	footsteps.stream = stream
	footsteps.pitch_scale = 1.4 if running else 1.0
	footsteps.play()
	_broadcast_jump_sfx(_last_surface_kind, global_position)

func _play_swim_one_shot(speed: float) -> void :
	if swim == null: return
	var s: = _pick_random_stream(PATH_SWIMMING)
	if s == null: return
	swim.stream = s

	swim.pitch_scale = clamp(0.95 + speed / 900.0, 0.95, 1.15)
	swim.play()

func _update_swim_cadence(delta: float) -> void :
	var underwater_now: = (_submerged_frac >= WATER_SWIM_THRESHOLD)

	var horiz = abs(velocity.x)
	var vert = abs(velocity.y)
	var speed = max(horiz, vert)

	var moving = underwater_now and speed >= SWIM_MIN_SPEED and not _dead and not _eating_active


	if not _swim_active and moving:
		_swim_timer = 0.0
		_play_swim_one_shot(speed)
		_swim_timer = SWIM_STROKE_INTERVAL * 0.35
		_swim_active = true
	elif _swim_active and not moving:
		_swim_timer = 0.0
		_swim_active = false

		if swim and swim.playing and swim.stream: swim.stop()


	if not _swim_active:
		return

	var interval = max(0.2, SWIM_STROKE_INTERVAL * (1.0 - clamp(speed, 0.0, 600.0) / 1600.0))
	_swim_timer += delta
	if _swim_timer >= interval:
		_swim_timer -= interval
		_play_swim_one_shot(speed)

func _update_step_cadence(delta: float, running: bool) -> void :
	var on_floor: = is_on_floor()
	var speed = abs(velocity.x)
	var moving = on_floor and not _hurt_active and not _dead and not _eating_active and speed >= MIN_STEP_SPEED


	if on_floor != _prev_on_floor:
		_prev_on_floor = on_floor
		_step_timer = 0.0
		if on_floor and moving:
			_play_step_hit(running)
			_broadcast_step_sfx(_last_surface_kind, global_position)

			_step_timer = (RUN_STEP_INTERVAL if running else WALK_STEP_INTERVAL) * 0.35
		return


	if moving and not _was_moving:
		_play_step_hit(running)
		_broadcast_step_sfx(_last_surface_kind, global_position)
		_step_timer = (RUN_STEP_INTERVAL if running else WALK_STEP_INTERVAL) * 0.35
	elif not moving and _was_moving:
		_step_timer = 0.0

	_was_moving = moving
	if not moving:
		return

	_step_timer += delta
	var interval: = RUN_STEP_INTERVAL if running else WALK_STEP_INTERVAL
	if _step_timer >= interval:
		_step_timer -= interval
		_play_step_hit(running)
		_broadcast_step_sfx(_last_surface_kind, global_position)

func _pick_random_stream(paths: Array) -> AudioStream:
	if paths.is_empty():
		return null
	var p: = String(paths[randi() % paths.size()])
	return _audio(p)

func _surface_banks() -> Dictionary:
	var kind: = _surface_kind_at_feet()
	if kind != &"unknown": _last_surface_kind = kind
	else: kind = _last_surface_kind
	match kind:
		&"stone": return {"hits": STONE_HITS, "jumps": STONE_JUMPS}
		&"wood": return {"hits": WOOD_HITS, "jumps": WOOD_JUMPS}
		&"snow": return {"hits": SNOW_HITS, "jumps": SNOW_JUMPS}
		&"sand": return {"hits": SAND_HITS, "jumps": SAND_JUMPS}
		&"gravel": return {"hits": GRAVEL_HITS, "jumps": GRAVEL_JUMPS}
		_: return {"hits": GRASS_HITS, "jumps": GRASS_JUMPS}

func _pick_random(arr: Array) -> AudioStream:
	if arr.is_empty():
		return null
	var path = arr[randi() % arr.size()]
	if typeof(path) == TYPE_STRING:
		return load(path) as AudioStream
	return path as AudioStream


var health: = 10
var MAXIMUM_BLOCK_FALL: = 5
const FALL_EXTRA_EVERY_BLOCKS: = 2
const HURT_BOUNCE_VELOCITY: = -350.0
const FALL_BLOCK_FALLBACK: = 74.0


const HEART = preload("res://hud/heart.png")
const HALF_HEART = preload("res://hud/half heart.png")
const HEARTDEAD = preload("res://hud/heartdead.png")


const HEARTWHITE = preload("res://hud/heartwhite.png")
const HALF_HEART_WHITE = preload("res://hud/half heart white.png")
const HEARTDEADWHITE = preload("res://hud/heartdeadwhite.png")


const HEARTWHITEDAMAGE = preload("res://hud/heartwhitedamage.png")
const HALFHEARTWHITEDAMAGE = preload("res://hud/halfheartwhitedamage.png")

var _fall_peak_y: = 0.0
var _max_fall_px: = 0.0
const FALL_DAMAGE_AMOUNT: = 1

@onready var heart: Sprite2D = $"../CanvasLayer/health/Heart"
@onready var heart_2: Sprite2D = $"../CanvasLayer/health/Heart2"
@onready var heart_3: Sprite2D = $"../CanvasLayer/health/Heart3"
@onready var heart_4: Sprite2D = $"../CanvasLayer/health/Heart4"
@onready var heart_5: Sprite2D = $"../CanvasLayer/health/Heart5"

var hunger: = 10

const FOOD = preload("res://hud/food.png")
const HALF_FOOD = preload("res://hud/half food.png")
const FOODGONE = preload("res://hud/foodgone.png")

@onready var food: Sprite2D = $"../CanvasLayer/hunger/Food"
@onready var food_2: Sprite2D = $"../CanvasLayer/hunger/Food2"
@onready var food_3: Sprite2D = $"../CanvasLayer/hunger/Food3"
@onready var food_4: Sprite2D = $"../CanvasLayer/hunger/Food4"
@onready var food_5: Sprite2D = $"../CanvasLayer/hunger/Food5"
@onready var eat: AudioStreamPlayer2D = $eat

@onready var hurtbox_area: Area2D = get_node_or_null("Hurtbox")
@onready var hurtbox_shape: CollisionShape2D = (hurtbox_area.get_node_or_null("CollisionShape2D") if hurtbox_area else null)


const MAX_HUNGER: = 10
const HUNGER_DECAY_SEC: = 60.0
const HUNGER_RUNNING_MULT: = 1.25

const FULL_REGEN_TICK_SEC: = 0.5
const NORMAL_REGEN_TICK_SEC: = 4.0


const HUNGER_PULSE_MIN: = 1
const HUNGER_PULSE_MAX: = 3
const SAT_EPS: = 0.01
const HUNGER_PULSE_PERIOD: = 1.2
const HUNGER_PULSE_DUTY: = 0.12
var _hunger_pulse_t: = 0.0

const HUNGER_PULSE_PERIOD_BASE: = 1.25
const HUNGER_PULSE_ON_MIN: = 0.08
const HUNGER_PULSE_ON_MAX: = 0.2
const HUNGER_PULSE_OFF_MIN: = 0.45
const HUNGER_PULSE_OFF_MAX: = 3

enum HungerShakeMode{OFF, PULSE, CONT}
var _hunger_shake_mode: = HungerShakeMode.OFF

var _hunger_pulse_state: = false
var _hunger_pulse_left: = 0.0

var _hunger_accum: = 0.0
var _regen_accum: = 0.0


var _regen_effect_time: = 0.0
var _regen_effect_active: = false

var _regen_wave_active: = false
var _regen_wave_t: = 0.0
const REGEN_WAVE_SPEED: = 4.2
const REGEN_WAVE_AMPL: = 3.0
const REGEN_WAVE_PHASE_STEP: = 0.6

const ABSORB = preload("uid://bp64lfi8tnxmy")
const ABSORB_WHITE = preload("uid://jr0550nb3khf")
const ABSORB_WHITE_DAMAGE = preload("uid://cy0vwmdcdyurv")
const HALF_ABSORB = preload("uid://dbr2hjoi6s5ek")
const HALF_ABSORB_WHITE = preload("uid://dttisryoci5qy")
const HALF_ABSORB_WHITE_DAMAGE = preload("uid://bko2xjj0exc3k")

@onready var absorb: Sprite2D = $"../CanvasLayer/health/Absorb"
@onready var absorb_2: Sprite2D = $"../CanvasLayer/health/Absorb2"
@onready var absorb_3: Sprite2D = $"../CanvasLayer/health/Absorb3"
@onready var absorb_4: Sprite2D = $"../CanvasLayer/health/Absorb4"
@onready var absorb_5: Sprite2D = $"../CanvasLayer/health/Absorb5"

var absorption: = 0
const MAX_ABSORPTION: = 10


func _absorb_sprites() -> Array:
	return [absorb, absorb_2, absorb_3, absorb_4, absorb_5]

func _update_absorb_ui() -> void :

	var sprites: = _absorb_sprites()
	for i in sprites.size():
		var s: Sprite2D = sprites[i]
		var seg = clamp(absorption - i * 2, 0, 2)
		match seg:
			2:
				s.texture = ABSORB
				s.visible = true
			1:
				s.texture = HALF_ABSORB
				s.visible = true
			_:
				s.texture = null
				s.visible = false


var _absorb_flash_token: = 0

func _set_absorb_white_damage_for_value(pips: int) -> void :
	var sprites: = _absorb_sprites()
	for i in sprites.size():
		var s: Sprite2D = sprites[i]
		var seg = clamp(pips - i * 2, 0, 2)
		match seg:
			2:
				s.texture = ABSORB_WHITE_DAMAGE
				s.visible = true
			1:
				s.texture = HALF_ABSORB_WHITE_DAMAGE
				s.visible = true
			_:
				s.texture = null
				s.visible = false


func _set_absorb_white(on: bool) -> void :

	if not on:
		_update_absorb_ui()
		return
	var sprites: = _absorb_sprites()
	for i in sprites.size():
		var s: Sprite2D = sprites[i]
		var seg = clamp(absorption - i * 2, 0, 2)
		match seg:
			2:
				s.texture = ABSORB_WHITE
				s.visible = true
			1:
				s.texture = HALF_ABSORB_WHITE
				s.visible = true
			_:
				s.texture = null
				s.visible = false

func _flash_absorb_gain(times: int, total_duration: float = 0.5) -> void :

	_absorb_flash_token += 1
	var token: = _absorb_flash_token

	times = max(1, times)
	var slot: = total_duration / float(times * 2)

	await get_tree().process_frame
	for _i in times:
		if token != _absorb_flash_token: break
		_set_absorb_white(true)
		await get_tree().create_timer(slot).timeout

		if token != _absorb_flash_token: break
		_set_absorb_white(false)
		await get_tree().create_timer(slot).timeout


	if token == _absorb_flash_token:
		_update_absorb_ui()

func add_absorption(amount: int) -> void :
	if amount == 0: return
	var prev: = absorption
	absorption = clamp(absorption + amount, 0, MAX_ABSORPTION)
	_update_absorb_ui()


	if absorption > prev:
		_flash_absorb_gain(2, 0.5)


func _flash_absorb_previous_damage(prev_pips: int, times: int, total_duration: float = 0.5) -> void :
	_absorb_flash_token += 1
	var token: = _absorb_flash_token
	times = max(1, times)
	var slot: = total_duration / float(times * 2)

	await get_tree().process_frame
	for _i in times:
		if token != _absorb_flash_token: break
		_set_absorb_white_damage_for_value(prev_pips)
		await get_tree().create_timer(slot).timeout

		if token != _absorb_flash_token: break
		_update_absorb_ui()
		await get_tree().create_timer(slot).timeout

	if token == _absorb_flash_token:
		_update_absorb_ui()


const BUBBLE = preload("res://hud/bubble.png")
const BURST = preload("res://hud/Burst.png")
const BUBBLEPOPPED = preload("res://hud/bubblepopped.png")

@onready var oxygenbar: Control = $"../CanvasLayer/oxygen"
@onready var bubble: Sprite2D = $"../CanvasLayer/oxygen/Bubble"
@onready var bubble_2: Sprite2D = $"../CanvasLayer/oxygen/Bubble2"
@onready var bubble_3: Sprite2D = $"../CanvasLayer/oxygen/Bubble3"
@onready var bubble_4: Sprite2D = $"../CanvasLayer/oxygen/Bubble4"
@onready var bubble_5: Sprite2D = $"../CanvasLayer/oxygen/Bubble5"


const OXYGEN_MAX: = 5
const OXYGEN_LOSS_SEC: = 2.5
const OXYGEN_REFILL_SEC: = 0.5
const DROWN_TICK_SEC: = 1.0

var oxygen: = OXYGEN_MAX
var _oxy_decay_accum: = 0.0
var _oxy_refill_accum: = 0.0
var _drown_accum: = 0.0
var _oxy_burst_token: = 0

func _oxygen_bubbles() -> Array:
	return [bubble, bubble_2, bubble_3, bubble_4, bubble_5]

func _set_oxygen(new_val: int) -> void :
	if _character == CharacterKind.FIREY:
		oxygen = 0
	else:
		oxygen = clamp(new_val, 0, OXYGEN_MAX)
	burst.play()
	_update_oxygen_ui()

func _update_oxygen_ui() -> void :
	if not is_instance_valid(oxygenbar): return
	var sprites: = _oxygen_bubbles()
	for i in sprites.size():

		if (i + 1) <= oxygen:
			sprites[i].texture = BUBBLE
		else:

			if sprites[i].texture != BURST:
				sprites[i].texture = BUBBLEPOPPED


	var show_bar: = (_submerged_frac >= WATER_ENTER_THRESHOLD) or (oxygen < OXYGEN_MAX)
	oxygenbar.visible = show_bar

func _burst_bubble(index_from_left: int, flash_time: = 0.18) -> void :

	var idx = clamp(index_from_left - 1, 0, 4)
	var sprites: = _oxygen_bubbles()
	if idx >= sprites.size(): return
	_oxy_burst_token += 1
	var token: = _oxy_burst_token
	var s: Sprite2D = sprites[idx]
	s.texture = BURST

	await get_tree().create_timer(flash_time).timeout
	if token == _oxy_burst_token and is_instance_valid(s):
		s.texture = BUBBLEPOPPED

func _update_oxygen_logic(delta: float) -> void :
	var underwater_now: = (_submerged_frac >= WATER_ENTER_THRESHOLD)
	var is_firey: = (_character == CharacterKind.FIREY)


	if is_firey:
		oxygen = 0


	oxygenbar.visible = underwater_now or (oxygen < OXYGEN_MAX)
	if is_firey:
		oxygenbar.visible = false

	if underwater_now:

		if not is_firey:
			_oxy_refill_accum = _oxy_refill_accum
			_oxy_decay_accum += delta
			while _oxy_decay_accum >= OXYGEN_LOSS_SEC and oxygen > 0:
				_oxy_decay_accum -= OXYGEN_LOSS_SEC
				_burst_bubble(oxygen)
				_set_oxygen(oxygen - 1)


		if oxygen <= 0:
			_drown_accum += delta
			while _drown_accum >= DROWN_TICK_SEC and health > 0:
				_drown_accum -= DROWN_TICK_SEC
				_apply_damage(1)
	else:

		_drown_accum = 0.0


		if not is_firey:
			if oxygen < OXYGEN_MAX:
				_oxy_refill_accum += delta
				var regained_any: = false
				while _oxy_refill_accum >= OXYGEN_REFILL_SEC and oxygen < OXYGEN_MAX:
					_oxy_refill_accum -= OXYGEN_REFILL_SEC
					_set_oxygen(oxygen + 1)
					regained_any = true
				if regained_any:
					_oxy_decay_accum = 0.0
			else:
				oxygenbar.visible = false

func _update_prohibited_icon() -> void :
	if not is_instance_valid(prohibited):
		return

	prohibited.visible = (_character == CharacterKind.FIREY) and _in_water


enum AnimState{IDLE, WALK, RUN, JUMP, FALL, HURT, DEAD, TRANSITION}
var _state: = AnimState.IDLE
var _transitioning: = false
var _queued_loop: StringName = &""
var _ignore_next_landing_damage: = false

enum CharacterKind{LEAFY, FIREY, COINY, PIN, TENNISBALL, GOLFBALL, PENCIL, MATCH, NEEDLE, PEN, ICECUBE, TEARDROP, ROCKY, FLOWER, BUBBLE, SNOWBALL, BLOCKY, WOODY, ERASER, SPONGY}

var _offsets: Dictionary = ANIM_X_OFFSETS
var _character: int = CharacterKind.LEAFY

const ANIM_X_OFFSETS: = {
	"default": 0.0, 
	"walk": -4.5, 
	"run": -7.0, 
	"towalk": -4.5, 
	"torun": -7.0, 
	"jump": -7.5, 
	"fall": -7.5, 
	"hurt": -7.5, 
	"dead": -7.5, 
	"eat": 0.0
}

const ANIM_X_OFFSETS_FIREY: = {
	"default": 0.0, 
	"walk": 2.0, 
	"run": 2.0, 
	"towalk": 2.0, 
	"torun": 2.0, 
	"jump": 2.0, 
	"fall": 2.0, 
	"hurt": 2.0, 
	"dead": 2.0, 
	"eat": 9.5
}

const ANIM_X_OFFSETS_COINY: = {
	"default": 0.0, 
	"walk": 1.0, 
	"run": 1.0, 
	"towalk": 1.0, 
	"torun": 1.0, 
	"jump": 1.0, 
	"fall": 1.0, 
	"hurt": 1.0, 
	"dead": 1.0, 
	"eat": 7.0
}

const ANIM_X_OFFSETS_PIN: = {
	"default": 0.0, 
	"walk": 0.0, 
	"run": 1.0, 
	"towalk": 0.0, 
	"torun": 1.0, 
	"jump": 1.0, 
	"fall": 1.0, 
	"hurt": 1.0, 
	"dead": 1.0, 
	"eat": 8.0
}

const ANIM_X_OFFSETS_TENNISBALL: = {
	"default": 0.0, 
	"walk": 0.0, 
	"run": 0.0, 
	"towalk": 0.0, 
	"torun": 0.0, 
	"jump": 0.0, 
	"fall": 0.0, 
	"hurt": 0.0, 
	"dead": 0.0, 
	"eat": 0.0
}

const ANIM_X_OFFSETS_PENCIL: = {
	"default": 0.0, 
	"walk": 0.0, 
	"run": 0.0, 
	"towalk": 0.0, 
	"torun": 0.0, 
	"jump": 0.0, 
	"fall": 0.0, 
	"hurt": 0.0, 
	"dead": 0.0, 
	"eat": 8.0
}

const ANIM_X_OFFSETS_MATCH: = {
	"default": 0.0, 
	"walk": 0.0, 
	"run": 0.0, 
	"towalk": 0.0, 
	"torun": 0.0, 
	"jump": 0.0, 
	"fall": 0.0, 
	"hurt": 0.0, 
	"dead": 0.0, 
	"eat": 10.0
}

const ANIM_X_OFFSETS_NEEDLE: = {
	"default": 0.0, 
	"walk": -1.0, 
	"run": -1.0, 
	"towalk": -1.0, 
	"torun": -1.0, 
	"jump": -1.0, 
	"fall": -1.0, 
	"hurt": -1.0, 
	"dead": -1.0, 
	"eat": -2.0
}

const ANIM_X_OFFSETS_TEARDROP: = {
	"default": 0.0, 
	"walk": 0.0, 
	"run": 0.0, 
	"towalk": 0.0, 
	"torun": 0.0, 
	"jump": 0.0, 
	"fall": 0.0, 
	"hurt": 0.0, 
	"dead": 0.0, 
	"eat": 6.0
}

const ANIM_X_OFFSETS_BLOCKY: = {
	"default": 0.0, 
	"walk": 0.0, 
	"run": 0.0, 
	"towalk": 0.0, 
	"torun": 0.0, 
	"jump": 0.0, 
	"fall": 0.0, 
	"hurt": 0.0, 
	"dead": 0.0, 
	"eat": 12.0
}

const ANIM_X_OFFSETS_WOODY: = {
	"default": 0.0, 
	"walk": 0.0, 
	"run": 0.0, 
	"towalk": 0.0, 
	"torun": 0.0, 
	"jump": 0.0, 
	"fall": 0.0, 
	"hurt": 0.0, 
	"dead": 0.0, 
	"eat": 12.0
}

const ANIM_X_OFFSETS_ERASER: = {
	"default": 0.0, 
	"walk": 0.0, 
	"run": 2.0, 
	"towalk": 0.0, 
	"torun": 2.0, 
	"jump": 4.0, 
	"fall": 4.0, 
	"hurt": 4.0, 
	"dead": 3.0, 
	"eat": 1.0
}


const LEAFY_PATH: = "res://Leafy.tres"
const FIREY_PATH: = "res://Firey.tres"
const COINY_PATH: = "res://Coiny.tres"
const PIN_PATH: = "res://Pin.tres"
const TENNISBALL_PATH: = "res://tennisball.tres"
const GOLFBALL_PATH: = "res://Golfball.tres"
const PENCIL_PATH: = "res://Pencil.tres"
const MATCH_PATH: = "res://Match.tres"
const NEEDLE_PATH: = "res://Needle.tres"
const PEN_PATH: = "res://Pen.tres"
const ICECUBE_PATH: = "res://Icecube.tres"
const TEARDROP_PATH: = "res://Teardrop.tres"
const ROCKY_PATH: = "res://Rocky.tres"
const FLOWER_PATH: = "res://Flower.tres"
const BUBBLE_PATH: = "res://bubble.tres"
const SNOWBALL_PATH: = "res://Snowball.tres"
const BLOCKY_PATH: = "res://Blocky.tres"
const WOODY_PATH: = "res://Woody.tres"
const ERASER_PATH: = "res://Eraser.tres"
const SPONGY_PATH: = "res://Spongy.tres"




func _sprite_frames(path: String) -> SpriteFrames:
	return _res(path) as SpriteFrames

@onready var leafy: CollisionShape2D = $Leafy
@onready var firey: CollisionShape2D = $Firey
@onready var coiny: CollisionShape2D = $Coiny
@onready var pin: CollisionShape2D = $Pin
@onready var tennis_ball: CollisionShape2D = $TennisBall
@onready var golfball: CollisionShape2D = $Golfball
@onready var pencil: CollisionShape2D = $Pencil
@onready var mmatch: CollisionShape2D = $Match
@onready var needle: CollisionShape2D = $Needle
@onready var pen: CollisionShape2D = $Pen
@onready var ice_cube: CollisionShape2D = $IceCube
@onready var teardrop: CollisionShape2D = $Teardrop
@onready var rocky: CollisionShape2D = $Rocky
@onready var flower: CollisionShape2D = $Flower
@onready var bubblee: CollisionShape2D = $Bubble
@onready var snowball: CollisionShape2D = $Snowball
@onready var blocky: CollisionShape2D = $Blocky
@onready var woody: CollisionShape2D = $Woody
@onready var eraser: CollisionShape2D = $Eraser
@onready var spongy: CollisionShape2D = $Spongy

const HURTBOX_MASK: = 1 << 7
var _local_attack_cd: = 0.0


var _jump_squash_tween: Tween
var _was_on_floor: = true


var _hurt_active: = false
var _dead: = false

var _eating_active: = false
var _pending_heal: = 0
var _pending_hunger: = 0
var _pending_sat: = 0.0
var _pending_absorb: = 0
var _pending_regen: = 0.0

const STARVE_TICK_SEC: = 4.0
var _starve_accum: = 0.0


const MAX_SATURATION: = 10.0
const SAT_COST_PER_HEAL: = 1.0
const SAT_DECAY_UNIT: = 1.0

var saturation: float = 0.0

const SAT_DEBUG: = true
var _sat_dbg_t: = 0.0

var _attack_cd: = 0.0

const SAT_CAPS_HUNGER: = true

var _hearts_flash_token: = 0


const HEART_SHAKE_THRESHOLD: = 3
const HUNGER_SHAKE_TRIGGER: = 0
const SHAKE_AMPL: = 2.0
const SHAKE_ENABLED: = true

var _hearts_shake_active: = false
var _hunger_shake_active: = false

var _heart_bases: Array[Vector2] = []
var _food_bases: Array[Vector2] = []

func hitsound():

	var underwater_now: = (_submerged_frac >= WATER_ENTER_THRESHOLD)
	var bank: = [
		PATH_WATER_DAMAGE_1, PATH_WATER_DAMAGE_2, PATH_WATER_DAMAGE_3, PATH_WATER_DAMAGE_4
	] if underwater_now else [
		PATH_DAMAGE_1, PATH_DAMAGE_2, PATH_DAMAGE_3
	]

	var stream: = _pick_random_stream(bank)
	if stream == null or hit == null:
		return

	hit.stream = stream
	hit.pitch_scale = 1.0
	hit.stop()
	hit.play()


	_broadcast_hit_sfx(stream.resource_path, global_position, false)

func _food_sprites() -> Array:
	return [food, food_2, food_3, food_4, food_5]

func _cache_ui_base_positions() -> void :
	_heart_bases.clear()
	for s in _heart_sprites():
		_heart_bases.append(s.position)
	_food_bases.clear()
	for s in _food_sprites():
		_food_bases.append(s.position)

func _apply_shake_to(sprites: Array, bases: Array, ampl: float) -> void :
	if bases.size() != sprites.size():
		_cache_ui_base_positions()
	var n = min(sprites.size(), bases.size())
	for i in n:
		var s: Sprite2D = sprites[i]
		if not is_instance_valid(s): continue
		var base = bases[i]
		var off: = Vector2(randf() * 2.0 - 1.0, randf() * 2.0 - 1.0) * ampl
		s.position = base + off

func _ensure_ui_bases() -> void :
	if _heart_bases.size() != _heart_sprites().size()\
	or _food_bases.size() != _food_sprites().size():
		_cache_ui_base_positions()

func _reset_positions(sprites: Array, bases: Array) -> void :

	if bases.size() != sprites.size():
		_cache_ui_base_positions()
	var n = min(sprites.size(), bases.size())
	for i in n:
		var s: Sprite2D = sprites[i]
		if is_instance_valid(s):
			s.position = bases[i]

func _refresh_shake_flags_from_values() -> void :
	if not _hud_enabled():
		return
	_ensure_ui_bases()


	var want_hearts: = (health <= HEART_SHAKE_THRESHOLD and not _dead)


	var new_mode: = HungerShakeMode.OFF
	if not _dead:
		if hunger <= 0:
			new_mode = HungerShakeMode.CONT
		elif saturation <= SAT_EPS:
			new_mode = HungerShakeMode.PULSE


	var mode_changed: = (new_mode != _hunger_shake_mode)
	if mode_changed:
		_reset_positions(_food_sprites(), _food_bases)
		_hunger_pulse_t = 0.0
		_hunger_pulse_left = 0.0
		_hunger_pulse_state = false

	_hunger_shake_mode = new_mode
	_hunger_shake_active = (new_mode != HungerShakeMode.OFF)


	if _hearts_shake_active and not want_hearts:
		_reset_positions(_heart_sprites(), _heart_bases)
	_hearts_shake_active = want_hearts

func _advance_hunger_pulse(delta: float) -> void :
	_hunger_pulse_left -= delta
	if _hunger_pulse_left <= 0.0:
		_hunger_pulse_state = not _hunger_pulse_state
		if _hunger_pulse_state:

			_hunger_pulse_left = randf_range(HUNGER_PULSE_ON_MIN, HUNGER_PULSE_ON_MAX) * HUNGER_PULSE_PERIOD_BASE
		else:

			_hunger_pulse_left = randf_range(HUNGER_PULSE_OFF_MIN, HUNGER_PULSE_OFF_MAX) * HUNGER_PULSE_PERIOD_BASE

func _apply_shake_food_random(prob: = 0.65) -> void :
	var sprites: = _food_sprites()
	for i in sprites.size():
		var s: Sprite2D = sprites[i]
		if not is_instance_valid(s): continue
		var base: = _food_bases[i]

		if randf() < prob:
			var ampl: = SHAKE_AMPL * (0.9 + 0.25 * randf())
			var off: = Vector2(randf() * 2.0 - 1.0, randf() * 2.0 - 1.0) * ampl
			s.position = base + off
		else:
			s.position = base

func _update_ui_shake(delta: float) -> void :
	if not _hud_enabled() or not SHAKE_ENABLED: return
	_ensure_ui_bases()


	if _regen_wave_active:
		_apply_hearts_regen_wave(delta)
	else:

		if _hearts_shake_active:
			_apply_shake_to(_heart_sprites(), _heart_bases, SHAKE_AMPL)
		else:

			_reset_positions(_heart_sprites(), _heart_bases)


	match _hunger_shake_mode:
		HungerShakeMode.CONT:
			_apply_shake_to(_food_sprites(), _food_bases, SHAKE_AMPL)
		HungerShakeMode.PULSE:
			_advance_hunger_pulse(delta)
			if _hunger_pulse_state:
				_apply_shake_food_random(0.65)
			else:
				_reset_positions(_food_sprites(), _food_bases)
		_:
			_reset_positions(_food_sprites(), _food_bases)

func _heart_sprites() -> Array:
	return [heart, heart_2, heart_3, heart_4, heart_5]

func _set_hearts_white(on: bool) -> void :

	if not on:
		_update_hearts_ui()
		return
	var sprites: = _heart_sprites()
	for i in sprites.size():
		var seg = clamp(health - i * 2, 0, 2)
		match seg:
			2: sprites[i].texture = HEARTWHITE
			1: sprites[i].texture = HALF_HEART_WHITE
			_: sprites[i].texture = HEARTDEADWHITE

func _flash_hearts(times: int, total_duration: float = 0.5) -> void :
	if not _hud_enabled(): return

	_hearts_flash_token += 1
	var token: = _hearts_flash_token

	times = max(1, times)
	var slot: = total_duration / float(times * 2)


	_call_deferred_flash_hearts(times, slot, token)


func _set_hearts_white_damage_for_health(hp: int) -> void :
	if not _hud_enabled(): return
	var sprites: = _heart_sprites()
	for i in sprites.size():
		var seg = clamp(hp - i * 2, 0, 2)
		match seg:
			2: sprites[i].texture = HEARTWHITEDAMAGE
			1: sprites[i].texture = HALFHEARTWHITEDAMAGE
			_: sprites[i].texture = HEARTDEADWHITE

func _flash_hearts_previous_damage(prev_hp: int, times: int, total_duration: float = 0.5) -> void :
	if not _hud_enabled(): return
	_hearts_flash_token += 1
	var token: = _hearts_flash_token

	times = max(1, times)
	var slot: = total_duration / float(times * 2)


	await get_tree().process_frame
	for _i in times:
		if token != _hearts_flash_token: break
		_set_hearts_white_damage_for_health(prev_hp)
		await get_tree().create_timer(slot).timeout

		if token != _hearts_flash_token: break
		_update_hearts_ui()
		await get_tree().create_timer(slot).timeout


	if token == _hearts_flash_token:
		_update_hearts_ui()

func _call_deferred_flash_hearts(times: int, slot: float, token: int) -> void :

	await get_tree().process_frame
	for _i in times:
		if token != _hearts_flash_token: break
		_set_hearts_white(true)
		await get_tree().create_timer(slot).timeout

		if token != _hearts_flash_token: break
		_set_hearts_white(false)
		await get_tree().create_timer(slot).timeout


	if token == _hearts_flash_token:
		_set_hearts_white(false)

func _sat_cap() -> float:
	return float(hunger)

func _set_hunger(new_val: int) -> void :
	hunger = clamp(new_val, 0, MAX_HUNGER)
	if SAT_CAPS_HUNGER:
		saturation = min(saturation, _sat_cap())
	_update_food_ui()


@rpc("any_peer", "call_local")
func cli_receive_damage(amount: int, impulse: Vector2) -> void :
	_apply_damage(amount)
	velocity.x = impulse.x


func _use_leafy() -> void :
	_character = CharacterKind.LEAFY
	_offsets = ANIM_X_OFFSETS

	animated_sprite_2d.frames = _sprite_frames(LEAFY_PATH)

	disable_all()
	leafy.disabled = false
	animated_sprite_2d.material = null

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(LEAFY_PATH)
	_sync_hurtbox_to_active_collider()

func _use_firey() -> void :
	_character = CharacterKind.FIREY
	_offsets = ANIM_X_OFFSETS_FIREY

	animated_sprite_2d.frames = _sprite_frames(FIREY_PATH)

	var mat: = CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	animated_sprite_2d.material = mat

	disable_all()
	firey.disabled = false
	fireyglow.enabled = true

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(FIREY_PATH)
	_sync_hurtbox_to_active_collider()
	oxygen = 0
	_update_oxygen_ui()

func _use_coiny() -> void :
	_character = CharacterKind.COINY
	_offsets = ANIM_X_OFFSETS_COINY

	animated_sprite_2d.frames = _sprite_frames(COINY_PATH)

	disable_all()
	coiny.disabled = false
	animated_sprite_2d.material = null

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(COINY_PATH)
	_sync_hurtbox_to_active_collider()

func _use_pin() -> void :
	_character = CharacterKind.PIN
	_offsets = ANIM_X_OFFSETS_PIN

	animated_sprite_2d.frames = _sprite_frames(PIN_PATH)

	disable_all()
	pin.disabled = false
	animated_sprite_2d.material = null

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(PIN_PATH)
	_sync_hurtbox_to_active_collider()

func _use_tb() -> void :
	_character = CharacterKind.TENNISBALL
	_offsets = ANIM_X_OFFSETS_TENNISBALL

	animated_sprite_2d.frames = _sprite_frames(TENNISBALL_PATH)

	disable_all()
	tennis_ball.disabled = false
	animated_sprite_2d.material = null

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(TENNISBALL_PATH)
	_sync_hurtbox_to_active_collider()

func _use_gb() -> void :
	_character = CharacterKind.GOLFBALL
	_offsets = ANIM_X_OFFSETS_TENNISBALL

	animated_sprite_2d.frames = _sprite_frames(GOLFBALL_PATH)

	disable_all()
	golfball.disabled = false
	animated_sprite_2d.material = null

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(GOLFBALL_PATH)
	_sync_hurtbox_to_active_collider()

func _use_pencil() -> void :
	_character = CharacterKind.PENCIL
	_offsets = ANIM_X_OFFSETS_PENCIL

	animated_sprite_2d.frames = _sprite_frames(PENCIL_PATH)

	disable_all()
	pencil.disabled = false
	animated_sprite_2d.material = null

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(PENCIL_PATH)
	_sync_hurtbox_to_active_collider()

func _use_match() -> void :
	_character = CharacterKind.MATCH
	_offsets = ANIM_X_OFFSETS_MATCH

	animated_sprite_2d.frames = _sprite_frames(MATCH_PATH)

	disable_all()
	mmatch.disabled = false
	animated_sprite_2d.material = null

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(MATCH_PATH)
	_sync_hurtbox_to_active_collider()

func _use_needle() -> void :
	_character = CharacterKind.NEEDLE
	_offsets = ANIM_X_OFFSETS_NEEDLE

	animated_sprite_2d.frames = _sprite_frames(NEEDLE_PATH)

	disable_all()
	needle.disabled = false
	animated_sprite_2d.material = null

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(NEEDLE_PATH)
	_sync_hurtbox_to_active_collider()

func _use_pen() -> void :
	_character = CharacterKind.PEN
	_offsets = ANIM_X_OFFSETS_PENCIL

	animated_sprite_2d.frames = _sprite_frames(PEN_PATH)

	disable_all()
	pen.disabled = false
	animated_sprite_2d.material = null

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(PEN_PATH)
	_sync_hurtbox_to_active_collider()

func _use_icecube() -> void :
	_character = CharacterKind.ICECUBE
	_offsets = ANIM_X_OFFSETS_TENNISBALL

	animated_sprite_2d.frames = _sprite_frames(ICECUBE_PATH)

	disable_all()
	ice_cube.disabled = false
	animated_sprite_2d.material = null

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(ICECUBE_PATH)
	_sync_hurtbox_to_active_collider()

func _use_teardrop() -> void :
	_character = CharacterKind.TEARDROP
	_offsets = ANIM_X_OFFSETS_TEARDROP

	animated_sprite_2d.frames = _sprite_frames(TEARDROP_PATH)

	disable_all()
	teardrop.disabled = false
	animated_sprite_2d.material = null

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(TEARDROP_PATH)
	_sync_hurtbox_to_active_collider()

func _use_rocky() -> void :
	_character = CharacterKind.ROCKY
	_offsets = ANIM_X_OFFSETS_TENNISBALL

	animated_sprite_2d.frames = _sprite_frames(ROCKY_PATH)

	disable_all()
	rocky.disabled = false
	animated_sprite_2d.material = null

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(ROCKY_PATH)
	_sync_hurtbox_to_active_collider()

func _use_flower() -> void :
	_character = CharacterKind.FLOWER
	_offsets = ANIM_X_OFFSETS_TENNISBALL

	animated_sprite_2d.frames = _sprite_frames(FLOWER_PATH)

	disable_all()
	flower.disabled = false
	animated_sprite_2d.material = null

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(FLOWER_PATH)
	_sync_hurtbox_to_active_collider()

func _use_bubble() -> void :
	_character = CharacterKind.BUBBLE
	_offsets = ANIM_X_OFFSETS_PENCIL

	animated_sprite_2d.frames = _sprite_frames(BUBBLE_PATH)

	disable_all()
	bubblee.disabled = false
	animated_sprite_2d.material = null

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(BUBBLE_PATH)
	_sync_hurtbox_to_active_collider()

func _use_sb() -> void :
	_character = CharacterKind.SNOWBALL
	_offsets = ANIM_X_OFFSETS_TENNISBALL

	animated_sprite_2d.frames = _sprite_frames(SNOWBALL_PATH)

	disable_all()
	snowball.disabled = false
	animated_sprite_2d.material = null

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(SNOWBALL_PATH)
	_sync_hurtbox_to_active_collider()

func _use_blocky() -> void :
	_character = CharacterKind.BLOCKY
	_offsets = ANIM_X_OFFSETS_BLOCKY

	animated_sprite_2d.frames = _sprite_frames(BLOCKY_PATH)

	disable_all()
	blocky.disabled = false
	animated_sprite_2d.material = null

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(BLOCKY_PATH)
	_sync_hurtbox_to_active_collider()

func _use_woody() -> void :
	_character = CharacterKind.WOODY
	_offsets = ANIM_X_OFFSETS_WOODY

	animated_sprite_2d.frames = _sprite_frames(WOODY_PATH)

	disable_all()
	woody.disabled = false
	animated_sprite_2d.material = null

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(WOODY_PATH)
	_sync_hurtbox_to_active_collider()

func _use_eraser() -> void :
	_character = CharacterKind.ERASER
	_offsets = ANIM_X_OFFSETS_ERASER

	animated_sprite_2d.frames = _sprite_frames(ERASER_PATH)

	disable_all()
	eraser.disabled = false
	animated_sprite_2d.material = null

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(ERASER_PATH)
	_sync_hurtbox_to_active_collider()

func _use_spongy() -> void :
	_character = CharacterKind.SPONGY
	_offsets = ANIM_X_OFFSETS_TENNISBALL

	animated_sprite_2d.frames = _sprite_frames(SPONGY_PATH)

	disable_all()
	spongy.disabled = false
	animated_sprite_2d.material = null

	_apply_anim_offset(animated_sprite_2d.animation)

	_unload_unused_sprite_frames(SPONGY_PATH)
	_sync_hurtbox_to_active_collider()

func disable_all():
	fireyglow.enabled = false
	leafy.disabled = true
	firey.disabled = true
	coiny.disabled = true
	pin.disabled = true
	tennis_ball.disabled = true
	golfball.disabled = true
	pencil.disabled = true
	mmatch.disabled = true
	needle.disabled = true
	pen.disabled = true
	ice_cube.disabled = true
	teardrop.disabled = true
	flower.disabled = true
	bubblee.disabled = true
	rocky.disabled = true
	snowball.disabled = true
	blocky.disabled = true
	woody.disabled = true
	eraser.disabled = true
	spongy.disabled = true


func _unload_unused_sprite_frames(active_path: String) -> void :
	if not is_multiplayer_authority():
		return

	var character_paths = [LEAFY_PATH, FIREY_PATH, COINY_PATH, PIN_PATH, TENNISBALL_PATH, GOLFBALL_PATH, PENCIL_PATH, MATCH_PATH, NEEDLE_PATH, PEN_PATH, ICECUBE_PATH, TEARDROP_PATH, ROCKY_PATH, BUBBLE_PATH, SNOWBALL_PATH, BLOCKY_PATH, WOODY_PATH, ERASER_PATH, SPONGY_PATH]
	for path in character_paths:
		if path != active_path and _asset_cache.has(path):
			_asset_cache.erase(path)

	if is_instance_valid(animated_sprite_2d)\
	and animated_sprite_2d.sprite_frames\
	and animated_sprite_2d.sprite_frames.resource_path != active_path:
		animated_sprite_2d.sprite_frames = null

var _cleanup_timer: = 0.0
const CLEANUP_INTERVAL: = 10.0

func _active_collider() -> CollisionShape2D:
	if not leafy.disabled: return leafy
	if not firey.disabled: return firey
	if not coiny.disabled: return coiny
	if not pin.disabled: return pin
	if not tennis_ball.disabled: return tennis_ball
	if not golfball.disabled: return golfball
	if not pencil.disabled: return pencil
	if not mmatch.disabled: return mmatch
	if not needle.disabled: return needle
	if not pen.disabled: return pen
	if not ice_cube.disabled: return ice_cube
	if not teardrop.disabled: return teardrop
	if not rocky.disabled: return rocky
	if not flower.disabled: return flower
	if not bubblee.disabled: return bubblee
	if not snowball.disabled: return snowball
	if not blocky.disabled: return blocky
	if not woody.disabled: return woody
	if not eraser.disabled: return eraser
	if not spongy.disabled: return spongy
	return leafy

func _pick_random_character() -> void :
	randomize()
	var choice: = randi() % 3
	match choice:
		0: _use_leafy()
		1: _use_firey()
		2: _use_coiny()
		3: _use_pin()

func apply_kind(k: int) -> void :
	match k:
		CharacterKind.LEAFY: _use_leafy()
		CharacterKind.FIREY: _use_firey()
		CharacterKind.COINY: _use_coiny()
		CharacterKind.PIN: _use_pin()
		CharacterKind.TENNISBALL: _use_tb()
		CharacterKind.GOLFBALL: _use_gb()
		CharacterKind.PENCIL: _use_pencil()
		CharacterKind.MATCH: _use_match()
		CharacterKind.NEEDLE: _use_needle()
		CharacterKind.PEN: _use_pen()
		CharacterKind.ICECUBE: _use_icecube()
		CharacterKind.TEARDROP: _use_teardrop()
		CharacterKind.ROCKY: _use_rocky()
		CharacterKind.FLOWER: _use_flower()
		CharacterKind.BUBBLE: _use_bubble()
		CharacterKind.SNOWBALL: _use_sb()
		CharacterKind.BLOCKY: _use_blocky()
		CharacterKind.WOODY: _use_woody()
		CharacterKind.ERASER: _use_eraser()
		CharacterKind.SPONGY: _use_spongy()
		_: _use_leafy()
	_sync_hurtbox_to_active_collider()

func _ensure_hurtbox() -> void :
	if hurtbox_area == null:
		hurtbox_area = Area2D.new()
		hurtbox_area.name = "Hurtbox"
		hurtbox_area.collision_layer = 1 << 7
		hurtbox_area.collision_mask = 0
		hurtbox_area.monitorable = true
		add_child(hurtbox_area)
	if hurtbox_shape == null:
		hurtbox_shape = CollisionShape2D.new()
		hurtbox_area.add_child(hurtbox_shape)

func _sync_hurtbox_to_active_collider() -> void :
	_ensure_hurtbox()
	var src: = _active_collider()
	if src == null or src.shape == null: return
	hurtbox_shape.shape = src.shape.duplicate(true)
	hurtbox_shape.position = src.position
	hurtbox_shape.rotation = src.rotation
	hurtbox_shape.scale = Vector2(src.scale.x * 3, src.scale.y)

func _apply_jump_gravity(delta: float) -> void :
	if is_on_floor(): return
	var g: = _g_up

	if velocity.y < 0.0:
		g = _g_up

		if not Input.is_action_pressed("jump"):
			g = _g_up * JUMP_CUT_MULT
	else:

		g = _g_down

	velocity.y = min(velocity.y + g * delta, MAX_FALL_SPEED)

func _set_underwater_ambience(active: bool) -> void :
	if active:
		underwater.play()
	else:
		underwater.stop()

func _ready() -> void :
	randomize()
	_refresh_space_cfg_from_world()
	add_to_group("player")
	call_deferred("_apply_saved_stats_if_any")
	var boot_kind: = _surface_kind_at_feet()
	safe_margin = SAFE_MARGIN_PX
	floor_snap_length = FLOOR_SNAP
	animated_sprite_2d.animation_finished.connect(_on_anim_finished)




	_ensure_hurtbox()
	_sync_hurtbox_to_active_collider()


	animated_sprite_2d.play("default")
	_base_scale = animated_sprite_2d.scale

	_update_hearts_ui()
	_update_food_ui()
	if is_instance_valid(item):
		_item_base_pos = item.position
		_last_flip_h = animated_sprite_2d.flip_h
	if cam:
		call_deferred("_refresh_camera_after_authority")
		_cam_zoom_base = cam.zoom
	if _hud_enabled():
		_update_hearts_ui()
		_update_food_ui()
		_cache_ui_base_positions()
		_refresh_shake_flags_from_values()
	if boot_kind != &"unknown":
		_last_surface_kind = boot_kind
	_cache_ui_base_positions()
	_refresh_shake_flags_from_values()
	_retune_jump_keep_same_HT()
	if is_instance_valid(oxygenbar):
		oxygenbar.visible = false
	_update_oxygen_ui()
	_update_absorb_ui()

	if is_instance_valid(prohibited):
		prohibited.visible = false
	_update_prohibited_icon()

func _punch_camera_zoom() -> void :
	if cam == null: return
	if is_instance_valid(_cam_zoom_tween):
		_cam_zoom_tween.kill()
	_cam_zoom_tween = get_tree().create_tween()
	_cam_zoom_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_cam_zoom_tween.tween_property(cam, "zoom", CAM_ZOOM_HURT, CAM_ZOOM_IN_TIME)
	_cam_zoom_tween.tween_property(cam, "zoom", _cam_zoom_base, CAM_ZOOM_OUT_TIME)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _apply_saved_stats_if_any() -> void :
	if not is_multiplayer_authority(): return
	if GameSession.current_world_id == "": return
	var s = PlayerSave.get_stats(GameSession.current_world_id)
	_health_hunger_sat_exh_apply(s)

	var world: = get_tree().get_first_node_in_group("world")
	if world:
		if multiplayer.is_server():
			world.srv_set_desired_stats(s["health"], s["hunger"], s["saturation"], s["exhaustion"])
		else:
			world.rpc_id(1, "srv_set_desired_stats", s["health"], s["hunger"], s["saturation"], s["exhaustion"])

var _stats_save_accum: = 0.0
var _last_saved_stats: = {"health": -1, "hunger": -1, "saturation": -1.0, "exhaustion": -1.0}

func _health_hunger_sat_exh_apply(s: Dictionary) -> void :
	if s == null: return
	health = clamp(int(s.get("health", health)), 0, 10)
	hunger = clamp(int(s.get("hunger", hunger)), 0, MAX_HUNGER)
	saturation = max(0.0, float(s.get("saturation", saturation)))
	exhaustion = max(0.0, float(s.get("exhaustion", exhaustion)))
	oxygen = clamp(int(s.get("oxygen", oxygen)), 0, OXYGEN_MAX)
	absorption = clamp(int(s.get("absorption", absorption)), 0, MAX_ABSORPTION)
	_update_hearts_ui()
	_update_food_ui()
	_update_oxygen_ui()
	_update_absorb_ui()

@rpc("any_peer", "call_local", "reliable")
func cli_apply_stats(s: Dictionary) -> void :
	_health_hunger_sat_exh_apply(s)

func _refresh_camera_after_authority() -> void :
	if cam:
		cam.enabled = is_multiplayer_authority()
		if cam.enabled:
			cam.reset_smoothing()

func start_regeneration(duration: float) -> void :
	if duration <= 0.0:
		return
	_regen_effect_time = duration
	_regen_effect_active = true
	_regen_wave_active = true
	_regen_wave_t = 0.0


	_regen_accum = 0.0
	_regen_last_mode = RM_EFFECT
	_regen_last_tick = FULL_REGEN_TICK_SEC

func _apply_hearts_regen_wave(delta: float) -> void :
	_regen_wave_t += delta * REGEN_WAVE_SPEED
	var sprites: = _heart_sprites()

	_ensure_ui_bases()
	for i in sprites.size():
		var s: Sprite2D = sprites[i]
		if not is_instance_valid(s): continue
		var base: = _heart_bases[i]
		var yoff: = sin(_regen_wave_t + float(i) * REGEN_WAVE_PHASE_STEP) * REGEN_WAVE_AMPL

		s.position = base + Vector2(0.0, yoff)

var _regen_last_mode: int = -1
var _regen_last_tick: float = -1.0


const RM_NONE: = 0
const RM_EFFECT: = 1
const RM_NAT_FAST: = 2
const RM_NAT_NORMAL: = 3

const MAX_REGEN_DELTA: = 0.25
const EPS: = 0.0001

func _current_regen_mode_and_tick() -> Array:

	if _regen_effect_active and _regen_effect_time > 0.0 and health < 10:
		return [RM_EFFECT, FULL_REGEN_TICK_SEC]


	if hunger >= 8 and health < 10 and not _hurt_active and not _eating_active:
		var fast: = (hunger >= MAX_HUNGER and saturation > 0.0)
		return [RM_NAT_FAST if fast else RM_NAT_NORMAL, 
			FULL_REGEN_TICK_SEC if fast else NORMAL_REGEN_TICK_SEC]

	return [RM_NONE, 999999.0]

func _update_hunger_and_regen(delta: float, running_flag: bool) -> void :
	if _dead: return


	if hunger == 0 and health > 2:
		_starve_accum = min(STARVE_TICK_SEC, _starve_accum + delta)
		if _starve_accum >= STARVE_TICK_SEC and not _hurt_active and not _eating_active:
			_starve_accum = 0.0
			_apply_damage(1)
	else:
		_starve_accum = 0.0


	if _regen_effect_active and _regen_effect_time > 0.0:
		_regen_effect_time = max(0.0, _regen_effect_time - delta)
		if _regen_effect_time <= 0.0:
			_regen_effect_active = false
			_regen_wave_active = false
			_reset_positions(_heart_sprites(), _heart_bases)


	var d = min(delta, MAX_REGEN_DELTA)

	var mode_tick: = _current_regen_mode_and_tick()
	var mode: = int(mode_tick[0])
	var tick: = float(mode_tick[1])


	if mode != _regen_last_mode or tick != _regen_last_tick:
		_regen_accum = min(_regen_accum, tick - EPS)
		_regen_last_mode = mode
		_regen_last_tick = tick

	match mode:
		RM_NONE:

			_regen_accum = min(_regen_accum, tick - EPS)
		_:
			_regen_accum += d

			if _regen_accum >= tick:
				_regen_accum -= tick
				var healed = min(1, 10 - health)
				if healed > 0:
					health += healed
					_update_hearts_ui()
					_flash_hearts(2, 0.5)

					if mode == RM_NAT_FAST or mode == RM_NAT_NORMAL:
						_add_exhaustion(EXH_PER_REGEN_HALF_HEART * float(healed))

func _enter_eat(heal: int, hunger_gain: int, sat_gain: float, absorb_gain: int) -> void :
	_eating_active = true
	_pending_heal = max(0, heal)
	_pending_hunger = max(0, hunger_gain)
	_pending_sat = max(0.0, sat_gain)
	_pending_absorb = max(0, absorb_gain)

	_cancel_transition_if_any()


	_reset_uw_fall_anim()
	animated_sprite_2d.speed_scale = 1.0
	animated_sprite_2d.play("eat")
	_apply_anim_offset("eat")
	_set_falling_audio(false)
	if eat:
		eat.play()

		var world: = get_tree().get_first_node_in_group("world")
		if world and eat.stream:
			var path: = String(eat.stream.resource_path)
			if path != "":
				var pos: = global_position
				var vol: = -4.0
				var pid: = multiplayer.get_unique_id()
				if multiplayer.is_server():
					world._server_broadcast_player_sfx(pid, world.SFX_KIND_EAT, path, pos, vol)
				else:
					world.rpc_id(1, "srv_request_player_sfx", world.SFX_KIND_EAT, path, pos, vol)

	velocity.x = 0.0
	floor_snap_length = FLOOR_SNAP
	_snap_suspended = false

func _finish_eat() -> void :
	var old_health: = health

	if _pending_heal > 0:
		health = min(10, health + _pending_heal)
		_update_hearts_ui()


	if _pending_hunger > 0:
		_set_hunger(hunger + _pending_hunger)
	if _pending_sat > 0.0:
		var cap: = _sat_cap()
		saturation = min(cap, saturation + _pending_sat)
		_refresh_shake_flags_from_values()


	if _pending_absorb > 0:
		add_absorption(_pending_absorb)


	if _pending_regen > 0.0:
		if _regen_effect_active:

			_regen_effect_time = max(_regen_effect_time, _pending_regen)
		else:
			start_regeneration(_pending_regen)
		_pending_regen = 0.0

	if health > old_health:
		_flash_hearts(2, 0.5)
		_flash_absorb_gain(2, 0.5)

	_pending_heal = 0
	_pending_hunger = 0
	_pending_sat = 0.0
	_pending_absorb = 0
	_eating_active = false

	_hunger_accum = 0.0
	_starve_accum = 0.0


	if is_on_floor():
		if not _dead:
			_play_if_alive("default")


func _try_eat() -> void :
	if _eating_active or _hurt_active or _dead:
		return

	var hotbar: = get_tree().get_first_node_in_group("hotbar")
	var world: = get_tree().get_first_node_in_group("world")
	if hotbar == null or world == null:
		return

	var item_id: = int(hotbar.call("get_selected_item_id"))
	if item_id == 0:
		return
	if not world.call("is_item_edible", item_id):
		return

	var took: = int(hotbar.call("consume_selected", 1))
	if took <= 0:
		return

	var eff: Dictionary = world.call("edible_effects", item_id)
	var heal: = int(eff.get("heal", 0))
	var food: = int(eff.get("hunger", 0))

	var sat: = float(eff.get("sat", 0.0))
	if sat <= 0.0 and food > 0:
		sat = float(food) * 1.2

	var absorb: = int(eff.get("absorb", 0))


	var regen_secs: = float(eff.get("regeneration", 0.0))
	_pending_regen = max(0.0, regen_secs)

	_enter_eat(heal, food, sat, absorb)



func _set_falling_audio(active: bool) -> void :
	if active:
		if not falling.playing:
			falling.play()
	else:
		if falling.playing:
			falling.stop()

func _apply_anim_offset(anim_name: String) -> void :
	var base: = float(_offsets.get(anim_name, 0.0))
	var sign: = -1.0 if animated_sprite_2d.flip_h else 1.0
	animated_sprite_2d.position.x = base * sign

func _get_feet_atlas_coords() -> Vector2i:
	if tile_map_layer == null:
		return Vector2i(-1, -1)
	var local: = tile_map_layer.to_local(global_position + Vector2(0.0, FEET_SAMPLE_OFFSET))
	var cell: = tile_map_layer.local_to_map(local)
	return tile_map_layer.get_cell_atlas_coords(cell)

func _is_cell_collidable(cell: Vector2i) -> bool:
	if tile_map_layer == null:
		return false
	if tile_map_layer.get_cell_source_id(cell) == -1:
		return false
	var td: TileData = tile_map_layer.get_cell_tile_data(cell)
	if td == null:
		return false
	var ts: = tile_map_layer.tile_set
	if ts == null:
		return false
	var layers: = ts.get_physics_layers_count()
	for i in range(layers):
		if td.get_collision_polygons_count(i) > 0:
			return true
	return false

func _surface_cell_below_feet(max_down: = 4) -> Vector2i:

	var feet_world: = global_position + Vector2(0.0, FEET_SAMPLE_OFFSET)
	var base_cell: = tile_map_layer.local_to_map(tile_map_layer.to_local(feet_world))
	for dy in range(0, max_down + 1):
		var c: = base_cell + Vector2i(0, dy)
		if _is_cell_collidable(c):
			return c
	return Vector2i(-1, -1)

func _surface_kind_at_feet() -> StringName:
	if tile_map_layer == null:
		return &"unknown"
	var c: = _surface_cell_below_feet(4)
	if c.x == -1:
		return &"unknown"
	var ac: = tile_map_layer.get_cell_atlas_coords(c)
	if ac in STONE_COORDS: return &"stone"
	if ac in WOOD_COORDS: return &"wood"
	if ac in GRASS_COORDS: return &"grass"
	if ac in SNOW_COORDS: return &"snow"
	if ac in SAND_COORDS: return &"sand"
	if ac in GRAVEL_COORDS: return &"gravel"
	return &"unknown"


func _get_block_px() -> float:
	if tile_map_layer and tile_map_layer.tile_set:
		return float(tile_map_layer.tile_set.tile_size.x)
	return FALL_BLOCK_FALLBACK

func _update_hearts_ui() -> void :
	if not _hud_enabled(): return
	var sprites: = [heart, heart_2, heart_3, heart_4, heart_5]
	for i in sprites.size():
		var seg = clamp(health - i * 2, 0, 2)
		match seg:
			2: sprites[i].texture = HEART
			1: sprites[i].texture = HALF_HEART
			_: sprites[i].texture = HEARTDEAD
	_refresh_shake_flags_from_values()

func _update_food_ui() -> void :
	if not _hud_enabled(): return
	var sprites: = [food, food_2, food_3, food_4, food_5]
	for i in sprites.size():
		var seg = clamp(hunger - i * 2, 0, 2)
		match seg:
			2: sprites[i].texture = FOOD
			1: sprites[i].texture = HALF_FOOD
			_: sprites[i].texture = FOODGONE
	_refresh_shake_flags_from_values()


func _apply_damage(amount: int) -> void :
	_maybe_replay_aou_if_lethal(amount)
	if _dead or amount <= 0:
		return


	if _aou_iframe_t > 0.0:
		return

	var total: = amount
	var remaining: = total


	if absorption > 0 and remaining > 0:
		var prev_abs: = absorption
		var used = min(remaining, absorption)
		absorption -= used
		remaining -= used
		_update_absorb_ui()
		_flash_absorb_previous_damage(prev_abs, 1, 0.3)


	if remaining <= 0:
		_add_exhaustion(EXH_PER_DAMAGE_HALF_HEART * float(total))
		_regen_accum = 0.0
		_enter_hurt()
		return


	var old_health: = health
	var new_hp = max(0, health - remaining)


	if new_hp <= 0 and _aou_selected_and_consume():
		_flash_hearts_previous_damage(old_health, 1, 0.3)
		_trigger_aou_save()
		return


	health = new_hp
	_update_hearts_ui()

	_add_exhaustion(EXH_PER_DAMAGE_HALF_HEART * float(total))
	_flash_hearts_previous_damage(old_health, 3, 0.75)
	_regen_accum = 0.0

	if health == 0:
		_die()
	else:
		_enter_hurt()


func _update_abyss_damage(delta: float) -> void :
	if global_position.y > ABYSS_Y:
		if not _abyss_inside:
			_abyss_inside = true
		_abyss_accum += delta
		while _abyss_accum >= ABYSS_TICK_SEC:
			_abyss_accum -= ABYSS_TICK_SEC
			_apply_abyss_damage(1)
	else:
		_abyss_inside = false
		_abyss_accum = 0.0

func _apply_abyss_damage(amount: int) -> void :
	if _dead or amount <= 0:
		return
	var old: = health
	health = max(0, health - amount)
	_update_hearts_ui()
	_flash_hearts_previous_damage(old, 3, 0.75)
	_regen_accum = 0.0
	if health == 0:
		_die()

func _play_fall_land_sound(blocks: int, water_protected: bool) -> void :
	if water_protected:
		return
	if blocks >= 8:
		hitfall.stream = _audio(PATH_FALL_DAMAGE_BIG_OGG)
		if hitfall.stream:
			hitfall.stop()
			hitfall.play()
	elif blocks >= 5:
		hitfall.stream = _audio(PATH_FALL_DAMAGE_SMALL_OGG)
		if hitfall.stream:
			hitfall.stop()
			hitfall.play()

func _enter_hurt() -> void :
	_cancel_eat()
	_hurt_active = true
	_hurt_time_left = (HURT_WATER_DURATION if (_in_water or _submerged_frac >= WATER_ENTER_THRESHOLD) else 0.0)
	_state = AnimState.HURT
	_cancel_transition_if_any()
	animated_sprite_2d.play("hurt")
	_apply_anim_offset("hurt")
	_set_falling_audio(false)
	if hit: hitsound()

	_punch_camera_zoom()

	velocity.y = HURT_BOUNCE_VELOCITY
	floor_snap_length = 0.0
	_snap_suspended = true
	_awaiting_jump_finish = false
	_ignore_next_landing_damage = true

func is_dead() -> bool:
	return _dead

var _saved_collision_layer: = 0
var _saved_collision_mask: = 0

func _set_dead_collisions_frozen(freeze: bool) -> void :
	if freeze:
		_saved_collision_layer = collision_layer
		_saved_collision_mask = collision_mask
		collision_layer = 0
		collision_mask = 0

		if is_instance_valid(hurtbox_area):
			hurtbox_area.monitoring = false
			hurtbox_area.monitorable = false
		if is_instance_valid(hurtbox_shape):
			hurtbox_shape.disabled = true
	else:
		collision_layer = _saved_collision_layer
		collision_mask = _saved_collision_mask
		if is_instance_valid(hurtbox_area):
			hurtbox_area.monitoring = true
			hurtbox_area.monitorable = true
		if is_instance_valid(hurtbox_shape):
			hurtbox_shape.disabled = false


var _death_fx_token: int = 0

@rpc("any_peer", "call_local", "reliable")
func cli_do_death_fx(pos: Vector2, flip_left: bool) -> void :

	if not _dead:
		_dead = true
		_set_dead_collisions_frozen(true)
		_hurt_active = false
		_state = AnimState.DEAD
		if animated_sprite_2d:
			animated_sprite_2d.stop()
			animated_sprite_2d.play("dead")
			_apply_anim_offset("dead")

	_play_death_fx(pos, flip_left)



@rpc("any_peer", "reliable")
func srv_relay_respawn_state(spawn_pos: Vector2) -> void :
	if not multiplayer.is_server(): return
	rpc("cli_mark_alive", spawn_pos)

@rpc("any_peer", "call_local", "reliable")
func cli_mark_alive(spawn_pos: Vector2) -> void :
	_dead = false
	_set_dead_collisions_frozen(false)

	global_position = spawn_pos

@rpc("any_peer", "reliable")
func srv_relay_death_fx(pos: Vector2, flip_left: bool) -> void :
	if not multiplayer.is_server(): return

	rpc("cli_do_death_fx", pos, flip_left)

func _play_death_fx(pos: Vector2, flip_left: bool) -> void :
	if not _dead:
		return


	var token: = _death_fx_token

	_kill_death_fx_tweens()

	var target_rot: = (PI * 0.5) if flip_left else ( - PI * 0.5)
	rotation = 0.0

	_death_rot_tween = get_tree().create_tween()
	_death_rot_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_death_rot_tween.tween_property(self, "rotation", target_rot, 0.25)


	await get_tree().create_timer(1.0).timeout
	if token != _death_fx_token or not _dead:
		return

	if is_instance_valid(animated_sprite_2d):
		animated_sprite_2d.modulate.a = 1.0
		_death_fade_tween = get_tree().create_tween()
		_death_fade_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_death_fade_tween.tween_property(animated_sprite_2d, "modulate:a", 0.0, 0.6)


	var world: = get_tree().get_first_node_in_group("world")
	if world and (token == _death_fx_token) and _dead:
		if multiplayer.is_server():
			world.rpc("cli_spawn_white_gas", pos)
		else:
			world.rpc_id(1, "srv_spawn_white_gas", pos)

func _kill_death_fx_tweens() -> void :
	if is_instance_valid(_death_rot_tween):
		_death_rot_tween.kill()
	_death_rot_tween = null
	if is_instance_valid(_death_fade_tween):
		_death_fade_tween.kill()
	_death_fade_tween = null

@rpc("any_peer", "reliable")
func srv_relay_respawn_fx_reset() -> void :
	if not multiplayer.is_server(): return
	rpc("cli_sync_reset_visuals")

@rpc("any_peer", "call_local", "reliable")
func cli_sync_reset_visuals() -> void :

	_death_fx_token += 1
	_kill_death_fx_tweens()

	rotation = 0.0

	if is_instance_valid(animated_sprite_2d):

		animated_sprite_2d.visible = true
		animated_sprite_2d.modulate = Color(1, 1, 1, 1)

		if animated_sprite_2d.sprite_frames != null:
			animated_sprite_2d.play("default")
			_apply_anim_offset("default")

var _death_rot_tween: Tween
var _death_fade_tween: Tween

func _play_if_alive(name: String) -> void :
	if _dead and name != "dead":
		return
	animated_sprite_2d.play(name)
	_apply_anim_offset(name)

func _stop_looping_sfx() -> void :

	if falling and falling.playing: falling.stop()
	if footsteps and footsteps.playing: footsteps.stop()
	if water and water.playing: water.stop()
	if underwater and underwater.playing: underwater.stop()
	if swim and swim.playing: swim.stop()

func _die() -> void :
	_dead = true
	_set_dead_collisions_frozen(true)
	_hurt_active = false
	_state = AnimState.DEAD
	_cancel_transition_if_any()
	if animated_sprite_2d:
		animated_sprite_2d.stop()
		animated_sprite_2d.play("dead")
		_apply_anim_offset("dead")

	_set_falling_audio(false)


	hitsound()


	_stop_looping_sfx()

	_death_fx_token += 1

	var flip_left: = animated_sprite_2d and animated_sprite_2d.flip_h
	var pos: = global_position


	var pid: = multiplayer.get_unique_id()
	if multiplayer.is_server():
		rpc("cli_stop_player_loopers", pid)
	else:
		rpc_id(1, "srv_relay_stop_player_loopers", pid)


	if multiplayer.is_server():
		rpc("cli_do_death_fx", pos, flip_left)
	else:
		rpc_id(1, "srv_relay_death_fx", pos, flip_left)

	var world: = get_tree().get_first_node_in_group("world")
	if world and world.has_method("show_death_screen"):
		world.call("show_death_screen")
	_punch_camera_zoom()

var _respawning: = false

func _request_respawn() -> void :
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process(false)

	var world: = get_tree().get_first_node_in_group("world")
	if world == null:
		_local_respawn(get_global_position())
		return

	if world.has_method("srv_request_respawn"):
		if multiplayer.is_server():
			world.srv_request_respawn()
		else:
			world.rpc_id(1, "srv_request_respawn")

@rpc("any_peer", "call_local", "reliable")
func cli_respawn_at(spawn_pos: Vector2, reset_health: int = 10, reset_hunger: int = 10, keep_inventory: bool = false) -> void :
	if _respawning: return
	_respawning = true
	_respawn_keep_inventory = keep_inventory


	set_physics_process(false)
	set_process(false)
	if not is_multiplayer_authority():
		set_multiplayer_authority(multiplayer.get_unique_id(), true)


	if animated_sprite_2d:
		animated_sprite_2d.stop()



	_dead = false
	_hurt_active = false
	_eating_active = false
	_pending_heal = 0
	_pending_hunger = 0
	_starve_accum = 0.0
	_hunger_accum = 0.0

	_regen_effect_active = false
	_regen_effect_time = 0.0
	_regen_accum = 0.0
	_pending_regen = 0.0


	_regen_wave_active = false
	_regen_wave_t = 0.0
	_reset_positions(_heart_sprites(), _heart_bases)
	saturation = 0.0
	exhaustion = 0.0
	_pending_sat = 0
	_pending_regen = 0.0
	absorption = 0
	_update_absorb_ui()
	_ignore_next_landing_damage = false
	_awaiting_jump_finish = false
	_transitioning = false
	_queued_loop = &""
	oxygen = OXYGEN_MAX
	_oxy_decay_accum = 0.0
	_oxy_refill_accum = 0.0
	_drown_accum = 0.0
	_update_oxygen_ui()


	health = clamp(reset_health, 0, 10)
	hunger = clamp(reset_hunger, 0, MAX_HUNGER)
	_update_hearts_ui()
	_update_food_ui()


	global_position = spawn_pos
	velocity = Vector2.ZERO
	floor_snap_length = FLOOR_SNAP
	_snap_suspended = false
	_fall_peak_y = global_position.y
	_max_fall_px = 0.0

	rotation = 0.0
	if is_instance_valid(animated_sprite_2d):
		animated_sprite_2d.modulate.a = 1.0
		animated_sprite_2d.visible = true

	_set_dead_collisions_frozen(false)


	if animated_sprite_2d:
		animated_sprite_2d.modulate.a = 1.0
		animated_sprite_2d.play("default")
		_apply_anim_offset("default")
	_state = AnimState.IDLE


	if multiplayer.is_server():
		rpc("cli_sync_reset_visuals")
		rpc("cli_mark_alive", global_position)
	else:
		rpc_id(1, "srv_relay_respawn_fx_reset")
		rpc_id(1, "srv_relay_respawn_state", global_position)


	call_deferred("_finish_respawn_enable_and_clear")

var _respawn_keep_inventory: = false

func _finish_respawn_enable_and_clear() -> void :
	set_physics_process(is_multiplayer_authority())
	set_process(is_multiplayer_authority())
	process_mode = Node.PROCESS_MODE_INHERIT

	_sync_hurtbox_to_active_collider()


	call_deferred("_restore_snap_after_respawn")


	if cam:
		cam.enabled = is_multiplayer_authority()
		if cam.enabled:
			cam.reset_smoothing()

	if not _respawn_keep_inventory:
		_clear_inventory_local()
	_respawn_keep_inventory = false

	_respawning = false
	_cache_ui_base_positions()
	_refresh_shake_flags_from_values()
	if cam: cam.zoom = _cam_zoom_base
	_refresh_space_cfg_from_world()
	_space_cfg_refresh_accum = 0.0

	var w: = get_tree().get_first_node_in_group("world")
	if w.has_method("client_set_held_item"):
		w.call_deferred("client_set_held_item", 0)


	_death_fx_token += 1
	_kill_death_fx_tweens()
	if is_instance_valid(_cam_zoom_tween):
		_cam_zoom_tween.kill()
	_cam_zoom_tween = null
	if cam:
		cam.zoom = _cam_zoom_base
	rotation = 0.0
	if animated_sprite_2d:
		animated_sprite_2d.modulate.a = 1.0


	if multiplayer.is_server():
		rpc("cli_sync_reset_visuals")
	else:
		rpc_id(1, "srv_relay_respawn_fx_reset")

func _restore_snap_after_respawn() -> void :

	floor_snap_length = FLOOR_SNAP
	_snap_suspended = false

func _local_respawn(spawn_pos: Vector2) -> void :

	cli_respawn_at(spawn_pos, 10, 10)

func _clear_inventory_local() -> void :
	var hotbar: = get_tree().get_first_node_in_group("hotbar")
	if hotbar:
		if hotbar.has_method("clear_all"):
			hotbar.call("clear_all")

func _cancel_eat() -> void :
	if not _eating_active:
		return
	_eating_active = false
	_pending_heal = 0
	_pending_hunger = 0
	if eat and eat.playing:
		eat.stop()

var _pos_save_accum: = 0.0
var _pos_last_saved: = Vector2.INF

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST and GameSession.current_world_id != "":
		PlayerSave.set_last_pos(GameSession.current_world_id, global_position)
		PlayerSave.set_stats(GameSession.current_world_id, health, hunger, saturation, exhaustion, oxygen, absorption)
		PlayerSave.save_now(GameSession.current_world_id)

func _hud_enabled() -> bool:
	return is_multiplayer_authority()

func set_input_locked(on: bool) -> void :
	_input_locked = on
	if _dead:
		return
	if on:
		velocity.x = 0.0
		if is_on_floor():
			if animated_sprite_2d.animation != "default":
				_play_if_alive("default")

func _refresh_space_cfg_from_world() -> void :
	var world: = get_tree().get_first_node_in_group("world")
	if world == null:
		_space_cfg_ok = false
		return




	if world.has_method("get_yoyle_space_fade_profile"):
		var prof: Dictionary = world.call("get_yoyle_space_fade_profile")
		if typeof(prof) == TYPE_DICTIONARY and prof.has("base_y") and prof.has("full_y"):
			_space_base_y = float(prof["base_y"])
			_space_full_y = float(prof["full_y"])
			_space_cfg_ok = is_finite(_space_base_y) and is_finite(_space_full_y) and _space_base_y > _space_full_y
			return


	if world.has_method("get_yoyle_summit_apex_y"):
		var apex_y: = float(world.call("get_yoyle_summit_apex_y"))
		var pole_h: = float(world.get("SUMMIT_POLE_HEIGHT") if world.has_method("get") else 160.0)
		var sphere_r: = float(world.get("SPHERE_RADIUS") if world.has_method("get") else 7.0)


		_space_base_y = apex_y
		_space_full_y = apex_y - pole_h



		_space_cfg_ok = is_finite(_space_base_y) and is_finite(_space_full_y) and _space_base_y > _space_full_y
	else:
		_space_cfg_ok = false



var _tp_guard_on: = false
var _tp_guard_px: = 0.0

func reset_fall_state_after_teleport(from_pos: Vector2) -> void :
	var moved_down: = (global_position.y > from_pos.y + 0.5)

	_fall_peak_y = global_position.y
	_max_fall_px = 0.0
	velocity = Vector2.ZERO


	_tp_guard_on = moved_down or is_on_floor()
	_tp_guard_px = _get_block_px() * 0.75
	_ignore_next_landing_damage = _tp_guard_on


func _physics_process(delta: float) -> void :
	if is_multiplayer_authority():
		_cleanup_timer += delta
		if _cleanup_timer >= CLEANUP_INTERVAL:
			_cleanup_timer = 0.0

			var keys = _asset_cache.keys()
			var active_path = animated_sprite_2d.sprite_frames.resource_path if is_instance_valid(animated_sprite_2d) and animated_sprite_2d.sprite_frames else ""
			for k in keys:
				if k != active_path and k not in [LEAFY_PATH, FIREY_PATH, COINY_PATH, PIN_PATH]:
					_asset_cache.erase(k)
	var peer: = multiplayer.multiplayer_peer
	if peer == null or peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return
	if not is_multiplayer_authority():
		return
	_pos_save_accum += delta
	if GameSession.current_world_id != "":
		var moved_far: = (_pos_last_saved == Vector2.INF) or (global_position.distance_to(_pos_last_saved) >= 24.0)
		if _pos_save_accum >= 2.0 or moved_far:
			PlayerSave.set_last_pos(GameSession.current_world_id, global_position)
			PlayerSave.queue_save()
			_pos_last_saved = global_position
			_pos_save_accum = 0.0

	_stats_save_accum += delta
	if GameSession.current_world_id != "":
		var changed = (
			_last_saved_stats["health"] != health or 
			_last_saved_stats["hunger"] != hunger or 
			abs(_last_saved_stats["saturation"] - saturation) > 0.01 or 
			abs(_last_saved_stats["exhaustion"] - exhaustion) > 0.01
		)
		if _stats_save_accum >= 2.0 or changed:
			PlayerSave.set_stats(GameSession.current_world_id, health, hunger, saturation, exhaustion, oxygen, absorption)
			PlayerSave.queue_save()
			_last_saved_stats = {
				"health": health, "hunger": hunger, 
				"saturation": saturation, "exhaustion": exhaustion
			}
			_stats_save_accum = 0.0

	if not _dead and health <= 0:
		_die()
		return

	var input_allowed: = ( not _input_locked) and ( not _dead)

	var in_dir: = (Input.get_axis("left", "right") if input_allowed else 0.0)
	var in_run: = (input_allowed and Input.is_action_pressed("ui_run") and hunger >= 4)
	var in_jump_press: = (input_allowed and Input.is_action_just_pressed("jump"))
	var in_jump_hold: = (input_allowed and Input.is_action_pressed("jump"))
	var in_eat_press: = (input_allowed and Input.is_action_just_pressed("eat"))


	var dir: = 0.0
	var running: = false

	if _dead:

		velocity = Vector2.ZERO
		_update_step_cadence(delta, false)
		_update_ui_shake(delta)

		return



	if _eating_active and not _hurt_active:

		_reset_uw_fall_anim()
		if animated_sprite_2d.speed_scale == 0.0:
			animated_sprite_2d.speed_scale = 1.0
		if animated_sprite_2d.animation != "eat" or not animated_sprite_2d.is_playing():
			animated_sprite_2d.play("eat")
			_apply_anim_offset("eat")
		_set_falling_audio(false)
		_awaiting_jump_finish = false

		velocity.x = 0.0
		if not is_on_floor():
			if _submerged_frac >= WATER_SWIM_THRESHOLD:

				if in_jump_hold:
					velocity.y = move_toward(velocity.y, - WATER_ASCEND_SPEED, WATER_BUOYANCY_GRAV * delta)
				else:
					velocity.y = min(velocity.y + WATER_BUOYANCY_GRAV * delta, MAX_FALL_SPEED * 0.33)
				velocity.x *= pow(WATER_DRAG_X, delta)
			else:
				_apply_jump_gravity(delta)

		move_and_slide()
		_update_step_cadence(delta, false)
		_update_hunger_and_regen(delta, false)
		_update_ui_shake(delta)
		return

	var was_in_water: = _in_water
	_submerged_frac = _measure_submergence()
	_in_water = (_submerged_frac >= WATER_ENTER_THRESHOLD)
	_update_oxygen_logic(delta)


	if _hurt_active and _hurt_time_left > 0.0:
		_hurt_time_left -= delta




	if _in_water and not was_in_water:
		_play_water_enter()
		_set_underwater_ambience(true)
		_update_prohibited_icon()
		_suspend_hurt_airborne = false
	elif ( not _in_water) and was_in_water:
		_play_water_exit()
		_set_underwater_ambience(false)
		_update_prohibited_icon()
		if swim and swim.playing: swim.stop()
		_swim_active = false
		_swim_timer = 0.0

		_reset_uw_fall_anim()
		animated_sprite_2d.speed_scale = 1.0
		animated_sprite_2d.stop()
		animated_sprite_2d.play("jump")
		_apply_anim_offset("jump")
		_state = AnimState.JUMP
		_set_falling_audio(false)
		_awaiting_jump_finish = true

		_just_exited_water = true
		_pending_exit_pop = in_jump_hold
		_exit_pop_vy = WATER_EXIT_BOOST_VY

		_touched_water_in_air = true


		if _hurt_active:
			if _hurt_time_left <= 0.0:

				_hurt_active = false
			else:

				_suspend_hurt_airborne = true

	if _aou_iframe_t > 0.0:
		_aou_iframe_t = max(0.0, _aou_iframe_t - delta)


	if in_jump_press and not _hurt_active:
		_jump_buffer_t = JUMP_BUFFER
	elif not input_allowed:
		_jump_buffer_t = 0.0

	if in_eat_press:
		_try_eat()


	if is_on_floor():
		_coyote_t = COYOTE_TIME
		if _snap_suspended:
			floor_snap_length = FLOOR_SNAP
			_snap_suspended = false
		_set_falling_audio(false)
		_awaiting_jump_finish = false
	else:
		_coyote_t = max(0.0, _coyote_t - delta)


	if not is_on_floor():
		if _submerged_frac >= WATER_SWIM_THRESHOLD:


			if in_jump_hold:

				velocity.y = move_toward(velocity.y, - WATER_ASCEND_SPEED, WATER_BUOYANCY_GRAV * delta)
			else:

				velocity.y = min(velocity.y + WATER_BUOYANCY_GRAV * delta, MAX_FALL_SPEED * 0.33)

			velocity.x *= pow(WATER_DRAG_X, delta)
		else:

			velocity += get_gravity() * delta


	var can_jump: = ( not _hurt_active) and _jump_buffer_t > 0.0 and (_coyote_t > 0.0 or allow_infinite_jump)
	if can_jump:
		if velocity.y > 0.0: velocity.y = 0.0
		velocity.y = - _jump_v0
		_add_exhaustion(EXH_PER_SPRINT_JUMP if running else EXH_PER_JUMP)
		_play_jump_one_shot(running)
		_do_jump_stretch()
		_set_falling_audio(false)
		_cancel_transition_if_any()
		animated_sprite_2d.stop()
		animated_sprite_2d.play("jump")
		_apply_anim_offset("jump")
		_awaiting_jump_finish = true
		floor_snap_length = 0.0
		_snap_suspended = true
		_jump_buffer_t = 0.0
		_coyote_t = 0.0

	if not is_on_floor() and _snap_suspended and velocity.y >= 0.0:
		floor_snap_length = FLOOR_SNAP
		_snap_suspended = false






	var can_read_input: = input_allowed and (( not _hurt_active) or (_submerged_frac >= WATER_ENTER_THRESHOLD))
	if can_read_input:
		dir = in_dir
		running = in_run
	else:
		dir = 0.0
		running = false
	var target_speed: = (RUN_SPEED if running else WALK_SPEED)


	var allow_flip: = is_on_floor() or (_submerged_frac >= WATER_SWIM_THRESHOLD)
	if allow_flip and dir != 0:
		var new_flip: = (dir < 0)
		if new_flip != animated_sprite_2d.flip_h:
			animated_sprite_2d.flip_h = new_flip


			for collider in get_children():
				if collider is CollisionShape2D:
					collider.position.x = abs(collider.position.x) * (-1 if new_flip else 1)

			_apply_anim_offset(animated_sprite_2d.animation)
			_update_item_flip_from_sprite()


	var desired_x: = dir * target_speed
	var on_floor: = is_on_floor()
	var accel: = (ACCEL_GROUND if on_floor else ACCEL_AIR)
	var decel: = (DECEL_GROUND if on_floor else DECEL_AIR)


	if not on_floor and abs(velocity.y) <= APEX_THRESHOLD:
		accel += APEX_ACCEL_BONUS



	var hurt_blocks_move: = _hurt_active\
	and (_submerged_frac < WATER_ENTER_THRESHOLD)\
	and not (_suspend_hurt_airborne and not on_floor)

	if hurt_blocks_move:
		velocity.x = 0.0
	else:
		if dir == 0.0:
			velocity.x = move_toward(velocity.x, 0.0, decel * delta)
		else:
			var reversing = sign(desired_x) != sign(velocity.x) and abs(velocity.x) > 20.0
			var step: = (decel * TURN_BOOST if reversing else accel) * delta
			velocity.x = move_toward(velocity.x, desired_x, step)


	if dir == 0.0 and abs(velocity.x) < 2.0:
		velocity.x = 0.0

	if _was_on_floor and not is_on_floor():

		_fall_peak_y = global_position.y
		_max_fall_px = 0.0


		if not _snap_suspended:
			floor_snap_length = 0.0
			_snap_suspended = true

		_touched_water_in_air = false


	if _just_exited_water and _pending_exit_pop:
		velocity.y = min(velocity.y, _exit_pop_vy)
	_pending_exit_pop = false
	_just_exited_water = false

	var before: = global_position
	move_and_slide()

	if not is_on_floor():

		_fall_peak_y = min(_fall_peak_y, global_position.y)
		var current_drop: = global_position.y - _fall_peak_y
		_max_fall_px = max(_max_fall_px, current_drop)
		if _submerged_frac >= WATER_ENTER_THRESHOLD:
			_touched_water_in_air = true

	var moved_x = abs(global_position.x - before.x)

	if USE_EXHAUSTION and moved_x > 0.0:
		var meters = moved_x / _get_block_px()
		var per_meter: = (EXH_PER_METER_SPRINT if running else EXH_PER_METER_WALK)
		_add_exhaustion(per_meter * meters)


	_step_cool_t = max(0.0, _step_cool_t - delta)
	if not _hurt_active and _step_cool_t == 0.0 and is_on_floor() and abs(velocity.x) > 0.1 and moved_x < 0.05 and is_on_wall():
		if _try_step_up_and_move():
			_step_cool_t = STEP_COOLDOWN

	_jump_buffer_t = max(0.0, _jump_buffer_t - delta)

	if not is_on_floor() and _near_floor(2.0):
		_coyote_t = COYOTE_TIME


	if _tp_guard_on:
		var post_tp_drop = max(0.0, global_position.y - _fall_peak_y)
		if post_tp_drop > _tp_guard_px:
			_tp_guard_on = false
			_ignore_next_landing_damage = false


	if not _was_on_floor and is_on_floor():
		if _snap_suspended:
			floor_snap_length = FLOOR_SNAP
			_snap_suspended = false

		var blocks: = int(floor(_max_fall_px / _get_block_px()))
		var did_damage: = false

		var water_protected: = _touched_water_in_air or _in_water or (_submerged_frac >= WATER_ENTER_THRESHOLD)
		_suspend_hurt_airborne = false


		_play_fall_land_sound(blocks, water_protected)

		if not (_ignore_next_landing_damage or _tp_guard_on)\
		and blocks >= MAXIMUM_BLOCK_FALL and not water_protected:
			var over: = blocks - MAXIMUM_BLOCK_FALL
			var extra: = int(over / FALL_EXTRA_EVERY_BLOCKS)
			var dmg = FALL_DAMAGE_AMOUNT + max(0, extra)
			if dmg > 0:
				_apply_damage(dmg)
				did_damage = true
		else:
			_ignore_next_landing_damage = false


		if _hurt_active and not did_damage:
			_hurt_active = false
			if not _dead:
				_play_if_alive("default")


		var banks: = _surface_banks()
		var land_stream: = _pick_random(banks["hits"])
		if land_stream and footsteps:
			footsteps.stream = land_stream
			var vol_db = clamp(-10.0 + float(blocks) * 1.8, -10.0, 0.0)
			footsteps.volume_db = vol_db
			footsteps.pitch_scale = (0.9 if blocks >= 6 else 1.0)
			if not (hit and hit.playing):
				footsteps.play()


		_fall_peak_y = global_position.y
		_max_fall_px = 0.0
		_touched_water_in_air = false
		_tp_guard_on = false
		_ignore_next_landing_damage = false



	if _in_water and _submerged_frac >= WATER_SWIM_THRESHOLD:
		_drive_underwater_fall_anim(delta)
	else:
		_reset_uw_fall_anim()
	_update_animation_state(dir, running)


	_was_on_floor = is_on_floor()
	_update_swim_cadence(delta)
	_update_step_cadence(delta, running)
	_update_hunger_and_regen(delta, running)
	_update_ui_shake(delta)
	_update_abyss_damage(delta)


	if _sky == null or not is_instance_valid(_sky):
		_sky = get_tree().get_first_node_in_group("sky_cycle")


	_space_cfg_refresh_accum += delta
	if ( not _space_cfg_ok) or _space_cfg_refresh_accum >= 2.0:
		_refresh_space_cfg_from_world()
		_space_cfg_refresh_accum = 0.0


	if _space_cfg_ok:
		var denom = max(0.001, _space_base_y - _space_full_y)
		var p = (_space_base_y - float(global_position.y)) / denom
		p = clamp(p, 0.0, 1.0)


		if _sky == null or not is_instance_valid(_sky):
			_sky = get_tree().get_first_node_in_group("daynight")
			if _sky == null:
				_sky = get_tree().get_first_node_in_group("sky_cycle")

		if _sky and _sky.has_method("set_space_progress"):
			_sky.call("set_space_progress", p)

func _near_floor(dist: = 2.0) -> bool:

	return test_move(global_transform.translated(Vector2(0, dist)), Vector2.ZERO)


func _update_animation_state(_dir: float, running: bool) -> void :

	if _dead:
		return



	if _just_exited_water:
		_cancel_transition_if_any()
		if animated_sprite_2d.animation != "jump":
			animated_sprite_2d.stop()
			animated_sprite_2d.play("jump")
			_apply_anim_offset("jump")
		_state = AnimState.JUMP
		_set_falling_audio(false)
		return

	if is_on_floor() and not _hurt_active and _state == AnimState.HURT:
		_state = AnimState.IDLE

	if _eating_active and not _hurt_active:
		animated_sprite_2d.speed_scale = 1.0
		_set_falling_audio(false)
		return



	if _hurt_active:

		if _suspend_hurt_airborne and not is_on_floor():

			pass
		else:
			if (_in_water or _submerged_frac >= WATER_ENTER_THRESHOLD):
				if _hurt_time_left > 0.0:
					if animated_sprite_2d.animation != "hurt":
						animated_sprite_2d.play("hurt");_apply_anim_offset("hurt")
				else:
					if animated_sprite_2d.animation != "fall":
						animated_sprite_2d.play("fall");_apply_anim_offset("fall")
				_set_falling_audio(false)
				return
			else:
				if not is_on_floor() and animated_sprite_2d.animation != "hurt":
					animated_sprite_2d.play("hurt");_apply_anim_offset("hurt")
				_set_falling_audio(false)
				return

	if _in_water and _submerged_frac >= WATER_SWIM_THRESHOLD:
		_cancel_transition_if_any()
		if animated_sprite_2d.animation != "fall":
			animated_sprite_2d.play("fall")
			_apply_anim_offset("fall")
		_set_falling_audio(false)
		_state = AnimState.FALL
		return


	if not is_on_floor():
		_cancel_transition_if_any()
		if _awaiting_jump_finish:
			if animated_sprite_2d.animation != "jump":
				animated_sprite_2d.stop()
				animated_sprite_2d.play("jump")
				_apply_anim_offset("jump")
			_set_falling_audio(false)
			_state = AnimState.JUMP
			return
		if animated_sprite_2d.animation != "fall":
			animated_sprite_2d.play("fall")
			_apply_anim_offset("fall")
		_set_falling_audio(true)
		_state = AnimState.FALL
		return


	if _transitioning:
		return

	var desired: = AnimState.IDLE
	if abs(velocity.x) > 5.0:
		desired = AnimState.RUN if running else AnimState.WALK

	if desired == _state:
		var want: = "default" if _state == AnimState.IDLE else ("walk" if _state == AnimState.WALK else "run")
		if animated_sprite_2d.animation != want:
			animated_sprite_2d.play(want)
			_apply_anim_offset(want)
		return

	if _state == AnimState.JUMP or _state == AnimState.FALL:
		match desired:
			AnimState.WALK:
				animated_sprite_2d.play("walk");_apply_anim_offset("walk");_state = AnimState.WALK
			AnimState.RUN:
				animated_sprite_2d.play("run");_apply_anim_offset("run");_state = AnimState.RUN
			_:
				animated_sprite_2d.play("default");_apply_anim_offset("default");_state = AnimState.IDLE
		return

	match _state:
		AnimState.IDLE:
			if desired == AnimState.WALK:
				_play_transition("towalk", false, "walk")
			elif desired == AnimState.RUN:
				_play_transition("towalk", false, "walk")
		AnimState.WALK:
			if desired == AnimState.IDLE:
				_play_transition("towalk", true, "default")
			elif desired == AnimState.RUN:
				_play_transition("torun", false, "run")
		AnimState.RUN:
			if desired == AnimState.WALK:
				_play_transition("torun", true, "walk")
			elif desired == AnimState.IDLE:
				_play_transition("torun", true, "walk")

	if is_on_floor() and _transitioning and (animated_sprite_2d.animation == "jump" or animated_sprite_2d.animation == "fall"):
		_cancel_transition_if_any()
		_awaiting_jump_finish = false

func _play_transition(name: StringName, backwards: bool, next_loop: StringName) -> void :
	_transitioning = true
	_state = AnimState.TRANSITION
	_queued_loop = next_loop
	_apply_anim_offset(String(name))
	if backwards:
		animated_sprite_2d.play_backwards(name)
	else:
		animated_sprite_2d.play(name)

func _on_anim_finished() -> void :
	if _dead:
		return

	if _transitioning:
		_set_falling_audio(false)
		animated_sprite_2d.play(_queued_loop)
		_apply_anim_offset(_queued_loop)
		_transitioning = false
		match _queued_loop:
			"default": _state = AnimState.IDLE
			"walk": _state = AnimState.WALK
			"run": _state = AnimState.RUN
			_: _state = AnimState.IDLE
		_queued_loop = &""
		return

	if animated_sprite_2d.animation == "eat":
		_finish_eat()
		return

	if animated_sprite_2d.animation == "jump":
		_awaiting_jump_finish = false
		if not is_on_floor():
			animated_sprite_2d.play("fall")
			_apply_anim_offset("fall")
			_state = AnimState.FALL
			_set_falling_audio(true)

func _cancel_transition_if_any() -> void :
	if _transitioning:
		_transitioning = false
		_queued_loop = &""


func _do_jump_stretch() -> void :
	if is_instance_valid(_jump_squash_tween):
		_jump_squash_tween.kill()
	animated_sprite_2d.scale = _base_scale * Vector2(0.85, 1.15)
	_jump_squash_tween = get_tree().create_tween()
	_jump_squash_tween.tween_property(animated_sprite_2d, "scale", _base_scale, 0.12)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _try_step_up_and_move() -> bool:
	var start: = global_position
	for h in range(1, STEP_HEIGHT + 1):
		if test_move(global_transform.translated(Vector2(0, - h)), Vector2.ZERO):
			continue
		global_position.y -= h
		var pos_before: = global_position
		move_and_slide()
		if abs(global_position.x - pos_before.x) > 0.05:
			return true
		global_position = start
	return false

@rpc("any_peer", "call_local")
func cli_add_exhaustion(amount: float) -> void :
	_add_exhaustion(max(0.0, amount))


@export var allow_infinite_jump: = false

@rpc("any_peer", "call_local", "reliable")
func cli_set_infinite_jumping(on: bool) -> void :
	allow_infinite_jump = on

@rpc("any_peer", "call_local", "reliable")
func cli_set_max_fall(blocks: int) -> void :
	MAXIMUM_BLOCK_FALL = max(0, blocks)

@rpc("any_peer", "call_local", "reliable")
func cli_set_camera_zoom(z: float) -> void :
	if cam and is_instance_valid(cam):

		var zoom_val = clamp(z, 0.1, 5.0)
		cam.zoom = Vector2(zoom_val, zoom_val)

@rpc("any_peer", "call_local")
func cli_snap_teleport_to(pos: Vector2) -> void :

	global_position = pos
	velocity = Vector2.ZERO


	floor_snap_length = FLOOR_SNAP
	_snap_suspended = false


	_fall_peak_y = pos.y
	_max_fall_px = 0.0
	_touched_water_in_air = false


	_ignore_next_landing_damage = true


	_was_on_floor = true
