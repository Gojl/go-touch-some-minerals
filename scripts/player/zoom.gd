extends Camera2D


@export var base_inspect_zoom: float
var inspect_zoom: Vector2
@export var zoom_speed: float
var default_zoom: Vector2
var player: CharacterBody2D = null
var is_inspecting: bool = false
var target_rock: Node2D = null

func _ready():
	default_zoom = zoom


	player = get_parent() as CharacterBody2D
	if not player:
		push_error("Camera must be a child of the player CharacterBody2D")
		return

	player.mode_changed.connect(_on_player_mode_changed)

func _on_player_mode_changed(new_mode, rock: Node2D, nzoom = base_inspect_zoom) -> void:
	if new_mode == player.Mode.EXPLORE:
		is_inspecting = false
		target_rock = null
	else:
		inspect_zoom = Vector2(nzoom,nzoom)
		is_inspecting = true
		target_rock = rock
func _process(delta):
	if not player:
		return

	if is_inspecting and target_rock and player.current_mode == player.Mode.INSPECT:
		var rock_position = target_rock.global_position + Vector2(-10, 0)
		global_position = global_position.lerp(
			rock_position,
			delta * zoom_speed
		)
		zoom = zoom.lerp(inspect_zoom, delta * zoom_speed)
	elif is_inspecting and target_rock:
		global_position = global_position.lerp(
			target_rock.global_position,
			delta * zoom_speed
		)
		zoom = zoom.lerp(inspect_zoom + Vector2(5, 5), delta * zoom_speed)
	else:
		global_position = global_position.lerp(
			player.global_position,
			delta * zoom_speed
		)
		zoom = zoom.lerp(default_zoom, delta * zoom_speed)

func _input(event):
	if not player:
		return


	if is_inspecting:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			player.exit_inspect()
