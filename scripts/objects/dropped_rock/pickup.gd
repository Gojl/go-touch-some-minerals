extends TextureButton

var player: Node = null
var mineral: Node2D

func _mouse_entered() -> void:
	CursorManager.set_cursor("select")
func _mouse_exited() -> void:
	CursorManager.reset_cursor()

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	mineral = get_parent().get_parent().get_parent()
	mouse_entered.connect(_mouse_entered)
	mouse_exited.connect(_mouse_exited)
func _pressed() -> void:
	if player:
		player.collect_mineral(mineral.type, mineral.quality, mineral.weight, mineral.mweight,mineral.fragility)
		player.exit_inspect()
		mineral.queue_free()
		player.cancel_blocked = false
