extends CharacterBody3D
class_name Humanoid

signal health_changed(old_health, new_health, max_health)
signal died

@export_group("Humanoid Properties")
@export var HEALTH = 100.0
@export var MAX_HEALTH = 100.0

@export var MOVE_SPEED = 5.0
@export var ROTATE_SPEED = 5

@export_group("Looking Properties")
@export var look_direction : Vector3
@export var look_at_target : bool
@export var target : Node3D

@export var moveable : bool = true
@export var invincible : bool = false

func take_damage(damage : float):
	if invincible: return
	HEALTH -= damage
	health_changed.emit(HEALTH, HEALTH, MAX_HEALTH)
	if HEALTH <= 0:
		died.emit()


func move_in_direction(direction : Vector3):
	if direction and moveable:
		velocity.x = direction.x * MOVE_SPEED
		velocity.z = direction.z * MOVE_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, MOVE_SPEED)
		velocity.z = move_toward(velocity.z, 0, MOVE_SPEED)


func look_towards_target(delta : float):
	if (not target == null and look_at_target):
		var target_position = target.global_position
		var direction = (target_position - global_position).normalized()
		look_in_direction(direction, delta)


func look_in_direction(direction :Vector3, delta : float) -> void:
	look_direction = direction
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * ROTATE_SPEED)
