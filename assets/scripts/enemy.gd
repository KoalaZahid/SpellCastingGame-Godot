extends Humanoid
class_name Enemy

@onready var health_bar = $SubViewport/HealthBar
@export var active : bool = true
@export var player : Player

@export var spells : Array[Spell]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	target = player
	pass

var time:float = 0.
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not active: return
	time+=delta
	var x_look = cos(time) * 10
	var z_look = sin(time) * 10
	look_in_direction(Vector3(x_look,0,z_look),delta)

func _input(event: InputEvent) -> void:
	if not active: return
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_K:
			var spell = spells[0]
			spell.initialize()
			spell.charge(1/60)
			spell.release()

func _on_died() -> void:
	print("DIED")
