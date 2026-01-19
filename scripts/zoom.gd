extends Camera2D

@export var inspect_zoom := Vector2(35, 35)
@export var zoom_speed := 4.0
var default_zoom: Vector2

func _ready():
	default_zoom = zoom
	
func _process(delta):
	if Globals.mode != Globals.Mode.EXPLORE and Globals.inspected_rock:
		global_position = global_position.lerp(
			Globals.inspected_rock.global_position,
			delta * zoom_speed
		)
		zoom = zoom.lerp(inspect_zoom, delta * zoom_speed)
	else:
		global_position = global_position.lerp(
			Globals.player.global_position,
			delta * zoom_speed
		)
		zoom = zoom.lerp(default_zoom, delta * zoom_speed)


func _input(event):
	if Globals.mode != Globals.Mode.EXPLORE:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			Globals.exit_inspect()
