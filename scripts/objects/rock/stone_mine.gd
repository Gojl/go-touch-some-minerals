extends Node2D
var max_charge_time := 1.5
var max_force := 100.0
var base_mineral_quality: float = 0.65
var mineral_quality_randomness_up: float = 0.35
var mineral_quality_randomness_down: float = 0.1
var base_mineral_health: float = 50
var mineral_type: String = "Gold"
var mineral_fragility: float = 0.1
var mineral_tier: int = 1 
var weight: float = 1
var mineral_percentage = 1

@onready var mine_area: Area2D = $MineArea
@onready var mine_shape: CollisionShape2D = $MineArea/CollisionShape2D

var charging := false
var charge_time := 0.0
var mineral_health := base_mineral_health
var mineral_quality := 0.0
var start_min_qual := 0.0
var player: Node = null

func _ready() -> void:
	mineral_quality = randf_range(-mineral_quality_randomness_down, mineral_quality_randomness_up) + base_mineral_quality
	$MineArea.connect("input_event", Callable(self, "_on_mine_input"))
	start_min_qual = mineral_quality
	# Wait for scene to be ready, then find player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	if not player:
		push_error("Stone mine: Could not find player!")

func _on_mine_input(viewport, event, shape_idx):
	if not player:
		return
	
	var current_mode = player.get_current_mode()
	if current_mode != player.Mode.MINE:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				print("STARTING CHARGE")
				charging = true
				charge_time = 0.0
			else:
				print("RELEASE - HIT")
				release_hit()

func get_core_global_position() -> Vector2:
	return mine_area.global_position + mine_shape.position

func _process(delta):
	if charging:
		charge_time += delta
		charge_time = min(charge_time, max_charge_time)

func release_hit():
	if not charging:
		print("RELEASED, BUT NO CHARGE")
		return

	charging = false

	var force := (charge_time / max_charge_time) * max_force
	charge_time = 0.0
	print("HIT FORCE:", force)
	var mouse_pos := get_global_mouse_position() 
	apply_hit(force, mouse_pos)

func apply_hit(force: float, hit_pos: Vector2):
	var core_pos := get_core_global_position()
	var dist := hit_pos.distance_to(core_pos)

	var core_radius := 2.0       
	var ideal_radius := 3.0      
	var core_force_scale := 20.0

	if dist <= core_radius:
		print("CORE - DAMAGING QUALITY")
		var dist_factor := 2.0 - (dist / core_radius)
		var loss := mineral_fragility * (1.0 + force / core_force_scale) * dist_factor
		mineral_quality -= loss

	elif dist <= ideal_radius:
		if force >= base_mineral_health * 2.0:
			mineral_health = 0
			mineral_quality = 0
			print("IDEAL HIT - skill issue lmao")
		else:
			var ideal_force := base_mineral_health * 0.97
			var max_force_error := base_mineral_health * 0.9
			var force_ratio = force / ideal_force
			var force_error = abs(force - ideal_force)
			var error_norm = clamp(force_error / max_force_error, 0.0, 1.0)
			var loss_factor := pow(error_norm, 3.5)
			var min_ideal_loss := 0.08
			loss_factor = max(loss_factor, error_norm * min_ideal_loss)

			if force_ratio < 0.35:
				loss_factor += 0.6
			elif force_ratio < 0.6:
				loss_factor += 0.35
			elif force_ratio > 1.6:
				loss_factor += 0.8
			elif force_ratio > 1.25:
				loss_factor += 0.45

			if force < ideal_force:
				var hp_ratio = clamp(mineral_health / base_mineral_health, 0.0, 1.0)
				var weak_hp_factor := lerpf(0.4, 1.0, pow(hp_ratio, 4.0))
				loss_factor *= weak_hp_factor
			else: 
				loss_factor *= 2.2
				loss_factor += pow(error_norm, 1.2)

			var absorbed_force = min(force, mineral_health)
			var excess_force = max(force - mineral_health, 0.0)
			
			loss_factor *= start_min_qual**2
			
			mineral_health -= absorbed_force
		
			if excess_force > 0:
				var excess_force_scale := base_mineral_health * 0.5
				var excess_quality_loss := clampf(excess_force / excess_force_scale, 0.0, 1.0)
				excess_quality_loss *= 1.5
				excess_quality_loss **= 1.35
				loss_factor += excess_quality_loss
				
			mineral_quality -= mineral_fragility * loss_factor
			print("IDEAL HIT - good hit")
	else:
		print("TOO FAR - NOTHING HAPPENS")

	mineral_quality = snapped(clamp(mineral_quality, 0.0, 1.0), 0.01)
	check_result()

func check_result():
	if mineral_health <= 0 or mineral_quality <= 0:
		finish_mining()

func calc_mined_chunk_host_rock(mineral_weight: float) -> float:
	var rock_scale := 3.0
	var exponent := 1.1
	var min_host := 50.0
	
	var host_rock := rock_scale * pow(mineral_weight, exponent)
	host_rock = max(host_rock,min_host)
	
	return host_rock
	
func finish_mining():
	if not player:
		queue_free()
		return	
	var mineral_weight = weight
	weight = calc_mined_chunk_host_rock(mineral_weight)
	weight = snapped(weight + mineral_weight,0.01)
	if mineral_quality > 0:
		player.collect_mineral(mineral_type, mineral_quality, weight, mineral_weight)
		player.exit_inspect()
		queue_free()
	else:
		print("MINERAL DESTROYED, no mineral obtained")
		player.exit_inspect()
		queue_free()
