extends Control

signal finished

@onready var label = $RichTextLabel

func show_text(text: String):
	label.text = text
	animate()

func animate():
	var tween = create_tween()

	var start_y = get_viewport_rect().size.y
	var end_y = start_y - size.y - 20

	global_position.y = start_y

	tween.tween_property(self, "global_position:y", end_y, 0.3)
	tween.tween_interval(2.0)
	tween.tween_property(self, "global_position:y", start_y, 0.3)

	tween.tween_callback(func():
		finished.emit()
		queue_free()
	)
