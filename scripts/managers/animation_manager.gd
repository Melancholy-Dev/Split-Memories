class_name AnimationManager extends Node

# Signals
signal initial_animation_finished

# Nodes
@export var animation_player: AnimationPlayer

# Animations Costants
const RESET: StringName = &"RESET"
const GAME_STARTED: StringName = &"game_started"
const UNDO_TRANSITION: StringName = &"undo_transition"
const SCENE_CHANGE_BLUR: StringName = &"scene_change_blur"
const SCENE_CHANGE_GLASS: StringName = &"scene_change_glass"
const LOADING_NEW_LEVEL: StringName = &"loading_new_level"
const FINAL_SCREEN: StringName = &"final_screen"
const PAUSE_MENU: StringName = &"pause_menu"

# Variables
var is_animating := true


func _ready() -> void:
	animation_player.process_mode = Node.PROCESS_MODE_ALWAYS
	animation_player.animation_finished.connect(_on_animation_finished)
	UndoManager.is_undoing_started.connect(play_undo_transition)

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name != GAME_STARTED:
		return
	is_animating = false
	initial_animation_finished.emit()

func play_reset() -> void:
	is_animating = true
	animation_player.play(RESET)
	await animation_player.animation_finished
	is_animating = false

func play_undo_transition() -> void:
	is_animating = true
	animation_player.stop()
	animation_player.play(UNDO_TRANSITION)
	await animation_player.animation_finished
	is_animating = false

func play_scene_change_transition(completed_label: Label = null) -> void:
	is_animating = true
	animation_player.play(SCENE_CHANGE_BLUR)
	await animation_player.animation_finished
	if completed_label != null:
		completed_label.visible = true
		await get_tree().create_timer(1.5).timeout
		completed_label.visible = false
	animation_player.play(SCENE_CHANGE_GLASS)
	await animation_player.animation_finished
	is_animating = false

func play_loading_new_level_transition() -> void:
	is_animating = true
	animation_player.play(LOADING_NEW_LEVEL)
	await animation_player.animation_finished
	is_animating = false

func play_final_screen() -> void:
	await play_reset()
	is_animating = true
	animation_player.play(FINAL_SCREEN)
	await animation_player.animation_finished
	is_animating = false

func play_pause_menu_transition(show_menu: bool) -> void:
	is_animating = true
	if show_menu:
		animation_player.play(PAUSE_MENU)
	else:
		animation_player.play_backwards(PAUSE_MENU)
	await animation_player.animation_finished
	is_animating = false
