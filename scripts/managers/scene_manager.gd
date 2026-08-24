class_name SceneManager extends Node

# Signals
signal loading_level()
signal level_loaded()

# Nodes
@export var animation_player: AnimationPlayer
@export var levels_root: Node2D
@export var level_scenes: Array[PackedScene] = []

# Variables
var current_level: Node
var current_level_index := 0
var is_changing_level := false


func _ready() -> void:
	_load_level(0)

func _load_level(index: int) -> void:
	if index < 0 or index >= level_scenes.size():
		return
	if is_instance_valid(current_level):
		UndoManager.clear_boards()
		current_level.queue_free()
		await get_tree().process_frame
	current_level = level_scenes[index].instantiate()
	levels_root.add_child(current_level)
	current_level_index = index
	var puzzle_manager: PuzzleManager = null
	if current_level is PuzzleManager:
		puzzle_manager = current_level
	if puzzle_manager != null:
		puzzle_manager.puzzle_completed.connect(_on_puzzle_completed)

func _on_puzzle_completed() -> void:
	loading_level.emit()
	%AnimationManager.play_scene_change_transition() # TODO: Could be ordered using signals
	await animation_player.animation_finished
	await get_tree().create_timer(1.5).timeout
	if current_level_index + 1 < level_scenes.size():
		await _load_level(current_level_index + 1)
		%AnimationManager.play_reset()
		level_loaded.emit()
