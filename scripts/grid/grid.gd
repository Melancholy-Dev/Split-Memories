class_name Grid extends Node2D

# Signals
signal player_step_completed(direction: Vector2i, moved_entities: Array[GridEntity])

# Variables
var grid_size := Vector2i(14, 17) # Cells number
var tile_size := Vector2i(16, 16) # Cells size
var cells: Array = []


func _ready() -> void:
	_init()

func _init() -> void:
	cells.clear()
	for y in range(grid_size.y): # Scrolling Matrix
		var row: Array = []
		for x in range(grid_size.x):
			row.append(null)
		cells.append(row)

func is_inside_grid(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0:
		return false
	elif cell.x >= grid_size.x or cell.y >= grid_size.y:
		return false
	else:
		return true

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * tile_size.x + tile_size.x / 2.0,
		cell.y * tile_size.y + tile_size.y / 2.0
	)

func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floor(world_position.x / tile_size.x),
		floor(world_position.y / tile_size.y)
	)

func get_entity_at(cell: Vector2i) -> GridEntity:
	if not is_inside_grid(cell):
		return null
	return cells[cell.y][cell.x]

func register_entity(entity: GridEntity, cell: Vector2i) -> bool:
	if not is_inside_grid(cell):
		print("Outside grid limits")
		return false
	if get_entity_at(cell) != null:
		print("Cell %s is already occupied" % cell)
		return false
	cells[cell.y][cell.x] = entity
	entity.init(self, cell)
	return true

func unregister_entity(entity: GridEntity) -> void:
	var cell := entity.grid_position
	if is_inside_grid(cell) and get_entity_at(cell) == entity:
		cells[cell.y][cell.x] = null

func create_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for row in cells:
		for entity in row:
			if entity != null:
				snapshot[entity] = entity.grid_position
	return snapshot

func restore_snapshot(snapshot: Dictionary) -> void:
	for row in cells:
		row.fill(null)
	for entity_key in snapshot:
		var entity: GridEntity
		if entity_key is GridEntity:
			entity = entity_key
		if entity == null:
			continue
		var cell: Vector2i = snapshot[entity_key]
		if not is_inside_grid(cell):
			continue
		cells[cell.y][cell.x] = entity
		entity.set_grid_position(cell)
		entity.position = cell_to_world(cell)

func _set_entity_cell(entity: GridEntity, new_cell: Vector2i) -> void:
	var old_cell := entity.grid_position
	if is_inside_grid(old_cell) and get_entity_at(old_cell) == entity:
		cells[old_cell.y][old_cell.x] = null
	cells[new_cell.y][new_cell.x] = entity
	entity.set_grid_position(new_cell)

func _move_entity_in_grid(entity: GridEntity, new_cell: Vector2i) -> void:
	var old_cell := entity.grid_position
	if is_inside_grid(old_cell):
		if get_entity_at(old_cell) == entity:
			cells[old_cell.y][old_cell.x] = null
	cells[new_cell.y][new_cell.x] = entity
	entity.set_grid_position(new_cell)

func try_move_player(player: Player, direction: Vector2i) -> Array[GridEntity]:
	var moved_entities: Array[GridEntity] = []
	var player_cell := player.grid_position
	var next_cell := player_cell + direction
	var entity := get_entity_at(next_cell)
	# Player cannot exit from the grid
	if not is_inside_grid(next_cell):
		player_step_completed.emit(direction, moved_entities)
		return moved_entities
	# Empity cell (only player move)
	if entity == null:
		_move_entity_in_grid(player, next_cell)
		moved_entities.append(player)
		player_step_completed.emit(direction, moved_entities)
		return moved_entities
	# Static object encountered (player cannot move)
	if not entity.can_be_pushed():
		player_step_completed.emit(direction, moved_entities)
		return moved_entities

	# Pushable objects encountered (chain of objects)
	var push_chain: Array[GridEntity] = []
	var scan_cell := next_cell
	while true:
		var next_entity := get_entity_at(scan_cell)
		if next_entity == null:
			break
		# If static object in front
		if not next_entity.can_be_pushed():
			player_step_completed.emit(direction, moved_entities)
			return moved_entities
		push_chain.append(next_entity)
		scan_cell += direction
		# Chain can't go out from the grid
		if not is_inside_grid(scan_cell):
			player_step_completed.emit(direction, moved_entities)
			return moved_entities
	# Move the objects (from the farthest to the nearest)
	var index: int = push_chain.size() - 1
	while index >= 0:
		var object_to_push: GridEntity = push_chain[index]
		var target_cell: Vector2i = object_to_push.grid_position + direction
		_move_entity_in_grid(object_to_push, target_cell)
		moved_entities.append(object_to_push)
		index -= 1
	# Move the player
	_move_entity_in_grid(player, next_cell)
	moved_entities.append(player)
	player_step_completed.emit(direction, moved_entities)
	return moved_entities
