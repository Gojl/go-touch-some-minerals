extends Area2D

signal clicked(rock)

func _ready() -> void:
	connect("input_event", Callable(self, "_on_input_event"))

func _on_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:
		Globals.mode = Globals.Mode.INSPECT
		Globals.inspected_rock = self
