extends Node

@export var buttons_container: BoxContainer

@export var hover_scale: Vector2 = Vector2(1.07, 1.07)
@export var hover_color: Color = Color(0.65, 0.95, 1.0, 1.0)

@export_range(0.05, 0.5, 0.01)
var animation_duration: float = 0.12

var _normal_scales: Dictionary = {}
var _normal_colors: Dictionary = {}
var _active_tweens: Dictionary = {}


func _ready() -> void:
	if buttons_container == null:
		push_error("ButtonAnimator: Buttons Container is not assigned.")
		return

	# Wait until the VBoxContainer finishes arranging its children.
	await get_tree().process_frame

	for child in buttons_container.get_children():
		if child is Button:
			_setup_button(child as Button)


func _setup_button(button: Button) -> void:
	_normal_scales[button] = button.scale
	_normal_colors[button] = button.modulate

	_update_button_pivot(button)

	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	button.mouse_entered.connect(
		_on_button_mouse_entered.bind(button)
	)

	button.mouse_exited.connect(
		_on_button_mouse_exited.bind(button)
	)

	button.focus_entered.connect(
		_on_button_focus_entered.bind(button)
	)

	button.focus_exited.connect(
		_on_button_focus_exited.bind(button)
	)

	button.resized.connect(
		_update_button_pivot.bind(button)
	)


func _update_button_pivot(button: Button) -> void:
	button.pivot_offset = button.size * 0.5


func _on_button_mouse_entered(button: Button) -> void:
	_show_hover(button)


func _on_button_mouse_exited(button: Button) -> void:
	if not button.has_focus():
		_show_normal(button)


func _on_button_focus_entered(button: Button) -> void:
	_show_hover(button)


func _on_button_focus_exited(button: Button) -> void:
	if not _is_mouse_over(button):
		_show_normal(button)


func _show_hover(button: Button) -> void:
	var normal_scale: Vector2 = _normal_scales.get(
		button,
		Vector2.ONE
	)

	_animate_button(
		button,
		normal_scale * hover_scale,
		hover_color
	)


func _show_normal(button: Button) -> void:
	var normal_scale: Vector2 = _normal_scales.get(
		button,
		Vector2.ONE
	)

	var normal_color: Color = _normal_colors.get(
		button,
		Color.WHITE
	)

	_animate_button(
		button,
		normal_scale,
		normal_color
	)


func _animate_button(
	button: Button,
	target_scale: Vector2,
	target_color: Color
) -> void:
	var previous_tween := _active_tweens.get(button) as Tween

	if previous_tween != null and previous_tween.is_valid():
		previous_tween.kill()

	var tween := create_tween()

	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		button,
		"scale",
		target_scale,
		animation_duration
	)

	tween.tween_property(
		button,
		"modulate",
		target_color,
		animation_duration
	)

	_active_tweens[button] = tween


func _is_mouse_over(button: Button) -> bool:
	var local_mouse_position := button.get_local_mouse_position()
	var button_rect := Rect2(Vector2.ZERO, button.size)

	return button_rect.has_point(local_mouse_position)
