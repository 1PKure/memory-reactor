extends Node
class_name PortalInteraction

@export var button: BaseButton
@export var portal_visual: CanvasItem

@export var normal_speed: float = 1.0
@export var normal_intensity: float = 1.0

@export var hover_speed: float = 2.2
@export var hover_intensity: float = 1.35

@export var click_speed: float = 4.0
@export var click_intensity: float = 1.8

@export var transition_speed: float = 10.0

var shader_material: ShaderMaterial

var current_speed: float = 1.0
var current_intensity: float = 1.0

var target_speed: float = 1.0
var target_intensity: float = 1.0


func _ready() -> void:
	if button == null:
		push_error("PortalInteraction: falta asignar la referencia del botón.")
		return

	if portal_visual == null:
		push_error("PortalInteraction: falta asignar la referencia de PortalVisual.")
		return

	shader_material = portal_visual.material as ShaderMaterial

	if shader_material == null:
		push_error("PortalInteraction: PortalVisual necesita un ShaderMaterial.")
		return

	shader_material = shader_material.duplicate() as ShaderMaterial
	portal_visual.material = shader_material

	current_speed = normal_speed
	current_intensity = normal_intensity

	target_speed = normal_speed
	target_intensity = normal_intensity

	_apply_shader_values()

	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)
	button.button_down.connect(_on_button_down)
	button.button_up.connect(_on_button_up)


func _process(delta: float) -> void:
	if shader_material == null:
		return

	var interpolation_factor: float = 1.0 - exp(-transition_speed * delta)

	current_speed = lerp(current_speed, target_speed, interpolation_factor)
	current_intensity = lerp(current_intensity, target_intensity, interpolation_factor)

	_apply_shader_values()


func _on_mouse_entered() -> void:
	target_speed = hover_speed
	target_intensity = hover_intensity


func _on_mouse_exited() -> void:
	target_speed = normal_speed
	target_intensity = normal_intensity


func _on_button_down() -> void:
	target_speed = click_speed
	target_intensity = click_intensity


func _on_button_up() -> void:
	if button.is_hovered():
		target_speed = hover_speed
		target_intensity = hover_intensity
	else:
		target_speed = normal_speed
		target_intensity = normal_intensity


func _apply_shader_values() -> void:
	shader_material.set_shader_parameter("portal_speed", current_speed)
	shader_material.set_shader_parameter("portal_intensity", current_intensity)
