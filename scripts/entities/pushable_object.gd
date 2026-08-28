class_name PushableObject extends GridEntity

# Variables
@export var object_type: String = ""


func _ready() -> void:
	if get_node_or_null("Components/AudioComponent") != null:
		return

func is_pushable() -> bool:
	return true

func blocks_movement() -> bool:
	return not is_disabled
