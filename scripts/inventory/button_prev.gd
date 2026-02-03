extends TextureButton

func _pressed() -> void:
	var inv = get_tree().get_first_node_in_group("inventory")
	if inv:
		inv.prev_page()
