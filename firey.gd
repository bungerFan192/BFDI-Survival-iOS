extends CharacterBase

var current_burning = null
var tag_cooldown = 0.0
var next_shot_id = 0


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)

	if not _is_local_player():
		return

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if current_burning != null: _tag_player(current_burning)

func _tag_player(hit: Node) -> void:
	tag_cooldown = 0.20
	next_shot_id += 1
	var target_id = int(hit.get("player_owner_id"))
	if target_id < 0:
		return

	var spawner = get_parent()
	if spawner != null and spawner.has_method("send_damage"):
		spawner.send_damage(target_id, damage, next_shot_id)

func _on_burning_area_body_entered(body: Node3D) -> void:
	damage = 0.2
	if not body.name.to_lower().contains("firey"): current_burning = body

func _on_burning_area_body_exited(_body: Node3D) -> void:
	current_burning = null
