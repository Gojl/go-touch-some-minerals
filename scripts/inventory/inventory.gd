# inventory.gd
extends Control

enum Mode { GAMEPLAY, UI_DISPLAY }

@export var mode: Mode = Mode.GAMEPLAY

var player: Node = null

@onready var slots_container := $Control/backpack_grid
@onready var empty_label     = $empty_label
@onready var weight_label    = $weight_label
@onready var weight_label_ui = $weight_label_ui
@onready var money_label     = $money_label
@onready var money_label_ui  = $money_label_ui

@onready var invSlot        := preload("res://scenes/inv_slot.tscn")
var droppedMineral          := preload("res://scenes/dropped_mineral.tscn")

@export var slide_time := 0.1

var all_slots: Array[Control] = []
var is_animating  := false
var is_open       := false
var current_page  := 0
var items_per_page := 10

var _base_prices: Dictionary


func _ready() -> void:
	await get_tree().process_frame

	if not _load_data():
		return

	add_to_group("inventory")

	for i in range(items_per_page):
		var slot = invSlot.instantiate()
		if mode == Mode.GAMEPLAY:
			slot.get_node("sell_button").visible = false
		else:
			slot.get_node("crack_button").visible = false
			slot.get_node("drop_button").visible = false
		slots_container.add_child(slot)
		all_slots.append(slot)
		slot.hide()

	if mode == Mode.GAMEPLAY:
		_init_gameplay()
	else:
		_init_ui_display()


# ========= GAMEPLAY mode =========

func _init_gameplay() -> void:
	player = get_tree().get_first_node_in_group("player")

	if not player:
		push_error("Inventory [GAMEPLAY]: no player node")
		return

	player.mineral_collected.connect(_on_mineral_collected)
	player.mode_changed.connect(_on_toggle_inventory)

	scale = Vector2.ZERO
	rotation_degrees = -90
	visible = false
	
	weight_label_ui.visible = false
	money_label_ui.visible = false

	_refresh_labels()


func _process(delta: float) -> void:
	if mode != Mode.GAMEPLAY:
		return

	if is_open:
		scale = scale.lerp(Vector2(0.018, 0.018), delta * 10)
		rotation_degrees = lerpf(rotation_degrees, 0.0, delta * 10)
	else:
		scale = scale.lerp(Vector2.ZERO, delta * 10)
		rotation_degrees = lerpf(rotation_degrees, -90.0, delta * 10)

	visible = scale > Vector2(0.003, 0.003)


func _on_toggle_inventory(new_mode, bp_node: Node2D, _zoom = null) -> void:
	if new_mode == player.Mode.INV:
		position = bp_node.position
		show_page(current_page)
		_open()
	else:
		_close()


func _open() -> void:
	is_open = true


func _close() -> void:
	for i in range(Game.inventory.size()):
		all_slots[i % items_per_page].hide()
	is_open = false


# ========= UI_DISPLAY mode =========

func _init_ui_display() -> void:
	player = get_tree().get_first_node_in_group("player")

	visible = true
	
	weight_label.visible = false
	money_label.visible = false
	
	$body.visible = false
	$empty_label.text = "You don't have any minerals"

	show_page(0)
	_refresh_labels()


# ========= shared logic =========

func show_page(page: int) -> void:
	current_page = page
	var start := page * items_per_page

	if Game.inventory.is_empty():
		empty_label.visible = true
		for s in all_slots:
			s.hide()
			s.clear()
		return

	empty_label.visible = false

	for slot_index in range(items_per_page):
		var data_index := start + slot_index
		var slot       := all_slots[slot_index]

		if data_index < Game.inventory.size():
			var item = Game.inventory[data_index]
			slot.show()
			slot.set_slot_data(
				item.type, item.quality, item.weight,
				item.mweight, data_index
			)
		else:
			slot.hide()
			slot.clear()


func can_go_next() -> bool:
	return (current_page + 1) * items_per_page < Game.inventory.size()

func can_go_prev() -> bool:
	return current_page > 0


func next_page() -> void:
	if is_animating or not can_go_next():
		return
	_slide_page(1)


func prev_page() -> void:
	if is_animating or not can_go_prev():
		return
	_slide_page(-1)


func _slide_page(direction: int) -> void:
	is_animating = true
	var width:float = slots_container.size.x
	var exit_x := -width * direction

	var t1 := create_tween()
	t1.tween_property(slots_container, "position:x", exit_x, slide_time)\
	  .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t1.finished.connect(func():
		current_page += direction
		show_page(current_page)
		slots_container.position.x = width * direction

		var t2 := create_tween()
		t2.tween_property(slots_container, "position:x", 0.0, slide_time)\
		  .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		t2.finished.connect(func(): is_animating = false)
	)


# ========= item actions =========

func crack_mineral(id: int) -> void:
	var item = Game.inventory[id]

	if item.weight <= 1.75 * item.mweight or item.weight < 30:
		Notifications.notify("Can't crack")
		return

	var r: float = item.mweight / item.weight
	var rock_r := 1.0 - r
	var success: float = (0.2 + pow(rock_r, 2) * 0.4) / (item.fragility / 2.2)
	success = clamp(success, 0.0, 1.0)

	if randf() < success:
		Game.inventory[id].weight = (item.weight - item.mweight) * randf_range(0.7, 0.9) + item.mweight
		Notifications.notify("Crack successful")
	else:
		Notifications.notify("Crack failed")
		var loss := randf_range(0.7, 0.9)
		Game.inventory[id].mweight *= loss - 0.05
		Game.inventory[id].weight   = Game.inventory[id].mweight + (item.weight - item.mweight) * loss
		Game.inventory[id].quality -= snapped(randf_range(0.08, 0.2), 0.01)
		if Game.inventory[id].quality <= 0.0:
			Game.inventory.remove_at(id)

	_after_change()


func drop_mineral(id: int) -> void:
	if mode != Mode.GAMEPLAY or not player:
		push_warning("Inventory: drop_mineral niedostępny w trybie UI_DISPLAY")
		return

	if id < 0 or id >= Game.inventory.size():
		return

	Notifications.notify("Dropping mineral")

	var map   := player.get_parent()
	var piece := droppedMineral.instantiate()
	var item   = Game.inventory[id]

	piece.global_position = player.global_position + Vector2(15, 0)
	piece.type      = item.type
	piece.quality   = item.quality
	piece.weight    = item.weight
	piece.mweight   = item.mweight
	piece.fragility = item.fragility
	piece.add_to_group("rocks")

	Game.inventory.remove_at(id)
	map.add_child(piece)
	_after_change()


func sell_mineral(id: int) -> void:
	if id < 0 or id >= Game.inventory.size():
		return

	var item = Game.inventory[id]
	Game.money += snapped(
		snapped(item.mweight, 1) * _base_prices[item.type] * pow(item.quality, 0.85),
		0.01
	)
	Game.inventory.remove_at(id)
	_after_change()


func _after_change() -> void:
	_refresh_labels()
	show_page(current_page)
	Game.save_data()


func _refresh_labels() -> void:
	money_label.text = str(Game.money) + " PLN"
	money_label_ui.text = money_label.text

	if player:
		weight_label.text = \
			str(snapped(player.total_weight / 1000.0, 0.01)) + \
			" / " + str(snapped(player.backpack_size / 1000.0, 0.01)) + " KG"
		weight_label_ui.text = weight_label.text
	else:
		var total := 0.0
		for item in Game.inventory:
			total += item.weight
		weight_label.text = str(snapped(total / 1000.0, 0.01)) + " KG"
		weight_label_ui.text = weight_label.text


# ========= player signals ==========

func _on_mineral_collected(
	mineral_type: String, quality: float,
	weight: float, mweight: float, fragility: float
) -> void:
	Game.inventory.append({
		"type": mineral_type, "quality": quality,
		"weight": weight, "mweight": mweight, "fragility": fragility
	})

	if player.total_weight + weight > player.backpack_size:
		drop_mineral(Game.inventory.size() - 1)
	else:
		_after_change()
		player.inv_updated(Game.inventory)


# ========= helpers =========

func _load_data() -> bool:
	_base_prices = _read_json("res://data/prices.json")
	return _base_prices != null


func _read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Inventory: nie można otworzyć '%s'" % path)
		return null
	var result = JSON.parse_string(file.get_as_text())
	file.close()
	if result == null:
		push_error("Inventory: błąd parsowania JSON '%s'" % path)
	return result
