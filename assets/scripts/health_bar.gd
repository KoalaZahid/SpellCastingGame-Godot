extends ProgressBar

@onready var player = $"../../Player"
@onready var health_label = $Label

var health_format = "%d / %d"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#set_value_no_signal(true)
	_update_info(player.HEALTH, player.MAX_HEALTH)


func _on_player_health_changed(old_health: Variant, new_health: Variant, max_health: Variant) -> void:
	_update_info(new_health, max_health)

func _update_info(new_health, max_health):
	health_label.text = health_format % [new_health, max_health]
	var health_scale = new_health / max_health
	#var new_bar_size = Vector2(bar_max_size.x * health_scale, bar_max_size.y)
	var tween = create_tween()
	tween.tween_property(self, "value", health_scale*100, 0.2)
