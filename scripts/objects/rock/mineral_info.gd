extends Control

var player: Node

func _ready() -> void:
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("stone_mine: Could not find player node in group 'player'!")
	player.mode_changed.connect(_clear)

func _clear(mode, _rock = null, _zoom = -1.5) -> void:
	print("clear")
	if mode != player.Mode.INSPECT:
		queue_free()
