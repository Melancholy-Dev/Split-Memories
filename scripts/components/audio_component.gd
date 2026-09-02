class_name AudioComponent extends Node

# Nodes
var audio_manager: AudioManager

# Files
@export_category("Audio player")
@export var audio_player: AudioStreamPlayer2D

@export_category("Sounds")
@export var footstep_stream: AudioStream
@export var push_stream: AudioStream
@export var game_button_stream: AudioStream


func set_audio_manager(manager: AudioManager) -> void:
	if audio_manager == manager:
		return
	audio_manager = manager
	audio_manager.volumes_changed.connect(_update_volume)
	_update_volume()

func _update_volume() -> void:
	if audio_player == null or audio_manager == null:
		return
	audio_player.volume_db = audio_manager.sound_volume_db + audio_manager.master_volume_db

func _on_player_movement_started(_direction: Vector2i) -> void:
	_play(footstep_stream)

func _on_pushable_moved(_old_position: Vector2i, _new_position: Vector2i) -> void:
	if UndoManager.is_undoing():
		return
	_play(push_stream)

func _on_game_button_pressed(is_pressed: bool) -> void:
	if is_pressed and not UndoManager.is_undoing():
		_play(game_button_stream)

func _play(stream: AudioStream) -> void:
	if stream == null or audio_player == null:
		return
	audio_player.stream = stream
	audio_player.play()
