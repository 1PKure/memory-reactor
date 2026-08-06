extends Control

@export var level_database: LevelDatabase
@export var level_node_scene: PackedScene
@export_file("*.tscn") var game_scene_path: String = "res://scenes/game/Game.tscn"

@onready var level_container: GridContainer = $LevelContainer

@onready var preview_panel: Panel = $PreviewPanel
@onready var preview_image: TextureRect = $PreviewPanel/PreviewImage
@onready var level_name: Label = $PreviewPanel/LevelName
@onready var description_label: Label = $PreviewPanel/DescriptionLabel
@onready var play_button: Button = $PreviewPanel/PlayButton
@onready var back_button: Button = $BackButton

var selected_level: LevelData
var pending_unlock_ids: Array[int] = []
var unlock_message_label: Label


func _ready() -> void:
	preview_panel.visible = false
	
	play_button.pressed.connect(_on_play_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	_setup_unlock_message_label()
	
	pending_unlock_ids = LevelProgress.consume_pending_unlock_animations()
	
	build_level_selector()
	
	if not pending_unlock_ids.is_empty():
		_show_unlock_message()


func build_level_selector() -> void:
	clear_level_container()
	
	if level_database == null:
		push_warning("LevelDatabase is not assigned in the inspector.")
		return
	
	if level_node_scene == null:
		push_warning("LevelNodeButton scene is not assigned in the inspector.")
		return
	
	for level_data in level_database.levels:
		var level_node := level_node_scene.instantiate() as LevelNodeButton
		
		if level_node == null:
			push_warning("The assigned scene does not have LevelNodeButton.gd attached.")
			continue
		
		level_container.add_child(level_node)
		level_node.setup(level_data)
		level_node.level_selected.connect(_on_level_selected)
		
		if pending_unlock_ids.has(level_data.level_id):
			level_node.call_deferred("animate_unlock")


func clear_level_container() -> void:
	for child in level_container.get_children():
		child.queue_free()


func _on_level_selected(level_data: LevelData) -> void:
	selected_level = level_data
	
	preview_image.texture = level_data.preview_image
	level_name.text = level_data.level_name
	description_label.text = level_data.description
	
	show_preview_panel()


func show_preview_panel() -> void:
	preview_panel.visible = true
	preview_panel.modulate.a = 0.0
	preview_panel.scale = Vector2(0.95, 0.95)
	
	var tween := create_tween()
	tween.tween_property(preview_panel, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(preview_panel, "scale", Vector2.ONE, 0.15)


func _on_play_button_pressed() -> void:
	if selected_level == null:
		return
	
	if selected_level.scene_path.is_empty():
		push_warning("Selected level has no scene path.")
		return
	
	SelectedLevel.set_level(selected_level)
	get_tree().change_scene_to_file(game_scene_path)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://examples/scenes/menus/main_menu/main_menu_with_animations.tscn")


func _setup_unlock_message_label() -> void:
	unlock_message_label = Label.new()
	unlock_message_label.text = "NEW PROTOCOLS UNLOCKED"
	unlock_message_label.visible = false
	unlock_message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	add_child(unlock_message_label)
	
	unlock_message_label.anchor_left = 0.5
	unlock_message_label.anchor_right = 0.5
	unlock_message_label.offset_left = -180
	unlock_message_label.offset_right = 180
	unlock_message_label.offset_top = 24
	unlock_message_label.offset_bottom = 64
	unlock_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _show_unlock_message() -> void:
	unlock_message_label.visible = true
	unlock_message_label.modulate.a = 0.0
	unlock_message_label.scale = Vector2(0.9, 0.9)
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(unlock_message_label, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(unlock_message_label, "scale", Vector2.ONE, 0.18)
	
	await get_tree().create_timer(1.4).timeout
	
	var fade_tween := create_tween()
	fade_tween.tween_property(unlock_message_label, "modulate:a", 0.0, 0.25)
	await fade_tween.finished
	
	unlock_message_label.visible = false
