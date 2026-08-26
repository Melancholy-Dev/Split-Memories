extends Node # Autoload Singleton class

# Signals
signal direction_pressed_p1(direction: Vector2i)
signal direction_pressed_p2(direction: Vector2i)
signal undo_pressed
signal pause_pressed

# Nodes
@onready var pm := get_tree().get_first_node_in_group("pause_menu")
@onready var main_menu := get_tree().get_first_node_in_group("main_menu")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_scene_manager()

func _connect_scene_manager() -> void:
	var scene_manager := get_tree().get_first_node_in_group("scene_manager")
	scene_manager.loading_level.connect(_disable_input_reading)
	scene_manager.level_loaded.connect(_enabling_input_reading)

func _disable_input_reading() -> void:
	set_process_unhandled_input(false)

func _enabling_input_reading() -> void:
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if main_menu.visible:
		return

	if event.is_action_pressed("pause"):
		pause_pressed.emit()
	
	if event.is_action_pressed("move_up_p1") and not pm.is_paused:
		direction_pressed_p1.emit(Vector2i.UP)
	elif event.is_action_pressed("move_down_p1") and not pm.is_paused:
		direction_pressed_p1.emit(Vector2i.DOWN)
	elif event.is_action_pressed("move_left_p1") and not pm.is_paused:
		direction_pressed_p1.emit(Vector2i.LEFT)
	elif event.is_action_pressed("move_right_p1") and not pm.is_paused:
		direction_pressed_p1.emit(Vector2i.RIGHT)
	
	if event.is_action_pressed("move_up_p2") and not pm.is_paused:
		direction_pressed_p2.emit(Vector2i.UP)
	elif event.is_action_pressed("move_down_p2") and not pm.is_paused:
		direction_pressed_p2.emit(Vector2i.DOWN)
	elif event.is_action_pressed("move_left_p2") and not pm.is_paused:
		direction_pressed_p2.emit(Vector2i.LEFT)
	elif event.is_action_pressed("move_right_p2") and not pm.is_paused:
		direction_pressed_p2.emit(Vector2i.RIGHT)

	if event.is_action_pressed("undo") and not pm.is_paused:
		undo_pressed.emit()
