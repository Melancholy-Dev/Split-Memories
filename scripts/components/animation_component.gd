class_name AnimationComponent extends Node

# Nodes
@export var player: Player
@export var animated_sprite: AnimatedSprite2D
@export var movement_component: MovementComponent

# Animations Costants
const IDLE_UP: StringName = &"idle_up"
const IDLE_DOWN: StringName = &"idle_down"
const IDLE_LEFT: StringName = &"idle_left"
const IDLE_RIGHT: StringName = &"idle_right"
const MOVE_UP: StringName = &"move_up"
const MOVE_DOWN: StringName = &"move_down"
const MOVE_LEFT: StringName = &"move_left"
const MOVE_RIGHT: StringName = &"move_right"

# Variables
var last_direction := Vector2i.DOWN


func _ready() -> void:
	movement_component.movement_started.connect(play_move_animation)
	movement_component.movement_blocked.connect(play_idle_animation)
	movement_component.movement_finished.connect(_on_movement_finished)
	last_direction = _get_direction(animated_sprite.animation)
	play_idle_animation()

func _process(_delta: float) -> void:
	if movement_component.is_moving:
		return
	if not _is_direction_held(last_direction):
		play_idle_animation()

func play_move_animation(direction: Vector2i) -> void:
	last_direction = direction
	var animation_name := _get_animation_name(direction)
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)

func play_idle_animation() -> void:
	var animation_name := _get_animation_name(last_direction, true)
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)

func _on_movement_finished() -> void:
	if not _is_direction_held(last_direction):
		play_idle_animation()

func _is_direction_held(direction: Vector2i) -> bool:
	return InputManager.is_direction_pressed(player.is_player_one, direction)

func _get_animation_name(direction: Vector2i, idle: bool = false) -> StringName:
	match direction:
		Vector2i.UP:
			return IDLE_UP if idle else MOVE_UP
		Vector2i.DOWN:
			return IDLE_DOWN if idle else MOVE_DOWN
		Vector2i.LEFT:
			return IDLE_LEFT if idle else MOVE_LEFT
		Vector2i.RIGHT:
			return IDLE_RIGHT if idle else MOVE_RIGHT
		_:
			return &"RESET"

func _get_direction(animation_name: StringName) -> Vector2i:
	match animation_name:
		IDLE_UP, MOVE_UP:
			return Vector2i.UP
		IDLE_LEFT, MOVE_LEFT:
			return Vector2i.LEFT
		IDLE_RIGHT, MOVE_RIGHT:
			return Vector2i.RIGHT
		_:
			return Vector2i.DOWN
