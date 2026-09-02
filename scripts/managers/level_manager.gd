extends Node2D

# Nodes
@export var board: Grid
@export var player: Player
@onready var pushable_objects := $Entities/PushableObjects.get_children()
@onready var static_objects := $Entities/StaticObjects.get_children()
@onready var buttons: Node = get_node_or_null("Entities/Buttons")


func _ready() -> void:
	for object in static_objects:
		_register_entity_at_editor_position(object)
	for object in pushable_objects:
		_register_entity_at_editor_position(object)
	if buttons != null:
		for button in buttons.get_children():
			_register_entity_at_editor_position(button)
	_register_entity_at_editor_position(player)
	UndoManager.register_board(board)
	if buttons != null:
		for button in buttons.get_children():
			if button is PressureButton:
				button.check_players()

func _register_entity_at_editor_position(entity: GridEntity) -> void:
	var board_position := board.to_local(entity.global_position)
	board.register_entity(entity, board.world_to_cell(board_position))
