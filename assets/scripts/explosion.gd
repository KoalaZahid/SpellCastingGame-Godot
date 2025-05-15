extends Node3D
class_name Explosion

@onready var area = $Area3D
@onready var collision_shape = $Area3D/CollisionShape3D
@onready var particles = $OnImpact

@export var radius : float = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision_shape.shape.radius = radius
	area.global_position = global_position

# is_in_group(group_name : String)
func explode(ignore_group : String):
	#print("Radius: ",collision_shape.shape.radius)
	#position = pos
	for body in area.get_overlapping_bodies():
		print(body)
	particles.emitting = true
	await get_tree().create_timer(particles.lifetime+0.1).timeout
	queue_free()

#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
