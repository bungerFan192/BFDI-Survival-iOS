extends CharacterBase

var fingering := false
var tag_cooldown := 0.0
var next_shot_id := 0
var fakefinger := false


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)

	if not _is_local_player():
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		fingering = true


func _physics_process(delta: float) -> void:
	if tag_cooldown > 0.0:
		tag_cooldown -= delta

	if _is_local_player() and fingering and tag_cooldown <= 0.0:
		fingering = false
		fakefinger = true

		# Align the tag ray with the local camera's look direction.
		$RayCast.global_rotation = camera.global_rotation

		get_tree().create_timer(0.5).timeout.connect(
			func(): fakefinger = false,
			CONNECT_ONE_SHOT
		)

		if $RayCast.is_colliding():
			var hit : Object = $RayCast.get_collider()
			if hit != self and hit.is_in_group("player") and hit.has_method("_recieve_damage"):
				_tag_player(hit)

	anim_suffix = " finger" if fakefinger else ""
	super._physics_process(delta)


func _tag_player(hit: Node) -> void:
	tag_cooldown = 0.20
	next_shot_id += 1
	var target_id := int(hit.get("player_owner_id"))
	if target_id < 0:
		return

	var spawner := get_parent()
	if spawner != null and spawner.has_method("send_damage"):
		spawner.send_damage(target_id, 1, next_shot_id)
