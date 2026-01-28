extends Node2D

var is_open: bool = false
var inventory_data: Dictionary = {}
var player: Node = null

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
		show_inventory()
		update_display()
	else:
		print("Inventory closed")
		hide_inventory()

func show_inventory() -> void:
	visible = true

func hide_inventory() -> void:
	visible = false

func update_display() -> void:
	
	print("Current inventory:", inventory_data)

func _on_mineral_collected(mineral_type: String, quality: float) -> void:
	if not inventory_data.has(mineral_type):
		inventory_data[mineral_type] = []
	
	inventory_data[mineral_type].append(quality)
	print("Inventory updated: ", mineral_type, " quality: ", quality)
	
	if is_open:
		update_display()

func get_inventory() -> Dictionary:
	return inventory_data
