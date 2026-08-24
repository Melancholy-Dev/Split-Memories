class_name AnimationManager extends Node

# Nodes
@export var animation_player: AnimationPlayer


func _ready() -> void:
	UndoManager.is_undoing_started.connect(play_undo_transition)
	%SceneManager.loading_level.connect(play_reset)

func play_reset() -> void:
	animation_player.play("RESET")

func play_undo_transition() -> void:
	if animation_player.is_playing():
		play_reset()
		animation_player.play("black_transition")
	animation_player.play("black_transition")

func play_scene_change_transition() -> void:
	animation_player.play("level_completed")
