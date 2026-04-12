extends Node

const NOTIF_SCENE = preload("res://scenes/notifcation.tscn")

var queue: Array[String] = []
var is_showing := false

func notify(text: String):
	queue.append(text)
	_try_show_next()

func _try_show_next():
	if is_showing:
		return

	if queue.is_empty():
		return

	is_showing = true

	var text = queue.pop_front()
	var notif = NOTIF_SCENE.instantiate()

	var layer = CanvasLayer.new()
	get_tree().root.add_child(layer)
	layer.add_child(notif)

	notif.finished.connect(_on_notification_finished)

	notif.show_text(text)

func _on_notification_finished():
	is_showing = false
	_try_show_next()
