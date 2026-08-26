class_name MainMenu extends Menu

# Nodes
@onready var scene_manager := get_tree().get_first_node_in_group("scene_manager")
@export var menu_buttons: VBoxContainer
@export var level_buttons: VBoxContainer
@export var tutorial: Control
@export var credits: Control
@export var back_button: VBoxContainer


func _ready() -> void:
	super._ready()
	$GameVersion.text = "Game Version: " + ProjectSettings.get_setting(
		"application/config/version"
	)

### Menu Buttons pressed
func _on_play_button_pressed() -> void:
	_button_selected()
	_game_started(0)

func _on_levels_button_pressed() -> void:
	_button_selected()
	menu_buttons.visible = false
	back_button.visible = true
	level_buttons.visible = true
	_focus_button(0)

func _on_tutorial_button_pressed() -> void:
	_button_selected()
	menu_buttons.visible = false
	back_button.visible = true
	tutorial.visible = true
	_focus_button(0)

func _on_credits_button_pressed() -> void:
	_button_selected()
	menu_buttons.visible = false
	back_button.visible = true
	credits.visible = true
	_focus_button(0)

func _on_quit_button_pressed() -> void:
	_button_selected()
	get_tree().quit()

# Sub-Menu Buttons
func _on_back_button_pressed() -> void:
	_button_selected()
	back_button.visible = false
	menu_buttons.visible = true
	level_buttons.visible = false
	tutorial.visible = false
	credits.visible = false
	_focus_initial_node()

func _on_level_1_button_pressed() -> void:
	_button_selected()
	_game_started(0)

func _on_level_2_button_pressed() -> void:
	_button_selected()
	_game_started(1)

func _on_level_3_button_pressed() -> void:
	_button_selected()
	_game_started(2)

func _game_started(level: int) -> void:
	await scene_manager.load_level(level)
	await %AnimationManager.play_scene_change_transition()
	visible = false
	await %AnimationManager.play_loading_new_level_transition()
