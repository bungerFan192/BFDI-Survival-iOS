extends CharacterBody2D


@export var swim_speed: = 240.0
@export var chase_speed: = 360.0
@export var accel: = 900.0


@export var gravity_scale_land: = 1.0
@export var flop_impulse: = Vector2(140.0, -120.0)
@export var flop_every: = 1.2
@export var suffocate_after: = 8.0


@export var attack_range_blocks: = 4.0
@export var idle_range_blocks: = 8.0
@export var touch_damage: = 1
@export var touch_cooldown: = 1.8
@export var touch_radius_blocks: = 0.9


@export var block_px: = 74.0


@export var fish_id: = 0
@export var min_hp: = 3
@export var max_hp: = 6


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox / CollisionShape2D
@onready var hit: AudioStreamPlayer2D = $hit
@onready var fish_loop: AudioStreamPlayer2D = $fish
@onready var tile_map_layer: TileMapLayer = $"../../TileMapLayer"


const WATER_COORDS_FISH: = [Vector2i(4, 5)]
const PROBE_WIDTH_PX: = 18.0
const PROBE_TOP_PX: = -18.0
const PROBE_BOTTOM_PX: = 18.0
const PROBE_STEPS: = 5

const SUBMERGE_THRESHOLD: = 0.55
const BUOYANCY_ACCEL: = 520.0
const CLAMP_UP_SPEED: = 180.0
const MAX_SINK_SPEED: = 120.0
const WATER_DRAG_X: = 0.9
const FLOAT_SURFACE_OFFSET: = 12.0
const BOB_AMPL: = 5.0
const BOB_FREQ: = 1.0


const HURTBOX_MASK: = 1 << 7

var _hp: = 1
var _touch_cd: = 0.0
var _dead: = false
var _dir: = 1
var _chasing: = false
var _decide_t: = 0.0
@export var decision_every: = 1.0
@export var rand_flip_chance: = 0.1

var _submerged_frac: = 0.0
var _in_water: = false
var _bob_t: = 0.0
var _time_out_of_water: = 0.0
var _flop_t: = 0.0


const CHASE_DIVE_FACTOR: = 0.65
const CHASE_DEPTH_OFFSET: = 8.0
const WATER_EDGE_CLEAR: = 10.0
const BOB_CHASE_SCALE: = 0.3

func _find_bottom_y(max_scan_px: = 10.0 * block_px) -> float:
	if tile_map_layer == null:
		return NAN
	var start_y: = global_position.y + PROBE_BOTTOM_PX + 2.0
	var step: = block_px * 0.5
	var y: = start_y
	var scanned: = 0.0
	while scanned < max_scan_px:
		var cell: = _cell_at_point_to_map(Vector2(global_position.x, y))
		if not _is_water_cell(cell):

			return y - step * 0.5
		y += step
		scanned += abs(step)
	return NAN



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

var _hit_tw: Tween = null

func _flash_hit(duration: float = 0.25) -> void :
	if _dead: return
	if _hit_tw:
		_hit_tw.kill()
		_hit_tw = null

	var a: = modulate.a
	var hit_c: = Color(1.0, 0.25, 0.25, a)

	_hit_tw = get_tree().create_tween()
	_hit_tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_hit_tw.tween_property(self, "modulate", hit_c, duration * 0.5)
	_hit_tw.tween_property(self, "modulate", Color(1, 1, 1, a), duration * 0.5)

@rpc("any_peer", "call_local")
func cli_fish_die_and_fade(fade_sec: float) -> void :
	if _dead: return
	_dead = true


	set_physics_process(false)
	set_process(false)
	if has_node("AnimatedSprite2D"): $AnimatedSprite2D.stop()
	if has_node("CollisionShape2D"): $CollisionShape2D.disabled = true
	if has_node("Hurtbox/CollisionShape2D"): $Hurtbox / CollisionShape2D.disabled = true
	if has_node("fish"): $fish.stop()


	var a: = modulate.a
	modulate = Color(1.0, 0.3, 0.3, a)
	var tw: = get_tree().create_tween()
	tw.tween_property(self, "modulate:a", 0.0, fade_sec)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished



func _ready() -> void :
	randomize()
	_hp = randi_range(min_hp, max_hp)
	add_to_group("fish")
	var is_auth: = multiplayer.is_server() and is_multiplayer_authority()
	set_physics_process(is_auth)
	set_process(is_auth)


	if has_node("hit"):
		hit = $hit
	if has_node("fish"):
		fish_loop = $fish
	if fish_loop:
		fish_loop.play()

	$Hurtbox.collision_layer = 1 << 7
	$Hurtbox.collision_mask = 0
	_play_swim()


func _cell_at_point_to_map(pt_world: Vector2) -> Vector2i:
	if tile_map_layer == null: return Vector2i(-1, -1)
	return tile_map_layer.local_to_map(tile_map_layer.to_local(pt_world))

func _is_water_cell(cell: Vector2i) -> bool:
	if tile_map_layer == null: return false
	if tile_map_layer.get_cell_source_id(cell) == -1: return false
	return tile_map_layer.get_cell_atlas_coords(cell) in WATER_COORDS_FISH

func _measure_submergence() -> float:
	if tile_map_layer == null: return 0.0
	var top: = global_position + Vector2(0.0, PROBE_TOP_PX)
	var bot: = global_position + Vector2(0.0, PROBE_BOTTOM_PX)
	var hits: = 0
	for i in PROBE_STEPS:
		var t: = float(i) / float(max(1, PROBE_STEPS - 1))
		var y = lerp(top.y, bot.y, t)
		var left: = global_position.x - PROBE_WIDTH_PX * 0.5
		var right: = global_position.x + PROBE_WIDTH_PX * 0.5
		var cells: = [
			_cell_at_point_to_map(Vector2(left, y)), 
			_cell_at_point_to_map(Vector2(global_position.x, y)), 
			_cell_at_point_to_map(Vector2(right, y)), 
		]
		for c in cells:
			if _is_water_cell(c):
				hits += 1
				break
	return float(hits) / float(PROBE_STEPS)

func _find_surface_y(max_scan_px: = 10.0 * block_px) -> float:
	if tile_map_layer == null: return NAN
	var start_y: = global_position.y + PROBE_TOP_PX - 2.0
	var step: = - block_px * 0.5
	var y: = start_y
	var scanned: = 0.0
	while scanned < max_scan_px:
		var cell: = _cell_at_point_to_map(Vector2(global_position.x, y))
		if not _is_water_cell(cell):
			return y - step * 0.5
		y += step
		scanned += abs(step)
	return NAN


func _play_swim() -> void :
	if sprite and not _dead:
		if sprite.animation != "swim":
			sprite.play("default")

@rpc("any_peer", "call_local")
func cli_fish_bite_anim(duration: float = 0.25) -> void :
	if _dead or sprite == null: return
	sprite.play("bite")
	await get_tree().create_timer(duration).timeout
	if not _dead:
		_play_swim()


func _server_touch_attack(delta: float) -> void :
	if _dead or not _in_water: return
	_touch_cd = max(0.0, _touch_cd - delta)
	if _touch_cd > 0.0: return

	var radius_px: = touch_radius_blocks * block_px
	var shape: = CircleShape2D.new()
	shape.radius = radius_px

	var params: = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, global_position)
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = HURTBOX_MASK

	var hits: = get_world_2d().direct_space_state.intersect_shape(params, 8)
	if hits.is_empty(): return

	var best_player: Node = null
	var best_d2: = INF
	for h in hits:
		var n: = h.get("collider") as Node
		while n and not n.is_in_group("player"):
			n = n.get_parent()
		if n and n.is_in_group("player"):
			var d2: = global_position.distance_squared_to((n as Node2D).global_position)
			if d2 < best_d2:
				best_d2 = d2
				best_player = n

	if best_player:
		var vid: = best_player.get_multiplayer_authority()

		var dir = sign((best_player as Node2D).global_position.x - global_position.x)
		if dir == 0: dir = 1
		var kb: = Vector2(200.0 * dir, -100.0)
		(best_player as Node).rpc_id(vid, "cli_receive_damage", int(touch_damage), kb)


		rpc("cli_fish_bite_anim", 0.25)
		_touch_cd = touch_cooldown
		_chasing = true

@rpc("any_peer", "call_local")
func cli_fish_take_damage(amount: int) -> void :
	if _dead: return
	_hp = max(0, _hp - max(1, amount))


	hitsound()
	_flash_hit(0.25)

	if _hp == 0:
		_die_now()

func _die_now() -> void :
	if _dead: return
	_dead = true
	set_physics_process(false)
	set_process(false)
	if fish_loop: fish_loop.stop()
	if collision_shape_2d: collision_shape_2d.disabled = true
	if hurtbox_shape: hurtbox_shape.disabled = true

	var tw: = get_tree().create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.35)
	await tw.finished
	queue_free()


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


func _physics_process(delta: float) -> void :

	_submerged_frac = _measure_submergence()
	_in_water = _submerged_frac >= SUBMERGE_THRESHOLD


	var target: = _nearest_player()
	if target:
		var atk_r: = attack_range_blocks * block_px
		var idle_r: = idle_range_blocks * block_px
		var d2: = global_position.distance_squared_to(target.global_position)

		if _chasing:
			_chasing = d2 <= idle_r * idle_r
		else:
			_chasing = d2 <= atk_r * atk_r

		if _chasing:
			_dir = sign(target.global_position.x - global_position.x)
			if _dir == 0:
				_dir = 1


	_decide_t -= delta
	if _decide_t <= 0.0:
		_decide_t = decision_every
		if not _chasing and _in_water and randf() < rand_flip_chance:
			_dir *= -1


	if _in_water:
		_time_out_of_water = 0.0
		_flop_t = 0.0


		_bob_t += delta
		var bob_base: = sin(TAU * BOB_FREQ * _bob_t) * BOB_AMPL
		var surface_y: = _find_surface_y()
		var bottom_y: = _find_bottom_y()


		var bob: = bob_base * (BOB_CHASE_SCALE if _chasing else 1.0)

		var target_y: float
		if is_nan(surface_y) and is_nan(bottom_y):

			var want_frac: = 0.6
			var err: = want_frac - _submerged_frac
			target_y = global_position.y - err * 40.0 + bob
		else:

			var patrol_y: = surface_y - FLOAT_SURFACE_OFFSET if not is_nan(surface_y) else global_position.y

			if not _chasing and not is_nan(surface_y) and not is_nan(bottom_y):
				patrol_y = lerp(surface_y + WATER_EDGE_CLEAR, bottom_y - WATER_EDGE_CLEAR, 0.5)
			target_y = patrol_y + bob


		if _chasing and target:
			var prefer_y: = (target.global_position.y + CHASE_DEPTH_OFFSET)
			if not is_nan(surface_y):
				prefer_y = max(prefer_y, surface_y + WATER_EDGE_CLEAR)
			if not is_nan(bottom_y):
				prefer_y = min(prefer_y, bottom_y - WATER_EDGE_CLEAR)

			target_y = lerp(target_y, prefer_y, CHASE_DIVE_FACTOR)


		var dy: = target_y - global_position.y
		var desired_vy = clamp(dy * 2.0, - CLAMP_UP_SPEED, MAX_SINK_SPEED)
		velocity.y = move_toward(velocity.y, desired_vy, BUOYANCY_ACCEL * delta)


		var want_speed: float
		if _chasing:
			want_speed = chase_speed * float(_dir)
		else:
			want_speed = swim_speed * float(_dir)
		velocity.x = move_toward(velocity.x, want_speed, accel * delta)
		velocity.x *= pow(WATER_DRAG_X, delta)


		if _dir != 0 and sprite:
			sprite.flip_h = (_dir > 0)
	else:

		_time_out_of_water += delta
		_flop_t += delta
		velocity += get_gravity() * gravity_scale_land * delta

		if is_on_floor() and _flop_t >= flop_every:
			_flop_t = 0.0

			var j: = flop_impulse
			var bias: = _nearest_player()
			if bias:
				var toward = sign(bias.global_position.x - global_position.x)
				if toward == 0:
					toward = 1
				j.x = abs(j.x) * toward
			velocity += j


		if _time_out_of_water >= suffocate_after:
			_die_now()
			return


	_server_touch_attack(delta)


	move_and_slide()


	if global_position.y > 10000:
		queue_free()
