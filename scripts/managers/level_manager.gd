extends Node2D

# Nodes
@export var board: Grid
@export var player: Player
@onready var pushable_objects := $Entities/PushableObjects.get_children()
@onready var static_objects := $Entities/StaticObjects.get_children()


func _ready() -> void:
	for object in static_objects:
		board.register_entity(object, object.initial_grid_position)
	for object in pushable_objects:
		board.register_entity(object, object.initial_grid_position)
	board.register_entity(player, player.initial_grid_position)
	UndoManager.register_board(board)
