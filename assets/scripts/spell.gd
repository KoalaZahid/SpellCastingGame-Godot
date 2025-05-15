extends Node3D
class_name Spell

signal spell_used

@export var spell_container : Node3D
@export var caster : Humanoid
@export var holder : Node3D
@export var lifetime = 15.

@export_group("Spell Properties")
@onready var timer = $Timer

@export var spell_name : String
@export_enum("Fire","Water") var element : int
@export var cooldown : float = 1
@export var max_charge_time : float = 1
@export var mp_cost : float = 0
@export_group("Components")
@export var spell_shape : ShapeModifier
@export var modifiers : Array[SpellComponentClass]

@export var affect_caster : bool = true

var spell_damage = 5
var additional_charge = 0

var spell_available : bool
var charge_time : float

var spell_speed = 0
var spell_durability = 0

var spell_scene
var spell_objects : Array[Node3D] = []
var spell_obj_meta : Dictionary
func _remove_spell_from_summon(spell_object):
	var index = spell_objects.find(spell_object)
	if index != -1:
		spell_objects.remove_at(index)
		spell_obj_meta.erase(spell_object)

var enemy_group_name : String
var enemy_group_id : int

var instances = {}
var maxInstances = 100

## Modifiers
# Multi cast
var spell_amount = 1
var additional_theta = 0
var time = 0

# Homing
var homing : bool = false
var rotate_speed = deg_to_rad(90)
var rotate_speed_update = deg_to_rad(45)

# Life Steal
var health_steal : bool = false

# Bounce
var bounce_amount = 0
#var collision_timer = Timer.new()

func _ready() -> void:
	spell_scene = load(spell_shape.get_shape_scene())
	var properties = spell_shape.get_spell_properties()
	spell_speed = properties.Speed
	spell_durability = properties.Durability
	charge_time = 0.
	spell_available = true
	enemy_group_name = "Player" if caster.get_groups()[0]=="Enemy" else "Enemy"
	enemy_group_id = 3 if enemy_group_name=="Player" else 4
	_modifier_change()

func _modifier_change():
	spell_amount = 1
	homing = false
	health_steal = false
	bounce_amount = 0
	
	max_charge_time = 1
	additional_charge = 0
	for modifier in modifiers:
		additional_charge += modifier.cast_cost
		match modifier.modifier_name:
			"Multicast":
				spell_amount = modifier.amount
			"Homing":
				homing = true
			"Life Steal":
				health_steal = true
			"Bounce":
				bounce_amount = modifier.amount
	max_charge_time += additional_charge
	cooldown = 0.2 * spell_amount
	timer.wait_time = cooldown+additional_charge


func initialize():
	rotate_speed = deg_to_rad(85)
	if not spell_available: return
	if instances.size() >= maxInstances: return
	if affect_caster:
		caster.look_at_target = true
		caster.moveable = false
	for e in spell_amount:
		var spell_object = spell_scene.instantiate()
		spell_object.name = spell_name
		
		var r = randf()
		var g = randf()
		var b = randf()
		for child in spell_object.get_children():
			var color = Vector3(r,g,b).normalized()*0.7
			if child is OmniLight3D:
				child.light_color = Color(color.x,color.y,color.z)
			if child is not MeshInstance3D: continue
			var material = child.get_active_material(0)
			var newMat = material.duplicate()
			newMat.set("shader_parameter/Effect_Color", color)
			child.set_surface_override_material(0,newMat)
			
		
		holder.add_child(spell_object)
		spell_object.global_position = holder.global_position
		spell_object.global_basis = holder.global_basis
		spell_objects.append(spell_object)
		spell_obj_meta[spell_object] = {initial_theta = 2*PI/spell_objects.size()*e}


func charge(delta : float):
	if not spell_available: return
	time += delta
	additional_theta = PI/2 * time
	if spell_objects.size() == 0: return
	
	charge_time += delta
	# Make charge increment the multi cast
	
	var radius = 1 if (spell_objects.size() > 1 and spell_amount > 1) else 0
	for i in spell_objects.size():
		var spell_object = spell_objects[i]
		if not spell_object: continue
		spell_obj_meta[spell_object] = {initial_theta = 2*PI/spell_objects.size()*i}
		var obj_meta = spell_obj_meta[spell_object]
		var x_pos = radius * cos(obj_meta.initial_theta + additional_theta)
		var y_pos = radius * sin(obj_meta.initial_theta + additional_theta)
		
		spell_object.position = Vector3(x_pos,y_pos,0)
		
		if (charge_time >= max_charge_time):
			charge_time = max_charge_time
		else:
			spell_shape.charge(spell_object, min(charge_time/max_charge_time,1))


func update(delta : float):
	for object : Node3D in instances:
		var objectMeta = instances[object]
		
		# Movement
		if homing:
			if not objectMeta.target: # find target to go to
				for enemy in objectMeta.area.get_overlapping_bodies():
					objectMeta.target = enemy
					#print("NEW TARGET FOUND")
					break
			else: # we have a target
				var direction : Vector3 = objectMeta.target.global_transform.origin - object.global_transform.origin
				#print(objectMeta.target.global_transform.origin)
				#print(object.global_transform.origin)
				direction = direction.normalized()
				#print(direction)
				
				var rotate_amount = direction.cross(object.global_transform.basis.z)
				var rotY = rotate_amount.y * objectMeta.rotate_speed * delta
				objectMeta.rotate_speed += rotate_speed_update * delta
				object.rotate(Vector3.UP, rotY)
			
		object.position += object.transform.basis * Vector3(0,0,-spell_speed) * delta
		
		# Collision
		if objectMeta.ray.is_colliding() and objectMeta.ray.get_collider() != caster:
			if objectMeta.ray.get_collider() != objectMeta.previous_hit:
				#objectMeta.target = null
				objectMeta.previous_hit = objectMeta.ray.get_collider()
				objectMeta.collision_timer.stop()
				objectMeta.collision_timer.start()
				#collision_timer.timeout.connect(func(): objectMeta.previous_hit = null)
				objectMeta.collision_timer.connect("timeout", _on_collision_timer.bind(objectMeta))
				
				#objectMeta.ray.enabled = true
				spell_shape.on_impact(objectMeta.ray.get_collider(), objectMeta.ray.get_collision_point(), objectMeta.finalized, caster.get_parent())
				if objectMeta.ray.get_collider().is_in_group(enemy_group_name):
					objectMeta.ray.get_collider().take_damage(spell_damage)
					if health_steal:
						caster.take_damage(-spell_damage*0.1)
				
				# hit something (either humanoids or environment)
				objectMeta.bounces+=1
				var normal : Vector3 = objectMeta.ray.get_collision_normal()
				var reflectionX = object.transform.basis.x - 2 * object.transform.basis.x.dot(normal) * normal
				var reflectionY = object.transform.basis.y - 2 * object.transform.basis.y.dot(normal) * normal
				var reflectionZ = object.transform.basis.z - 2 * object.transform.basis.z.dot(normal) * normal
				if bounce_amount > 0: object.transform.basis = Basis(reflectionX, reflectionY, reflectionZ)
				if (objectMeta.bounces > bounce_amount):
					objectMeta.hit = true
		
		objectMeta.currentLife += delta
		if objectMeta.currentLife >= lifetime or (objectMeta.hit and spell_shape.spell_shape != 1):
			instances.erase(object)
			object.free()


func _on_collision_timer(objectMeta):
	objectMeta.previous_hit = null

func release():
	if not spell_available: return
	if spell_objects.size() == 0: return
	var charge_percentage = charge_time / max_charge_time * 100
	var spell_finalized = charge_percentage/100==1
	spell_available = false
	for e in range(spell_objects.size()):
		var spell_object = spell_objects[0]
		charge_percentage = round(charge_percentage)
		instances[spell_object] = {
			currentLife = 0., 
			finalized = spell_finalized,
			ray = spell_object.get_child(0),
			area = spell_object.get_child(1),
			target = null,
			hit = false,
			previous_hit = null,
			collision_timer = Timer.new(),
			rotate_speed = rotate_speed,
			bounces = 0,
			}
		spell_object.add_child(instances[spell_object].collision_timer)
		instances[spell_object].collision_timer.wait_time = 0.3
		instances[spell_object].collision_timer.autostart = false
		instances[spell_object].collision_timer.one_shot = true
		instances[spell_object].area.set_collision_mask_value(enemy_group_id, true)
		spell_object.reparent(spell_container)
		spell_object.global_position = holder.global_position
		spell_object.global_basis = holder.global_basis
		_remove_spell_from_summon(spell_object)
		await get_tree().create_timer(0.15).timeout
	timer.start()
	if affect_caster:
		caster.look_at_target = false
		caster.moveable = true
	spell_used.emit(cooldown)
	charge_time = 0.


func element_toString():
	match (element):
		0:
			return "Fire"
		1:
			return "Water"

func _process(delta: float) -> void:
	update(delta)


func _on_timer_timeout() -> void:
	timer.stop()
	spell_available = true
