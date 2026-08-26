extends Node # Autoload Singleton class

# Signals
signal direction_pressed_p1(direction: Vector2i)
signal direction_pressed_p2(direction: Vector2i)
signal undo_pressed
signal pause_pressed

# Nodes
@onready var pm := get_tree().get_first_node_in_group("pause_menu")
@onready var main_menu := get_tree().get_first_node_in_group("main_menu")
var _input_reading_enabled := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_scene_manager()

func _process(_delta: float) -> void:
	if not _can_move():
		return
	var direction_p1 := _get_held_direction("p1")
	if direction_p1 != Vector2i.ZERO:
		direction_pressed_p1.emit(direction_p1)
	var direction_p2 := _get_held_direction("p2")
	if direction_p2 != Vector2i.ZERO:
		direction_pressed_p2.emit(direction_p2)

func _connect_scene_manager() -> void:
	var scene_manager := get_tree().get_first_node_in_group("scene_manager")
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
	if event.is_action_pressed("pause"):
		if _can_pause():
			pause_pressed.emit()
		return
	if not _can_move():
		return
	if event.is_action_pressed("move_up_p1"):
		direction_pressed_p1.emit(Vector2i.UP)
	elif event.is_action_pressed("move_down_p1"):
		direction_pressed_p1.emit(Vector2i.DOWN)
	elif event.is_action_pressed("move_left_p1"):
		direction_pressed_p1.emit(Vector2i.LEFT)
	elif event.is_action_pressed("move_right_p1"):
		direction_pressed_p1.emit(Vector2i.RIGHT)
	if event.is_action_pressed("move_up_p2"):
		direction_pressed_p2.emit(Vector2i.UP)
	elif event.is_action_pressed("move_down_p2"):
		direction_pressed_p2.emit(Vector2i.DOWN)
	elif event.is_action_pressed("move_left_p2"):
		direction_pressed_p2.emit(Vector2i.LEFT)
	elif event.is_action_pressed("move_right_p2"):
		direction_pressed_p2.emit(Vector2i.RIGHT)

	if event.is_action_pressed("undo"):
		undo_pressed.emit()

func _get_held_direction(player_suffix: String) -> Vector2i:
	if Input.is_action_pressed("move_up_" + player_suffix):
		return Vector2i.UP
	if Input.is_action_pressed("move_down_" + player_suffix):
		return Vector2i.DOWN
	if Input.is_action_pressed("move_left_" + player_suffix):
		return Vector2i.LEFT
	if Input.is_action_pressed("move_right_" + player_suffix):
		return Vector2i.RIGHT
	return Vector2i.ZERO

func _can_move() -> bool:
	if not _input_reading_enabled:
		return false
	if main_menu != null and main_menu.visible:
		return false
	if pm != null and pm.is_paused:
		return false
	var animation_manager := get_tree().get_first_node_in_group("animation_manager")
	return animation_manager == null or not animation_manager.is_animating

func _can_pause() -> bool:
	if not _input_reading_enabled:
		return false
	var animation_manager := get_tree().get_first_node_in_group("animation_manager")
	if animation_manager != null and animation_manager.is_animating:
		return false
	for movement_component in get_tree().get_nodes_in_group("movement_components"):
		if movement_component.is_moving:
			return false
	return true
