extends Node

@onready var text_grid = $text_grid
@onready var mineral_label = $text_grid/mineral_label
@onready var quality_label = $text_grid/quality_label
@onready var weight_label = $text_grid/weight_label
@onready var mweight_label = $text_grid/mweight_label

func set_slot_data(type: String, quality: float, weight: float, mweight: float) -> void:
	mineral_label.text = "Type: " + type
	quality_label.text = "Quality: " + str(quality)
	if weight/1000 >= 1:
		weight_label.text = "Weight: " + str(weight/1000) + "KG"
	else:
		weight_label.text = "Weight: " + str(weight) + "G"
	mweight_label.text = "Mineral percentage: " + str(snapped((mweight / weight * 100),0.01))
	
	for child in text_grid.get_children():
		child.custom_minimum_size = Vector2(text_grid.size.x, text_grid.size.y / text_grid.get_child_count())
