class_name AnimationComponent extends Node

# Nodes
@export var player: Player
@export var animated_sprite: AnimatedSprite2D

# Variables
var last_direction := Vector2i.DOWN
var movement_component: MovementComponent


func _ready() -> void:
	movement_component = player.get_node("Components/MovementComponent") as MovementComponent
	movement_component.movement_started.connect(play_move_animation)
	movement_component.movement_finished.connect(_on_movement_finished)
	last_direction = _get_direction(animated_sprite.animation)
	play_idle_animation()

func _process(_delta: float) -> void:
	if movement_component.is_moving:
		return
	if _is_direction_held(last_direction):
		animated_sprite.play(_get_animation_name(last_direction))
	else:
		play_idle_animation()

func play_move_animation(direction: Vector2i) -> void:
	last_direction = direction
	var animation_name := _get_animation_name(direction)
	animated_sprite.play(animation_name)

func play_idle_animation() -> void:
	animated_sprite.play(_get_animation_name(last_direction, true))

func _on_movement_finished() -> void:
	if not _is_direction_held(last_direction):
		play_idle_animation()

func _is_direction_held(direction: Vector2i) -> bool:
	var player_suffix: String
	if player.is_player_one:
		player_suffix = "p1"
	else:
		player_suffix = "p2"
	match direction:
		Vector2i.UP:
			return Input.is_action_pressed("move_up_" + player_suffix)
		Vector2i.DOWN:
			return Input.is_action_pressed("move_down_" + player_suffix)
		Vector2i.LEFT:
			return Input.is_action_pressed("move_left_" + player_suffix)
		Vector2i.RIGHT:
			return Input.is_action_pressed("move_right_" + player_suffix)
		_:
			return false

func _get_animation_name(direction: Vector2i, idle: bool = false) -> StringName:
	var prefix: StringName
	if idle:
		prefix = "idle_"
	else:
		prefix = "move_"
	match direction:
		Vector2i.UP:
			return StringName(prefix + "up")
		Vector2i.DOWN:
			return StringName(prefix + "down")
		Vector2i.LEFT:
			return StringName(prefix + "left")
		Vector2i.RIGHT:
			return StringName(prefix + "right")
		_:
			return &"RESET"

func _get_direction(animation_name: StringName) -> Vector2i:
	match animation_name:
		&"idle_up", &"move_up":
			return Vector2i.UP
		&"idle_left", &"move_left":
			return Vector2i.LEFT
		&"idle_right", &"move_right":
			return Vector2i.RIGHT
		_:
			return Vector2i.DOWN
