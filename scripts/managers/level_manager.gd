extends Node2D

# Nodes
@export var board: Grid
@export var player: Player
@onready var pushable_objects := $Entities/PushableObjects.get_children()
@onready var static_objects := $Entities/StaticObjects.get_children()


func _ready() -> void:
	for object in static_objects:
		_register_entity_at_editor_position(object)
	for object in pushable_objects:
		_register_entity_at_editor_position(object)
	_register_entity_at_editor_position(player)
	UndoManager.register_board(board)

func _register_entity_at_editor_position(entity: GridEntity) -> void:
	var board_position := board.to_local(entity.global_position)
	entity.initial_grid_position = board.world_to_cell(board_position)
	board.register_entity(entity, entity.initial_grid_position)
