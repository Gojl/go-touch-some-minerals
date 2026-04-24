extends Control

var is_open: bool = false
var player: Node = null

@onready var slots_container := $body/Control/backpack_grid
@onready var empty_label = $body/empty_label
@onready var invSlot := preload("res://scenes/inv_slot.tscn")
@onready var weight_label = $body/weight_label
@onready var money_label = $body/money_label

@export var slide_time := 0.1

var droppedMineral := preload("res://scenes/dropped_mineral.tscn")

var all_slots: Array[Control] = []


var is_animating := false
var current_page := 0
var items_per_page := 10

var _base_prices: Dictionary

var open = false

func _ready() -> void:
	await get_tree().process_frame
	if not _load_data():
		return
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
		player.mode_changed.connect(_on_toggle_inventory)
	else:
		push_error("Inventory: Could not find player!")

	scale = Vector2(0,0)
	rotation_degrees = -90

func _load_data() -> bool:
	_base_prices = _read_json("res://data/prices.json")

	if _base_prices == null:
		return false

	return true

func _read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("inventory: cannot open '%s'" % path)
		return null
	var text := file.get_as_text()
	file.close()
	var result = JSON.parse_string(text)
	if result == null:
		push_error("inventory: JSON parse failed for '%s'" % path)
	return result

func _process(delta):
	if open:
		scale = scale.lerp(Vector2(0.018,0.018), delta * 10)
		rotation_degrees = lerpf(rotation_degrees, 0, delta * 10)
	else:
		scale = scale.lerp(Vector2(0,0), delta * 10)
		rotation_degrees = lerpf(rotation_degrees, -90, delta * 10)
	if scale <= Vector2(0.003,0.003):
		visible = false
	else:
		visible = true

func _on_toggle_inventory(newMode, bpNode: Node2D, _useless_zoom = null) -> void:
	if newMode == player.Mode.INV:
		position = bpNode.position
		show_page(current_page)
		show_inventory()
	else:
		hide_inventory()

func show_inventory() -> void:
	open = true

func hide_inventory() -> void:
	for i in range(Game.inventory.size()):
		var slot_to_show = all_slots[i % 10]
		slot_to_show.hide()
	open = false

func show_page(page: int) -> void:
	var start := page*items_per_page

	if Game.inventory.size() > 0:
		empty_label.visible = false
		for slot_index in range(items_per_page):
			var data_index := start + slot_index
			var slot := all_slots[slot_index]

			if data_index < Game.inventory.size():
				var item = Game.inventory[data_index]
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
	return (current_page + 1) * items_per_page < Game.inventory.size()

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
	if Game.inventory[id].weight <= 1.75 * Game.inventory[id].mweight or Game.inventory[id].weight < 30:
		Notifications.notify("Can't crack")
	else:
		var base_chance = 0.2
		var r = Game.inventory[id].mweight / Game.inventory[id].weight
		var rock_r = 1 - r

		var success = (base_chance + pow(rock_r, 2) * 0.4) / (Game.inventory[id].fragility / 2.2)
		success = clamp(success, 0, 1)

		if randf() < success:
			Game.inventory[id].weight = (Game.inventory[id].weight - Game.inventory[id].mweight) * randf_range(0.7,0.9)
			Game.inventory[id].weight += Game.inventory[id].mweight
			Notifications.notify("Crack successful")
		else:
			Notifications.notify("Crack failed")
			var loss = randf_range(0.7,0.9)
			var hweight = (Game.inventory[id].weight - Game.inventory[id].mweight) * loss
			Game.inventory[id].mweight *= loss - 0.05
			Game.inventory[id].weight = Game.inventory[id].mweight + hweight
			Game.inventory[id].quality -= snapped(randf_range(0.08,0.2),0.01)
			if Game.inventory[id].quality <= 0:
				Game.inventory.remove_at(id)
		inv_updated()
		show_page(current_page)

func drop_mineral(id: int):
	Notifications.notify("Dropping mineral")

	if id < 0 or id >= Game.inventory.size():
		return

	var map = player.get_parent()
	var new_dropped_mineral = droppedMineral.instantiate()
	new_dropped_mineral.global_position = player.global_position + Vector2(15, 0)
	new_dropped_mineral.type = Game.inventory[id].type
	new_dropped_mineral.quality = Game.inventory[id].quality
	new_dropped_mineral.weight = Game.inventory[id].weight
	new_dropped_mineral.mweight = Game.inventory[id].mweight
	new_dropped_mineral.fragility = Game.inventory[id].fragility
	new_dropped_mineral.add_to_group("rocks")
	Game.inventory.remove_at(id)
	map.add_child(new_dropped_mineral)
	inv_updated()
	show_page(current_page)

func inv_updated() -> void:
	player.inv_updated(Game.inventory)
	weight_label.text = str(snapped(player.total_weight / 1000, 0.01 )) + " / " + str(snapped(player.backpack_size / 1000, 0.01)) + " KG"
	money_label.text = str(Game.money) + " PLN"
	Game.save_data()

func _on_mineral_collected(mineral_type: String, quality: float, weight: float, mweight: float, fragility: float) -> void:
	Game.inventory.append({"type": mineral_type, "quality": quality, "weight": weight, "mweight": mweight, "fragility": fragility})
	if player.total_weight + weight > player.backpack_size:
		drop_mineral(Game.inventory.size()-1)
	else:
		inv_updated()

func sell_mineral(id: int):
	if id < 0 or id >= Game.inventory.size():
		return
	Game.money += snapped(snapped(Game.inventory[id].mweight,1) * _base_prices[Game.inventory[id].type] * pow(Game.inventory[id].quality,0.85),0.01)
	Game.inventory.remove_at(id)
	inv_updated()
	show_page(current_page)
