extends CharacterBody2D

@export var movement_speed: float = 160.0
@export var backpack_size: float = 10000
@export var inspect_range: float = 108

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

func _physics_process(delta: float) -> void:
	if current_mode != Mode.EXPLORE:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var direction := Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()
	
	velocity = direction * movement_speed
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider is RigidBody2D:
			var push_direction = (collider.global_position-global_position).normalized()
			collider.apply_force(push_direction * movement_speed / 2.5 / collider.mass)
	
	
	
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		if direction != Vector2.ZERO:
			sprite.play("new_animation")
		else:
			sprite.play("default")

func enter_inspect_mode(rock: Node2D) -> void:
	current_mode = Mode.INSPECT
	inspected_rock = rock
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
	current_mode = Mode.EXPLORE
	inspected_rock = null
	mode_changed.emit(current_mode, null)
	print("Exited to EXPLORE mode")

func collect_mineral(mineral_type: String, quality: float, weight: float, mineral_weight: float, rock_position: Vector2) -> void:
	mineral_collected.emit(mineral_type, quality, weight,mineral_weight, rock_position)
	print("Collected: ", mineral_type, " quality: ", quality, " weight: ", weight)

func get_current_mode() -> Mode:
	return current_mode

func get_inspected_rock() -> Node2D:
	return inspected_rock
