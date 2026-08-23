class_name Player extends GridEntity

# Variables
@export var is_player_one := true

func is_pushable() -> bool:
	return false

func blocks_movement() -> bool:
	return true
