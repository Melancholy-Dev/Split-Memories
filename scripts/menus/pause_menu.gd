class_name PauseMenu extends Menu

# Nodes
@onready var scene_manager: SceneManager = %SceneManager
@onready var main_menu: MainMenu = %MainMenu

# Variables
var is_paused := false


func _ready() -> void:
	super._ready()
	InputManager.pause_pressed.connect(_pause_pressed)

func _pause_pressed() -> void:
	if is_paused == true:
		visible = false
		is_paused = false
		_resume()
	elif is_paused == false:
		visible = true
		is_paused = true
		_focus_initial_node()
		_pause()

func _resume() -> void:
	get_tree().paused = false

func _pause() -> void:
	get_tree().paused = true


## Buttons
func _on_resume_button_pressed() -> void:
	_pause_pressed()

func _on_retry_button_pressed() -> void:
	_resume()
	await %AnimationManager.play_scene_change_transition()
	await scene_manager.load_level(scene_manager.current_level_index)
	await %AnimationManager.play_reset()
	visible = false
	is_paused = false

func _on_main_menu_button_pressed() -> void:
	_resume()
	await %AnimationManager.play_scene_change_transition()
	UndoManager.clear_boards()
	if is_instance_valid(scene_manager.current_level):
		scene_manager.current_level.queue_free()
		await get_tree().process_frame
	main_menu.visible = true
	main_menu._on_back_button_pressed()
	visible = false
	await %AnimationManager.play_reset()
	is_paused = false
