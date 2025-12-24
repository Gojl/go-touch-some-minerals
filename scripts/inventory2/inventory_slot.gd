# inventory_ui.gd (Godot 4.x)



# inventory_slot.gd
extends TextureButton
class_name InventorySlot


@export var allowed_type: String = ""
var current_item: Item = null


func can_accept(item: Item) -> bool:
	return item != null and item.item_type == allowed_type


func set_item(item: Item):
	current_item = item
	update_icon()


func update_icon():
	texture_normal = current_item.icon if current_item else null


# Drag & Drop support
func _get_drag_data(_pos):
	if current_item:
		var drag = TextureRect.new()
		drag.texture = current_item.icon
		set_drag_preview(drag)
		return current_item
		return null


func _can_drop_data(_pos, data):
	return typeof(data) == TYPE_OBJECT and can_accept(data)


func _drop_data(_pos, data):
	if can_accept(data):
		set_item(data)
