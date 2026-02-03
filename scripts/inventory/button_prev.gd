extends TextureButton

func _pressed() -> void:
	var inv = get_tree().get_first_node_in_group("inventory")
	if inv:
		inv.prev_page()

func _mouse_entered() -> void:
	CursorManager.set_cursor("select")
func _mouse_exited() -> void:
	CursorManager.reset_cursor()

func _ready() -> void:
	mouse_entered.connect(_mouse_entered)
	mouse_exited.connect(_mouse_exited)
