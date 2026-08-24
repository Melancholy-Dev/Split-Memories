class_name PushableObject extends GridEntity

# Nodes
@onready var sprite: Sprite2D = $Sprite

# Variables
@export var texture: Texture2D
var object_type: String = ""


func _ready() -> void:
	sprite.texture = texture
	if texture:
		if texture.resource_name != "":
			object_type = texture.resource_name
		else:
			push_error("Texture Not Assigned")

func is_pushable() -> bool:
	return true

func blocks_movement() -> bool:
	return true
