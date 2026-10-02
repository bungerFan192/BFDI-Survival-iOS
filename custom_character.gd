extends CharacterBase

var profile: Dictionary = {}
var fingering := false
var tag_cooldown := 0.0
var next_shot_id := 0

# Number of jumps the player has actually performed since touching the floor.
var jumps_used := 0

# Base = exactly ONE jump.
var max_jumps := 1

# Base damage is 50. Each damage point adds another 50.
var custom_damage := 50.0

var custom_speed := WALK_SPEED
var custom_max_hp := 300.0
var custom_range := 10.0


func _ready() -> void:
	# Let CharacterBase initialize the camera, nametag, etc. first.
	super._ready()

	# The character can be spawned before GD-Sync's player data has arrived.
	# Give it a few frames to receive the profile.
	await _wait_for_profile()

	_apply_profile()
	_apply_asset()

	if _is_local_player():
		hp = custom_max_hp

		if hpbar:
			hpbar.max_value = custom_max_hp
			hpbar.value = hp


func _wait_for_profile() -> void:
	if not GDSync.is_active():
		profile = {}
		return

	for i in range(30):
		var data = GDSync.player_get_data(
			player_owner_id,
			"character_profile",
			null
		)

		if data is Dictionary and not data.is_empty():
			profile = data
			return

		await get_tree().process_frame

	# No profile arrived. Use defaults.
	profile = {}


func _apply_profile() -> void:
	var stats: Dictionary = profile.get("stats", {})

	if not stats is Dictionary:
		stats = {}

	# 50 base damage + 50 for every damage point.
	custom_damage = 50.0 + float(int(stats.get("damage", 0))) * 50.0

	# EXACTLY one jump by default.
	# Each point gives one additional jump.
	max_jumps = 1 + int(stats.get("jumps", 0))

	custom_speed = WALK_SPEED + float(int(stats.get("speed", 0))) * 0.5
	custom_max_hp = 300.0 + float(int(stats.get("health", 0))) * 25.0
	custom_range = 100.0 + float(int(stats.get("range", 0))) * 10.0

	damage = custom_damage


func _apply_asset() -> void:
	var encoded := str(profile.get("asset_png", ""))

	if encoded.is_empty():
		return

	var bytes := Marshalls.base64_to_raw(encoded)

	if bytes.is_empty():
		push_warning("Custom character PNG data was empty.")
		return

	var image := Image.new()

	if image.load_png_from_buffer(bytes) != OK:
		push_warning("Could not decode custom character PNG.")
		return

	var texture := ImageTexture.create_from_image(image)

	# ONLY replace the main Asset Sprite3D.
	# Arms, legs, eyes and mouth remain untouched.
	var asset := get_node_or_null("Asset") as Sprite3D

	if asset == null:
		push_warning("CustomCharacter is missing its Asset Sprite3D.")
		return

	asset.texture = texture

	# Preserve the original Asset scale.
	# The imported image itself does NOT replace any limbs.
	asset.scale = Vector3.ONE


func set_character_profile(new_profile: Dictionary) -> void:
	if not new_profile is Dictionary:
		return

	profile = new_profile

	_apply_profile()
	_apply_asset()

	if _is_local_player():
		hp = custom_max_hp

		if hpbar:
			hpbar.max_value = custom_max_hp
			hpbar.value = hp


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)

	if not _is_local_player():
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			fingering = true


func _physics_process(delta: float) -> void:
	if tag_cooldown > 0.0:
		tag_cooldown -= delta

	if not _is_local_player():
		super._physics_process(delta)
		return

	if is_on_floor():
		# Touching the floor resets the jump counter.
		jumps_used = 0

	if fingering and tag_cooldown <= 0.0:
		fingering = false

		$RayCast.global_rotation = camera.global_rotation
		$RayCast.target_position = Vector3(0, 0, -custom_range)

		if $RayCast.is_colliding():
			var hit: Object = $RayCast.get_collider()

			if hit != self and hit.is_in_group("player") and hit.has_method("_recieve_damage"):
				_tag_player(hit)

	_custom_physics(delta)


func _custom_physics(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump system:
	#
	# max_jumps = 1 by default
	#
	# 0 points:
	#   ground jump only
	#
	# 1 point:
	#   ground + 1 air jump
	#
	# 2 points:
	#   ground + 2 air jumps
	#
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			jumps_used = 1
		elif jumps_used < max_jumps:
			velocity.y = JUMP_VELOCITY
			jumps_used += 1

	var current_speed := custom_speed

	if Input.is_action_pressed("sprint"):
		current_speed *= 1.75

	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var direction := (
		transform.basis *
		Vector3(input_dir.x, 0, input_dir.y)
	).normalized()

	if is_on_floor():
		if direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(
				velocity.x,
				0,
				current_speed * 0.2
			)

			velocity.z = move_toward(
				velocity.z,
				0,
				current_speed * 0.2
			)
	else:
		if direction:
			velocity.x = move_toward(
				velocity.x,
				direction.x * current_speed,
				delta * 15.0
			)

			velocity.z = move_toward(
				velocity.z,
				direction.z * current_speed,
				delta * 15.0
			)

	if $AnimationPlayer:
		var anim := "walk" if direction else "idle"
		$AnimationPlayer.play("AnimationEpic/" + anim)

	t_bob += delta * velocity.length() * float(is_on_floor())

	var camera_target_pos := Vector3.ZERO

	if is_on_floor() and direction:
		camera_target_pos.y = sin(t_bob * BOB_FREQ) * BOB_AMP
		camera_target_pos.x = cos(t_bob * BOB_FREQ / 2) * BOB_AMP

	camera.transform.origin = camera.transform.origin.lerp(
		camera_target_pos,
		delta * 10.0
	)

	move_and_slide()

	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()

		if collider is RigidBody3D:
			var push_dir := -collision.get_normal()

			collider.apply_impulse(
				push_dir * 20.0 * delta,
				collision.get_position() - collider.global_position
			)


func _tag_player(hit: Node) -> void:
	tag_cooldown = 0.20
	next_shot_id += 1

	var target_id := int(hit.get("player_owner_id"))

	if target_id < 0:
		return

	var spawner := get_parent()

	if spawner != null and spawner.has_method("send_damage"):
		spawner.send_damage(
			target_id,
			maxi(1, int(round(custom_damage))),
			next_shot_id
		)


func _recieve_damage(dmg: int = 100, shot_id: int = -1) -> void:
	hp -= dmg

	if hp <= 0.0:
		hp = custom_max_hp
		position = Vector3.ZERO

	if hpbar:
		hpbar.max_value = custom_max_hp
		hpbar.value = hp
