extends Control

@onready var list := $ScrollContainer/GridContainer
var entry := preload("res://scenes/sklep_entry.tscn")

func _ready() -> void:
	$pieniondze.text = str(Game.money) + " zł"
	var file := FileAccess.open("res://data/sklep.json", FileAccess.READ)
	var data: Array = JSON.parse_string(file.get_as_text())["shop"]
	file.close()
	
	for mineral in data:
		var e = entry.instantiate()
		e.setup(mineral)
		list.add_child(e)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/miasto.tscn")
