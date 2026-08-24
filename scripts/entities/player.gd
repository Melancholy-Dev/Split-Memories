class_name Player extends GridEntity

# Nodes
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

# Variables
@export var sprite_frames: SpriteFrames
@export var is_player_one := true


func _ready() -> void:
	animated_sprite.sprite_frames = sprite_frames

func is_pushable() -> bool:
	return false

func blocks_movement() -> bool:
	return true
