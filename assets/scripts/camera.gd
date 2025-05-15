extends Node3D
class_name OrthoCamera

@export var camera_sensitivity : float = 1.
@export var target : Node3D
@onready var cam_3d = $Camera3D
var camera_anchor_pos = Vector2(0,0)

var cam_zoom_range = Vector2(6,15)
var target_zoom = 15

#var cam_offset = Vector3(0,0,0)
var cam_offset = Vector2(0,0)

## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var screen_size = get_viewport().get_visible_rect().size
	var mouse_local_pos = mouse_pos/screen_size
	camera_anchor_pos = (mouse_local_pos * 2 - Vector2(1,1))
	camera_anchor_pos *= camera_sensitivity
	position = target.global_position
	var x_diff = camera_anchor_pos.x * sqrt(2)/2
	var y_diff = camera_anchor_pos.y * sqrt(2)/2
	
	## TODO: Fix camera offset to use built in hv offsets
	## TODO: Fix View Range to prevent player from seeing clipped geometry
	#var target_offset = Vector3(
		#-(x_diff + y_diff),
		#0,
		#-(y_diff - x_diff)
	#)
	var target_offset = Vector2(
		#(y_diff - x_diff),
		#(x_diff + y_diff)
		x_diff,
		-y_diff
	)
	
	var lerp_alpha = min(10 * _delta,1)
	
	cam_offset = lerp(cam_offset, target_offset, lerp_alpha)
	#position += cam_offset
	cam_3d.h_offset = cam_offset.x
	cam_3d.v_offset = cam_offset.y
	
	cam_3d.size = lerpf(cam_3d.size, target_zoom, lerp_alpha)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = max(target_zoom-1,cam_zoom_range.x)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = min(target_zoom+1,cam_zoom_range.y)
			
