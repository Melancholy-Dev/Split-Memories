extends Node # Autoload Singleton class

# Signals
signal direction_pressed_p1(direction: Vector2i)
signal direction_pressed_p2(direction: Vector2i)
signal undo_pressed
signal pause_pressed

# Nodes
@onready var pause_menu: PauseMenu = get_tree().get_first_node_in_group("pause_menu")
@onready var main_menu: MainMenu = get_tree().get_first_node_in_group("main_menu")
@onready var animation_manager: AnimationManager = get_tree().get_first_node_in_group("animation_manager")
@onready var scene_manager: SceneManager = get_tree().get_first_node_in_group("scene_manager")
var _input_reading_enabled := true

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
	_connect_scene_manager()

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

func _disable_input_reading() -> void:
	_input_reading_enabled = false
	set_process_unhandled_input(false)

func _enabling_input_reading() -> void:
	_input_reading_enabled = true
	set_process_unhandled_input(true)

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

func _get_held_direction(player_one: bool) -> Vector2i:
	if is_direction_pressed(player_one, Vector2i.UP):
		return Vector2i.UP
	if is_direction_pressed(player_one, Vector2i.DOWN):
		return Vector2i.DOWN
	if is_direction_pressed(player_one, Vector2i.LEFT):
		return Vector2i.LEFT
	if is_direction_pressed(player_one, Vector2i.RIGHT):
		return Vector2i.RIGHT
	return Vector2i.ZERO

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
