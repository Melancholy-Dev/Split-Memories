extends Node # Autoload Singleton class

# Signals
signal direction_pressed_p1(direction: Vector2i)
signal direction_pressed_p2(direction: Vector2i)


func _unhandled_input(event: InputEvent) -> void:
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
