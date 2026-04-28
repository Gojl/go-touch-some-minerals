extends Area2D

var button: Button
func _ready() -> void:
	await get_tree().process_frame
	button = get_tree().get_first_node_in_group("button_return")
	button.tree_exited.connect(free)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	visible = true
	$Sprite2D.modulate.a = 0.7

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		button.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		button.visible = false
