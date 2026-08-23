class_name AnimationComponent extends Node

# Nodes
@export var player: Player
@export var animated_sprite: AnimatedSprite2D
@export var sprite_frames: SpriteFrames
@onready var movement_component: MovementComponent = %MovementComponent


func _ready() -> void:
	animated_sprite.sprite_frames = sprite_frames
	if player.is_player_one:
		InputManager.direction_pressed_p1.connect(play_move_animation)
	else:
		InputManager.direction_pressed_p2.connect(play_move_animation)

func play_move_animation(direction: Vector2i) -> void:
	var animation_name := _get_animation_name(direction)
	animated_sprite.play(animation_name)

func _get_animation_name(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP:
			return &"move_up"
		Vector2i.DOWN:
			return &"move_down"
		Vector2i.LEFT:
			return &"move_left"
		Vector2i.RIGHT:
			return &"move_right"
		_:
			return &"RESET"
