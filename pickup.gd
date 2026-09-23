extends Area2D

@export var item_id: int = 0
@export var count: int = 1
@export var texture: Texture2D

@export var magnet_radius: = 120.0
@export var pickup_radius: = 22.0
@export var max_speed: = 280.0
@export var accel: = 1400.0
@export var float_up: = 16.0
@export var float_time: = 0.25
@export var magnet_delay: = 0.0


@export var pickup_id: int = 0


@export var meta: Dictionary = {}

var _vel: = Vector2.ZERO
var _player: Node2D
var _magnet_timer: = 0.0
var _waiting_ack: = false
var _sprite: Sprite2D
var _shape: CollisionShape2D
var _world
var _reseek_t: = 0.0

var _sync_timer: = 0.0

func _ready() -> void :
	add_to_group("pickup")

	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.scale = Vector2(0.6, 0.6)
	add_child(_sprite)

	_shape = CollisionShape2D.new()
	var c: = CircleShape2D.new()
	c.radius = pickup_radius
	_shape.shape = c
	add_child(_shape)


	_player = _find_local_player()

	_world = get_tree().get_first_node_in_group("world")
	_magnet_timer = magnet_delay


	if _world and _world.has_signal("local_player_ready"):
		_world.connect("local_player_ready", Callable(self, "_on_local_player_ready"))


	var tw: = get_tree().create_tween()
	tw.tween_property(self, "global_position:y", global_position.y - float_up, float_time * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position:y", global_position.y, float_time * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _on_local_player_ready(p: Node2D) -> void :

	if p and p.get_multiplayer_authority() == multiplayer.get_unique_id():
		_player = p

func apply_kick(dir: = Vector2(randf_range(-1.0, 1.0), -1.0).normalized(), strength: = 120.0) -> void :
	_vel += dir.normalized() * strength

func _physics_process(delta: float) -> void :
	if _waiting_ack:
		return


	if _world == null:
		_world = get_tree().get_first_node_in_group("world")


	if _player == null or not is_instance_valid(_player):
		_reseek_t += delta
		if _reseek_t >= 0.25:
			_reseek_t = 0.0
			_player = _find_local_player()


	if multiplayer.is_server():
		if _magnet_timer > 0.0:
			_magnet_timer = max(0.0, _magnet_timer - delta)

		var target_pos: = global_position
		if _world and _world.has_method("_server_nearest_player_pos"):
			target_pos = _world._server_nearest_player_pos(global_position)

		var d: = target_pos - global_position
		var dist: = d.length()


		if _magnet_timer == 0.0 and dist < magnet_radius:
			var dir = d / max(dist, 0.001)
			_vel = _vel.move_toward(dir * max_speed, accel * delta)
		else:
			_vel *= pow(0.0001, delta)

		global_position += _vel * delta


		_sync_timer += delta
		if _sync_timer >= 0.05:
			_sync_timer = 0.0
			_send_state_to_clients()


	if _player and is_instance_valid(_player):
		var d_local: = _player.global_position - global_position
		var dist_local: = d_local.length()


		if dist_local < 24.0 and _is_local_players_body():
			_request_server_pickup()

func _is_local_players_body() -> bool:
	return _player and _player.get_multiplayer_authority() == multiplayer.get_unique_id()

func _find_local_player() -> Node2D:
	for n in get_tree().get_nodes_in_group("player"):
		if n and is_instance_valid(n) and n.get_multiplayer_authority() == multiplayer.get_unique_id():
			return n as Node2D
	return null



func _request_server_pickup() -> void :
	if _world == null:
		_world = get_tree().get_first_node_in_group("world")
	if _world == null: return


	if not _client_can_take(item_id, count):
		_bump_if_full()
		return

	if pickup_id == 0:
		_local_pickup_fallback()
		return


	var hotbar: = get_tree().get_first_node_in_group("hotbar")
	if hotbar and texture and hotbar.has_method("register_item_icon"):
		hotbar.register_item_icon(item_id, texture)


	if multiplayer.is_server():
		_world.srv_request_pickup(pickup_id, multiplayer.get_unique_id())
	else:
		_world.rpc_id(1, "srv_request_pickup", pickup_id)


	_waiting_ack = true
	if _sprite: _sprite.visible = false
	if _shape: _shape.disabled = true
	_vel = Vector2.ZERO

func _client_can_take(id: int, amount: int) -> bool:
	var need: = amount


	var inv: = get_tree().get_first_node_in_group("inventory")
	if inv:
		if inv.has_method("space_for"):
			var take: = int(inv.space_for(id, need))
			need -= take


	var hb: = get_tree().get_first_node_in_group("hotbar")
	if hb and hb.has_method("space_for") and need > 0:
		var take_h: = int(hb.space_for(id, need))
		need -= take_h

	return need <= 0

func _bump_if_full() -> void :

	if _sprite == null: return
	var tw: = get_tree().create_tween()
	tw.tween_property(_sprite, "scale", Vector2(0.7, 0.7), 0.06)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_sprite, "scale", Vector2(0.6, 0.6), 0.12)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)




func _local_pickup_fallback() -> void :
	var hotbar: = get_tree().get_first_node_in_group("hotbar")
	if hotbar:
		if texture and hotbar.has_method("register_item_icon"):
			hotbar.register_item_icon(item_id, texture)

		if hotbar.has_method("add_with_meta"):
			hotbar.call("add_with_meta", item_id, count, meta)
		else:
			hotbar.call("add", item_id, count)
		hotbar._ensure_spyglass()
	queue_free()

func net_apply_state(pos: Vector2, vel: Vector2) -> void :

	if multiplayer.is_server():
		return
	global_position = pos
	_vel = vel

func _send_state_to_clients() -> void :
	if _world == null:
		_world = get_tree().get_first_node_in_group("world")
	if _world == null:
		return

	if multiplayer.is_server() and pickup_id != 0:
		_world.rpc("cli_pickup_state", pickup_id, global_position, _vel)
