extends Area2D

var player: Node = null

func _ready():
	connect("input_event", Callable(self, "_on_input_event"))
	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _on_input_event(viewport, event, shape_idx) -> void:
	if not player:
		return
		
	if event is InputEventMouseButton and event.pressed:
		var mineral = get_parent()
		if player.global_position.distance_to(mineral.global_position) <= player.inspect_range:
			if event.button_index == MOUSE_BUTTON_LEFT and player.get_current_mode() == player.Mode.EXPLORE:
				mineral.queue_free()
				player.collect_mineral(mineral.type, mineral.quality, mineral.weight, mineral.mweight)
