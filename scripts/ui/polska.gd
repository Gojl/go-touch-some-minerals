extends Control

func _ready():
	for node in get_tree().get_nodes_in_group("miejscowości"):
		node.mouse_entered.connect(_on_hover.bind(node))

func _on_oborniki_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/miasto.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _on_hover(node) -> void:
	var cities := {
		"oborniki": "[b]Oborniki Śląskie[/b]\n[color=gray]Region:[/color] Dolny Śląsk (Sudety)\n[color=gray]Population:[/color] 9099\n[color=gray]Area:[/color] 14.46 km2\n[color=gray]Town rights:[/color] 1945\n[color=green]Odblokowano[/color]",
		"klodzko": "[b]Kłodzko[/b]\n[color=gray]Region:[/color] Kotlina Kłodzka\n[color=gray]Population:[/color] 25717\n[color=gray]Area:[/color] 25 km2\n[color=gray]Town rights:[/color] 1233\n[color=red]Nie odblokowano[/color]",
		"siemianowice": "[b]Siemianowice[/b]\n[color=gray]Region:[/color] Górny Śląsk\n[color=gray]Population:[/color] 65684\n[color=gray]Area:[/color] 25.5 km2\n[color=gray]Town rights:[/color] 1932\n[color=red]Nie odblokowano[/color]",
		"slupia": "[b]Nowa Słupia[/b]\n[color=gray]Region:[/color] Góry Świętokrzyskie\n[color=gray]Population:[/color] 1600\n[color=gray]Area:[/color] 13.97 km2\n[color=gray]Town rights:[/color] 1351\n[color=red]Nie odblokowano[/color]"
	}

	$RichTextLabel.text = cities[node.name]
