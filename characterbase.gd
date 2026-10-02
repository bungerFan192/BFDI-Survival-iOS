extends CharacterBody3D
class_name CharacterBase

const WALK_SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003

const BOB_FREQ = 2.0
const BOB_AMP = 0.08

var damage : float = 100

var t_bob := 0.0
var hp : float = 300
var local_player_initialized := false
var last_damage_shot_by_sender: Dictionary = {}

@export var player_owner_id: int = -1
var spongy := false

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera
@onready var hpbar: ProgressBar = $CanvasLayer2/HP
var nametag: Label3D

var anim_suffix
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	_setup_nametag()
	local_player_initialized = _is_local_player()

	if not get_window().focus_entered.is_connected(_recapture_mouse):
		get_window().focus_entered.connect(_recapture_mouse)

	if local_player_initialized:
		camera.current = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		# Remote players must never steal the local camera or process local UI.
		camera.current = false
		$CanvasLayer.visible = false
		$CanvasLayer2.visible = false


func _setup_nametag() -> void:
	nametag = Label3D.new()
	nametag.name = "NameTag"
	nametag.position = Vector3(0, 2, 0)
	nametag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nametag.no_depth_test = true
	nametag.font_size = 60
	nametag.outline_size = 10
	nametag.modulate = Color.WHITE
	nametag.text = ""
	add_child(nametag)


func set_player_name(value: String) -> void:
	if nametag == null:
		_setup_nametag()
	nametag.text = value


func _is_local_player() -> bool:
	return GDSync.is_active() and player_owner_id == GDSync.get_client_id()


func _recapture_mouse() -> void:
	if _is_local_player():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_local_player():
		return

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	camera.top_level = false
	camera.current = true

	if DisplayServer.is_touchscreen_available():
		$CanvasLayer.show()
	$CanvasLayer2.show()

	# Desktop: keep the existing captured-mouse camera controls.
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * SENSITIVITY)
		head.rotate_x(-event.relative.y * SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	if event is InputEventMouseButton and event.pressed:
		_recapture_mouse()

	# Mobile: drag on the right half of the screen to look around.
	# Movement controls are intentionally unchanged.
	if event is InputEventScreenDrag:
		var viewport_width := get_viewport().get_visible_rect().size.x
		if event.position.x >= viewport_width * 0.5:
			rotate_y(-event.relative.x * SENSITIVITY)
			head.rotate_x(-event.relative.y * SENSITIVITY)
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))


func _physics_process(delta: float) -> void:
	# Only the client that owns this alias simulates movement. Remote players
	# are updated by GD-Sync PropertySynchronizers.
	if not _is_local_player():
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if Input.is_action_just_pressed("jump") and not is_on_floor() and spongy:
		velocity.y = JUMP_VELOCITY

	var current_speed := WALK_SPEED
	$AnimationPlayer.speed_scale = 1.5
	if Input.is_action_pressed("sprint"):
		current_speed = WALK_SPEED * 1.75
		$AnimationPlayer.speed_scale = 3

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if is_on_floor():
		if direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed * 0.2)
			velocity.z = move_toward(velocity.z, 0, current_speed * 0.2)
	else:
		if direction:
			velocity.x = move_toward(velocity.x, direction.x * current_speed, delta * 15.0)
			velocity.z = move_toward(velocity.z, direction.z * current_speed, delta * 15.0)

	var anim := "idle"
	if direction:
		anim = "walk"
	if anim_suffix:
		anim += anim_suffix

	$AnimationPlayer.play("AnimationEpic/" + anim)

	t_bob += delta * velocity.length() * float(is_on_floor())
	var camera_target_pos := Vector3.ZERO
	if is_on_floor() and direction:
		camera_target_pos.y = sin(t_bob * BOB_FREQ) * BOB_AMP
		camera_target_pos.x = cos(t_bob * BOB_FREQ / 2) * BOB_AMP

	camera.transform.origin = camera.transform.origin.lerp(camera_target_pos, delta * 10.0)

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


# Called remotely on the computer that owns this player node instance.
func _recieve_damage(dmg: int = 100, shot_id: int = -1) -> void:
	# Ignore duplicate/replayed damage packets. A shot can only affect this
	# player once, even if the same damage event is delivered more than once.
	# shot_id is scoped to the attacker, so two different players can both
	# legitimately send shot 1. player_spawner passes the attacker ID through
	# the damage packet and uses it to reject duplicates/out-of-order packets.

	hp -= dmg
	if hp <= 0:
		hp = 300
		position = Vector3.ZERO

	if hpbar:
		hpbar.value = hp
