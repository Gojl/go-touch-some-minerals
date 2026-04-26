extends Node

@onready var text_grid = $text_grid
@onready var mineral_label = $text_grid/mineral_label
@onready var quality_label = $text_grid/quality_label
@onready var weight_label = $text_grid/weight_label
@onready var mweight_label = $text_grid/mweight_label
@onready var drop_button = $drop_button
var id: int

func clear() -> void:
	for child in text_grid.get_children():
		child.text = ""
	id = -1

func set_slot_data(type: String, quality: float, weight: float, mweight: float, tid: int) -> void:
	mineral_label.text = "[color=gray]Type:\n[/color]" + type.capitalize()
	quality_label.text = "[color=gray]Quality:\n[/color]" + str(quality)
	if weight/1000 >= 1:
		weight_label.text = "[color=gray]Weight:\n[/color]" + str(snapped(weight/1000,0.01)) + "KG"
	else:
		weight_label.text = "[color=gray]Weight:\n[/color]" + str(snapped(weight,0.01)) + "G"
	if type != "rock":
		mweight_label.text = "[color=gray]Percentage:\n[/color]" + str(snapped((mweight / weight * 100),1))

	id = tid

	for child in text_grid.get_children():
		child.custom_minimum_size = Vector2(text_grid.size.x, text_grid.size.y / text_grid.get_child_count())
