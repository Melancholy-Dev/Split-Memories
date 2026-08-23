class_name GridEntity extends Node2D

# Signals
signal grid_position_changed(old_position: Vector2i, new_position: Vector2i)

# Variables
@export var initial_grid_position: Vector2i
var grid_position: Vector2i
var board: Grid


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
	return true

func can_be_pushed() -> bool:
	return is_pushable()
