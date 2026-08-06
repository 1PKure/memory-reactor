extends Node3D
class_name MemoryLevelController

signal reactor_button_pressed(button_id: int)

@export var level_number: int = 1
@export var level_title: String = "Memory Reactor"

@export_category("Rules")
@export var max_rounds: int = 3
@export var starting_sequence_length: int = 2
@export var max_stability: int = 100
@export var error_penalty: int = 25
@export var max_consecutive_repeats: int = 2

@export_category("Sequence Timing")
@export var round_start_delay: float = 0.8
@export var sequence_step_delay: float = 0.55
@export var sequence_gap_delay: float = 0.25

@export_category("Camera")
@export var camera_path: NodePath = "Camera3D"

@export_category("VFX")
@export var error_sparks_path: NodePath = "VFX/ErrorSparks"
@export var success_pulse_path: NodePath = "VFX/SuccessPulse"
@export var victory_burst_path: NodePath = "VFX/VictoryBurst"
@export var defeat_smoke_path: NodePath = "VFX/DefeatSmoke"

@onready var buttons_container: Node3D = $Buttons
@onready var game_camera: Camera3D = get_node_or_null(camera_path) as Camera3D
@onready var reactor_core: MeshInstance3D = $ReactorCore
@onready var error_sparks: GPUParticles3D = get_node_or_null(error_sparks_path) as GPUParticles3D
@onready var success_pulse: GPUParticles3D = get_node_or_null(success_pulse_path) as GPUParticles3D
@onready var victory_burst: GPUParticles3D = get_node_or_null(victory_burst_path) as GPUParticles3D
@onready var defeat_smoke: GPUParticles3D = get_node_or_null(defeat_smoke_path) as GPUParticles3D

var reactor_buttons: Array[ReactorButton] = []
var valid_button_ids: Array[int] = []

var _camera_original_position: Vector3
var _camera_shake_tween: Tween
var _reactor_visual_state: StringName = &""
var _reactor_core_base_scale: Vector3
var _reactor_core_material: StandardMaterial3D
var _reactor_core_pulse_tween: Tween

const REACTOR_STABLE_COLOR := Color(0.35, 0.95, 1.0)
const REACTOR_WARNING_COLOR := Color(1.0, 0.65, 0.15)
const REACTOR_CRITICAL_COLOR := Color(1.0, 0.15, 0.10)
const REACTOR_OVERCLOCK_COLOR := Color(0.85, 0.2, 1.0)

var _reactor_overclock_active: bool = false

func _ready() -> void:
	_setup_camera()
	_setup_buttons()
	set_buttons_enabled(false)
	_setup_reactor_core()

func _setup_reactor_core() -> void:
	if reactor_core == null:
		push_warning("No ReactorCore found in level.")
		return
	
	_reactor_core_base_scale = reactor_core.scale
	
	var material := reactor_core.get_active_material(0)
	
	if material is StandardMaterial3D:
		_reactor_core_material = material.duplicate() as StandardMaterial3D
		reactor_core.set_surface_override_material(0, _reactor_core_material)
		
		_reactor_core_material.emission_enabled = true
	
	update_reactor_visual(max_stability)
	
func update_reactor_visual(stability: int) -> void:
	if _reactor_overclock_active:
		return
	var stability_ratio := float(stability) / float(max(max_stability, 1))
	var new_state: StringName
	
	if stability_ratio > 0.60:
		new_state = &"stable"
	elif stability_ratio > 0.30:
		new_state = &"warning"
	else:
		new_state = &"critical"
	
	if new_state == _reactor_visual_state:
		return
	
	_reactor_visual_state = new_state
	
	match new_state:
		&"stable":
			_apply_reactor_state(
				REACTOR_STABLE_COLOR,
				1.04,
				0.75,
				1.4
			)
		
		&"warning":
			_apply_reactor_state(
				REACTOR_WARNING_COLOR,
				1.08,
				0.40,
				2.0
			)
		
		&"critical":
			_apply_reactor_state(
				REACTOR_CRITICAL_COLOR,
				1.13,
				0.20,
				3.0
			)


func set_reactor_overclock(active: bool, stability: int) -> void:
	_reactor_overclock_active = active
	
	if active:
		_reactor_visual_state = &"overclock"
		
		_apply_reactor_state(
			REACTOR_OVERCLOCK_COLOR,
			1.20,
			0.20,
			3.0
		)
	else:
		_reactor_visual_state = &""
		update_reactor_visual(stability)

func _apply_reactor_state(
	color: Color,
	pulse_scale: float,
	pulse_duration: float,
	emission_energy: float
) -> void:
	if _reactor_core_material != null:
		_reactor_core_material.albedo_color = color
		_reactor_core_material.emission_enabled = true
		_reactor_core_material.emission = color
		_reactor_core_material.emission_energy_multiplier = emission_energy
	
	_start_reactor_pulse(pulse_scale, pulse_duration)

func _start_reactor_pulse(
	scale_multiplier: float,
	half_duration: float
) -> void:
	if reactor_core == null:
		return
	
	if _reactor_core_pulse_tween != null:
		_reactor_core_pulse_tween.kill()
	
	reactor_core.scale = _reactor_core_base_scale
	
	_reactor_core_pulse_tween = create_tween()
	_reactor_core_pulse_tween.set_loops()
	_reactor_core_pulse_tween.set_trans(Tween.TRANS_SINE)
	_reactor_core_pulse_tween.set_ease(Tween.EASE_IN_OUT)
	
	_reactor_core_pulse_tween.tween_property(
		reactor_core,
		"scale",
		_reactor_core_base_scale * scale_multiplier,
		half_duration
	)
	
	_reactor_core_pulse_tween.tween_property(
		reactor_core,
		"scale",
		_reactor_core_base_scale,
		half_duration
	)
func get_button_count() -> int:
	return reactor_buttons.size()


func get_valid_button_ids() -> Array[int]:
	return valid_button_ids.duplicate()


func has_button_id(button_id: int) -> bool:
	return valid_button_ids.has(button_id)


func set_buttons_enabled(value: bool) -> void:
	for button in reactor_buttons:
		button.set_press_enabled(value)


func play_button_feedback(button_id: int) -> void:
	var button := get_button_by_id(button_id)
	
	if button == null:
		push_warning("No button found with ID: %s" % button_id)
		return
	
	button.play_sequence_feedback()


func play_error_feedback() -> void:
	shake_camera(0.14, 0.28)
	_restart_particles(error_sparks)


func play_success_feedback() -> void:
	_restart_particles(success_pulse)


func play_victory_feedback() -> void:
	shake_camera(0.08, 0.18)
	_restart_particles(victory_burst)


func play_defeat_feedback() -> void:
	shake_camera(0.22, 0.45)
	_restart_particles(defeat_smoke)


func shake_camera(intensity: float = 0.12, duration: float = 0.25) -> void:
	if game_camera == null:
		return
	
	if _camera_shake_tween != null:
		_camera_shake_tween.kill()
		game_camera.position = _camera_original_position
	
	var shake_steps := 8
	var step_duration := duration / float(shake_steps)
	
	_camera_shake_tween = create_tween()
	
	for i in range(shake_steps):
		var random_offset := Vector3(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity),
			0.0
		)
		
		_camera_shake_tween.tween_property(
			game_camera,
			"position",
			_camera_original_position + random_offset,
			step_duration
		)
	
	_camera_shake_tween.tween_property(
		game_camera,
		"position",
		_camera_original_position,
		step_duration
	)


func get_button_by_id(button_id: int) -> ReactorButton:
	for button in reactor_buttons:
		if button.button_id == button_id:
			return button
	
	return null


func _setup_camera() -> void:
	if game_camera == null:
		push_warning("No Camera3D found in level. Camera shake will be disabled.")
		return
	
	_camera_original_position = game_camera.position


func _setup_buttons() -> void:
	reactor_buttons.clear()
	valid_button_ids.clear()
	
	var auto_id := 0
	
	for child in buttons_container.get_children():
		if child is ReactorButton:
			var button := child as ReactorButton
			
			button.button_id = auto_id
			
			reactor_buttons.append(button)
			valid_button_ids.append(button.button_id)
			
			if not button.button_pressed.is_connected(_on_button_pressed):
				button.button_pressed.connect(_on_button_pressed)
			
			auto_id += 1
	
	print("Level ", level_number, " - connected buttons: ", reactor_buttons.size())
	print("Auto assigned button IDs: ", valid_button_ids)


func _restart_particles(particles: GPUParticles3D) -> void:
	if particles == null:
		return
	
	particles.emitting = false
	particles.restart()
	particles.emitting = true


func _on_button_pressed(button_id: int) -> void:
	reactor_button_pressed.emit(button_id)
