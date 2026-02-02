extends Control

var is_open: bool = false
var inventory_data := []
var player: Node = null

@onready var grid := $body/BackpackGrid
@onready var empty_label = $body/empty_label
var invSlot := preload("res://scenes/inv_slot.tscn")
var droppedMineral := preload("res://scenes/dropped_mineral.tscn")

var all_slots: Array[Control] = []

var current_page := 0
var items_per_page := 10

var open = false

func _ready() -> void:
	await get_tree().process_frame  
	player = get_tree().get_first_node_in_group("player")
	
	for i in range(items_per_page):
		var slot = invSlot.instantiate()
		grid.add_child(slot)
		all_slots.append(slot)
		slot.hide()
		
	
	if player:
		player.mineral_collected.connect(_on_mineral_collected)
		print("Inventory connected to player")
		player.mode_changed.connect(_on_toggle_inventory)
	else:
		push_error("Inventory: Could not find player!")
	
	scale = Vector2(0,0)
	rotation_degrees = -90

func _process(delta):
	if open:
		scale = scale.lerp(Vector2(0.018,0.018), delta * 4)
		rotation_degrees = lerpf(rotation_degrees, 0, delta * 4)
	else:
		scale = scale.lerp(Vector2(0,0), delta * 4)
		rotation_degrees = lerpf(rotation_degrees, -90, delta * 4)
	if scale <= Vector2(0.0005,0.0005):
		visible = false
	else:
		visible = true

func _on_toggle_inventory(newMode, bpNode: Node2D) -> void:	
	if newMode == player.Mode.INV:
		position = bpNode.position
		show_page(current_page)
		show_inventory()
	else:
		hide_inventory()

func show_inventory() -> void:
	open = true

func hide_inventory() -> void:
	for i in range(inventory_data.size()):
		var slot_to_show = all_slots[i % 10]
		slot_to_show.hide()
	open = false

func show_page(page: int) -> void:
	var start := page*items_per_page
	
	if inventory_data.size() > 0:
		empty_label.visible = false
		for slot_index in range(items_per_page):
			var data_index := start + slot_index
			var slot := all_slots[slot_index]
			
			if data_index < inventory_data.size():
				var item = inventory_data[data_index]
				slot.show()
				slot.set_slot_data(item.type, item.quality, item.weight, item.mweight, data_index)
			else:
				slot.hide()
				slot.clear()
	else:
		for i in range(all_slots.size()):
			all_slots[i].hide()
		empty_label.visible = true

func next_page():
	if (current_page + 1) * items_per_page < inventory_data.size():
		current_page += 1
		show_page(current_page)
func prev_page():
	if current_page > 0:
		current_page -= 1
		show_page(current_page)

func drop_mineral(id: int):
	print("Dropping mineral")
	var map = player.get_parent()
	var new_dropped_mineral = droppedMineral.instantiate()
	new_dropped_mineral.global_position = player.global_position + Vector2(15, 0)
	new_dropped_mineral.type = inventory_data[id].type
	new_dropped_mineral.quality = inventory_data[id].quality
	new_dropped_mineral.weight = inventory_data[id].weight
	new_dropped_mineral.mweight = inventory_data[id].mweight
	inventory_data.remove_at(id)
	map.add_child(new_dropped_mineral)
	player.inv_updated(inventory_data)
	show_page(current_page)

func _on_mineral_collected(mineral_type: String, quality: float, weight: float, mweight: float) -> void:
	inventory_data.append({"type": mineral_type, "quality": quality, "weight": weight, "mweight": mweight})
	player.inv_updated(inventory_data)
	print("Inventory updated: ", mineral_type, " quality: ", quality)
