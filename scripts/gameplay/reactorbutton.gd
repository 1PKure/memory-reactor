extends Area3D
class_name ReactorButton

signal button_pressed(button_id: int)

@export var button_id: int = 0
@export var button_color: Color = Color.CYAN
@export var active_color: Color = Color(0.75, 1.0, 1.0)

@export var press_scale: float = 0.92
@export var tween_duration: float = 0.08
@export var can_be_pressed: bool = true

@export_category("Visual Tuning")
@export var base_emission_energy: float = 0.08
@export var active_emission_energy: float = 0.55
@export var active_light_energy: float = 0.65

@onready var visual_mesh: MeshInstance3D = $VisualMesh
@onready var button_light: OmniLight3D = $ButtonLight
@onready var audio_manager: Node = get_node_or_null("/root/AudioManager")

var _default_scale: Vector3
var _base_material: StandardMaterial3D
var _active_material: StandardMaterial3D
var _current_tween: Tween


func _ready() -> void:
	input_ray_pickable = true
	
	_default_scale = scale
	
	_create_materials()
	_set_active_visual(false)
	
	if button_light != null:
		button_light.light_energy = 0.0
		button_light.omni_range = 1.4


func _input_event(
	camera: Camera3D,
	event: InputEvent,
	event_position: Vector3,
	normal: Vector3,
	shape_idx: int
) -> void:
	if not can_be_pressed:
		return
	
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_press()


func set_press_enabled(value: bool) -> void:
	can_be_pressed = value


func play_sequence_feedback() -> void:
	_play_visual_feedback()
	_play_button_sound()


func _press() -> void:
	_play_visual_feedback()
	_play_button_sound()
	button_pressed.emit(button_id)


func _play_visual_feedback() -> void:
	if _current_tween != null:
		_current_tween.kill()
	
	_set_active_visual(true)
	
	_current_tween = create_tween()
	_current_tween.set_trans(Tween.TRANS_BACK)
	_current_tween.set_ease(Tween.EASE_OUT)
	
	_current_tween.tween_property(self, "scale", _default_scale * press_scale, tween_duration)
	_current_tween.tween_property(self, "scale", _default_scale, tween_duration)
	_current_tween.tween_callback(_set_active_visual.bind(false))


func _create_materials() -> void:
	_base_material = StandardMaterial3D.new()
	_base_material.albedo_color = button_color
	_base_material.emission_enabled = true
	_base_material.emission = button_color
	_base_material.emission_energy_multiplier = base_emission_energy
	
	_active_material = StandardMaterial3D.new()
	_active_material.albedo_color = active_color
	_active_material.emission_enabled = true
	_active_material.emission = active_color
	_active_material.emission_energy_multiplier = active_emission_energy
	
	visual_mesh.material_override = _base_material


func _set_active_visual(value: bool) -> void:
	if value:
		visual_mesh.material_override = _active_material
		
		if button_light != null:
			button_light.light_color = active_color
			button_light.light_energy = active_light_energy
	else:
		visual_mesh.material_override = _base_material
		
		if button_light != null:
			button_light.light_color = button_color
			button_light.light_energy = 0.0


func _play_button_sound() -> void:
	if audio_manager == null:
		return
	
	if not audio_manager.has_method("play_button_sound"):
		return
	
	audio_manager.call("play_button_sound", button_id)
