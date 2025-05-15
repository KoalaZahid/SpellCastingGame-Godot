extends Label

func _ready() -> void:
	visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			print("PRESSED")
			get_tree().paused = not get_tree().paused
			visible = get_tree().paused
