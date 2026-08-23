class_name MovementComponent extends Node

# Nodes
@export var player: Player
@export var board: Grid

# Variables
var movement_duration := 0.12
var is_moving := false


func _ready() -> void:
	if player.is_player_one:
		InputManager.direction_pressed_p1.connect(_on_direction_pressed)
	else:
		InputManager.direction_pressed_p2.connect(_on_direction_pressed)

func _on_direction_pressed(direction: Vector2i) -> void:
	if is_moving or UndoManager.is_undoing():
		return

	is_moving = true
	var previous_state := UndoManager.capture_state()
	var moved_entities := board.try_move_player(player, direction)
	if not moved_entities.is_empty():
		UndoManager.commit_state(previous_state)

	if moved_entities.is_empty():
		await get_tree().create_timer(movement_duration).timeout
	else:
		await _animate_entities(moved_entities)

	is_moving = false

func _animate_entities(entities: Array[GridEntity]) -> void:
	for entity in entities:
		var target_position := board.cell_to_world(entity.grid_position)
		var tween := entity.create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(
			entity,
			"position",
			target_position,
			movement_duration
		)

	await get_tree().create_timer(movement_duration).timeout
