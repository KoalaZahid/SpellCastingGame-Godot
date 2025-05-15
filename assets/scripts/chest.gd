extends StaticBody3D
class_name Chest

@onready var interaction_area = $InteractionArea
@onready var player = $"../Player"
var opened = false

# modifiers
var bounce_modifier_scene = preload("res://assets/instances/SpellComponents/Bounce_Modifier.tscn")
var homing_modifier_scene = preload("res://assets/instances/SpellComponents/Homing_Modifier.tscn")
var lifesteal_modifier_scene = preload("res://assets/instances/SpellComponents/LifeSteal_Modifier.tscn")
var multicast_modifier_scene = preload("res://assets/instances/SpellComponents/MultiCast_Modifier.tscn")
var modifiers = [bounce_modifier_scene, homing_modifier_scene, lifesteal_modifier_scene, multicast_modifier_scene]

@export var items: Array[SpellComponentClass] = []
@export var loot_amount : int = 3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction_area.interact = Callable(self, "_on_interact")
	setup()


## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

func get_biased_random(min: int, max: int):
	#return floor(abs(randf() - randf()) * (1 + max - min) + min)
	return floor((max - min) * (1 - sqrt(1 - randf()))**2.6)

func setup():
	for _i in loot_amount:
		var item = modifiers[randi_range(0,modifiers.size()-1)].instantiate()
		add_child(item)
		if "amount" in item:
			item.amount = get_biased_random(item.MIN_AMOUNT, item.MAX_AMOUNT)
			item.update()
		items.append(item)

func _on_interact():
	if opened: return
	opened = true
	print('CHEST OPENED!!!')
	for item in items:
		item.reparent(player.get_node("Inventory"))
	#print(test_variable)
	
