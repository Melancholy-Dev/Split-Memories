class_name PuzzleManager extends Node2D

signal puzzle_completed

# Nodes
@onready var objects_1: Node = $Side_1/Entities/PushableObjects
@onready var objects_2: Node = $Side_2/Entities/PushableObjects

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
	if _get_objects_state(objects_1) == _get_objects_state(objects_2):
		puzzle_solved = true
		_on_puzzle_solved()

func _get_objects_state(container: Node) -> Array[String]:
	var state: Array[String] = []
	for child in container.get_children():
		var object := child as PushableObject
		if object != null:
			state.append("%s:%d,%d" % [object.object_type, object.grid_position.x, object.grid_position.y])
	state.sort()
	return state

func _on_puzzle_solved() -> void:
	puzzle_completed.emit()
