class_name PushableObject extends GridEntity

# Nodes
@onready var sprite: Sprite2D = $Sprite

# Variables
@export var texture: Texture2D
@export var object_type: String = ""


func _ready() -> void:
	sprite.texture = texture

func is_pushable() -> bool:
	return true

func blocks_movement() -> bool:
	return true
