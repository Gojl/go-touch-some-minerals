extends CharacterBody2D

@export var movement_speed: float = 160.0

@onready var chunk_size = Globals.chunk_size
var global_chunk: Vector2i = Vector2i.ZERO

signal chunk_changed(new_chunk: Vector2i)

func _ready() -> void:
	Globals.player = self

func _physics_process(delta: float) -> void:
	if Globals.mode != Globals.Mode.EXPLORE:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction := Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()
	
	velocity = direction * movement_speed
	move_and_slide()

	if direction != Vector2.ZERO:
		$AnimatedSprite2D.play("new_animation")
	else:
		$AnimatedSprite2D.play("default")
