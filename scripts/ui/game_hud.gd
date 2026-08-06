extends Control
class_name GameHUD

signal retry_pressed
signal level_selector_pressed
signal protocol_choice_selected

@onready var round_indicators: HBoxContainer = $RoundIndicators
@onready var stability_label: Label = $VBoxContainer/StabilityLabel
@onready var stability_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var score_label: Label = $ScoreLabel
@onready var message_label: Label = $MessageLabel

@onready var reactor_title_label: Label = $ReactorInfo/ReactorTitleLabel
@onready var reactor_status_label: Label = $ReactorInfo/ReactorStatusLabel

@onready var end_panel: Panel = $EndPanel
@onready var end_title_label: Label = $EndPanel/EndTitleLabel
@onready var end_description_label: Label = $EndPanel/EndDescriptionLabel
@onready var retry_button: Button = $EndPanel/RetryButton
@onready var level_selector_button: Button = $EndPanel/LevelSelectorButton

@onready var protocol_panel: Panel = $ProtocolPanel
@onready var protocol_title_label: Label = $ProtocolPanel/ProtocolTitleLabel
@onready var protocol_description_label: Label = $ProtocolPanel/ProtocolDescriptionLabel
@onready var stabilize_button: Button = $ProtocolPanel/StabilizeButton
@onready var overclock_button: Button = $ProtocolPanel/OverclockButton

var selected_protocol_option: String = ""

var _message_tween: Tween
var _end_panel_tween: Tween
var _protocol_panel_tween: Tween
var reactor_overclock_active: bool = false

func _ready() -> void:
	_setup_mouse_filters()
	_setup_initial_visibility()
	_connect_buttons()


func _setup_mouse_filters() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	stability_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stability_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	reactor_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reactor_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	end_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	retry_button.mouse_filter = Control.MOUSE_FILTER_STOP
	level_selector_button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	protocol_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	stabilize_button.mouse_filter = Control.MOUSE_FILTER_STOP
	overclock_button.mouse_filter = Control.MOUSE_FILTER_STOP
	
func set_reactor_overclock(active: bool) -> void:
	reactor_overclock_active = active
	
	if active:
		reactor_status_label.text = "OVERCLOCK"


func _setup_initial_visibility() -> void:
	end_panel.visible = false
	protocol_panel.visible = false
	
	message_label.modulate.a = 1.0
	message_label.scale = Vector2.ONE
	
	stability_label.scale = Vector2.ONE
	score_label.scale = Vector2.ONE


func _connect_buttons() -> void:
	retry_button.pressed.connect(_on_retry_button_pressed)
	level_selector_button.pressed.connect(_on_level_selector_button_pressed)
	stabilize_button.pressed.connect(_on_stabilize_button_pressed)
	overclock_button.pressed.connect(_on_overclock_button_pressed)


func update_round(current_round: int, max_rounds: int) -> void:
	
	if round_indicators.get_child_count() != max_rounds:
		_create_round_indicators(max_rounds)
	
	for i in range(max_rounds):
		var indicator := round_indicators.get_child(i) as Label
		
		if i < current_round - 1:
			indicator.text = "●"
		elif i == current_round - 1:
			indicator.text = "◉"
		else:
			indicator.text = "○"
	
	_pulse_control(round_indicators)
	
func _create_round_indicators(max_rounds: int) -> void:
	for child in round_indicators.get_children():
		round_indicators.remove_child(child)
		child.queue_free()
	
	for i in range(max_rounds):
		var indicator := Label.new()
		indicator.text = "○"
		indicator.add_theme_font_size_override("font_size", 24)
		indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		round_indicators.add_child(indicator)

func update_stability(stability: int) -> void:
	stability_bar.value = stability
	
	if reactor_overclock_active:
		reactor_status_label.text = "OVERCLOCK"
		return
	
	if stability > 60:
		reactor_status_label.text = "STABLE"
	elif stability > 30:
		reactor_status_label.text = "WARNING"
	else:
		reactor_status_label.text = "CRITICAL"


func update_score(score: int) -> void:
	score_label.text = "Score: %s" % score
	_pulse_control(score_label)


func show_message(message: String) -> void:
	message_label.text = message
	
	if _message_tween != null:
		_message_tween.kill()
	
	message_label.modulate.a = 0.0
	message_label.scale = Vector2(0.9, 0.9)
	
	_message_tween = create_tween()
	_message_tween.set_trans(Tween.TRANS_BACK)
	_message_tween.set_ease(Tween.EASE_OUT)
	_message_tween.tween_property(message_label, "modulate:a", 1.0, 0.12)
	_message_tween.parallel().tween_property(message_label, "scale", Vector2.ONE, 0.12)

	
func show_end_panel(title: String, description: String) -> void:
	end_title_label.text = title
	end_description_label.text = description
	
	end_panel.visible = true
	
	if _end_panel_tween != null:
		_end_panel_tween.kill()
	
	end_panel.modulate.a = 0.0
	end_panel.scale = Vector2(0.9, 0.9)
	
	_end_panel_tween = create_tween()
	_end_panel_tween.set_trans(Tween.TRANS_BACK)
	_end_panel_tween.set_ease(Tween.EASE_OUT)
	_end_panel_tween.tween_property(end_panel, "modulate:a", 1.0, 0.18)
	_end_panel_tween.parallel().tween_property(end_panel, "scale", Vector2.ONE, 0.18)


func hide_end_panel() -> void:
	end_panel.visible = false


func show_protocol_panel(
	stability_recovery: int,
	score_bonus: int,
	extra_steps: int,
	speed_multiplier: float
) -> void:
	selected_protocol_option = ""
	
	protocol_title_label.text = "PROTOCOL CHOICE"
	protocol_description_label.text = (
		"The reactor is stable enough to push its limits.\n\n"
		+ "STABILIZE: Recover +%s Stability.\n" % stability_recovery
		+ "OVERCLOCK: Gain +%s Score, add +%s sequence step, and speed up the next sequence." % [score_bonus, extra_steps]
	)
	
	stabilize_button.text = "STABILIZE"
	overclock_button.text = "OVERCLOCK"
	
	protocol_panel.visible = true
	
	if _protocol_panel_tween != null:
		_protocol_panel_tween.kill()
	
	protocol_panel.modulate.a = 0.0
	protocol_panel.scale = Vector2(0.9, 0.9)
	
	_protocol_panel_tween = create_tween()
	_protocol_panel_tween.set_trans(Tween.TRANS_BACK)
	_protocol_panel_tween.set_ease(Tween.EASE_OUT)
	_protocol_panel_tween.tween_property(protocol_panel, "modulate:a", 1.0, 0.18)
	_protocol_panel_tween.parallel().tween_property(protocol_panel, "scale", Vector2.ONE, 0.18)


func hide_protocol_panel() -> void:
	protocol_panel.visible = false


func get_selected_protocol_option() -> String:
	return selected_protocol_option


func _pulse_control(control: Control) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2(1.08, 1.08), 0.08)
	tween.tween_property(control, "scale", Vector2.ONE, 0.08)


func _on_retry_button_pressed() -> void:
	retry_pressed.emit()


func _on_level_selector_button_pressed() -> void:
	level_selector_pressed.emit()


func _on_stabilize_button_pressed() -> void:
	selected_protocol_option = "stabilize"
	protocol_choice_selected.emit()


func _on_overclock_button_pressed() -> void:
	selected_protocol_option = "overclock"
	protocol_choice_selected.emit()
