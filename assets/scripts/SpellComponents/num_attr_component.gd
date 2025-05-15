extends SpellComponentClass

@export var MAX_AMOUNT = 8
@export var MIN_AMOUNT = 1
@export var amount : int = 2
@export var individual_amt : float

func _ready():
	update()
	
func update():
	amount = clamp(amount, MIN_AMOUNT, MAX_AMOUNT)
	cast_cost = individual_amt * amount
