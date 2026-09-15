class_name Menu extends Control

# Signals
signal button_focus_entered
signal button_selected

# Nodes
@export var initial_focus: Button
@onready var buttons: Array[Button] = []

# Variables
var _last_focused: Control = null


func _ready() -> void:
	for node in find_children("*", "Button", true, false):
		if node.is_in_group("ui_button"):
			var button := node as Button
			buttons.append(button)
			button.focus_entered.connect(_on_button_focus_entered)
	call_deferred("_focus_initial_node")
	_last_focused = get_viewport().gui_get_focus_owner()

func _focus_initial_node() -> void:
	if visible and is_instance_valid(initial_focus):
		initial_focus.focus_mode = Control.FOCUS_ALL
		initial_focus.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_ENABLED
		_last_focused = initial_focus
		initial_focus.grab_focus()


func _focus_button(index: int) -> void:
	if index >= 0 and index < buttons.size():
		buttons[index].grab_focus()

func _on_button_focus_entered() -> void:
	var button = get_viewport().gui_get_focus_owner()
	if button == _last_focused:
		return
	_last_focused = button
	button_focus_entered.emit()

func _button_selected() -> void:
	button_selected.emit()
