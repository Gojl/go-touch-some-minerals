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
		update_display()
		show_inventory()
	else:
		hide_inventory()

func show_inventory() -> void:
	open = true

func hide_inventory() -> void:
	open = false

func show_page(page: int) -> void:
	var start := page*items_per_page
	
	for child in grid.get_children():
		grid.remove_child(child) 
	
	if all_slots.size() > 0:
		empty_label.visible = false
	else:
		empty_label.visible = true
		
	for i in range(start, all_slots.size()):
		var slot_to_show = all_slots[i]
		grid.add_child(slot_to_show)
		slot_to_show.set_slot_data(inventory_data[i].type, inventory_data[i].quality, inventory_data[i].weight, inventory_data[i].m_weight)
	
func update_display() -> void:	
	show_page(0)
	print("Current inventory:", inventory_data)

var totalWeight: float = 0

func dropMineral(type: String, quality: float, weight: float,mweight: float, position: Vector2):
	print("Dropping mineral")
	var map = player.get_parent()
	var new_dropped_mineral = droppedMineral.instantiate()
	new_dropped_mineral.global_position = position
	new_dropped_mineral.type = type
	new_dropped_mineral.quality = quality
	new_dropped_mineral.weight = weight
	new_dropped_mineral.mweight = mweight
	map.add_child(new_dropped_mineral)

func _on_mineral_collected(mineral_type: String, quality: float, weight: float, mweight: float, position: Vector2) -> void:
	totalWeight += weight
	
	if totalWeight <= player.backpack_size:
		inventory_data.append({"type": mineral_type, "quality": quality, "weight": weight, "m_weight": mweight})
		all_slots.append(invSlot.instantiate())
		print("Inventory updated: ", mineral_type, " quality: ", quality)
	else:
		totalWeight -= weight
		dropMineral(mineral_type, quality, weight,mweight, position)
