extends TextureButton

var mineral: Node2D = null
var player: Node = null
var slot = null

func _mouse_entered() -> void:
	CursorManager.set_cursor("select")
func _mouse_exited() -> void:
	CursorManager.reset_cursor()

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	mineral = get_parent().get_parent().get_parent()
	slot = get_parent()
	mouse_entered.connect(_mouse_entered)
	mouse_exited.connect(_mouse_exited)

func _pressed() -> void:
	if mineral:
		if mineral.weight <= 1.75 * mineral.mweight or mineral.weight < 30:
			print("Can't crack")
		else:
			var base_chance = 0.2
			var r = mineral.mweight / mineral.weight
			var rock_r = 1 - r

			var success = (base_chance + pow(rock_r, 2) * 0.4) / (mineral.fragility / 2.2)
			success = clamp(success, 0, 1)

			if randf() < success:
				mineral.weight = (mineral.weight - mineral.mweight) * randf_range(0.7,0.9)
				mineral.weight += mineral.mweight
				print("Crack successful")
			else:
				print("Crack failed")
				var loss = randf_range(0.7,0.9)
				var hweight = (mineral.weight - mineral.mweight) * loss
				mineral.mweight *= loss - 0.05
				mineral.weight = mineral.mweight + hweight
				mineral.quality -= snapped(randf_range(0.08,0.2),0.01)
				if mineral.quality <= 0:
					if player:
						player.exit_inspect()
					mineral.queue_free()
		if slot:
			slot.mineral_updated()
