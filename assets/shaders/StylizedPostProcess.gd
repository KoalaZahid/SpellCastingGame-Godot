@tool
extends CompositorEffect
class_name StylizedPostProcess

var shader_file = "res://assets/shaders/StylizedPostProcess.glsl"

@export_range(0, 0.99, 0.01) var shade_smoothness : float = 0
@export_range(1,24,1) var color_bands : float = 12

# constructor
func _init() -> void:
	# Stage in rendering pipeline to execute
	effect_callback_type = CompositorEffect.EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	# Create Render Thread
	RenderingServer.call_on_render_thread(initilize_compute)

# Notification Signal
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and shader.is_valid():
		rd.free_rid(shader)

var rd : RenderingDevice
var shader : RID
var pipeline : RID

# Sampler
var nearest_sampler : RID

func initilize_compute() -> void:
	rd = RenderingServer.get_rendering_device()
	if !rd: return
	
	var glsl_file : RDShaderFile = load(shader_file)
	shader = rd.shader_create_from_spirv(glsl_file.get_spirv())
	pipeline = rd.compute_pipeline_create(shader)


func _render_callback(effect_callback_type: int, render_data: RenderData) -> void:
	if not rd: return
	var render_scene_buffers : RenderSceneBuffersRD = render_data.get_render_scene_buffers()
	if not render_scene_buffers: return
	
	# Scene Buffers
	var size = render_scene_buffers.get_internal_size()
	if size.x == 0 and size.y == 0:
		return
	
	# Compute Shader Groups (defined in the compute shader glsl file)
	var x_groups = (size.x - 1) / 8 + 1
	var y_groups = (size.y - 1) / 8 + 1
	var z_groups = 1
	
	# resolution of the screen (or texture size if using a texture 2DRD)
	var push_constant : PackedFloat32Array = PackedFloat32Array()
	# Render Size
	push_constant.push_back(size.x)
	push_constant.push_back(size.y)
	# Reserved
	push_constant.push_back(0.0)
	push_constant.push_back(0.0)
	
	var view_count = render_scene_buffers.get_view_count()
	for view in range(view_count):
		# get the texture buffer from the rendering pipeline
		var input_image : RID = render_scene_buffers.get_color_layer(view)
		
		# Screen Uniform
		var screen_uniform : RDUniform = RDUniform.new()
		screen_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		screen_uniform.binding = 0
		screen_uniform.add_id(input_image)
		
		# Parameters for the shader
		var param : PackedFloat32Array = PackedFloat32Array()
		param.push_back(shade_smoothness)
		param.push_back(color_bands)
		var param_buffer : RID = rd.storage_buffer_create(param.size()*4, param.to_byte_array())
		var param_uniform : RDUniform = RDUniform.new()
		param_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		param_uniform.binding = 1
		param_uniform.add_id(param_buffer)
		
		# Send all uniforms, write all uniforms in the array
		var uniform_array = [screen_uniform, param_uniform]
		var uniform_set := rd.uniform_set_create(uniform_array, shader, 0)
		
		# compute
		var compute_list := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
		rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
		# push constant is x4 becuase floats are represented with 4 bytes (32 bits)
		rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
		rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
		rd.compute_list_end()
		
		rd.free_rid(uniform_set)
