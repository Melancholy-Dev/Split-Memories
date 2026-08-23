class_name AudioManager extends Node

# Nodes
@export var _sound_player: AudioStreamPlayer
@export var _music_player: AudioStreamPlayer

# Audio files
@export var undo_stream: AudioStream


func _ready() -> void:
	UndoManager.is_undoing_started.connect(play_undo_sound)

func play_undo_sound() -> void:
	if undo_stream == null:
		return
	_sound_player.stream = undo_stream
	_sound_player.play()
