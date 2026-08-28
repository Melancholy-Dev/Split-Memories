class_name PressureButton extends GridEntity

# Signals
signal pressed_changed(is_pressed: bool)

# Variables
@export var is_pressed_texture: Texture2D
@export var objects_to_disable: Array[GridEntity] = []
@onready var sprite: Sprite2D = $Sprite2D
var unpressed_texture: Texture2D
var is_pressed := false


func _ready() -> void:
	unpressed_texture = sprite.texture

func init(_board: Grid, _position: Vector2i) -> void:
	super.init(_board, _position)
	board.player_step_completed.connect(_on_player_step_completed)

func is_pushable() -> bool:
	return false

func blocks_movement() -> bool:
	return false

func check_players() -> void:
	_refresh_state()

func _on_player_step_completed(_direction: Vector2i, moved_entities: Array[GridEntity]) -> void:
	for entity: GridEntity in moved_entities:
		if not entity is Player:
			continue
		var movement_component := entity.get_node_or_null("Components/MovementComponent")
		if movement_component == null:
			_refresh_state()
		else:
			movement_component.movement_finished.connect(_refresh_state, CONNECT_ONE_SHOT)

func _refresh_state() -> void:
	var pressed := false
	for entity: GridEntity in board.get_entities_at(grid_position):
		if entity is Player:
			pressed = true
			break
	if pressed == is_pressed:
		return
	is_pressed = pressed
	if is_pressed:
		sprite.texture = is_pressed_texture
	else:
		sprite.texture = unpressed_texture
	for object in objects_to_disable:
		if not is_instance_valid(object):
			continue
		if is_pressed:
			object.disable()
		else:
			object.enable()
	pressed_changed.emit(is_pressed)
