extends CanvasLayer

signal closed

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		await get_tree().process_frame
		closed.emit()

func _on_resume_pressed() -> void:
	closed.emit()

func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
	get_tree().paused = false
	queue_free()
