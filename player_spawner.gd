extends Node3D

## GD-Sync player spawning, ownership and damage replication.
##
## Every client creates the same player node paths using the GD-Sync client ID.
## Player movement/look state is synchronized by PropertySynchronizer nodes
## embedded in the player scenes.

@export var teardrop_scene: PackedScene
@export var spongy_scene: PackedScene
@export var firey_scene: PackedScene
@export var custom_character_scene: PackedScene

const SPAWN_POSITIONS := [
	Vector3(0, 1, 0),
	Vector3(6, 1, 0),
	Vector3(-6, 1, 0),
	Vector3(0, 1, 6),
	Vector3(0, 1, -6),
	Vector3(6, 1, 6),
	Vector3(-6, 1, -6),
]

var players: Dictionary = {}


func _ready() -> void:
	GDSync.expose_func(_receive_damage_remote)
	if not GDSync.client_joined.is_connected(_on_client_joined):
		GDSync.client_joined.connect(_on_client_joined)
	if not GDSync.client_left.is_connected(_on_client_left):
		GDSync.client_left.connect(_on_client_left)

	# Spawn everyone already inside the lobby. This replaces GD-Sync's member
	# snapshot and also handles the case where this scene loads after joining.
	call_deferred("_spawn_existing_clients")


func _spawn_existing_clients() -> void:
	if not GDSync.is_active():
		return

	for client_id in GDSync.lobby_get_all_clients():
		_spawn_player(int(client_id))


func _on_client_joined(client_id: int) -> void:
	# All clients receive this signal. The joining client is spawned on every
	# machine, including clients that were already in the lobby.
	_spawn_player(client_id)


func _on_client_left(client_id: int) -> void:
	var player : Variant = players.get(client_id)
	if is_instance_valid(player):
		player.queue_free()

	players.erase(client_id)
	print("GD-SYNC PLAYER LEFT | id=", client_id)


func _spawn_player(client_id: int) -> void:
	if client_id < 0 or players.has(client_id):
		return

	var character := str(GDSync.player_get_data(client_id, "character", "teardrop"))
	var scene := _scene_for_character(character)

	if scene == null:
		push_error("No player scene is assigned for character: " + character)
		return

	var player := scene.instantiate()
	player.name = str(client_id)
	player.player_owner_id = client_id

	add_child(player)
	player.global_position = _spawn_position_for(client_id)

	GDSync.set_gdsync_owner(player, client_id)

	players[client_id] = player

	# Set the nametag after the player has entered the tree.
	if player.has_method("set_player_name"):
		var username := GDSync.player_get_username(client_id, "Player " + str(client_id))
		player.set_player_name(username)

	print("GD-SYNC SPAWNED PLAYER | id=", client_id, " | character=", character)


func _scene_for_character(character: String) -> PackedScene:
	match character.to_lower():
		"custom":
			return custom_character_scene if custom_character_scene != null else teardrop_scene
		"spongy":
			return spongy_scene if spongy_scene != null else teardrop_scene
		"firey":
			return firey_scene if firey_scene != null else teardrop_scene
		_:
			return teardrop_scene


func _spawn_position_for(id: int) -> Vector3:
	return SPAWN_POSITIONS[absi(id) % SPAWN_POSITIONS.size()]


# Kept as the public entry point used by the existing character scripts.
# The target client's own machine applies HP changes.
func send_damage(target_id: int, damage: int = 1, shot_id: int = -1) -> void:
	if target_id < 0 or not GDSync.is_active():
		return

	var sender_id := GDSync.get_client_id()
	if sender_id == target_id:
		return

	GDSync.call_func_on(target_id, _receive_damage_remote, sender_id, target_id, damage, shot_id)


func _receive_damage_remote(sender_id: int, target_id: int, damage: int, shot_id: int) -> void:
	if target_id != GDSync.get_client_id():
		return

	var target : Variant = players.get(target_id)
	if not is_instance_valid(target) or not target.has_method("_recieve_damage"):
		return

	var previous_shot := int(target.get_meta("last_damage_shot_%s" % sender_id, -1))
	if shot_id >= 0 and shot_id <= previous_shot:
		return

	if shot_id >= 0:
		target.set_meta("last_damage_shot_%s" % sender_id, shot_id)

	target._recieve_damage(maxi(1, damage), shot_id)


func _exit_tree() -> void:
	if GDSync.client_joined.is_connected(_on_client_joined):
		GDSync.client_joined.disconnect(_on_client_joined)
	if GDSync.client_left.is_connected(_on_client_left):
		GDSync.client_left.disconnect(_on_client_left)
