extends Node

@export_category("Music")
@export var background_music: AudioStream
@export var play_music_on_ready: bool = true

@export_category("Button Sounds")
@export var button_sounds: Array[AudioStream] = []
@export var default_button_sound: AudioStream
@export var use_pitch_variation: bool = true

@export_category("Feedback Sounds")
@export var error_sound: AudioStream
@export var success_sound: AudioStream
@export var victory_sound: AudioStream
@export var defeat_sound: AudioStream

@export_category("Volume")
@export_range(-40.0, 6.0, 0.1) var music_volume_db: float = -12.0
@export_range(-40.0, 6.0, 0.1) var sfx_volume_db: float = -4.0

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var button_sfx_player: AudioStreamPlayer = $ButtonSfxPlayer
@onready var feedback_sfx_player: AudioStreamPlayer = $FeedbackSfxPlayer


func _ready() -> void:
	music_player.volume_db = music_volume_db
	button_sfx_player.volume_db = sfx_volume_db
	feedback_sfx_player.volume_db = sfx_volume_db
	
	if play_music_on_ready:
		play_background_music()


func play_background_music() -> void:
	if background_music == null:
		return
	
	if music_player.stream == background_music and music_player.playing:
		return
	
	music_player.stream = background_music
	music_player.play()


func stop_background_music() -> void:
	music_player.stop()


func play_button_sound(button_id: int) -> void:
	var stream := _get_button_stream(button_id)
	
	if stream == null:
		return
	
	button_sfx_player.stop()
	button_sfx_player.stream = stream
	button_sfx_player.pitch_scale = _get_button_pitch(button_id)
	button_sfx_player.play()


func play_error_sound() -> void:
	_play_feedback_sound(error_sound)


func play_success_sound() -> void:
	_play_feedback_sound(success_sound)


func play_victory_sound() -> void:
	_play_feedback_sound(victory_sound)


func play_defeat_sound() -> void:
	_play_feedback_sound(defeat_sound)


func set_music_volume_db(value: float) -> void:
	music_volume_db = value
	music_player.volume_db = music_volume_db


func set_sfx_volume_db(value: float) -> void:
	sfx_volume_db = value
	button_sfx_player.volume_db = sfx_volume_db
	feedback_sfx_player.volume_db = sfx_volume_db


func _get_button_stream(button_id: int) -> AudioStream:
	if button_id >= 0 and button_id < button_sounds.size():
		if button_sounds[button_id] != null:
			return button_sounds[button_id]
	
	return default_button_sound


func _get_button_pitch(button_id: int) -> float:
	if not use_pitch_variation:
		return 1.0
	
	match button_id:
		0:
			return 0.9
		1:
			return 1.0
		2:
			return 1.1
		3:
			return 1.2
		_:
			return 1.0


func _play_feedback_sound(stream: AudioStream) -> void:
	if stream == null:
		return
	
	feedback_sfx_player.stop()
	feedback_sfx_player.pitch_scale = 1.0
	feedback_sfx_player.stream = stream
	feedback_sfx_player.play()
