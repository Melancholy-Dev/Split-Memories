class_name AnimationManager extends Node

# Nodes
@export var animation_player: AnimationPlayer


func _ready() -> void:
	animation_player.process_mode = Node.PROCESS_MODE_ALWAYS
	UndoManager.is_undoing_started.connect(play_undo_transition)

func play_reset() -> void:
	animation_player.play("RESET")
	await animation_player.animation_finished

func play_undo_transition() -> void:
	animation_player.stop()
	animation_player.play("undo_transition")
	await animation_player.animation_finished

func play_scene_change_transition(completed_label: Label = null) -> void:
	animation_player.play("scene_change_blur")
	await animation_player.animation_finished
	if completed_label != null:
		completed_label.visible = true
		await get_tree().create_timer(1.5).timeout
		completed_label.visible = false
	animation_player.play("scene_change_glass")
	await animation_player.animation_finished

func play_loading_new_level_transition() -> void:
	animation_player.play("loading_new_level")
	await animation_player.animation_finished

func play_pause_menu_transition(show_menu: bool) -> void:
	if show_menu:
		animation_player.play("pause_menu")
	else:
		animation_player.play_backwards("pause_menu")
	await animation_player.animation_finished
