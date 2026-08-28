class_name GridEntity extends Node2D

# Signals
signal grid_position_changed(old_position: Vector2i, new_position: Vector2i)

# Variables
@export var can_be_disabled := false
var initial_grid_position: Vector2i
var grid_position: Vector2i
var board: Grid
var is_disabled := false


func init(_board: Grid, _position: Vector2i) -> void:
	board = _board
	initial_grid_position = _position
	grid_position = _position
	position = board.cell_to_world(grid_position)

func set_grid_position(new_position: Vector2i) -> void:
	var old_position := grid_position
	grid_position = new_position
	grid_position_changed.emit(old_position, new_position)

func is_pushable() -> bool: # Override
	return false

func blocks_movement() -> bool: # Override
	return not is_disabled

func can_be_pushed() -> bool:
	return is_pushable()

func disable() -> void:
	if not can_be_disabled:
		return
	is_disabled = true
	visible = false

func enable() -> void:
	if not can_be_disabled:
		return
	is_disabled = false
	visible = true
	if board != null:
		board.move_entities_out_of_cell(grid_position, self)
