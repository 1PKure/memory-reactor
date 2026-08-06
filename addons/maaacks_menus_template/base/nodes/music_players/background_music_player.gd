extends AudioStreamPlayer

@export var target_volume_db: float = -15.0
@export var fade_duration: float = 1.5

func _ready() -> void:
	volume_db = -80.0
	play()

	var tween := create_tween()
	tween.tween_property(self, "volume_db", target_volume_db, fade_duration)
