class_name SceneManager extends Node

# Signals
signal loading_level()
signal level_loaded()
signal main_menu_requested()
signal level_started(level: int)

# Nodes
@export var levels_root: Node2D
@export var level_scenes: Array[PackedScene] = []
@export var puzzle_completed_label: Label

# Variables
var current_level: Node
var current_level_index := 0


func request_main_menu() -> void:
	main_menu_requested.emit()

func load_level(index: int) -> void:
	if index < 0 or index >= level_scenes.size():
		return
	if is_instance_valid(current_level):
		UndoManager.clear_boards()
		current_level.queue_free()
	current_level = level_scenes[index].instantiate()
	levels_root.add_child(current_level)
	current_level_index = index
	level_started.emit(index)
	if current_level is PuzzleManager:
		var puzzle_manager := current_level as PuzzleManager
		puzzle_manager.puzzle_completed.connect(_on_puzzle_completed)

func _on_puzzle_completed() -> void:
	loading_level.emit()
	await %AnimationManager.play_scene_change_transition(puzzle_completed_label)
	if current_level_index + 1 < level_scenes.size():
		load_level(current_level_index + 1)
		await %AnimationManager.play_loading_new_level_transition()
		level_loaded.emit()
	else:
		UndoManager.clear_boards()
		if is_instance_valid(current_level):
			current_level.queue_free()
		current_level = null
		await %AnimationManager.play_final_screen()
		request_main_menu()
		await %AnimationManager.play_reset()
		level_loaded.emit()
