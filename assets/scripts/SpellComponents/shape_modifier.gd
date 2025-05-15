extends SpellComponentClass
class_name ShapeModifier


enum Shapes{Ball=0, Arrow=1, Shield=2, Crescent=3}
var Ball_Scene = "res://assets/instances/SpellComponents/Shapes/Ball.tscn"
var Arrow_Scene = "res://assets/instances/SpellComponents/Shapes/Ball.tscn"
var Block_Scene = "res://assets/instances/SpellComponents/Shapes/Ball.tscn"
var Crescnet_Scene = "res://assets/instances/SpellComponents/Shapes/Ball.tscn"
var shape_instances = [Ball_Scene,Arrow_Scene,Block_Scene,Crescnet_Scene]

var explosion_scene = load("res://assets/instances/explosion.tscn")

@export var spell_shape : Shapes

func get_shape_scene() -> String:
	return shape_instances[spell_shape]

func _spell_property(speed : float, durability : float):
	return {Speed = speed, Durability = durability}

func get_spell_properties():
	if (spell_shape == Shapes.Ball): 	# Ball
		return _spell_property(6,2)
	elif (spell_shape == Shapes.Arrow):	# Arrow
		return _spell_property(8,1)
	elif (spell_shape == Shapes.Shield):	# Shield
		return _spell_property(1,8)
	else:								# Crescent
		return _spell_property(6,3)

func charge(obj, amount : float): # 0 - 1
	if (spell_shape == Shapes.Ball): 	# Ball
		if amount >= 1:
			obj.get_node("Main").mesh.radius *= 2
			obj.get_node("Main").mesh.height *= 2
	elif (spell_shape == Shapes.Arrow):	# Arrow
		pass
	elif (spell_shape == Shapes.Shield):	# Shield
		pass
	else:								# Crescent
		pass

func on_impact(hit_obj, hit_position, finalized : bool, parent_node):
	if (spell_shape == Shapes.Ball): 	# Ball
		#print("OWWWCH")
		#print(hit_obj)
		#print(hit_position)
		var explosion = explosion_scene.instantiate()
		explosion.global_position = hit_position
		explosion.radius = 10
		parent_node.add_child(explosion)
		explosion.explode("Player")
		if finalized:
			print("Big boi explosion")
			pass
		else:
			print('Little baby man explosion')
			pass
	elif (spell_shape == Shapes.Arrow):	# Arrow
		pass
	elif (spell_shape == Shapes.Shield):	# Shield
		pass
	else:								# Crescent
		pass
