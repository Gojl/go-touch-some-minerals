extends Node

@onready var text_grid = $text_grid
@onready var mineral_label = $text_grid/mineral_label
@onready var quality_label = $text_grid/quality_label
@onready var weight_label = $text_grid/weight_label
@onready var mweight_label = $text_grid/mweight_label

func _ready() -> void:
	mineral_updated()

func mineral_updated() -> void:
	var mineral = get_parent().get_parent()
	mineral_label.text = "Type: " + mineral.type
	quality_label.text = "Quality: " + str(mineral.quality)
	if mineral.weight/1000 >= 1:
		weight_label.text = "Weight: " + str(snapped(mineral.weight/1000,0.01)) + "KG"
	else:
		weight_label.text = "Weight: " + str(snapped(mineral.weight,0.01)) + "G"
	mweight_label.text = "Mineral percentage: " + str(snapped((mineral.mweight / mineral.weight * 100),1))

	for child in text_grid.get_children():
		child.custom_minimum_size = Vector2(text_grid.size.x, text_grid.size.y / text_grid.get_child_count())
