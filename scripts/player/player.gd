extends CharacterBody2D

@export var base_movement_speed: float = 160.0
@export var backpack_size: float = 10000
var carry_capacity = 25000
@export var inspect_range: float = 81
var current_movespeed = base_movement_speed
var total_weight = 0.0

enum Mode {
	EXPLORE,
	INSPECT,
	MINE,
	INV
}

var chunk_size: int = 16
var global_chunk: Vector2i = Vector2i.ZERO
var current_mode: Mode = Mode.EXPLORE
var inspected_rock: Node2D = null

var _tool_data: Dictionary = {}
var current_tool: String   = "chisel_upgraded"

@onready var bp_node = $backpack

signal mode_changed(new_mode: Mode, rock: Node2D)
signal mineral_collected(mineral_type: String, quality: float)

func _ready() -> void:
	add_to_group("player")
	visible = true
	_load_tools()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if current_mode == Mode.INV:
			exit_inspect()
		elif current_mode == Mode.EXPLORE:
			enter_inventory(bp_node)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if get_current_mode() != Mode.INSPECT:
			return
		if get_viewport().gui_get_hovered_control():
			return
		var query = PhysicsPointQueryParameters2D.new()
		query.position = get_global_mouse_position()
		var result = get_world_2d().direct_space_state.intersect_point(query)
		var clicked_inspected_rock = false
		for r in result:
			if r.collider.get_parent() == inspected_rock:
				clicked_inspected_rock = true
				break
		if not clicked_inspected_rock:
			exit_inspect()

func move_multi() -> float:
	var load_ratio = total_weight / carry_capacity

	var start_slow := 0.6
	var full_stop := 1.0

	if load_ratio <= start_slow:
		return 1.0

	if load_ratio >= full_stop:
		return 0.0

	var t = (load_ratio - start_slow) / (full_stop - start_slow)

	var e := 2.0
	var c := pow(t, e)

	var min_speed := 0.2

	return lerp(1.0, min_speed, c)

func inv_updated(inventory: Array) -> void:
	total_weight = 0
	for item in inventory:
		total_weight += item.weight
	current_movespeed = base_movement_speed * move_multi()

func _physics_process(delta: float) -> void:
	if current_mode != Mode.EXPLORE:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction := Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()

	velocity = direction * current_movespeed
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider is RigidBody2D:
			var push_direction = (collider.global_position-global_position).normalized()
			collider.apply_force(push_direction * current_movespeed / 2.5 / collider.mass)

	if global_position.distance_to(get_global_mouse_position()) > inspect_range:
		CursorManager.reset_cursor()

	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		if direction != Vector2.ZERO:
			sprite.play("new_animation")
		else:
			sprite.play("default")

func enter_inspect_mode(rock: Node2D, zoom = -1.5, mine = true) -> void:
	if current_mode == Mode.INSPECT:
		return
	current_mode = Mode.INSPECT
	inspected_rock = rock
	if mine:
		CursorManager.set_cursor("mine")
	_set_other_rocks_visible(rock, false)
	if zoom > 0:
		mode_changed.emit(current_mode, rock, zoom)
	else:
		mode_changed.emit(current_mode, rock)
	$Camera2D/MineralInfo.show()

func enter_inventory(backpack: Node2D) -> void:
	current_mode = Mode.INV
	inspected_rock = backpack
	mode_changed.emit(current_mode, backpack)
	$Camera2D/MineralInfo.hide()

func enter_mine_mode(rock: Node2D) -> void:
	current_mode = Mode.MINE
	mode_changed.emit(current_mode, rock)
	$Camera2D/MineralInfo.hide()

func exit_inspect() -> void:
	if CursorManager.current_cursor != "idle":
		CursorManager.set_cursor("inspect")
	current_mode = Mode.EXPLORE
	inspected_rock = null
	_set_other_rocks_visible(null, true)
	mode_changed.emit(current_mode, null)
	$Camera2D/MineralInfo.hide()

func collect_mineral(mineral_type: String, quality: float, weight: float, mineral_weight: float, fragility: float) -> void:
	mineral_collected.emit(mineral_type, quality, weight,mineral_weight, fragility)
	print("Collected: ", mineral_type, " quality: ", quality, " weight: ", weight)

func get_current_mode() -> Mode:
	return current_mode

func get_inspected_rock() -> Node2D:
	return inspected_rock

func _load_tools() -> void:
	var file := FileAccess.open("res://data/narzedzia.json", FileAccess.READ)
	if not file:
		push_error("player: cannot open narzedzia.json")
		return
	var result = JSON.parse_string(file.get_as_text())
	file.close()
	if result == null:
		push_error("player: failed to parse narzedzia.json")
		return
	for tool in result["tools"]:
		_tool_data[tool["name"]] = tool
	if not _tool_data.has(current_tool):
		push_error("player: default tool '%s' not found in narzedzia.json" % current_tool)

func get_tool() -> Dictionary:
	if _tool_data.has(current_tool):
		return _tool_data[current_tool]
	push_warning("player: tool '%s' not loaded, returning neutral fallback" % current_tool)
	return {
		"name": "fallback", "type": "universal", "tier": 0,
		"efficiency":   {"metal_in_rock": 1.0, "mineral_in_rock": 1.0, "crystal_in_rock": 1.0, "loose": 1.0},
		"quality_loss": {"metal_in_rock": 0.0, "mineral_in_rock": 0.0, "crystal_in_rock": 0.0, "loose": 0.0}
	}

func _set_other_rocks_visible(excluded: Node2D, tvisible: bool) -> void:
	for rock in get_tree().get_nodes_in_group("rocks"):
		if rock == excluded:
			continue
		rock.visible = tvisible
		for child in rock.get_children():
			if child is Area2D:
				child.input_pickable = visible
