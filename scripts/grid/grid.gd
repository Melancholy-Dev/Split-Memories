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
	for cell: Vector2i in [old_cell, new_cell]:
		for occupant: GridEntity in get_entities_at(cell):
			var button := occupant as PressureButton
			if button != null:
				button.check_players()
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

func unregister_entity(entity: GridEntity) -> void:
	var cell := entity.grid_position
	if is_inside_grid(cell):
		cells[cell.y][cell.x].erase(entity)

func create_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for row in cells:
		for cell in row:
			for entity: GridEntity in cell:
				var entity_state: Dictionary = {"grid_position": entity.grid_position}
				if entity is Player:
					var animation_component := entity.get_node_or_null("Components/AnimationComponent")
					if animation_component != null:
						entity_state["animation"] = animation_component.animated_sprite.animation
						entity_state["last_direction"] = animation_component.last_direction
				snapshot[entity] = entity_state
	return snapshot

func restore_snapshot(snapshot: Dictionary) -> void:
	for row in cells:
		for entities in row:
			entities.clear()
	for entity_key in snapshot:
		var entity: GridEntity
		if entity_key is GridEntity:
			entity = entity_key
		if entity == null:
			continue
		var entity_state = snapshot[entity_key]
		var cell: Vector2i
		if entity_state is Dictionary:
			cell = entity_state["grid_position"]
		else:
			cell = entity_state
		if not is_inside_grid(cell):
			continue
		cells[cell.y][cell.x].append(entity)
		entity.set_grid_position(cell)
		entity.position = cell_to_world(cell)
		if entity is Player and entity_state is Dictionary and entity_state.has("animation"):
			var animation_component := entity.get_node_or_null("Components/AnimationComponent")
			if animation_component != null:
				animation_component.last_direction = entity_state["last_direction"]
				animation_component.play_idle_animation()

func _set_entity_cell(entity: GridEntity, new_cell: Vector2i) -> void:
	var old_cell := entity.grid_position
	if is_inside_grid(old_cell):
		cells[old_cell.y][old_cell.x].erase(entity)
	cells[new_cell.y][new_cell.x].append(entity)
	entity.set_grid_position(new_cell)

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
	var entity := get_entity_at(next_cell)
	# Player cannot exit from the grid
	if not is_inside_grid(next_cell):
		player_step_completed.emit(direction, moved_entities)
		return moved_entities
	# Empty cell or non-blocking entity (only player move)
	if entity == null:
		_move_entity_in_grid(player, next_cell)
		moved_entities.append(player)
		player_step_completed.emit(direction, moved_entities)
		return moved_entities
	# Blocking entity encountered (player cannot move)
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
		# If another blocking entity is in front
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
