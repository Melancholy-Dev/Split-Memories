class_name PauseMenu extends Menu

# Nodes
@onready var scene_manager := get_tree().get_first_node_in_group("scene_manager")

# Variables
var is_paused := false
var _transitioning := false


func _ready() -> void:
	super._ready()
	InputManager.pause_pressed.connect(_pause_pressed)

func _pause_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	if is_paused:
		_resume()
		await %AnimationManager.play_pause_menu_transition(false)
		visible = false
		is_paused = false
	else:
		visible = true
		is_paused = true
		_pause()
		_focus_initial_node()
		await %AnimationManager.play_pause_menu_transition(true)
	_transitioning = false

func _resume() -> void:
	get_tree().paused = false

func _pause() -> void:
	get_tree().paused = true


## Buttons
func _on_resume_button_pressed() -> void:
	_pause_pressed()

func _on_retry_button_pressed() -> void:
	_resume()
	visible = false
	await %AnimationManager.play_scene_change_transition()
	await scene_manager.load_level(scene_manager.current_level_index)
	await %AnimationManager.play_loading_new_level_transition()
	is_paused = false

func _on_main_menu_button_pressed() -> void:
	_resume()
	visible = false
	await %AnimationManager.play_scene_change_transition()
	UndoManager.clear_boards()
	if is_instance_valid(scene_manager.current_level):
		scene_manager.current_level.queue_free()
		await get_tree().process_frame
	%MainMenu.visible = true
	%MainMenu._on_back_button_pressed()
	await %AnimationManager.play_reset()
	is_paused = false
