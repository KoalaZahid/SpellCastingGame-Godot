extends Humanoid
class_name Player

@onready var pivot = $Pivot

@export var anchored : bool = false

var viewport : Viewport
var camera : Camera3D

func _ready() -> void:
	viewport = get_viewport()
	camera = viewport.get_camera_3d()


var last_direction = Vector3(0,0,0)
# Physics Update Function
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor() and not anchored:
		velocity += get_gravity() * delta
		
	if anchored: return
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("player_left", "player_right", "player_forward", "player_backward")
	
	var direction := (Vector3(-input_dir.x-input_dir.y, 0, input_dir.x-input_dir.y)).normalized()
	
	if direction and not look_at_target:
			look_direction = direction
	
	move_in_direction(direction)
		
	look_in_direction(look_direction,delta)
	move_and_slide()


func _process(delta: float):
	if not look_at_target: return
	if target == null:
		var mouse_pos = _get_mouse_pos3d()
		var local_look_direction = (mouse_pos - position).normalized()
		look_direction = local_look_direction
	else:
		look_towards_target(delta)


func _get_mouse_pos3d() -> Vector3:
	var mouse_pos = viewport.get_mouse_position()
	var origin = camera.project_ray_origin(mouse_pos)
	var direction = camera.project_ray_normal(mouse_pos)
	var end = origin + direction * camera.far
	
	var plane = Plane(Vector3(0,1,0), position.y)
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	var result = plane.intersects_ray(origin,direction*camera.far)
	return result
