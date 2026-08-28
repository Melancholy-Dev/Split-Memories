class_name AudioComponent extends Node

# Nodes
@onready var audio_manager: AudioManager = get_tree().get_first_node_in_group("audio_manager")

# Files
@export_category("Audio player")
@export var audio_player: AudioStreamPlayer2D

@export_category("Sounds")
@export var footstep_stream: AudioStream
@export var push_stream: AudioStream
@export var game_button_stream: AudioStream


func _ready() -> void:
	if audio_manager != null:
		audio_manager.volumes_changed.connect(_update_volume)
		_update_volume()
	var entity := get_parent().get_parent() as GridEntity
	if entity == null or audio_player == null:
		return
	if entity is Player:
		var movement_component := entity.get_node_or_null("Components/MovementComponent")
		if movement_component != null:
			movement_component.movement_started.connect(_on_player_movement_started)
	elif entity is PushableObject:
		entity.grid_position_changed.connect(_on_pushable_moved)
	elif entity is PressureButton:
		var button := entity as PressureButton
		button.pressed_changed.connect(_on_game_button_pressed)

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
	if stream == null:
		return
	audio_player.stream = stream
	audio_player.play()
