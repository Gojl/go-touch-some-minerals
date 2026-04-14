extends Area2D

signal clicked(rock)

var player: Node = null
var infoslot = preload("res://scenes/mineral_info.tscn")
var loader = preload("res://scenes/loader.tscn")

func _ready() -> void:
	connect("input_event", Callable(self, "_on_input_event"))

	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

	if not player:
		push_error("Rock collider: Could not find player!")

func _mouse_enter() -> void:
	if not player or not visible:
		return
	var current_mode = player.get_current_mode()
	var rock_node = get_parent()
	if player.global_position.distance_to(rock_node.global_position) <= player.inspect_range:
		if current_mode == player.Mode.EXPLORE:
			CursorManager.set_cursor("inspect")
		elif  current_mode == player.Mode.INSPECT:
			CursorManager.set_cursor("mine")

func _mouse_exit() -> void:
	CursorManager.reset_cursor()

func _exit_tree() -> void:
	_mouse_exit()

func _on_input_event(_viewport, event, _shape_idx) -> void:
	if not player or not visible:
		return
	if event is not InputEventMouseButton or not event.pressed:
		return
	
	var current_mode = player.get_current_mode()
	var rock_node = get_parent()
	if player.global_position.distance_to(rock_node.global_position) <= player.inspect_range and event.button_index == MOUSE_BUTTON_LEFT:
		if current_mode == player.Mode.EXPLORE:
			player.enter_inspect_mode(rock_node)
			var newSlot = infoslot.instantiate()
			rock_node.add_child(newSlot)
			newSlot.setInfo(rock_node.mineral_type,rock_node.weight * randf_range(0.85,1.15),clampf(rock_node.mineral_quality * randf_range(0.9,1.1),0,1),rock_node.mineral_percentage + randf_range(-0.1,0.1))
			var newLoader = loader.instantiate()
			rock_node.add_child(newLoader)
			newLoader.setData(newSlot, 4)
			emit_signal("clicked", rock_node)
		elif current_mode == player.Mode.INSPECT:
			player.enter_mine_mode(rock_node)
