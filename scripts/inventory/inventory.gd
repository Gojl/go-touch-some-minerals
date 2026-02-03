extends Control

var is_open: bool = false
var inventory_data := []
var player: Node = null

@onready var slots_container := $body/Control/backpack_grid
@onready var empty_label = $body/empty_label
@onready var invSlot := preload("res://scenes/inv_slot.tscn")
@onready var weight_label = $body/weight_label

@export var slide_time := 0.2

var droppedMineral := preload("res://scenes/dropped_mineral.tscn")

var all_slots: Array[Control] = []

var is_animating := false
var current_page := 0
var items_per_page := 10

var open = false

func _ready() -> void:
	await get_tree().process_frame  
	player = get_tree().get_first_node_in_group("player")
	
	add_to_group("inventory")
	
	inv_updated()
	
	for i in range(items_per_page):
		var slot = invSlot.instantiate()
		slots_container.add_child(slot)
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

func can_go_next() -> bool:
	return (current_page + 1) * items_per_page < inventory_data.size()

func can_go_prev() -> bool:
	return current_page > 0


func next_page():
	if is_animating or not can_go_next():
		return

	is_animating = true
	var width = slots_container.size.x

	var tween := create_tween()
	tween.tween_property(
		slots_container,
		"position:x",
		-width,
		slide_time
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func():
		current_page += 1
		show_page(current_page)

		slots_container.position.x = width

		var t2 := create_tween()
		t2.tween_property(
			slots_container,
			"position:x",
			0,
			slide_time
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

		t2.finished.connect(func():
			is_animating = false
		)
	)

func prev_page():
	if is_animating or not can_go_prev():
		return

	is_animating = true
	var width = slots_container.size.x

	var tween := create_tween()
	tween.tween_property(
		slots_container,
		"position:x",
		width,
		slide_time
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func():
		current_page -= 1
		show_page(current_page)

		slots_container.position.x = -width

		var t2 := create_tween()
		t2.tween_property(
			slots_container,
			"position:x",
			0,
			slide_time
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

		t2.finished.connect(func():
			is_animating = false
		)
	)


func crack_mineral(id: int):
	if inventory_data[id].weight <= 2.5 * inventory_data[id].mweight or inventory_data[id].weight < 30:
		print("Can't crack")
	else:
		var base_chance = 0.2
		var r = inventory_data[id].mweight / inventory_data[id].weight
		var rock_r = 1 - r
		
		var success = base_chance + pow(rock_r, 2) * 0.4
		success = clamp(success, 0, 1)
		
		if randf() < success:
			inventory_data[id].weight = (inventory_data[id].weight - inventory_data[id].mweight) * randf_range(0.7,0.9)
			inventory_data[id].weight += inventory_data[id].mweight
			print("Crack successful")
		else:
			print("Crack failed")
			var loss = randf_range(0.7,0.9)
			var hweight = (inventory_data[id].weight - inventory_data[id].mweight) * loss
			inventory_data[id].mweight *= loss - 0.05
			inventory_data[id].weight = inventory_data[id].mweight + hweight
			inventory_data[id].quality -= snapped(randf_range(0.08,0.2),0.01)
			if inventory_data[id].quality <= 0:
				inventory_data.remove_at(id)
		inv_updated()
		show_page(current_page)

func drop_mineral(id: int):
	print("Dropping mineral")
	
	if id < 0 or id >= inventory_data.size():
		return
	
	var map = player.get_parent()
	var new_dropped_mineral = droppedMineral.instantiate()
	new_dropped_mineral.global_position = player.global_position + Vector2(15, 0)
	new_dropped_mineral.type = inventory_data[id].type
	new_dropped_mineral.quality = inventory_data[id].quality
	new_dropped_mineral.weight = inventory_data[id].weight
	new_dropped_mineral.mweight = inventory_data[id].mweight
	inventory_data.remove_at(id)
	map.add_child(new_dropped_mineral)
	inv_updated()
	show_page(current_page)

func inv_updated() -> void:
	player.inv_updated(inventory_data)
	weight_label.text = str(snapped(player.total_weight / 1000, 0.01 )) + " / " + str(snapped(player.backpack_size / 1000, 0.01)) + "KG"

func _on_mineral_collected(mineral_type: String, quality: float, weight: float, mweight: float) -> void:
	inventory_data.append({"type": mineral_type, "quality": quality, "weight": weight, "mweight": mweight})
	inv_updated()
	print("Inventory updated: ", mineral_type, " quality: ", quality)
