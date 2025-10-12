extends CharacterBody2D

@export var movement_speed : float = 8000.0
var charachter_direction : Vector2
@onready var chunk_size = get_parent().chunk_size
var global_chunk: Vector2i = Vector2i.ZERO

signal chunk_changed(new_chunk: Vector2i)

enum States { IDLE, WALK, ATTACK, SLAM, DEAD, HIT }
var currentState = States.IDLE

func _physics_process(delta):
	handle_state_transitions()
	perform_state_actions(delta)
	move_and_slide()

func _process(_delta: float) -> void:
	var new_chunk = Vector2i(
		floor(global_position.x / (16 * chunk_size)),
		floor(global_position.y / (16 * chunk_size))
	) * -1
	if new_chunk != global_chunk:
		global_chunk = new_chunk
		emit_signal("chunk_changed", new_chunk)

func handle_state_transitions():
	if Input.is_action_pressed("left") or Input.is_action_pressed("right") or Input.is_action_pressed("up") or Input.is_action_pressed("down"):
		currentState = States.WALK
	else:
		currentState = States.IDLE
	
func perform_state_actions(delta):
	match currentState:
		States.WALK:
			charachter_direction.x = Input.get_axis("left","right")
			charachter_direction.y = Input.get_axis("up","down")
			charachter_direction = charachter_direction.normalized()
			
			$AnimatedSprite2D.play("new_animation")
			velocity = charachter_direction * movement_speed * delta
		
		States.IDLE:
			$AnimatedSprite2D.play("default")
			velocity = velocity.move_toward(Vector2.ZERO, movement_speed * delta)
