extends Node

const MAX_LEVEL_ID: int = 3

var unlocked_level_ids: Array[int] = [1]
var completed_level_ids: Array[int] = []
var pending_unlock_animation_ids: Array[int] = []

var last_starting_sequences_by_level: Dictionary = {}


func is_level_unlocked(level_id: int) -> bool:
	return unlocked_level_ids.has(level_id)


func is_level_completed(level_id: int) -> bool:
	return completed_level_ids.has(level_id)


func complete_level(level_id: int) -> void:
	if not completed_level_ids.has(level_id):
		completed_level_ids.append(level_id)
	
	var next_level_id := level_id + 1
	
	if next_level_id <= MAX_LEVEL_ID:
		_unlock_level(next_level_id)


func consume_pending_unlock_animations() -> Array[int]:
	var result := pending_unlock_animation_ids.duplicate()
	pending_unlock_animation_ids.clear()
	return result


func get_last_starting_sequence(level_id: int) -> Array[int]:
	if not last_starting_sequences_by_level.has(level_id):
		return []
	
	return last_starting_sequences_by_level[level_id].duplicate()


func set_last_starting_sequence(level_id: int, new_sequence: Array[int]) -> void:
	last_starting_sequences_by_level[level_id] = new_sequence.duplicate()


func reset_progress_for_testing() -> void:
	unlocked_level_ids = [1]
	completed_level_ids.clear()
	pending_unlock_animation_ids.clear()
	last_starting_sequences_by_level.clear()


func _unlock_level(level_id: int) -> void:
	if level_id <= 0:
		return
	
	if level_id > MAX_LEVEL_ID:
		return
	
	if unlocked_level_ids.has(level_id):
		return
	
	unlocked_level_ids.append(level_id)
	pending_unlock_animation_ids.append(level_id)
	
	print("Level unlocked: ", level_id)
