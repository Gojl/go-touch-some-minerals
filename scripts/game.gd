extends Node

var money: float = 0
var items: Array = []

const SAVE_PATH := "user://save.json"

func _ready():
	load_data()

func save_data():
	var data = {
		"money": money,
		"items": items
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var content = file.get_as_text()
	var data = JSON.parse_string(content)

	if typeof(data) == TYPE_DICTIONARY:
		money = data.get("money", 0)
		items = data.get("items", [])
