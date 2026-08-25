class_name PushableObject extends GridEntity

@export var object_type: String = ""

func is_pushable() -> bool:
	return true

func blocks_movement() -> bool:
	return true
