extends PanelContainer

const FIELDS := {
	"color":         "Color",
	"streak":        "Streak",
	"luster":        "Luster",
	"cleavage":      "Cleavage",
	"density":       "Density",
	"fracture":      "Fracture",
	"transparency":  "Transparency",
	"mohs_hardness": "Hardness (Mohs)",
	"fragility":     "Fragility",
	"rarity_percent":"Rarity (%)",
	"spawn_layer":   "Depth",
}

var mineral_name: String

func setup(data: Dictionary) -> void:
	mineral_name = data["name"]
	get_node("MarginContainer/VBoxContainer/name_label").text = mineral_name.to_upper()

	var grid := get_node("MarginContainer/VBoxContainer/grid")
	for key in FIELDS:
		if not data.has(key):
			continue
		var lk := Label.new()
		lk.text = FIELDS[key] + ":"
		lk.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		lk.add_theme_font_override("font", load("res://assets/fonts/Pixel-UniCode.ttf"))
		var lv := Label.new()
		lv.text = str(data[key])
		lv.add_theme_font_override("font", load("res://assets/fonts/Pixel-UniCode.ttf"))
		lv.add_theme_font_size_override("font_size", 22)
		grid.add_child(lk)
		grid.add_child(lv)
