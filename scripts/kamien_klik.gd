extends Area2D

signal clicked(rock)

func _ready() -> void:
	connect("input_event", Callable(self, "_on_input_event"))

func _on_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and Globals.mode == Globals.Mode.EXPLORE:
			Globals.mode = Globals.Mode.INSPECT
			Globals.inspected_rock = self
			emit_signal("clicked", self)
			print("Kliknięto lewym: INSPECT")
		
		elif event.button_index == MOUSE_BUTTON_RIGHT and Globals.mode == Globals.Mode.INSPECT:
			Globals.mode = Globals.Mode.MINE
			Globals.inspected_rock = self
			print("Kliknięto prawym: MINE")
