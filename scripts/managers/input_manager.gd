extends Node # Autoload Singleton class

# Signals
signal input_method_changed
signal direction_pressed_p1(direction: Vector2i)
signal direction_pressed_p2(direction: Vector2i)
signal undo_pressed
signal pause_pressed

# Nodes
@onready var pause_menu: PauseMenu = get_tree().get_first_node_in_group("pause_menu")
@onready var main_menu: MainMenu = get_tree().get_first_node_in_group("main_menu")
@onready var animation_manager: AnimationManager = get_tree().get_first_node_in_group("animation_manager")
@onready var scene_manager: SceneManager = get_tree().get_first_node_in_group("scene_manager")

# Variables
var _input_reading_enabled := true
var _is_controller_active := false
var _is_touch_active := false
var _level_touch_controls_visible := false
var _active_controller_id := -1
var _last_held_direction_p1 := Vector2i.ZERO
var _last_held_direction_p2 := Vector2i.ZERO
const CONTROLLER_DEADZONE := 0.2
const DIRECTION_AXIS_HYSTERESIS := 0.1

# Input Costants
const MOVE_UP_P1: StringName = &"move_up_p1"
const MOVE_DOWN_P1: StringName = &"move_down_p1"
const MOVE_LEFT_P1: StringName = &"move_left_p1"
const MOVE_RIGHT_P1: StringName = &"move_right_p1"
const MOVE_UP_P2: StringName = &"move_up_p2"
const MOVE_DOWN_P2: StringName = &"move_down_p2"
const MOVE_LEFT_P2: StringName = &"move_left_p2"
const MOVE_RIGHT_P2: StringName = &"move_right_p2"
const UNDO: StringName = &"undo"
const PAUSE: StringName = &"pause"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var connected_joypads := Input.get_connected_joypads()
	if not connected_joypads.is_empty():
		_active_controller_id = connected_joypads.front()
		_is_controller_active = true
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_connect_scene_manager()
	_connect_control_buttons()
	animation_manager.touch_buttons_animation_finished.connect(_on_touch_buttons_animation_finished)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION:
		_set_touch_active()
	elif event is InputEventScreenDrag and event.device != InputEvent.DEVICE_ID_EMULATION:
		_set_touch_active()
	elif event is InputEventKey and event.pressed and not event.echo:
		_set_input_method(false)
	elif event is InputEventMouseButton and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION:
		_set_input_method(false)
	elif event is InputEventJoypadButton and event.pressed:
		_set_input_method(true, event.device)
	elif event is InputEventJoypadMotion and absf(event.axis_value) >= CONTROLLER_DEADZONE:
		_set_input_method(true, event.device)

func _set_input_method(controller_active: bool, controller_id := -1) -> void:
	var changed: bool
	if controller_active:
		var connected_joypads := Input.get_connected_joypads()
		if not connected_joypads.has(controller_id):
			if connected_joypads.is_empty():
				return
			controller_id = connected_joypads.front()
		changed = not _is_controller_active or _is_touch_active or _active_controller_id != controller_id
		_is_controller_active = true
		_is_touch_active = false
		_active_controller_id = controller_id
		if changed:
			input_method_changed.emit()
	else:
		changed = _is_controller_active or _is_touch_active
		_is_controller_active = false
		_is_touch_active = false
		if changed:
			input_method_changed.emit()

func _set_touch_active() -> void:
	if _is_touch_active and not _is_controller_active:
		return
	_is_controller_active = false
	_is_touch_active = true
	input_method_changed.emit()

func is_controller_active() -> bool:
	return _is_controller_active

func is_touch_active() -> bool:
	return _is_touch_active

func set_level_touch_buttons_visible(visible: bool) -> void:
	if _level_touch_controls_visible == visible:
		return
	_level_touch_controls_visible = visible
	for node in get_tree().get_nodes_in_group("level_touch_buttons"):
		var button := node as TouchScreenButton
		if button != null:
			button.set_process_input(visible)
			if visible:
				button.visible = true
			elif node.is_in_group("movement_touch_buttons"):
				button.visible = false
	animation_manager.play_touch_buttons_animation(visible)

func _on_touch_buttons_animation_finished(visible: bool) -> void:
	if visible or _level_touch_controls_visible:
		return
	for node in get_tree().get_nodes_in_group("level_touch_buttons"):
		var button := node as TouchScreenButton
		if button != null:
			button.visible = false

func get_controller_undo_label() -> String:
	var controller_name := _get_active_controller_name()
	if _is_playstation_controller(controller_name):
		return "X"
	if _is_nintendo_controller(controller_name):
		return "B"
	return "A"

func get_controller_pause_label() -> String:
	var controller_name := _get_active_controller_name()
	if _is_playstation_controller(controller_name):
		if "ps3" in controller_name:
			return "Start"
		return "Options"
	if _is_nintendo_controller(controller_name):
		return "+"
	return "Start"

func _get_active_controller_name() -> String:
	var connected_joypads := Input.get_connected_joypads()
	if connected_joypads.has(_active_controller_id):
		return Input.get_joy_name(_active_controller_id).to_lower()
	if not connected_joypads.is_empty():
		return Input.get_joy_name(connected_joypads.front()).to_lower()
	return ""

func _is_playstation_controller(controller_name: String) -> bool:
	return (
		"playstation" in controller_name
		or "sony" in controller_name
		or "dualshock" in controller_name
		or "dualsense" in controller_name
		or "ps3" in controller_name
		or "ps4" in controller_name
		or "ps5" in controller_name
	)

func _is_nintendo_controller(controller_name: String) -> bool:
	return (
		"nintendo" in controller_name
		or "switch" in controller_name
		or "joy-con" in controller_name
		or "joycon" in controller_name
	)

func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		if _active_controller_id == -1:
			_active_controller_id = device
			if _is_controller_active:
				input_method_changed.emit()
		return
	if device != _active_controller_id:
		return

	var connected_joypads := Input.get_connected_joypads()
	if connected_joypads.is_empty():
		_active_controller_id = -1
		if _is_controller_active:
			_is_controller_active = false
			input_method_changed.emit()
	else:
		_active_controller_id = connected_joypads.front()
		if _is_controller_active:
			input_method_changed.emit()

func _process(_delta: float) -> void:
	if not _can_move():
		return
	var direction_p1 := _get_held_direction(true)
	if direction_p1 != Vector2i.ZERO:
		direction_pressed_p1.emit(direction_p1)
	var direction_p2 := _get_held_direction(false)
	if direction_p2 != Vector2i.ZERO:
		direction_pressed_p2.emit(direction_p2)

func _connect_scene_manager() -> void:
	scene_manager.loading_level.connect(_disable_input_reading)
	scene_manager.level_loaded.connect(_enabling_input_reading)

func _connect_control_buttons() -> void:
	for node in get_tree().get_nodes_in_group("pause_control_button"):
		var pause_button := node as Button
		if pause_button != null:
			pause_button.pressed.connect(_on_pause_button_pressed)
	for node in get_tree().get_nodes_in_group("undo_control_button"):
		var undo_button := node as Button
		if undo_button != null:
			undo_button.pressed.connect(_on_undo_button_pressed)

func _on_pause_button_pressed() -> void:
	if (main_menu == null or not main_menu.visible) and _can_pause():
		pause_pressed.emit()

func _on_undo_button_pressed() -> void:
	if _can_move():
		undo_pressed.emit()

func _disable_input_reading() -> void:
	_input_reading_enabled = false
	set_process_unhandled_input(false)
	set_level_touch_buttons_visible(false)

func _enabling_input_reading() -> void:
	_input_reading_enabled = true
	set_process_unhandled_input(true)
	set_level_touch_buttons_visible(
		is_instance_valid(scene_manager.current_level)
		and (main_menu == null or not main_menu.visible)
		and (pause_menu == null or not pause_menu.is_paused)
	)

func _unhandled_input(event: InputEvent) -> void:
	if main_menu != null and main_menu.visible:
		return
	if event.is_action_pressed(PAUSE):
		if _can_pause():
			pause_pressed.emit()
		return
	if not _can_move():
		return
	if event.is_action_pressed(UNDO):
		undo_pressed.emit()

func is_direction_pressed(player_one: bool, direction: Vector2i) -> bool:
	match direction:
		Vector2i.UP:
			return Input.is_action_pressed(MOVE_UP_P1 if player_one else MOVE_UP_P2)
		Vector2i.DOWN:
			return Input.is_action_pressed(MOVE_DOWN_P1 if player_one else MOVE_DOWN_P2)
		Vector2i.LEFT:
			return Input.is_action_pressed(MOVE_LEFT_P1 if player_one else MOVE_LEFT_P2)
		Vector2i.RIGHT:
			return Input.is_action_pressed(MOVE_RIGHT_P1 if player_one else MOVE_RIGHT_P2)
		_:
			return false

func can_move() -> bool:
	return _can_move()

func _get_held_direction(player_one: bool) -> Vector2i:
	var movement := Input.get_vector(
		MOVE_LEFT_P1 if player_one else MOVE_LEFT_P2,
		MOVE_RIGHT_P1 if player_one else MOVE_RIGHT_P2,
		MOVE_UP_P1 if player_one else MOVE_UP_P2,
		MOVE_DOWN_P1 if player_one else MOVE_DOWN_P2
	)
	if movement.is_zero_approx():
		if player_one:
			_last_held_direction_p1 = Vector2i.ZERO
		else:
			_last_held_direction_p2 = Vector2i.ZERO
		return Vector2i.ZERO

	var last_direction := _last_held_direction_p1 if player_one else _last_held_direction_p2
	var horizontal_strength := absf(movement.x)
	var vertical_strength := absf(movement.y)
	var use_horizontal_axis: bool
	if horizontal_strength > vertical_strength + DIRECTION_AXIS_HYSTERESIS:
		use_horizontal_axis = true
	elif vertical_strength > horizontal_strength + DIRECTION_AXIS_HYSTERESIS:
		use_horizontal_axis = false
	elif last_direction.x != 0:
		use_horizontal_axis = true
	elif last_direction.y != 0:
		use_horizontal_axis = false
	else:
		use_horizontal_axis = horizontal_strength > vertical_strength

	var direction := Vector2i.ZERO
	if use_horizontal_axis:
		direction = Vector2i.RIGHT if movement.x > 0.0 else Vector2i.LEFT
	else:
		direction = Vector2i.DOWN if movement.y > 0.0 else Vector2i.UP

	if player_one:
		_last_held_direction_p1 = direction
	else:
		_last_held_direction_p2 = direction
	return direction

func _can_move() -> bool:
	if not _input_reading_enabled:
		return false
	if main_menu != null and main_menu.visible:
		return false
	if pause_menu != null and pause_menu.is_paused:
		return false
	return animation_manager == null or not animation_manager.is_animating

func _can_pause() -> bool:
	if not _input_reading_enabled:
		return false
	if animation_manager != null and animation_manager.is_animating:
		return false
	for movement_component in get_tree().get_nodes_in_group("movement_components"):
		if movement_component.is_moving:
			return false
	return true
