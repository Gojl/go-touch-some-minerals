extends Control

@onready var list := $ScrollContainer/GridContainer
var entry := preload("res://scenes/atlas_entry.tscn")

func _ready() -> void:
	var file := FileAccess.open("res://data/atlas.json", FileAccess.READ)
	var data: Array = JSON.parse_string(file.get_as_text())["minerals"]
	file.close()
	
	for mineral in data:
		var e = entry.instantiate()
		e.setup(mineral)
		list.add_child(e)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
