class_name Grid extends Node2D

# Signals
signal player_step_completed
signal entity_relocated(entity: GridEntity, old_position: Vector2i, new_position: Vector2i)
signal state_restored

# Variables
var grid_size := Vector2i(14, 17) # Cells number
var tile_size := Vector2i(16, 16) # Cells size
var cells: Array = []


func _ready() -> void:
	for y in range(grid_size.y): # Scrolling Matrix
		var row: Array = []
		for x in range(grid_size.x):
			row.append([])
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

func get_entities_at(cell: Vector2i) -> Array:
	if not is_inside_grid(cell):
		return []
	return cells[cell.y][cell.x]

func get_entity_at(cell: Vector2i) -> GridEntity:
	for entity: GridEntity in get_entities_at(cell):
		if entity.blocks_movement():
			return entity
	return null

func find_nearest_free_cell(origin: Vector2i) -> Vector2i:
	var nearest_cell := Vector2i(-1, -1)
	var nearest_distance := grid_size.x + grid_size.y
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell := Vector2i(x, y)
			if cell == origin or get_entity_at(cell) != null:
				continue
			var distance := absi(cell.x - origin.x) + absi(cell.y - origin.y)
			if distance < nearest_distance:
				nearest_cell = cell
				nearest_distance = distance
	return nearest_cell

func move_entities_out_of_cell(cell: Vector2i, excluded_entity: GridEntity = null) -> void:
	var entities_inside: Array[GridEntity] = []
	for entity: GridEntity in get_entities_at(cell):
		if entity != excluded_entity and entity.blocks_movement():
			entities_inside.append(entity)
	for entity in entities_inside:
		var free_cell := find_nearest_free_cell(cell)
		if is_inside_grid(free_cell):
			relocate_entity(entity, free_cell)

func relocate_entity(entity: GridEntity, new_cell: Vector2i) -> bool:
	if not is_inside_grid(new_cell) or get_entity_at(new_cell) != null:
		return false
	var old_cell := entity.grid_position
	_move_entity_in_grid(entity, new_cell)
	entity.position = cell_to_world(new_cell)
	entity_relocated.emit(entity, old_cell, new_cell)
	return true

func register_entity(entity: GridEntity, cell: Vector2i) -> bool:
	if not is_inside_grid(cell):
		print("Outside grid limits")
		return false
	if get_entities_at(cell).has(entity):
		print("Entity is already registered")
		return false
	if entity.blocks_movement() and get_entity_at(cell) != null:
		print("Cell %s is already occupied" % cell)
		return false
	cells[cell.y][cell.x].append(entity)
	entity.init(self, cell)
	return true

func notify_player_step_completed() -> void:
	player_step_completed.emit()

func create_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for row in cells:
		for cell in row:
			for entity: GridEntity in cell:
				snapshot[entity] = entity.create_snapshot()
	return snapshot

func restore_snapshot(snapshot: Dictionary) -> void:
	for row in cells:
		for entities in row:
			entities.clear()
	for entity: GridEntity in snapshot:
		var entity_state: Dictionary = snapshot[entity]
		var cell: Vector2i = entity_state["grid_position"]
		if not is_inside_grid(cell):
			continue
		cells[cell.y][cell.x].append(entity)
		entity.restore_snapshot(entity_state)
		entity.position = cell_to_world(cell)
	state_restored.emit()

func _move_entity_in_grid(entity: GridEntity, new_cell: Vector2i) -> void:
	var old_cell := entity.grid_position
	if is_inside_grid(old_cell):
		cells[old_cell.y][old_cell.x].erase(entity)
	cells[new_cell.y][new_cell.x].append(entity)
	entity.set_grid_position(new_cell)

func try_move_player(player: Player, direction: Vector2i) -> Array[GridEntity]:
	var moved_entities: Array[GridEntity] = []
	var player_cell := player.grid_position
	var next_cell := player_cell + direction
	# Player cannot exit from the grid
	if not is_inside_grid(next_cell):
		return moved_entities
	var entity := get_entity_at(next_cell)
	# Empty cell or non-blocking entity (only player move)
	if entity == null:
		_move_entity_in_grid(player, next_cell)
		moved_entities.append(player)
		return moved_entities
	# Blocking entity encountered (player cannot move)
	if not entity.is_pushable():
		return moved_entities

	# Pushable objects encountered (chain of objects)
	var push_chain: Array[GridEntity] = []
	var scan_cell := next_cell
	while true:
		var next_entity := get_entity_at(scan_cell)
		if next_entity == null:
			break
		# If another blocking entity is in front
		if not next_entity.is_pushable():
			return moved_entities
		push_chain.append(next_entity)
		scan_cell += direction
		# Chain can't go out from the grid
		if not is_inside_grid(scan_cell):
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
	return moved_entities
