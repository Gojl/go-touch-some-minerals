extends CharacterBody2D

@export var base_movement_speed: float = 160.0
@export var backpack_size: float = 10000
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

@onready var bp_node = $backpack

signal mode_changed(new_mode: Mode, rock: Node2D)
signal mineral_collected(mineral_type: String, quality: float)
signal chunk_changed(new_chunk: Vector2i)

func _ready() -> void:
	add_to_group("player")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if current_mode == Mode.INV:
			exit_inspect()
		elif current_mode == Mode.EXPLORE:
			enter_inventory(bp_node)

func move_multi() -> float:
	var load_ratio = total_weight / backpack_size
	if load_ratio <= 0.8:
		return 1.0
	elif load_ratio >= 1.2:
		return 0.0
	
	var t = clamp((load_ratio - 0.8) / 0.4, 0.0, 1.0)
	var e := 2
	var c := pow(t,e)
	
	var speed_at_full := 0.5
	
	return lerp(1.0, speed_at_full, c)

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

func enter_inspect_mode(rock: Node2D) -> void:
	current_mode = Mode.INSPECT
	inspected_rock = rock
	CursorManager.set_cursor("mine")
	_set_other_rocks_visible(rock, false)
	mode_changed.emit(current_mode, rock)
	print("Entered INSPECT mode")

func enter_inventory(backpack: Node2D) -> void:
	current_mode = Mode.INV
	inspected_rock = backpack
	mode_changed.emit(current_mode, backpack)
	print("Entered inventory")

func enter_mine_mode(rock: Node2D) -> void:
	current_mode = Mode.MINE
	mode_changed.emit(current_mode, rock)
	print("Entered MINE mode")

func exit_inspect() -> void:
	if CursorManager.current_cursor != "idle":
		CursorManager.set_cursor("inspect")
	current_mode = Mode.EXPLORE
	inspected_rock = null
	_set_other_rocks_visible(null, true)
	mode_changed.emit(current_mode, null)
	print("Exited to EXPLORE mode")

func collect_mineral(mineral_type: String, quality: float, weight: float, mineral_weight: float, fragility: float) -> void:
	mineral_collected.emit(mineral_type, quality, weight,mineral_weight, fragility)
	print("Collected: ", mineral_type, " quality: ", quality, " weight: ", weight)

func get_current_mode() -> Mode:
	return current_mode

func get_inspected_rock() -> Node2D:
	return inspected_rock

func _set_other_rocks_visible(excluded: Node2D, visible: bool) -> void:
	for rock in get_tree().get_nodes_in_group("rocks"):
		if rock == excluded:
			continue
		rock.visible = visible
		var klik = rock.get_node_or_null("kamien_klik")
		if klik:
			klik.input_pickable = visible
