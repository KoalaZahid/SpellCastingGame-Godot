extends ProgressBar

@onready var enemy = $"../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_on_enemy_health_changed(enemy.HEALTH, enemy.HEALTH, enemy.MAX_HEALTH)


func _on_enemy_health_changed(_old_health: Variant, new_health: Variant, max_health: Variant) -> void:
	var health_scale = new_health / max_health
	#var new_bar_size = Vector2(bar_max_size.x * health_scale, bar_max_size.y)
	var tween = create_tween()
	tween.tween_property(self, "value", health_scale*100, 0.2)
