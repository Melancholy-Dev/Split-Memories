class_name StaticObject extends GridEntity

# Nodes
@onready var sprite: Sprite2D = $Sprite

# Variables
@export var texture: Texture2D


func _ready() -> void:
	sprite.texture = texture

func is_pushable() -> bool:
	return false

func blocks_movement() -> bool:
	return true
