extends CharacterBody2D


@export var tile_px: = 74.0


@export var walk_speed_px: = 220.0
@export var jump_velocity_px: = -520.0
@export var look_ahead_px: = 0.75 * 74.0
@export var max_step_blocks: = 5.0
@export var max_drop_blocks: = 2.0


@export var reroll_delay_every_sec: = 60.0
@export var delay_min_sec: = 0.5
@export var delay_max_sec: = 2.0


@export var clearance_w_px: = 48.0
@export var clearance_h_px: = 64.0


@export var ground_mask: int = 1 << 0

@export var obstacle_mask: int = 1 << 0


@export var touch_radius_px: = 76.0
const HURTBOX_MASK: = 1 << 7

@onready var teleport_snd: AudioStreamPlayer2D = $teleport
@onready var scream_snd: AudioStreamPlayer2D = $scream
@onready var evil_leafy: Sprite2D = $EvilLeafy

@export var min_soil_thickness_tiles: = 2.0
@export var thickness_window_tiles: = 4.0

@export var stand_gap_px: = 2.0
@export var land_band_px: = 2.0 * tile_px
@export var land_step_px: = 2.0

@export var biome_check_interval: = 0.5
var _biome_check_t: = 0.0

var _is_server: = false

var health: = 1000

var _no_relocate_until: = 0.0
func _now() -> float: return Time.get_ticks_msec() * 0.001

@onready var colshape: CollisionShape2D = $CollisionShape2D
var _origin_to_feet_local: = Vector2.ZERO

var _dead: = false
var _sim_pos: Vector2
var _since_tp: = 0.0
var _since_reroll: = 0.0
var _delay_cur_sec: = 1.0
var _facing_dir: = 1.0
var _scream_cd: = 0.0
const SCREAM_COOLDOWN: = 1

const SFX_TELEPORT: = 0
const SFX_SCREAM: = 1

@rpc("authority", "reliable")
func cli_play_sfx(kind: int) -> void :
	match kind:
		SFX_TELEPORT:
			if teleport_snd:
				teleport_snd.stop()
				teleport_snd.play()
		SFX_SCREAM:
			if scream_snd:
				scream_snd.stop()
				scream_snd.play()

func _ensure_on_loaded_chunk_or_relocate() -> bool:
	if _now() < _no_relocate_until:
		return true
	var w: = _world_node()
	if w == null:
		return true
	if not (w.has_method("_chunk_of_world_pos") and w.has_method("_is_chunk_loaded")):
		return true


	var feet: = _feet_from_origin(global_position)
	var cc: Vector2i = w._chunk_of_world_pos(feet)


	if w._is_chunk_loaded(cc):
		return true


	if _now() < _no_relocate_until:
		return false


	var spot = _evil_surface_near_x_or_null(feet.x)
	if spot != null:
		spawn_at_feet(spot as Vector2)
		_no_relocate_until = _now() + 0.5
		return false


	_despawn_clean("current chunk unloaded and no evil loaded")
	return false

func _world_node() -> Node:
	return get_tree().get_first_node_in_group("world")


func _feet_from_origin(world_pos: Vector2) -> Vector2:
	return world_pos + _origin_to_feet_local


func _is_in_evil_biome(feet: Vector2) -> bool:
	var w: = _world_node()
	if w == null: return true
	if not w.has_method("_chunk_of_world_pos") or not w.has_method("_biome_for_chunk"):
		return true
	var cc: Vector2i = w._chunk_of_world_pos(feet)
	var biome = w._biome_for_chunk(cc)
	return biome == w.BIOME_EVIL_FOREST



func _evil_surface_near_x_or_null(pref_x: float) -> Variant:
	var w: = _world_node()
	if w == null: return null
	if w.has_method("random_surface_spot_in_loaded_evil_near_x"):
		return w.random_surface_spot_in_loaded_evil_near_x(pref_x)
	return null


func _loaded_evil_count() -> int:
	var w: = _world_node()
	if w and w.has_method("loaded_evil_chunk_count"):
		return int(w.loaded_evil_chunk_count())
	return 999

func _exit_tree() -> void :
	print("[EvilLeafy] exit_tree -> notify world")
	var w: = _world_node()
	if w and w.has_method("_on_evil_leafy_despawned"):
		w._on_evil_leafy_despawned()


func spawn_at_feet(feet_wp: Vector2) -> void :
	var feet_snapped: = _push_out_of_solid(_safe_surface_stand(feet_wp))
	if not _is_clear_feet(feet_snapped):
		return
	global_position = feet_snapped - _origin_to_feet_local
	velocity = Vector2.ZERO
	_since_tp = 0.0
	_no_relocate_until = _now() + 0.8

	rpc("cli_set_state", global_position, _facing_dir)


func _despawn_now() -> void :
	set_physics_process(false)
	queue_free()

var _off_ground_t: = 0.0
@export var off_ground_relocate_delay: = 0.2

func _void_fall_watchdog(delta: float) -> bool:
	if _now() < _no_relocate_until:
		return true

	if is_on_floor():
		_off_ground_t = 0.0
		return true

	_off_ground_t += delta
	if _off_ground_t < off_ground_relocate_delay:
		return true


	var x: = _feet_from_origin(global_position).x
	var spot = _evil_surface_near_x_or_null(x)
	if spot != null:
		spawn_at_feet(spot as Vector2)
		_off_ground_t = 0.0
		_no_relocate_until = _now() + 0.5
		return false


	_despawn_clean("void fall & no loaded evil")
	return false

func _nearest_loaded_evil_surface_near_x(pref_x: float) -> Variant:
	var w: = _world_node()
	if w == null: return null


	if w.has_method("random_surface_spot_in_loaded_evil_near_x"):
		return w.random_surface_spot_in_loaded_evil_near_x(pref_x)
	return null

func _player_from_collider(collider: Object) -> Node:
	var n: = collider as Node
	while n:
		if n.is_in_group("player"):
			return n
		n = n.get_parent()
	return null


func _xform_from_feet(feet: Vector2) -> Transform2D:


	return Transform2D(0.0, feet - Vector2(0, clearance_h_px * 0.5))

func _rect_hits_at_feet(feet: Vector2) -> bool:
	var rect: = RectangleShape2D.new()
	rect.size = Vector2(clearance_w_px, clearance_h_px)
	var params: = PhysicsShapeQueryParameters2D.new()
	params.shape = rect
	params.transform = _xform_from_feet(feet)
	params.collide_with_bodies = true
	params.collide_with_areas = true
	params.collision_mask = obstacle_mask
	return not get_world_2d().direct_space_state.intersect_shape(params, 16).is_empty()

func _is_clear_feet(feet: Vector2) -> bool:
	return not _rect_hits_at_feet(feet)

func _ready() -> void :
	randomize()
	_is_server = multiplayer.is_server()


	if _is_server:
		if not is_multiplayer_authority():
			set_multiplayer_authority(multiplayer.get_unique_id(), true)
	else:

		set_physics_process(false)
		set_process(false)


	if colshape and colshape.shape is RectangleShape2D:
		var rect: RectangleShape2D = colshape.shape
		clearance_w_px = rect.size.x
		clearance_h_px = rect.size.y

		_origin_to_feet_local = colshape.position + Vector2(0, rect.size.y * 0.5)
	else:

		_origin_to_feet_local = Vector2(0, clearance_h_px * 0.5)

	_sim_pos = _safe_surface_stand(global_position)

	var my_feet: = _feet_from_origin(global_position)
	if not _is_in_evil_biome(my_feet):
		var spot = _nearest_loaded_evil_surface_near_x(my_feet.x)
		if spot != null:
			spawn_at_feet(spot as Vector2)
		else:
			var w: = _world_node()
			if w and w.has_method("_on_evil_leafy_despawned"):
				w._on_evil_leafy_despawned()
			queue_free()
			return
	_reroll_delay(true)
	set_physics_process(true)

func _stand_transform_at(center: Vector2) -> Transform2D:

	return Transform2D(0.0, center - Vector2(0, clearance_h_px))

func _box_hits_at(center: Vector2) -> bool:
	var rect: = RectangleShape2D.new()
	rect.size = Vector2(clearance_w_px, clearance_h_px)
	var params: = PhysicsShapeQueryParameters2D.new()
	params.shape = rect
	params.transform = _stand_transform_at(center)
	params.collide_with_bodies = true
	params.collide_with_areas = true
	params.collision_mask = obstacle_mask
	var hits: = get_world_2d().direct_space_state.intersect_shape(params, 16)
	return not hits.is_empty()


func _sweep_land_at_x(wx: float, hint_y: float) -> Vector2:

	var surf_y: = _ground_y_at_x_surface(wx, hint_y)

	var feet_goal: = Vector2(wx, surf_y - stand_gap_px)


	var y: = feet_goal.y - clearance_h_px
	var y_max: = feet_goal.y + land_band_px

	while y <= y_max:
		var feet: = Vector2(wx, y)
		if _is_clear_feet(feet):

			var fy: = feet_goal.y
			while fy >= y:
				if _is_clear_feet(Vector2(wx, fy)):
					return Vector2(wx, fy)
				fy -= 1.0
			return feet
		y += land_step_px


	return feet_goal

@export var support_band_px: = 28.0
@export var support_samples: = 5
@export var support_ratio_ok: = 0.6

func _surface_has_local_support(wx: float, y_hit: float) -> bool:


	var dss: = get_world_2d().direct_space_state
	var half_w: = 0.5 * clearance_w_px
	var ok: = 0
	var total = max(1, support_samples)
	for i in range(total):
		var t: = 0.0 if total == 1 else float(i) / float(total - 1)
		var x: = wx - half_w + t * (2.0 * half_w)

		var p: = PhysicsRayQueryParameters2D.new()
		p.collide_with_bodies = true
		p.collide_with_areas = true
		p.collision_mask = ground_mask
		p.from = Vector2(x, y_hit + 0.5)
		p.to = Vector2(x, y_hit + support_band_px)

		var hit: = dss.intersect_ray(p)
		if hit:
			var nrm: Vector2 = hit.get("normal", Vector2.UP)

			if nrm.y < -0.6:
				ok += 1

	return (float(ok) / float(total)) >= support_ratio_ok


@export var blink_min_px: = 160.0
@export var blink_max_px: = 520.0
@export var blink_step_px: = 0.5 * tile_px
@export var max_crests_per_blink: = 3

func _furthest_reachable_crest(from_feet: Vector2, dir: float) -> Vector2:
	var cur_y: = _ground_y_at_x_surface(from_feet.x, from_feet.y + 8.0)
	var max_step_px: = max_step_blocks * tile_px
	var max_drop_px: = max_drop_blocks * tile_px

	var best: = from_feet
	var x: = from_feet.x + dir * crest_step_px
	var end_x: = from_feet.x + dir * crest_scan_px
	var step: = crest_step_px * dir

	while (dir > 0.0 and x <= end_x) or (dir < 0.0 and x >= end_x):
		var y: = _ground_y_at_x_surface(x, cur_y + 8.0)
		var step_up = max(0.0, cur_y - y)
		var drop = max(0.0, y - cur_y)

		if step_up <= max_step_px or step_up <= crest_up_allow_px:
			if drop <= max_drop_px:
				var feet: = _sweep_land_at_x(x, y)
				if _is_clear_feet(feet):
					best = feet
		x += step
	return best

func _blink_target_along_ground(from_pos: Vector2, target_x: float, max_dx_px: float) -> Vector2:
	var pos_feet: = _safe_surface_stand(from_pos)
	var dir = sign(target_x - pos_feet.x)
	if dir == 0.0:
		return pos_feet

	var remain = min(abs(target_x - pos_feet.x), max_dx_px)
	var step: = blink_step_px
	var crests: = 0

	while remain > 0.0:
		var dx = min(step, remain) * dir
		var next_x = pos_feet.x + dx

		var here_y: = _ground_y_at_x_surface(pos_feet.x, pos_feet.y + 8.0)
		var next_y: = _ground_y_at_x_surface(next_x, pos_feet.y + 8.0)
		var step_up_px = max(0.0, here_y - next_y)
		var drop_px = max(0.0, next_y - here_y)

		var next_feet: = _sweep_land_at_x(next_x, next_y)

		var blocked = step_up_px > max_step_blocks * tile_px\
		or drop_px > max_drop_blocks * tile_px\
		or not _is_clear_feet(next_feet)

		if blocked:
			if crests >= max_crests_per_blink:
				break
			var crest: = _furthest_reachable_crest(pos_feet, dir)
			if crest == pos_feet:
				break
			remain -= abs(crest.x - pos_feet.x)
			pos_feet = crest
			crests += 1
			continue

		pos_feet = next_feet
		remain -= step

	return pos_feet

func _despawn_clean(reason: String = "") -> void :

	set_physics_process(false)
	set_process(false)
	if teleport_snd and teleport_snd.playing: teleport_snd.stop()
	if scream_snd and scream_snd.playing: scream_snd.stop()

	queue_free()

func _physics_process(delta: float) -> void :
	if not is_multiplayer_authority():
		return

	var w: = _world_node()
	if w and w.has_method("any_evil_chunk_loaded") and not w.any_evil_chunk_loaded():
		_despawn_clean("no evil chunks")
		return

	if _dead:
		return

	if not _void_fall_watchdog(delta):
		return

	if _dead:
		return


	if not _ensure_on_loaded_chunk_or_relocate():
		return
	if _dead: return


	_biome_check_t += delta
	if _biome_check_t >= biome_check_interval:
		_biome_check_t = 0.0
		var feet_now: = _feet_from_origin(global_position)
		if not _is_in_evil_biome(feet_now):
			var spot = _evil_surface_near_x_or_null(feet_now.x)
			if spot == null:
				_despawn_clean("left biome and no evil loaded")
				return
			spawn_at_feet(spot)
			velocity = Vector2.ZERO

	_since_reroll += delta
	if _since_reroll >= reroll_delay_every_sec:
		_reroll_delay(false)

	_since_tp += delta
	if _since_tp >= _delay_cur_sec:
		_since_tp = 0.0
		_teleport_to_sim()


	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

	_scream_cd = max(0.0, _scream_cd - delta)
	_touch_attack()
	rpc("cli_set_state", global_position, _facing_dir)

@rpc("authority", "unreliable")
func cli_set_state(pos: Vector2, face: float) -> void :
	if multiplayer.is_server():
		return
	global_position = pos
	_facing_dir = face
	_update_flip()

func _solid_thickness_below(wx: float, y_hit: float) -> float:


	var dss: = get_world_2d().direct_space_state
	var window_px: = thickness_window_tiles * tile_px
	var p: = PhysicsRayQueryParameters2D.new()
	p.collide_with_bodies = true
	p.collide_with_areas = true
	p.collision_mask = ground_mask

	var y_top: = y_hit + 0.5
	var y_bottom: = y_hit + window_px
	var thickness_px: = 0.0
	var safety: = 0

	while safety < 32 and y_top < y_bottom:
		safety += 1
		p.from = Vector2(wx, y_top)
		p.to = Vector2(wx, y_bottom)
		var hit: = dss.intersect_ray(p)
		if not hit: break
		var pos: Vector2 = hit["position"]
		var nrm: Vector2 = hit.get("normal", Vector2.UP)

		if nrm.y < -0.6:

			var next_y: = pos.y + 1.0
			thickness_px = max(thickness_px, next_y - y_hit)
			y_top = next_y
		else:

			y_top = pos.y + 1.0

	return max(0.0, thickness_px)

@export var stuck_scan_tiles: = 4.0

func _nearest_valid_feet_toward(from_feet: Vector2, target_x: float) -> Vector2:
	var dir = sign(target_x - from_feet.x)
	if dir == 0.0: dir = 1.0
	var best: = from_feet
	var best_dx: = 0.0
	var max_x: = tile_px * stuck_scan_tiles
	var step = tile_px * 0.25 * dir
	var x = from_feet.x + step
	while abs(x - from_feet.x) <= max_x:
		var y: = _ground_y_at_x_surface(x, from_feet.y + 8.0)
		var feet: = _sweep_land_at_x(x, y)
		if _is_clear_feet(feet):
			var dx = dir * (feet.x - from_feet.x)
			if dx > best_dx:
				best_dx = dx
				best = feet
		x += step
	return best


func _teleport_to_sim() -> void :
	var target: = _nearest_player()
	if target == null:
		return

	var old_x: = _feet_from_origin(global_position).x

	var max_dx: = randf_range(blink_min_px, blink_max_px)
	var dst_feet: = _blink_target_along_ground(global_position, target.global_position.x, max_dx)


	if not _is_in_evil_biome(dst_feet):
		var repl = _evil_surface_near_x_or_null(dst_feet.x)
		if repl == null:
			_despawn_clean("blink would leave biome; none loaded")
			return
		dst_feet = repl as Vector2


	var w: = _world_node()
	if w and w.has_method("_chunk_of_world_pos") and w.has_method("_is_chunk_loaded"):
		var dst_cc: Vector2i = w._chunk_of_world_pos(dst_feet)
		if not w._is_chunk_loaded(dst_cc):
			var repl2 = _evil_surface_near_x_or_null(dst_feet.x)
			if repl2 == null:
				_despawn_clean("blink to unloaded chunk; none loaded")
				return
			dst_feet = repl2 as Vector2


	if abs(dst_feet.x - old_x) < 0.5:
		var want_x: = target.global_position.x
		var legal = _evil_surface_near_x_or_null(want_x)
		if legal != null:
			want_x = (legal as Vector2).x
		dst_feet = _nearest_valid_feet_toward(_safe_surface_stand(global_position), want_x)


	if not _is_clear_feet(dst_feet):
		return


	var dir_sign = sign(dst_feet.x - old_x)
	if dir_sign != 0.0:
		_facing_dir = dir_sign

	spawn_at_feet(dst_feet)
	_update_flip()


	if teleport_snd:
		teleport_snd.stop()
		teleport_snd.play()
	rpc("cli_play_sfx", SFX_TELEPORT)


func _reroll_delay(first: bool) -> void :
	_since_reroll = 0.0
	_delay_cur_sec = randf_range(delay_min_sec, delay_max_sec)
	if first:
		_since_tp = randf() * _delay_cur_sec


func _ghost_walk_step(from_pos: Vector2, target_pos: Vector2, dt: float) -> Vector2:
	var pos: = _safe_surface_stand(from_pos)

	var dir = sign(target_pos.x - pos.x)
	if dir == 0.0:
		return pos
	_facing_dir = dir


	var here_y: = _ground_y_at_x_surface(pos.x, pos.y + 8.0)
	var ahead_x = pos.x + dir * look_ahead_px
	var ahead_y: = _ground_y_at_x_surface(ahead_x, pos.y + 8.0)

	var step_up_px = max(0.0, here_y - ahead_y)
	var drop_px = max(0.0, ahead_y - here_y)
	var can_step = step_up_px <= max_step_blocks * tile_px
	var avoid_drop = drop_px > max_drop_blocks * tile_px

	var vx: = 0.0
	if not avoid_drop:
		vx = dir * walk_speed_px

	var vy: = 0.0
	if can_step and step_up_px > 0.0 and _jump_headroom_ok(pos, dir):
		vy = jump_velocity_px

	vy += get_gravity().y * dt
	pos.x += vx * dt
	pos.y += vy * dt


	var gy: = _ground_y_at_x_surface(pos.x, pos.y + 8.0)
	if pos.y > gy - 6.0:
		pos.y = gy - 6.0


	pos = _push_out_of_solid(_safe_surface_stand(pos))
	return pos


func _ground_y_at_x_surface(wx: float, hint_y: float) -> float:
	var dss: = get_world_2d().direct_space_state
	var top: = hint_y - 8.0 * tile_px
	var bottom: = hint_y + 3.0 * tile_px
	var min_thick_px: = min_soil_thickness_tiles * tile_px

	var p: = PhysicsRayQueryParameters2D.new()
	p.collide_with_bodies = true
	p.collide_with_areas = true
	p.collision_mask = ground_mask

	var y: = top
	var safety: = 0
	while safety < 64 and y < bottom:
		safety += 1
		p.from = Vector2(wx, y)
		p.to = Vector2(wx, bottom)
		var hit: = dss.intersect_ray(p)
		if not hit: break

		var pos: Vector2 = hit["position"]
		var nrm: Vector2 = hit.get("normal", Vector2.UP)

		if nrm.y < -0.6:
			var thick_px: = _solid_thickness_below(wx, pos.y)
			if thick_px >= min_thick_px and _surface_has_local_support(wx, pos.y):
				return pos.y
		y = pos.y + 1.0

	return hint_y

@export var crest_scan_px: = 2.0 * tile_px
@export var crest_step_px: = 0.25 * tile_px
@export var crest_up_allow_px: = 1.25 * tile_px

func _is_clear_here(stand_center: Vector2) -> bool:

	var rect: = RectangleShape2D.new()
	rect.size = Vector2(clearance_w_px, clearance_h_px)
	var params: = PhysicsShapeQueryParameters2D.new()
	params.shape = rect
	params.transform = Transform2D(0.0, stand_center - Vector2(0, clearance_h_px * 0.5))
	params.collide_with_bodies = true
	params.collide_with_areas = true
	params.collision_mask = obstacle_mask
	var hits: = get_world_2d().direct_space_state.intersect_shape(params, 16)
	return hits.is_empty()

func _safe_surface_stand(p: Vector2) -> Vector2:
	var s: = _sweep_land_at_x(p.x, p.y + 8.0)
	return s

func _push_out_of_solid(feet: Vector2) -> Vector2:

	if _is_clear_feet(feet):
		return feet


	for i in range(10):
		var test: = feet + Vector2(0, -4.0 * float(i + 1))
		var landed: = _sweep_land_at_x(test.x, test.y)
		if _is_clear_feet(landed):
			return landed


	var rings: = [8.0, 16.0, 24.0, 32.0, 48.0, 64.0]
	var dirs: = [
		Vector2(1, 0), Vector2(-1, 0), 
		Vector2(0, -1), Vector2(0, 1), 
		Vector2(1, -1).normalized(), Vector2(-1, -1).normalized(), 
		Vector2(1, 1).normalized(), Vector2(-1, 1).normalized()
	]
	for r in rings:
		for d in dirs:
			var x_try = feet.x + d.x * r
			var y_try = feet.y + d.y * r
			var landed2: = _sweep_land_at_x(x_try, y_try)
			if _is_clear_feet(landed2):
				return landed2


	return feet

func _jump_headroom_ok(stand_pos: Vector2, dir: float) -> bool:

	var dss: = get_world_2d().direct_space_state
	var start: = stand_pos + Vector2(dir * (look_ahead_px * 0.4), -8.0)
	var end: = start + Vector2(dir * (look_ahead_px * 0.6), - (clearance_h_px + 24.0))
	var steps: = 8
	for i in range(steps + 1):
		var t: = i / float(steps)
		var p: = start.lerp(end, t)
		var rq: = PhysicsRayQueryParameters2D.new()
		rq.from = p
		rq.to = p + Vector2(0, -4.0)
		rq.collide_with_areas = true
		rq.collide_with_bodies = true
		rq.collision_mask = obstacle_mask
		var h: = dss.intersect_ray(rq)
		if h:
			return false
	return true


func _touch_attack() -> void :
	if not _is_server:
		return

	var shape: = CircleShape2D.new()
	shape.radius = touch_radius_px
	var params: = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, global_position)
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = HURTBOX_MASK

	var hits: = get_world_2d().direct_space_state.intersect_shape(params, 8)
	if hits.is_empty():
		return


	var hit_players: Array = []
	for h in hits:
		var col = h.get("collider")
		if col == null:
			continue
		var player: = _player_from_collider(col)
		if player != null:
			hit_players.append(player)

	if hit_players.is_empty():
		return


	if _scream_cd <= 0.0:
		if scream_snd:
			scream_snd.stop()
			scream_snd.play()
		rpc("cli_play_sfx", SFX_SCREAM)
		_scream_cd = SCREAM_COOLDOWN


	for player in hit_players:
		if player.has_method("cli_receive_damage"):
			var owner_id = player.get_multiplayer_authority()
			if owner_id != 0:
				player.rpc_id(owner_id, "cli_receive_damage", 999, Vector2.ZERO)

func _update_flip() -> void :


	if evil_leafy:
		evil_leafy.flip_h = (_facing_dir > 0.0)

func take_damage(amount: int, src: Node = null) -> void :
	if _dead: return
	health = max(0, health - amount)
	if health == 0:
		_die()

func _die() -> void :
	_dead = true

	set_physics_process(false)
	queue_free()


func _nearest_player() -> Node2D:
	var best: Node2D = null
	var best_d2: = INF
	for p in get_tree().get_nodes_in_group("player"):
		if not p or not is_instance_valid(p):
			continue
		if p._dead:
			continue

		var p_feet = p.global_position
		if not _is_in_evil_biome(p_feet):
			continue
		var d2: = global_position.distance_squared_to(p.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = p
	return best
