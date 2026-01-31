extends Control

var is_open: bool = false
var inventory_data: Dictionary = {}
var player: Node = null

@onready var grid := $body/BackpackGrid
var invSlot := preload("res://scenes/inv_slot.tscn")

var all_slots: Array[Control] = []

var current_page := 0
var items_per_page := 10

func _ready() -> void:
	await get_tree().process_frame  
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		player.mineral_collected.connect(_on_mineral_collected)
		print("Inventory connected to player")
	else:
		push_error("Inventory: Could not find player!")
	
	hide_inventory()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle_inventory()

func toggle_inventory() -> void:
	is_open = not is_open
	
	if is_open:
		print("Inventory opened")
		update_display()
		show_inventory()
	else:
		print("Inventory closed")
		hide_inventory()

func show_inventory() -> void:
	visible = true

func hide_inventory() -> void:
	visible = false

func show_page(page: int) -> void:
	var start := page*items_per_page
	var end = start + items_per_page
	
	for child in grid.get_children():
		grid.remove_child(child) 
		
	for i in range(start, min(end, all_slots.size() - start)):
		grid.add_child(all_slots[i]) 
	
func update_display() -> void:	
	show_page(0)
	print("Current inventory:", inventory_data)

func _on_mineral_collected(mineral_type: String, quality: float) -> void:
	if not inventory_data.has(mineral_type):
		inventory_data[mineral_type] = []
		
	all_slots.append(invSlot.instantiate())
		
	inventory_data[mineral_type].append(quality)
	print("Inventory updated: ", mineral_type, " quality: ", quality)
	
	if is_open:
		update_display()

func get_inventory() -> Dictionary:
	return inventory_data
