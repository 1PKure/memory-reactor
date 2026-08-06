extends Node

var current_level_data: LevelData


func set_level(level_data: LevelData) -> void:
	current_level_data = level_data


func has_level() -> bool:
	return current_level_data != null


func clear_level() -> void:
	current_level_data = null
