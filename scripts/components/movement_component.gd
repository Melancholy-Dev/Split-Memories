class_name MovementComponent extends Node

# Signals
signal movement_started(direction: Vector2i)
signal movement_finished
signal movement_blocked

# Nodes
@export var player: Player
var board: Grid

# Variables
var movement_duration := 0.2
var is_moving := false
var _active_direction := Vector2i.ZERO
var _pending_direction := Vector2i.ZERO


func _ready() -> void:
	if player.is_player_one:
		InputManager.direction_pressed_p1.connect(_on_direction_pressed)
	else:
		InputManager.direction_pressed_p2.connect(_on_direction_pressed)

func _on_direction_pressed(direction: Vector2i) -> void:
	if not InputManager.can_move():
		_pending_direction = Vector2i.ZERO
		return
	if UndoManager.is_undoing():
		_pending_direction = Vector2i.ZERO
		return
	if is_moving:
		_pending_direction = direction if direction != _active_direction else Vector2i.ZERO
		return
	board = player.board
	if board == null:
		return
	_active_direction = direction
	is_moving = true
	var previous_state := UndoManager.capture_state()
	var moved_entities := board.try_move_player(player, direction)
	if moved_entities.size() > 1:
		UndoManager.commit_state(previous_state)
	if moved_entities.is_empty():
		movement_blocked.emit()
		await get_tree().create_timer(movement_duration).timeout
	else:
		movement_started.emit(direction)
		await _animate_entities(moved_entities)
	board.notify_player_step_completed()
	movement_finished.emit()
	is_moving = false
	var buffered_direction := _pending_direction
	_pending_direction = Vector2i.ZERO
	if buffered_direction != Vector2i.ZERO and not UndoManager.is_undoing():
		call_deferred("_on_direction_pressed", buffered_direction)

func _animate_entities(entities: Array[GridEntity]) -> void:
	for entity in entities:
		var start_position := entity.position.round()
		var target_position := board.cell_to_world(entity.grid_position).round()
		entity.position = start_position
		var tween := entity.create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.tween_method(
			func(progress: float) -> void:
				entity.position = start_position.lerp(target_position, progress).round(),
			0.0,
			1.0,
			movement_duration
		)

	await get_tree().create_timer(movement_duration).timeout
	for entity in entities:
		entity.position = board.cell_to_world(entity.grid_position).round()
