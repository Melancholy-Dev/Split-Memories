extends Node # Autoload Singleton class

# Signals
signal is_undoing_started()

# Variables
var _boards: Array[Grid] = []
var _history: Array[Dictionary] = []
var _is_undoing := false


func _ready() -> void:
	InputManager.undo_pressed.connect(_on_undo_pressed)

func register_board(board: Grid) -> void:
	if not _boards.has(board):
		_boards.append(board)

func clear_boards() -> void:
	_boards.clear()
	_history.clear()

func capture_state() -> Dictionary:
	var state: Dictionary = {}
	for board in _boards:
		state[board] = board.create_snapshot()
	return state

func commit_state(state: Dictionary) -> void:
	if not state.is_empty():
		_history.append(state)

func _on_undo_pressed() -> void:
	if _is_undoing or _history.is_empty():
		return
	_is_undoing = true
	is_undoing_started.emit()
	await get_tree().create_timer(0.3).timeout
	var state: Dictionary = _history.pop_back()
	for board in _boards:
		if state.has(board):
			board.restore_snapshot(state[board])
	_is_undoing = false

func is_undoing() -> bool:
	return _is_undoing
