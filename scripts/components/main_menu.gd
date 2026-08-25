class_name MainMenu extends Control

# Signals
signal button_focus_entered
signal button_selected

# Nodes
@onready var scene_manager := get_tree().get_first_node_in_group("scene_manager")
@export var menu_buttons: VBoxContainer
@export var level_buttons: VBoxContainer
@export var tutorial: Control
@export var credits: Control
@export var back_button: VBoxContainer
@onready var buttons: Array[Button] = [] # TODO: Could be optimized

# Variables
var button_type: String = ""
var _last_focused: Control = null


func _ready() -> void:
	# Buttons management
	for node in get_tree().get_nodes_in_group("ui_button"):
		if node is Button:
			var b := node as Button
			buttons.append(b)
	buttons[1].grab_focus()
	_last_focused = get_viewport().gui_get_focus_owner()

func _on_button_focus_entered() -> void:
	var button = get_viewport().gui_get_focus_owner()
	if button == _last_focused:
		return
	_last_focused = button
	button_focus_entered.emit()

### Menu Buttons pressed
func _on_play_button_pressed() -> void:
	button_selected.emit()
	button_type = "play"
	_game_started(0)

func _on_levels_button_pressed() -> void:
	button_selected.emit()
	button_type = "levels"
	menu_buttons.visible = false
	back_button.visible = true
	level_buttons.visible = true
	buttons[0].grab_focus()

func _on_tutorial_button_pressed() -> void:
	button_selected.emit()
	button_type = "tutorial"
	menu_buttons.visible = false
	back_button.visible = true
	tutorial.visible = true
	buttons[0].grab_focus()

func _on_credits_button_pressed() -> void:
	button_selected.emit()
	button_type = "credits"
	menu_buttons.visible = false
	back_button.visible = true
	credits.visible = true
	buttons[0].grab_focus()

func _on_quit_button_pressed() -> void:
	button_selected.emit()
	button_type = "quit"
	get_tree().quit()

# Sub-Menu Buttons
func _on_back_button_pressed() -> void:
	button_selected.emit()
	button_type = "back"
	button_type = "exit"
	back_button.visible = false
	menu_buttons.visible = true
	level_buttons.visible = false
	tutorial.visible = false
	credits.visible = false
	buttons[1].grab_focus()

func _on_level_1_button_pressed() -> void:
	button_selected.emit()
	button_type = "level_1"
	_game_started(0)

func _on_level_2_button_pressed() -> void:
	button_selected.emit()
	button_type = "level_2"
	_game_started(1)

func _on_level_3_button_pressed() -> void:
	button_selected.emit()
	button_type = "level_3"
	_game_started(2)

func _game_started(level: int) -> void:
	await %AnimationManager.play_scene_change_transition()
	await scene_manager.load_level(level)
	await %AnimationManager.play_reset()
	visible = false
