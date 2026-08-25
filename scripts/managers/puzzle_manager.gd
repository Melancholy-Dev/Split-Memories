class_name PuzzleManager extends Node2D

signal puzzle_completed

# Nodes
@onready var objects_1: Node = $Side_1/Entities/PushableObjects
@onready var objects_2: Node = $Side_2/Entities/PushableObjects
@onready var grid_1: Grid = $Side_1/Grid_1
@onready var grid_2: Grid = $Side_2/Grid_2

# Variables
var puzzle_solved := false


func _ready() -> void:
	for container in [objects_1, objects_2]:
		for child in container.get_children():
			var object: PushableObject = null
			if child is PushableObject:
				object = child
			if object != null:
				object.grid_position_changed.connect(_on_object_position_changed)

func _on_object_position_changed(_old_position: Vector2i, _new_position: Vector2i) -> void:
	call_deferred("check_puzzle_solution") # Function called at the end

func check_puzzle_solution() -> void:
	if puzzle_solved:
		return
	if _get_objects_state(objects_1, grid_1) == _get_objects_state(objects_2, grid_2, true):
		puzzle_solved = true
		_on_puzzle_solved()

func _get_objects_state(container: Node, grid: Grid, mirror_horizontal: bool = false) -> Array[String]:
	var state: Array[String] = []
	for child in container.get_children():
		var object := child as PushableObject
		if object != null:
			var cell := object.grid_position
			if mirror_horizontal:
				cell.x = grid.grid_size.x - 1 - cell.x
			state.append("%s:%d,%d" % [object.object_type, cell.x, cell.y])
	state.sort()
	return state

func _on_puzzle_solved() -> void:
	puzzle_completed.emit()
