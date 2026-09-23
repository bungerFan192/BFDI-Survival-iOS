extends Node2D


@export var camera_path: NodePath = ^"../Camera2D"


@export var pool_size: = 48
@export var initial_scatter_span_x: = 80000.0
@export var spawn_horizon_x: = 20000.0


@export var min_x_gap_px: = 1400.0
@export var max_spawn_attempts: = 16


@export var y_min: = 2000.0
@export var y_max: = 2500.0


@export var min_spawn_s: = 5.0
@export var max_spawn_s: = 15.0


@export var speed_min: = -40.0
@export var speed_max: = -15.0
@export var scale_min: = 0.7
@export var scale_max: = 1.4
@export var base_alpha: = 0.92


const CLOUD_TEXTURES: = [
	preload("res://cloud1.png"), 
	preload("res://cloud2.png"), 
	preload("res://cloud3.png"), 
]


var _cam: Camera2D
var _pool: Array[Sprite2D] = []
var _active: Array[Sprite2D] = []
var _timer: SceneTreeTimer

func _ready() -> void :
	randomize()
	_cam = get_node_or_null(camera_path)


	for i in pool_size:
		var spr: = Sprite2D.new()
		spr.texture = CLOUD_TEXTURES[0]
		spr.visible = false
		spr.process_mode = Node.PROCESS_MODE_DISABLED
		spr.modulate.a = base_alpha
		add_child(spr)
		_pool.append(spr)


	var start_rect: = _visible_world_rect()
	var left: = start_rect.get_center().x - initial_scatter_span_x * 0.5
	var right: = start_rect.get_center().x + initial_scatter_span_x * 0.5
	var count = min(pool_size, 28)
	for i in count:
		_spawn_cloud_scatter(left, right)


	_arm_timer()
	set_process(true)

func _arm_timer() -> void :
	_timer = get_tree().create_timer(randf_range(min_spawn_s, max_spawn_s))
	_timer.timeout.connect( func():
		_spawn_ahead_of_camera()
		_arm_timer()
	)


func _visible_world_rect() -> Rect2:
	var vp_size: = get_viewport().get_visible_rect().size
	if _cam:
		var world_size: = vp_size * _cam.zoom
		var top_left: = _cam.global_position - world_size * 0.5
		return Rect2(top_left, world_size)

	return Rect2(global_position - vp_size * 0.5, vp_size)



func _spawn_cloud_scatter(x_left: float, x_right: float) -> void :
	var spr: = _take_from_pool()
	if spr == null: return

	spr.texture = CLOUD_TEXTURES.pick_random()
	var sc: = randf_range(scale_min, scale_max)
	spr.scale = Vector2(sc, sc)
	spr.modulate.a = base_alpha
	var speed: = randf_range(speed_min, speed_max) * lerpf(0.7, 1.2, inverse_lerp(scale_min, scale_max, sc))
	spr.set_meta("speed", speed)


	var x: = _find_fair_x(x_left, x_right)
	var y: = randf_range(y_min, y_max)

	spr.global_position = Vector2(x, y)
	spr.visible = true
	spr.process_mode = Node.PROCESS_MODE_INHERIT
	_active.append(spr)

func _spawn_ahead_of_camera() -> void :
	var spr: = _take_from_pool()
	if spr == null: return

	spr.texture = CLOUD_TEXTURES.pick_random()
	var sc: = randf_range(scale_min, scale_max)
	spr.scale = Vector2(sc, sc)
	spr.modulate.a = base_alpha
	var speed: = randf_range(speed_min, speed_max) * lerpf(0.7, 1.2, inverse_lerp(scale_min, scale_max, sc))
	spr.set_meta("speed", speed)

	var rect: = _visible_world_rect()
	var band_left: = rect.position.x + rect.size.x + spawn_horizon_x * 0.1
	var band_right: = rect.position.x + rect.size.x + spawn_horizon_x

	var x: = _find_fair_x(band_left, band_right)
	var y: = randf_range(y_min, y_max)

	spr.global_position = Vector2(x, y)
	spr.visible = true
	spr.process_mode = Node.PROCESS_MODE_INHERIT
	_active.append(spr)


func _find_fair_x(x_left: float, x_right: float) -> float:
	var tries: = max_spawn_attempts
	var best_x: = randf_range(x_left, x_right)
	var best_score: = - INF
	while tries > 0:
		var x: = randf_range(x_left, x_right)
		var score: = _min_distance_x_to_active(x)
		if score > best_score:
			best_score = score
			best_x = x
		if score >= min_x_gap_px:
			return x
		tries -= 1
	return best_x

func _min_distance_x_to_active(x: float) -> float:
	if _active.is_empty(): return INF
	var dmin: = INF
	for spr in _active:
		dmin = min(dmin, abs(x - spr.global_position.x))
	return dmin



func _process(delta: float) -> void :
	if _active.is_empty(): return

	var rect: = _visible_world_rect()
	var left_kill: = rect.position.x - spawn_horizon_x - 2000.0
	var right_kill: = rect.position.x + rect.size.x + spawn_horizon_x + 2000.0
	var top_kill: = y_min - 800.0
	var bot_kill: = y_max + 800.0

	var i: = 0
	while i < _active.size():
		var spr: = _active[i]
		var speed: = float(spr.get_meta("speed", -25.0))
		spr.global_position.x += speed * delta

		var p: = spr.global_position
		if p.x < left_kill or p.x > right_kill or p.y < top_kill or p.y > bot_kill:
			_return_to_pool(_active[i])
			_active.remove_at(i)
		else:
			i += 1



func _take_from_pool() -> Sprite2D:
	if _pool.is_empty(): return null
	return _pool.pop_back()

func _return_to_pool(spr: Sprite2D) -> void :
	spr.visible = false
	spr.process_mode = Node.PROCESS_MODE_DISABLED
	_pool.append(spr)
