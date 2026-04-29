extends PanelContainer

var tool = {
	cost = 0.0,
	name = "",
	description = ""
}

var mineral_name: String

func setup(data: Dictionary) -> void:
	tool.name = data["name"]
	tool.cost = data["cost"]
	tool.description = data["description"]
	
	get_node("MarginContainer/VBoxContainer/Name").text = " ".join(tool.name.split("_")).capitalize()

	get_node("MarginContainer/VBoxContainer/Desc").text = tool.description
	var color = "[color=red]" if data["cost"] > Game.money else "[color=green]"
	get_node("MarginContainer/VBoxContainer/HBoxContainer/Price").text = color + str(tool.cost) + " zł"


func _on_buy_pressed() -> void:
	if tool.cost < Game.money:
		#Game.money -= tool.cost
		get_tree().reload_current_scene()
