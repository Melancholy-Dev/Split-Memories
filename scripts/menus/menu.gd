class_name Menu extends Control

# Signals
signal button_focus_entered
signal button_selected

# Nodes
@export var initial_focus: Button
@onready var buttons: Array[Button] = []

# Variables
var _last_focused: Control = null
var _focus_navigation_enabled := true
var _focus_sound_enabled := true


func _ready() -> void:
	for node in find_children("*", "Button", true, false):
		if node.is_in_group("ui_button"):
			var button := node as Button
			buttons.append(button)
			button.focus_entered.connect(_on_button_focus_entered)
	InputManager.input_method_changed.connect(_on_input_method_changed)
	_set_focus_navigation_enabled(not InputManager.is_touch_active())
	call_deferred("_focus_initial_node")
	_last_focused = get_viewport().gui_get_focus_owner()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_focus_sound_enabled = true
	elif event is InputEventJoypadButton and event.pressed:
		_focus_sound_enabled = true
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.2:
		_focus_sound_enabled = true
	elif event is InputEventMouseButton and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION:
		_focus_sound_enabled = false
	elif event is InputEventScreenTouch and event.pressed:
		_focus_sound_enabled = false

func _on_input_method_changed() -> void:
	var touch_active := InputManager.is_touch_active()
	_focus_sound_enabled = InputManager.is_controller_active()
	_set_focus_navigation_enabled(not touch_active)

func _set_focus_navigation_enabled(enabled: bool) -> void:
	if _focus_navigation_enabled == enabled:
		return
	_focus_navigation_enabled = enabled
	for button in buttons:
		if button.disabled:
			button.focus_mode = Control.FOCUS_NONE
		else:
			button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	if enabled:
		var focus_owner := get_viewport().gui_get_focus_owner()
		if focus_owner == null or not focus_owner.is_visible_in_tree():
			_focus_initial_node()
	else:
		get_viewport().gui_release_focus()

func _focus_initial_node() -> void:
	if not _focus_navigation_enabled:
		return
	if visible and is_instance_valid(initial_focus) and initial_focus.is_visible_in_tree() and not initial_focus.disabled:
		initial_focus.focus_mode = Control.FOCUS_ALL
		initial_focus.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_ENABLED
		_last_focused = initial_focus
		initial_focus.grab_focus()
		return
	for button in buttons:
		if button.is_visible_in_tree() and not button.disabled and button.focus_mode != Control.FOCUS_NONE:
			_last_focused = button
			button.grab_focus()
			return


func _focus_button(index: int) -> void:
	if index >= 0 and index < buttons.size():
		buttons[index].grab_focus()

func _on_button_focus_entered() -> void:
	var button = get_viewport().gui_get_focus_owner()
	if button == _last_focused:
		return
	_last_focused = button
	if _focus_sound_enabled:
		button_focus_entered.emit()

func _button_selected() -> void:
	button_selected.emit()
