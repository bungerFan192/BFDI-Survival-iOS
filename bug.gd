extends CharacterBody2D

@export var walk_speed: = 240.0
@export var chase_speed: = 380.0
@export var accel: = 900.0
@export var jump_velocity: = -560.0
@export var step_jump_velocity: = -360.0
@export var gravity_scale: = 1.0

@export var decision_every: = 0.8
@export var rand_flip_chance: = 0.15
@export var rand_jump_chance: = 0.1

@export var attack_range_blocks: = 4.0
@export var idle_range_blocks: = 8.0

@export var block_px: = 74.0
@export var is_cave_spawn: = false

@export var bug_id: = 0
@export var min_hp: = 1
@export var max_hp: = 2
@export var touch_damage: = 1
@export var touch_cooldown: = 2
@export var touch_radius_blocks: = 1.0

@onready var hit: AudioStreamPlayer2D = $hit
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: CollisionShape2D = $Hurtbox / CollisionShape2D

const OFFSCREEN_STEP_SEC: = 3.0
const OFFSCREEN_STEP_BLOCKS_MIN: = 8
const OFFSCREEN_STEP_BLOCKS_MAX: = 12
const OFFSCREEN_PLAYER_BIAS: = 0.35
const OFFSCREEN_RAY_UP_BLOCKS: = 6
const OFFSCREEN_RAY_DOWN_BLOCKS: = 16
@export var offscreen_step_every: = 3.0
@export var offscreen_step_blocks: = 6.0
var _offscreen_t: = 0.0

var _hp: = 1
var _touch_cd: = 0.0
var _dead: = false
var _hit_tw: Tween = null

var is_on_screen: bool = false

@onready var _hurtbox: Area2D = $Hurtbox
@onready var bug: AudioStreamPlayer2D = $bug

var _dir: = 1
var _decide_t: = 0.0
var _chasing: = false

var _despawn_left: = -1.0
var _despawn_total: = 0.0

var _front_ray: RayCast2D
var _floor_ray: RayCast2D


var _asset_cache: = {}
func _audio(path: String) -> AudioStream:
	if path == "": return null
	if _asset_cache.has(path): return _asset_cache[path]
	var r: = load(path)
	if r: _asset_cache[path] = r
	return r as AudioStream

const PATH_HIT: = "res://sounds/hit.wav"
const PATH_SLAP1: = "res://sounds/slap1.wav"
const PATH_SLAP2: = "res://sounds/slap2.wav"
const PATH_SLAP3: = "res://sounds/slap3.wav"
const PATH_SLAP4: = "res://sounds/slap4.wav"

func hitsound():
	var n: = randi_range(1, 5)
	var p: = PATH_HIT
	match n:
		2: p = PATH_SLAP1
		3: p = PATH_SLAP2
		4: p = PATH_SLAP3
		5: p = PATH_SLAP4
	if hit:
		hit.stream = _audio(p)
		hit.play()


@onready var tile_map_layer: TileMapLayer = $"../../TileMapLayer"

const WATER_COORDS_BUG: = [Vector2i(4, 5)]
const WATER_PROBE_WIDTH_PX_BUG: = 14.0
const WATER_PROBE_TOP_PX_BUG: = -22.0
const WATER_PROBE_BOTTOM_PX_BUG: = 22.0
const WATER_PROBE_STEPS_BUG: = 5


const BUG_WATER_SWIM_THRESHOLD: = 0.5
const BUG_BUOYANCY_GRAV: = 320.0
const BUG_MAX_SINK_SPEED: = 120.0
const BUG_WATER_DRAG_X: = 0.92


const BUG_FLOAT_SURFACE_OFFSET: = 10.0
const BUG_BUOYANCY_ACCEL: = 520.0
const BUG_CLAMP_UP_SPEED: = 180.0
const BUG_BOB_AMPL: = 6.0
const BUG_BOB_FREQ: = 0.8

var _bug_bob_t: = 0.0

var _bug_submerged_frac: = 0.0
var _bug_in_water: = false

func _bug_cell_at_point_to_map(pt_world: Vector2) -> Vector2i:
	if tile_map_layer == null:
		return Vector2i(-1, -1)
	return tile_map_layer.local_to_map(tile_map_layer.to_local(pt_world))

func _water_buoyancy_step(delta: float) -> void :

	_bug_submerged_frac = _bug_measure_submergence()
	_bug_in_water = (_bug_submerged_frac >= BUG_WATER_SWIM_THRESHOLD)

	if _bug_in_water:

		_bug_bob_t += delta
		var bob: = sin(TAU * BUG_BOB_FREQ * _bug_bob_t) * BUG_BOB_AMPL


		var surface_y: = _bug_find_surface_y()
		var target_y: float
		if is_nan(surface_y):

			var want_frac: = 0.6
			var err: = want_frac - _bug_submerged_frac
			target_y = global_position.y - err * 40.0 + bob
		else:

			target_y = surface_y - BUG_FLOAT_SURFACE_OFFSET + bob


		var dy: = target_y - global_position.y
		var desired_vy = clamp(dy * 2.0, - BUG_CLAMP_UP_SPEED, BUG_MAX_SINK_SPEED)
		velocity.y = move_toward(velocity.y, desired_vy, BUG_BUOYANCY_ACCEL * delta)


		velocity.x *= pow(BUG_WATER_DRAG_X, delta)
	else:

		velocity += get_gravity() * gravity_scale * delta

func _bug_is_water_cell(cell: Vector2i) -> bool:
	if tile_map_layer == null: return false
	if tile_map_layer.get_cell_source_id(cell) == -1: return false
	return tile_map_layer.get_cell_atlas_coords(cell) in WATER_COORDS_BUG

func _bug_measure_submergence() -> float:
	if tile_map_layer == null: return 0.0
	var top: = global_position + Vector2(0.0, WATER_PROBE_TOP_PX_BUG)
	var bot: = global_position + Vector2(0.0, WATER_PROBE_BOTTOM_PX_BUG)
	var hits: = 0
	for i in WATER_PROBE_STEPS_BUG:
		var t: = float(i) / float(max(1, WATER_PROBE_STEPS_BUG - 1))
		var y = lerp(top.y, bot.y, t)
		var left: = global_position.x - WATER_PROBE_WIDTH_PX_BUG * 0.5
		var right: = global_position.x + WATER_PROBE_WIDTH_PX_BUG * 0.5
		var cells: = [
			_bug_cell_at_point_to_map(Vector2(left, y)), 
			_bug_cell_at_point_to_map(Vector2(global_position.x, y)), 
			_bug_cell_at_point_to_map(Vector2(right, y)), 
		]
		for c in cells:
			if _bug_is_water_cell(c):
				hits += 1
				break
	return float(hits) / float(WATER_PROBE_STEPS_BUG)

func _bug_find_surface_y(max_scan_px: = 10.0 * block_px) -> float:

	if tile_map_layer == null:
		return NAN


	var start_y: = global_position.y + WATER_PROBE_TOP_PX_BUG - 2.0
	var step: = - block_px * 0.5
	var y: = start_y
	var scanned: = 0.0
	while scanned < max_scan_px:
		var cell: = _bug_cell_at_point_to_map(Vector2(global_position.x, y))
		var in_water: = _bug_is_water_cell(cell)
		if not in_water:

			return y - step * 0.5
		y += step
		scanned += abs(step)
	return NAN

func _ready() -> void :
	randomize()
	bug.play()
	_offscreen_t = randf() * offscreen_step_every
	_hurtbox.collision_layer = 1 << 7
	_hurtbox.collision_mask = 0
	add_to_group("bug")
	var is_auth: = multiplayer.is_server() and is_multiplayer_authority()


	set_physics_process(is_auth)
	set_process(is_auth)


	_front_ray = RayCast2D.new()
	_front_ray.collide_with_areas = false
	_front_ray.collide_with_bodies = true
	_front_ray.target_position = Vector2(18, 0)
	add_child(_front_ray)

	_floor_ray = RayCast2D.new()
	_floor_ray.collide_with_areas = false
	_floor_ray.collide_with_bodies = true
	_floor_ray.target_position = Vector2(12, 30)
	add_child(_floor_ray)


	_front_ray.enabled = is_auth
	_floor_ray.enabled = is_auth

	_update_rays()

const HURTBOX_MASK: = 1 << 7

func _server_touch_attack(delta: float) -> void :
	if _dead: return
	_touch_cd = max(0.0, _touch_cd - delta)
	if _touch_cd > 0.0: return

	var radius: = touch_radius_blocks * block_px

	var shape: = CircleShape2D.new()
	shape.radius = radius
	var params: = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, global_position)
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = HURTBOX_MASK

	var hits: = get_world_2d().direct_space_state.intersect_shape(params, 8)
	if hits.is_empty(): return


	var best_node: Node = null
	var best_d2: = INF
	for h in hits:
		var n: = h.get("collider") as Node
		while n and not n.is_in_group("player"):
			n = n.get_parent()
		if n and n.is_in_group("player"):
			var d2: = global_position.distance_squared_to((n as Node2D).global_position)
			if d2 < best_d2:
				best_d2 = d2
				best_node = n
	if best_node:
		var vid: = best_node.get_multiplayer_authority()
		var dir = sign((best_node as Node2D).global_position.x - global_position.x)
		if dir == 0: dir = 1
		var kb: = Vector2(220.0 * dir, -140.0)
		(best_node as Node).rpc_id(vid, "cli_receive_damage", int(touch_damage), kb)
		_touch_cd = touch_cooldown
		_chasing = true

@rpc("any_peer", "call_local")
func cli_bug_take_damage(amount: int) -> void :
	if _dead: return
	_hp = max(0, _hp - max(1, amount))


	hitsound()


	_flash_hit(0.25)
	print(_hp)

@rpc("any_peer", "call_local")
func cli_bug_knockback(impulse: Vector2) -> void :
	if _dead:
		return
	velocity += impulse

func _flash_hit(duration: float = 0.25) -> void :
	if _dead: return
	if _hit_tw:
		_hit_tw.kill()
		_hit_tw = null

	var a: = modulate.a
	var from_c: = modulate
	var hit_c: = Color(1.0, 0.25, 0.25, a)

	_hit_tw = get_tree().create_tween()
	_hit_tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


	_hit_tw.tween_property(self, "modulate", hit_c, duration * 0.5)
	_hit_tw.tween_property(self, "modulate", Color(1, 1, 1, a), duration * 0.5)

@rpc("any_peer", "call_local")
func cli_bug_die_and_fade(fade_sec: float) -> void :
	if _dead: return
	_dead = true

	if _hit_tw:
		_hit_tw.kill()
		_hit_tw = null


	set_physics_process(false)
	set_process(false)
	if _front_ray: _front_ray.enabled = false
	if _floor_ray: _floor_ray.enabled = false


	if bug:
		bug.stop()
		collision_shape_2d.disabled = true
		hurtbox.disabled = true


	var a: = modulate.a
	modulate = Color(1.0, 0.3, 0.3, a)
	var tw: = get_tree().create_tween()
	tw.tween_property(self, "modulate:a", 0.0, fade_sec)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished



func _server_chunk_has_viewers() -> bool:
	var world: = get_tree().get_first_node_in_group("world")
	if world == null:
		return true

	var cc = world.call("_chunk_of_world_pos", global_position)
	if typeof(cc) != TYPE_VECTOR2I:
		return true
	var n: = int(world.call("_loaded_count_peers", cc))
	return n > 0

func _offscreen_coarse_step() -> void :

	var dir: int = 1
	if randf() < 0.5:
		dir = -1
	var target_player: = _nearest_player()
	if target_player:
		var toward: = _sign(target_player.global_position.x - global_position.x)
		if toward == 0: toward = 1
		if randf() < OFFSCREEN_PLAYER_BIAS:
			dir = toward


	var blocks: = randi_range(OFFSCREEN_STEP_BLOCKS_MIN, OFFSCREEN_STEP_BLOCKS_MAX)
	var step_px: = float(blocks) * block_px
	var base_target: = global_position + Vector2(dir * step_px, 0)


	var dss: = get_world_2d().direct_space_state
	var from: = base_target + Vector2(0, - OFFSCREEN_RAY_UP_BLOCKS * block_px)
	var to: = base_target + Vector2(0, OFFSCREEN_RAY_DOWN_BLOCKS * block_px)

	var p: = PhysicsRayQueryParameters2D.new()
	p.from = from
	p.to = to
	p.collide_with_areas = false
	p.collide_with_bodies = true
	var hit: = dss.intersect_ray(p)

	if hit.has("position"):

		var hit_pos: Vector2 = hit["position"]
		global_position = Vector2(base_target.x, hit_pos.y - 6.0)
	else:

		global_position = base_target


	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void :

	_process_despawn(delta)
	if _despawn_left >= 0.0:

		_bug_submerged_frac = _bug_measure_submergence()
		_bug_in_water = (_bug_submerged_frac >= BUG_WATER_SWIM_THRESHOLD)

		if not is_on_floor():
			_water_buoyancy_step(delta)
		move_and_slide()
		return


	var any_viewer: = true
	if multiplayer.is_server():

		var world: = get_tree().get_first_node_in_group("world")
		if world:
			any_viewer = bool(world.call("_bug_has_any_viewer", bug_id))


		var target: = _nearest_player()
		if target:
			var atk_r: = attack_range_blocks * block_px
			var idle_r: = idle_range_blocks * block_px
			var d2: = global_position.distance_squared_to(target.global_position)
			var atk2: = atk_r * atk_r
			var idle2: = idle_r * idle_r

			if _chasing:
				_chasing = d2 <= idle2
			else:
				_chasing = d2 <= atk2

			if _chasing:
				_dir = _sign(target.global_position.x - global_position.x)
				if _dir == 0: _dir = 1
		else:
			_chasing = false

		var engaged: = _chasing


		if is_cave_spawn:
			if not any_viewer and not engaged:
				return
		else:

			if not any_viewer and not engaged:
				_offscreen_t += delta
				if _despawn_left < 0.0 and _offscreen_t >= OFFSCREEN_STEP_SEC:
					_offscreen_t = 0.0
					_offscreen_coarse_step()

				_bug_submerged_frac = _bug_measure_submergence()
				_bug_in_water = (_bug_submerged_frac >= BUG_WATER_SWIM_THRESHOLD)

				if not is_on_floor():
					_water_buoyancy_step(delta)
				move_and_slide()
				return

	_bug_submerged_frac = _bug_measure_submergence()
	_bug_in_water = (_bug_submerged_frac >= BUG_WATER_SWIM_THRESHOLD)

	if not is_on_floor():
		_water_buoyancy_step(delta)
	_server_touch_attack(delta)



	var target: = _nearest_player()
	if target:
		var atk_r: = attack_range_blocks * block_px
		var idle_r: = idle_range_blocks * block_px
		var d2: = global_position.distance_squared_to(target.global_position)
		var atk2: = atk_r * atk_r
		var idle2: = idle_r * idle_r


		if _chasing:
			_chasing = d2 <= idle2
		else:
			_chasing = d2 <= atk2

		if _chasing:
			_dir = _sign(target.global_position.x - global_position.x)
			if _dir == 0: _dir = 1


	_decide_t -= delta
	if _decide_t <= 0.0:
		_decide_t = decision_every
		if not _chasing:
			if randf() < rand_flip_chance:
				_dir *= -1
				_update_rays()
			elif randf() < rand_jump_chance and is_on_floor():
				velocity.y = step_jump_velocity


	_update_rays()
	var front_blocked: = _front_ray.is_colliding()
	var floor_ahead: = _floor_ray.is_colliding()

	if (front_blocked or not floor_ahead) and is_on_floor():

		if _bug_in_water:


			pass
		else:

			if _chasing or randf() < 0.6:
				velocity.y = jump_velocity
			else:
				_dir *= -1
				_update_rays()


	var want_speed: = (chase_speed if _chasing else walk_speed) * _dir
	velocity.x = move_toward(velocity.x, want_speed, accel * delta)
	move_and_slide()

	if multiplayer.is_server() and global_position.y > 10000:
		queue_free()

func _process_despawn(delta: float) -> void :

	var night: = false
	var sky: = get_tree().get_first_node_in_group("sky_cycle")
	if sky:
		night = bool(sky.get("is_night_now"))


	if is_cave_spawn:
		_despawn_left = -1.0
		modulate.a = 1.0
		return

	if night:
		_despawn_left = -1.0
		modulate.a = 1.0
	else:
		if _despawn_left < 0.0:
			_despawn_total = randf_range(1.0, 3.0)
			_despawn_left = _despawn_total
			if bug:
				bug.stop()
				collision_shape_2d.disabled = true
				hurtbox.disabled = true

		else:
			_despawn_left = max(0.0, _despawn_left - delta)
			modulate.a = (_despawn_left / _despawn_total)
			if _despawn_left <= 0.0:
				if multiplayer.is_server():
					var world: = get_tree().get_first_node_in_group("world")
					if world and world.has_method("_server_kill_bug_with_fade"):
						world.call("_server_kill_bug_with_fade", bug_id)
					elif world and world.has_method("_server_despawn_bug"):
						world.call("_server_despawn_bug", bug_id)
					else:
						queue_free()
				return

func _nearest_player() -> Node2D:
	var best: Node2D = null
	var best_d2: = INF
	for p in get_tree().get_nodes_in_group("player"):
		if p and is_instance_valid(p):
			var d2: = global_position.distance_squared_to(p.global_position)
			if d2 < best_d2:
				best_d2 = d2
				best = p
	return best

func _update_rays() -> void :
	var ahead: = Vector2(0.55 * block_px * _dir, 0)
	_front_ray.exclude_parent = true
	_floor_ray.exclude_parent = true
	_front_ray.target_position = ahead
	_floor_ray.target_position = ahead + Vector2(0, 0.75 * block_px)

func _sign(v: float) -> int:
	return -1 if v < 0.0 else (1 if v > 0.0 else 0)


func _on_screen_screen_entered() -> void :

	var world: = get_tree().get_first_node_in_group("world")
	if world == null: return
	if multiplayer.is_server():
		world.call("srv_report_bug_visible", bug_id, true)
	else:
		world.rpc_id(1, "srv_report_bug_visible", bug_id, true)



func _on_screen_screen_exited() -> void :

	var world: = get_tree().get_first_node_in_group("world")
	if world == null: return
	if multiplayer.is_server():
		world.call("srv_report_bug_visible", bug_id, false)
	else:
		world.rpc_id(1, "srv_report_bug_visible", bug_id, false)
