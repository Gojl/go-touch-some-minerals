extends Node2D

@export var max_charge_time := 1.5
@export var max_force := 100.0

@onready var mine_area: Area2D = $MineArea
@onready var mine_shape: CollisionShape2D = $MineArea/CollisionShape2D

var charging := false
var charge_time := 0.0
var mineral_health := 100.0
var mineral_quality := 1.0  # 1.0 = idealna

func _ready() -> void:
	$MineArea.connect("input_event", Callable(self, "_on_mine_input"))

func _on_mine_input(viewport, event, shape_idx):
	if Globals.mode != Globals.Mode.MINE:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				print("ZACZYNAM ŁADOWANIE")
				charging = true
				charge_time = 0.0
			else:
				print("PUSZCZAM – UDERZENIE")
				release_hit()

func get_core_global_position() -> Vector2:
	return mine_area.global_position + mine_shape.position

func _process(delta):
	if charging:
		charge_time += delta
		charge_time = min(charge_time, max_charge_time)

func release_hit():
	if not charging:
		print("PUŚCILIŚ, ALE NIE BYŁO CHARGE")
		return

	charging = false

	var force := (charge_time / max_charge_time) * max_force
	charge_time = 0.0  # ← WAŻNE
	print("SIŁA UDERZENIA:", force)
	var mouse_pos := get_global_mouse_position() 
	apply_hit(force, mouse_pos)



func apply_hit(force: float, hit_pos: Vector2):
	var core_pos := get_core_global_position()
	var dist := hit_pos.distance_to(core_pos)

	var core_radius := 2.0        # ZA BLISKO – psujesz
	var ideal_radius := 3.0      # IDEALNE KOPANIE

	if dist <= core_radius:
		print("RDZEŃ – PSUJESZ")
		mineral_quality -= force * 0.005

	elif dist <= ideal_radius:
		print("IDEALNE UDERZENIE – KOPIESZ")
		if force > mineral_health:
			mineral_quality -= (force-mineral_health)*0.005
			mineral_health=0 
		else: 
			mineral_health -= force
			mineral_quality -= 0.1/force
	else:
		print("ZA DALEKO – NIC SIĘ NIE DZIEJE")

	mineral_quality = clamp(mineral_quality, 0.0, 1.0)
	check_result()


func check_result():
	if mineral_health <= 0:
		finish_mining(true)
	if mineral_quality == 0.0:
		finish_mining(false)
		

func finish_mining(success: bool):
	if success:
		print("MINERAŁ WYDOBYTY, jakość:", mineral_quality)
		Globals.exit_inspect()
		queue_free()
	else:
		print("MINERAŁ ZNISZCZONY, jakość:", mineral_quality)
		Globals.exit_inspect()
		queue_free()
	
