extends Control


# This script assumes you created in the scene:
# - A GridContainer named "BackpackGrid" (slots)
# - A VBoxContainer named "EquipmentPanel" with dedicated slots (WeaponSlot, HelmetSlot, etc.)
# - Each slot is a custom InventorySlot node


@onready var backpack_grid = $BackpackGrid
@onready var equipment_panel = $EquipmentPanel


var inventory_slots = []
var equipment_slots = {}


func _ready():
# Collect backpack slots
	for child in backpack_grid.get_children():
		if child.has_method("set_item"):
			inventory_slots.append(child)


	# Collect equipment slots
	for child in equipment_panel.get_children():
		if child.has_method("set_item"):
			equipment_slots[child.allowed_type] = child


	update_visual_state()


# Update the whole UI visuals
func update_visual_state():
	for slot in inventory_slots:
		slot.update_icon()
	for slot in equipment_slots.values():
		slot.update_icon()


# Place item in equipment slot if allowed
func try_equip(item):
	if item.item_type in equipment_slots:
		var slot = equipment_slots[item.item_type]
		slot.set_item(item)
		update_visual_state()
		return true
		return false


# Store item in first free backpack slot
func add_to_backpack(item):
	for slot in inventory_slots:
		if slot.current_item == null:
			slot.set_item(item)
			update_visual_state()
			return true
			return false
