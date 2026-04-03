extends Area2D

var player: Node = null
@onready var mineral = get_parent()

func _ready():
	connect("input_event", Callable(self, "_on_input_event"))
	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _mouse_enter() -> void:
	if not player or not visible:
		return
	var current_mode = player.get_current_mode()
	if player.global_position.distance_to(mineral.global_position) <= player.inspect_range:
		if current_mode == player.Mode.EXPLORE:
			CursorManager.set_cursor("inspect")
	CursorManager.set_cursor("inspect")
func _mouse_exit() -> void:
	CursorManager.reset_cursor()
func _exit_tree() -> void:
	CursorManager.reset_cursor()

func _on_input_event(viewport, event, shape_idx) -> void:
	if not player:
		return
	if event is InputEventMouseButton and event.pressed:
		if player.global_position.distance_to(mineral.global_position) <= player.inspect_range:
			if event.button_index == MOUSE_BUTTON_LEFT and player.get_current_mode() == player.Mode.EXPLORE:
				player.enter_inspect_mode(mineral, 20, false)
