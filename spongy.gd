extends CharacterBase

var fingering := false
var tag_cooldown := 0.0
var next_shot_id := 0

func _ready() -> void:
	super._ready()
	damage = 200

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)

	if not _is_local_player():
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		fingering = true


func _physics_process(delta: float) -> void:
	if tag_cooldown > 0.0:
		tag_cooldown -= delta

	if not _is_local_player():
		return

	if fingering and tag_cooldown <= 0.0:
		fingering = false

		# Align the tag ray with the local camera's look direction.
		$RayCast.global_rotation = camera.global_rotation

		if $RayCast.is_colliding():
			var hit : Object = $RayCast.get_collider()
			if hit != self and hit.is_in_group("player") and hit.has_method("_recieve_damage"):
				_tag_player(hit)

	super._physics_process(delta)


func _tag_player(hit: Node) -> void:
	tag_cooldown = 0.20
	next_shot_id += 1
	var target_id := int(hit.get("player_owner_id"))
	if target_id < 0:
		return

	var spawner := get_parent()
	if spawner != null and spawner.has_method("send_damage"):
		spawner.send_damage(target_id, damage, next_shot_id)
