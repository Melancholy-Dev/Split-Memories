class_name AnimationManager extends Node

# Nodes
@export var animation_player: AnimationPlayer


func _ready() -> void:
	UndoManager.is_undoing_started.connect(play_undo_transition)

func play_reset() -> void:
	animation_player.play("RESET")
	await animation_player.animation_finished

func play_undo_transition() -> void:
	if animation_player.is_playing():
		animation_player.play("RESET")
		animation_player.play("black_transition")
	animation_player.play("black_transition")
	await animation_player.animation_finished

func play_scene_change_transition() -> void:
	animation_player.play("level_completed")
	await animation_player.animation_finished
