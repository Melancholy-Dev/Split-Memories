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
	board.entity_relocated.connect(_on_entity_relocated)
	board.state_restored.connect(_refresh_state)

func blocks_movement() -> bool:
	return false

func check_players() -> void:
	_refresh_state()

func _on_player_step_completed() -> void:
	_refresh_state()

func _on_entity_relocated(entity: GridEntity, old_position: Vector2i, new_position: Vector2i) -> void:
	if entity is Player and (old_position == grid_position or new_position == grid_position):
		_refresh_state()

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
