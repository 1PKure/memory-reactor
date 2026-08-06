extends Resource
class_name LevelData

@export var level_id: int = 0
@export var level_name: String = "New Level"
@export var scene_path: String = ""
@export var preview_image: Texture2D
@export var description: String = ""

@export var is_unlocked: bool = false
@export_range(0, 3) var stars: int = 0
@export var best_score: int = 0
