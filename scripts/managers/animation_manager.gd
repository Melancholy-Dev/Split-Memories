class_name AnimationManager extends Node

# Nodes
@export var animation_player: AnimationPlayer


func _ready() -> void:
	UndoManager.is_undoing_started.connect(play_undo_transition)

func play_undo_transition() -> void:
	if animation_player.is_playing():
		animation_player.play("RESET")
		animation_player.play("black_transition")
	animation_player.play("black_transition")
