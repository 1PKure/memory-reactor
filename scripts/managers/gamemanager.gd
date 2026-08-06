extends Node3D

enum GameState {
	LOADING,
	SHOWING_SEQUENCE,
	PLAYER_INPUT,
	ROUND_SUCCESS,
	ROUND_FAIL,
	PROTOCOL_CHOICE,
	VICTORY,
	DEFEAT
}

@export var fallback_level_scene: PackedScene
@export_file("*.tscn") var level_selector_scene_path: String = "res://scenes/levels/level_selector.tscn"
@export_category("Overclock Protocol")
@export var overclock_required_perfect_rounds: int = 2
@export var stabilize_recovery_amount: int = 25
@export var overclock_score_bonus: int = 500
@export var overclock_extra_sequence_steps: int = 1
@export_range(0.4, 1.0, 0.05) var overclock_next_round_speed_multiplier: float = 0.75

@onready var level_container: Node3D = $LevelContainer
@onready var hud: GameHUD = $CanvasLayer/HUD
@onready var audio_manager: Node = get_node_or_null("/root/AudioManager")

var current_level: Node
var level_controller: MemoryLevelController

var game_state: GameState = GameState.LOADING

var available_button_ids: Array[int] = []
var sequence: Array[int] = []
var player_index: int = 0
var _reactor_visual_state: StringName = &""
var current_round: int = 1
var stability: int = 100
var score: int = 0
var button_count: int = 0

var current_round_had_error: bool = false
var perfect_round_streak: int = 0
var overclock_next_round_active: bool = false
var overclock_round_active: bool = false

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	
	hud.retry_pressed.connect(_on_retry_pressed)
	hud.level_selector_pressed.connect(_on_level_selector_pressed)
	
	_load_selected_level()


func _load_selected_level() -> void:
	if SelectedLevel.has_level():
		var level_data := SelectedLevel.current_level_data
		
		if level_data.scene_path.is_empty():
			push_error("The selected level has an empty scene path.")
			_load_fallback_level()
			return
		
		var packed_scene := load(level_data.scene_path) as PackedScene
		
		if packed_scene == null:
			push_error("Could not load level scene: %s" % level_data.scene_path)
			_load_fallback_level()
			return
		
		_instantiate_level(packed_scene)
		return
	
	_load_fallback_level()


func _load_fallback_level() -> void:
	if fallback_level_scene != null:
		push_warning("Loading fallback level scene.")
		_instantiate_level(fallback_level_scene)
		return
	
	push_error("No selected level found and no fallback level scene assigned.")


func _instantiate_level(level_scene: PackedScene) -> void:
	_clear_current_level()
	
	current_level = level_scene.instantiate()
	level_container.add_child(current_level)
	
	print("Loaded level: ", current_level.name)
	
	call_deferred("_setup_current_level")


func _setup_current_level() -> void:
	if not current_level is MemoryLevelController:
		push_error("Loaded level does not have MemoryLevelController.gd on its root node.")
		return
	
	level_controller = current_level as MemoryLevelController
	
	if not level_controller.reactor_button_pressed.is_connected(_on_reactor_button_pressed):
		level_controller.reactor_button_pressed.connect(_on_reactor_button_pressed)
	
	button_count = level_controller.get_button_count()
	available_button_ids = level_controller.get_valid_button_ids()
	
	if button_count <= 0:
		push_error("Current level has no reactor buttons.")
		return
	
	if available_button_ids.is_empty():
		push_error("Current level has no valid button IDs.")
		return
	
	print("Available button IDs for sequence: ", available_button_ids)
	
	_start_game()


func _start_game() -> void:
	game_state = GameState.LOADING
	
	player_index = 0
	current_round = 1
	stability = level_controller.max_stability
	score = 0
	
	current_round_had_error = false
	perfect_round_streak = 0
	overclock_next_round_active = false
	
	_generate_starting_sequence()
	
	hud.hide_end_panel()
	hud.hide_protocol_panel()
	_update_hud()
	hud.show_message(level_controller.level_title)
	
	await get_tree().create_timer(0.8).timeout
	
	_start_round()


func _generate_starting_sequence() -> void:
	var current_level_id := _get_current_level_id()
	var last_sequence := LevelProgress.get_last_starting_sequence(current_level_id)
	
	var max_attempts := 10
	var attempts := 0
	
	while attempts < max_attempts:
		sequence.clear()
		
		for i in range(level_controller.starting_sequence_length):
			_add_random_sequence_step()
		
		if sequence != last_sequence:
			break
		
		attempts += 1
	
	LevelProgress.set_last_starting_sequence(current_level_id, sequence)
	print("Starting sequence generated: ", sequence)


func _start_round() -> void:
	if game_state == GameState.VICTORY or game_state == GameState.DEFEAT:
		return
	
	player_index = 0
	level_controller.set_buttons_enabled(false)
	
	_update_hud()
	await _show_sequence()


func _show_sequence() -> void:
	game_state = GameState.SHOWING_SEQUENCE
	
	hud.show_message("Memorize the sequence")
	
	await get_tree().create_timer(level_controller.round_start_delay).timeout
	
	print("Showing sequence: ", sequence)
	
	var step_delay := level_controller.sequence_step_delay
	var gap_delay := level_controller.sequence_gap_delay
	
	if overclock_next_round_active:
		step_delay *= overclock_next_round_speed_multiplier
		gap_delay *= overclock_next_round_speed_multiplier
	
	for button_id in sequence:
		if not level_controller.has_button_id(button_id):
			push_error("Sequence contains invalid button ID: %s" % button_id)
			continue
		
		level_controller.play_button_feedback(button_id)
		await get_tree().create_timer(step_delay).timeout
		await get_tree().create_timer(gap_delay).timeout
	
	overclock_next_round_active = false
	
	game_state = GameState.PLAYER_INPUT
	level_controller.set_buttons_enabled(true)
	hud.show_message("Repeat the sequence")
	print("Game State: PLAYER_INPUT")


func _on_reactor_button_pressed(button_id: int) -> void:
	if game_state != GameState.PLAYER_INPUT:
		print("Input ignored. Current state: ", game_state)
		return
	
	if sequence.is_empty():
		push_warning("Input received, but sequence is empty.")
		return
	
	if player_index < 0 or player_index >= sequence.size():
		push_error("Player index out of range. Index: %s | Sequence size: %s" % [player_index, sequence.size()])
		return
	
	var expected_button_id := sequence[player_index]
	
	print("Player input: ", button_id, " | Expected: ", expected_button_id, " | Index: ", player_index)
	
	if button_id == expected_button_id:
		_handle_correct_input()
	else:
		_handle_wrong_input()


func _handle_correct_input() -> void:
	score += 100
	player_index += 1
	
	_update_hud()
	
	if player_index >= sequence.size():
		_complete_round()


func _handle_wrong_input() -> void:
	game_state = GameState.ROUND_FAIL
	current_round_had_error = true
	
	level_controller.set_buttons_enabled(false)
	level_controller.play_error_feedback()
	_play_audio_method("play_error_sound")
	
	stability -= level_controller.error_penalty
	stability = max(stability, 0)
	_end_overclock_round()
	perfect_round_streak = 0
	
	_update_hud()
	
	if stability <= 0:
		_defeat()
		return
	
	hud.show_message("Wrong input. Reactor unstable.")
	
	await get_tree().create_timer(0.9).timeout
	
	_start_round()


func _complete_round() -> void:
	game_state = GameState.ROUND_SUCCESS
	level_controller.set_buttons_enabled(false)
	_end_overclock_round()
	level_controller.play_success_feedback()
	_play_audio_method("play_success_sound")
	
	score += 300
	
	if current_round_had_error:
		perfect_round_streak = 0
	else:
		perfect_round_streak += 1
	
	_update_hud()
	
	hud.show_message("Stabilized sequence")
	
	await get_tree().create_timer(0.9).timeout
	
	if current_round >= level_controller.max_rounds:
		_victory()
		return
	
	current_round += 1
	current_round_had_error = false
	
	_add_random_sequence_step()
	
	if perfect_round_streak >= overclock_required_perfect_rounds:
		await _run_overclock_protocol()
	
	_start_round()


func _run_overclock_protocol() -> void:
	game_state = GameState.PROTOCOL_CHOICE
	level_controller.set_buttons_enabled(false)
	
	hud.show_message("Protocol choice available")
	hud.show_protocol_panel(
		stabilize_recovery_amount,
		overclock_score_bonus,
		overclock_extra_sequence_steps,
		overclock_next_round_speed_multiplier
	)
	
	await hud.protocol_choice_selected
	
	var choice := hud.get_selected_protocol_option()
	hud.hide_protocol_panel()
	
	match choice:
		"stabilize":
			_apply_stabilize_protocol()
		"overclock":
			_apply_overclock_protocol()
		_:
			push_warning("Unknown protocol choice: %s" % choice)
	
	perfect_round_streak = 0
	
	_update_hud()
	await get_tree().create_timer(0.35).timeout


func _apply_stabilize_protocol() -> void:
	stability += stabilize_recovery_amount
	stability = min(stability, level_controller.max_stability)
	
	hud.show_message("Stability recovered")
	_play_audio_method("play_success_sound")
	
	print("Protocol selected: STABILIZE")


func _apply_overclock_protocol() -> void:
	score += overclock_score_bonus
	overclock_next_round_active = true
	overclock_round_active = true
	
	for i in range(overclock_extra_sequence_steps):
		_add_random_sequence_step()
	
	level_controller.set_reactor_overclock(true, stability)
	hud.set_reactor_overclock(true)
	
	hud.show_message("OVERCLOCK ENGAGED")
	_play_audio_method("play_success_sound")
	
	print("Protocol selected: OVERCLOCK")
	
func _end_overclock_round() -> void:
	if not overclock_round_active:
		return
	
	overclock_round_active = false
	
	level_controller.set_reactor_overclock(false, stability)
	hud.set_reactor_overclock(false)
	hud.update_stability(stability)
	
func _victory() -> void:
	game_state = GameState.VICTORY
	level_controller.set_buttons_enabled(false)
	
	var completed_level_id := level_controller.level_number
	
	if SelectedLevel.has_level():
		completed_level_id = SelectedLevel.current_level_data.level_id
	
	LevelProgress.complete_level(completed_level_id)
	
	level_controller.play_victory_feedback()
	_play_audio_method("play_victory_sound")
	
	hud.show_message("Reactor stabilized")
	hud.show_end_panel(
		"Victory",
		"Reactor protocol completed.\nFinal Score: %s" % score
	)


func _defeat() -> void:
	game_state = GameState.DEFEAT
	level_controller.set_buttons_enabled(false)
	
	level_controller.play_defeat_feedback()
	_play_audio_method("play_defeat_sound")
	
	hud.show_message("Reactor collapse")
	hud.show_end_panel(
		"Defeat",
		"The reactor lost all stability.\nFinal Score: %s" % score
	)


func _add_random_sequence_step() -> void:
	if available_button_ids.is_empty():
		push_error("Cannot add sequence step. No available button IDs.")
		return
	
	var candidate_ids := available_button_ids.duplicate()
	var last_button_id := _get_last_sequence_button_id()
	var repeat_count := _get_last_button_repeat_count()
	
	if last_button_id != -1:
		if repeat_count >= level_controller.max_consecutive_repeats and candidate_ids.size() > 1:
			candidate_ids.erase(last_button_id)
	
	var random_index: int = rng.randi_range(0, candidate_ids.size() - 1)
	var random_button_id: int = candidate_ids[random_index]
	
	sequence.append(random_button_id)
	print("Added sequence step: ", random_button_id, " | Full sequence: ", sequence)


func _get_last_sequence_button_id() -> int:
	if sequence.is_empty():
		return -1
	
	return sequence[sequence.size() - 1]


func _get_last_button_repeat_count() -> int:
	if sequence.is_empty():
		return 0
	
	var last_button_id := sequence[sequence.size() - 1]
	var repeat_count := 0
	
	for i in range(sequence.size() - 1, -1, -1):
		if sequence[i] == last_button_id:
			repeat_count += 1
		else:
			break
	
	return repeat_count


func _get_current_level_id() -> int:
	if SelectedLevel.has_level():
		return SelectedLevel.current_level_data.level_id
	
	return level_controller.level_number


func _update_hud() -> void:
	hud.update_round(current_round, level_controller.max_rounds)
	hud.update_stability(stability)
	hud.update_score(score)
	
	if level_controller != null:
		level_controller.update_reactor_visual(stability)


func _play_audio_method(method_name: StringName) -> void:
	if audio_manager == null:
		return
	
	if not audio_manager.has_method(method_name):
		return
	
	audio_manager.call(method_name)


func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()


func _on_level_selector_pressed() -> void:
	SelectedLevel.clear_level()
	get_tree().change_scene_to_file(level_selector_scene_path)


func _clear_current_level() -> void:
	for child in level_container.get_children():
		child.queue_free()
	
	current_level = null
	level_controller = null
