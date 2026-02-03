extends Node

var current_cursor := "idle"
var cursor_idle = preload("res://assets/crosshair_idle.png")
var cursor_mine = preload("res://assets/crosshair_mine.png")
var cursor_inspect = preload("res://assets/crosshair_inspect.png")
var cursor_select = preload("res://assets/crosshair_select.png")

var cursors: Array

func _ready() -> void:
	cursors = [{"type": "mine", "name": cursor_mine}, {"type":"idle","name": cursor_idle}, {"type":"inspect","name": cursor_inspect}, {"type": "select", "name": cursor_select}]

func set_cursor(name: String) -> void:
	for cursor in cursors:
		if cursor["type"] == name:
			current_cursor = name
			Input.set_custom_mouse_cursor(cursor["name"])
func reset_cursor() -> void:
	current_cursor = "idle"
	Input.set_custom_mouse_cursor(cursor_idle)
