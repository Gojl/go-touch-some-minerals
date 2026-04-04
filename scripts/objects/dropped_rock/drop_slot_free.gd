extends Control

var player: Node = null


func _ready() -> void:
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

	if player:
		player.mode_changed.connect(_on_exit_inspect)


func _on_exit_inspect(newMode, _Node: Node2D, _useless_zoom = null):
	if newMode != player.Mode.INSPECT:
		queue_free()
