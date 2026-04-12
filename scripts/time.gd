extends CanvasModulate

@export var cycle_length := 900.0

var time := 0.0

func _process(delta):
	time += delta
	if time >= cycle_length:
		time = cycle_length
	var t = time / cycle_length
	update_day_night(t)


func update_day_night(t):
	var day_end = 0.66

	var col = Color.WHITE

	if t < day_end:
		var day_progress = t / day_end
		col = Color(1.0, 0.95, 0.85).lerp(Color(1.0, 0.6, 0.4, 0.9), day_progress)
	else:
		var night_progress = (t - day_end) / (1.0 - day_end)
		col = Color(1.0, 0.6, 0.3).lerp(Color(0.2, 0.25, 0.4), night_progress)

	color = col
