extends Button
class_name LevelNodeButton

signal level_selected(level_data: LevelData)

@onready var icon_texture: TextureRect = $IconTexture
@onready var name_label: Label = $NameLabel
@onready var lock_icon: TextureRect = $LockIcon
@onready var stars_label: Label = $StarsLabel

var level_data: LevelData
var original_scale: Vector2 = Vector2.ONE
var is_unlocked: bool = false


func _ready() -> void:
	original_scale = scale
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)


func setup(data: LevelData) -> void:
	level_data = data
	
	name_label.text = data.level_name
	icon_texture.texture = data.preview_image
	stars_label.text = "★".repeat(data.stars)
	
	is_unlocked = data.is_unlocked or LevelProgress.is_level_unlocked(data.level_id)
	
	_apply_visual_state()


func force_locked_visual() -> void:
	is_unlocked = false
	lock_icon.visible = true
	modulate = Color(0.45, 0.45, 0.45, 1.0)
	disabled = false


func animate_unlock() -> void:
	disabled = true
	force_locked_visual()
	
	await get_tree().create_timer(0.25).timeout
	
	is_unlocked = true
	lock_icon.visible = false
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "modulate", Color.WHITE, 0.18)
	tween.parallel().tween_property(self, "scale", original_scale * 1.25, 0.18)
	tween.tween_property(self, "scale", original_scale, 0.12)
	
	await tween.finished
	
	disabled = false


func _apply_visual_state() -> void:
	disabled = false
	lock_icon.visible = not is_unlocked
	
	if is_unlocked:
		modulate = Color.WHITE
	else:
		modulate = Color(0.45, 0.45, 0.45, 1.0)


func _on_pressed() -> void:
	if level_data == null:
		return
	
	if not is_unlocked:
		animate_locked()
		return
	
	level_selected.emit(level_data)


func _on_mouse_entered() -> void:
	if not is_unlocked:
		return
	
	var tween := create_tween()
	tween.tween_property(self, "scale", original_scale * 1.08, 0.12)


func _on_mouse_exited() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", original_scale, 0.12)


func animate_locked() -> void:
	var start_position := position
	
	var tween := create_tween()
	tween.tween_property(self, "position:x", start_position.x + 8.0, 0.04)
	tween.tween_property(self, "position:x", start_position.x - 8.0, 0.04)
	tween.tween_property(self, "position:x", start_position.x, 0.04)
