
extends CharacterBody2D
class_name YoylitePearl

signal landed(world_pos: Vector2, pearl_id: int)

@export var owner_pid: int = 0
@export var pearl_id: int = 0
@export var initial_velocity: Vector2
@export var max_lifetime: float = 10
@export var visual_only: bool = false

var _age: = 0.0


var _g = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void :
	velocity = initial_velocity

func _physics_process(delta: float) -> void :
	_age += delta
	velocity.y += _g * delta
	var col: = move_and_collide(velocity * delta)
	if col:

		global_position = col.get_position()
		if visual_only:
			queue_free()
		else:
			emit_signal("landed", global_position, pearl_id)
			queue_free()
		return

	if _age >= max_lifetime:

		if visual_only:
			queue_free()
		else:
			emit_signal("landed", global_position, pearl_id)
			queue_free()


func end_at(pos: Vector2) -> void :
	global_position = pos
	queue_free()
