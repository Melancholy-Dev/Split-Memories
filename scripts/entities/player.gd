class_name Player extends GridEntity

# Variables
@export var is_player_one := true


func create_snapshot() -> Dictionary:
	var state := super.create_snapshot()
	var animation_component := get_node_or_null("Components/AnimationComponent")
	if animation_component != null:
		state["animation"] = animation_component.animated_sprite.animation
		state["last_direction"] = animation_component.last_direction
	return state

func restore_snapshot(state: Dictionary) -> void:
	super.restore_snapshot(state)
	if not state.has("animation"):
		return
	var animation_component := get_node_or_null("Components/AnimationComponent")
	if animation_component != null:
		animation_component.last_direction = state["last_direction"]
		animation_component.play_idle_animation()
