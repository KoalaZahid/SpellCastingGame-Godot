extends Button

@onready var sound = $AudioStreamPlayer

func _on_pressed() -> void:
	sound.play()
	
