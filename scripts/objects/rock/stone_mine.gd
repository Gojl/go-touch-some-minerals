extends Node2D

var mineral_type: String       = "iron"
var generation_type: String    = "mineral_in_rock"

var base_mineral_quality: float = 0.55
var quality_variation:    float = 0.2
var mineral_fragility:    int   = 2
var mohs_hardness:        float = 4.0
var mineral_percentage:   float = 0.45
var weight:               float = 5000.0
var mineral_weight:       float = 2250.0


var base_mineral_health: float:
	get:
		return 25.0 + mohs_hardness * 4.0

var max_charge_time := 1.5
var max_force       := 100.0

@onready var mine_area:   Area2D          = $MineArea
@onready var mine_shape:  CollisionShape2D = $MineArea/CollisionShape2D

var charging      := false
var charge_time   := 0.0
var mineral_health: float
var mineral_quality: float
var start_min_qual: float
var player: Node = null

func _ready() -> void:
	add_to_group("rocks")
	mineral_health  = base_mineral_health
	mineral_quality = clamp(
		base_mineral_quality + randf_range(-quality_variation, quality_variation),
		0.0, 1.0
	)
	start_min_qual  = mineral_quality

	$MineArea.connect("input_event", Callable(self, "_on_mine_input"))

	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("stone_mine: Could not find player node in group 'player'!")

func _on_mine_input(_viewport, event, _shape_idx) -> void:
	if not player:
		return
	if player.get_current_mode() != player.Mode.MINE:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			charging   = true
			charge_time = 0.0
		else:
			release_hit()

func get_core_global_position() -> Vector2:
	return mine_area.global_position + mine_shape.position

func _process(delta: float) -> void:
	if charging:
		charge_time = min(charge_time + delta, max_charge_time)

func release_hit() -> void:
	if not charging:
		return
	charging = false
	var force := (charge_time / max_charge_time) * max_force
	charge_time = 0.0
	apply_hit(force, get_global_mouse_position())

func apply_hit(force: float, hit_pos: Vector2) -> void:
	var tool          = player.get_tool() if player else {}
	var efficiency    := 1.0
	var ql_bonus      := 0.0
	if not tool.is_empty() and tool.has("efficiency"):
		efficiency = float(tool["efficiency"].get(generation_type, 1.0))
		ql_bonus   = float(tool["quality_loss"].get(generation_type, 0.0))

	var eff_force := force * efficiency

	var core_pos    := get_core_global_position()
	var dist        := hit_pos.distance_to(core_pos)

	var core_radius      := 2.0
	var ideal_radius     := 3.0
	var core_force_scale := 20.0

	if dist <= core_radius:
		var dist_factor := 2.0 - (dist / core_radius)
		var loss := (float(mineral_fragility) / 5.0 + ql_bonus) * (1.0 + force / core_force_scale) * dist_factor / 10.0
		mineral_quality -= loss

	elif dist <= ideal_radius:
		if force >= base_mineral_health * 2.0:
			mineral_health  = 0.0
			mineral_quality = 0.0
		else:
			var ideal_force     := base_mineral_health * 0.97
			var max_force_error := base_mineral_health * 0.9
			var force_ratio     := force / ideal_force
			var force_error      = abs(force - ideal_force)
			var error_norm       = clamp(force_error / max_force_error, 0.0, 1.0)
			var loss_factor     := pow(error_norm, 3.5)

			loss_factor = max(loss_factor, error_norm * 0.08)

			if   force_ratio < 0.35: loss_factor += 0.60
			elif force_ratio < 0.60: loss_factor += 0.35
			elif force_ratio > 1.60: loss_factor += 0.80
			elif force_ratio > 1.25: loss_factor += 0.45

			if force < ideal_force:
				var hp_ratio       = clamp(mineral_health / base_mineral_health, 0.0, 1.0)
				var weak_hp_factor := lerpf(0.4, 1.0, pow(hp_ratio, 4.0))
				loss_factor *= weak_hp_factor
			else:
				loss_factor  = loss_factor * 2.2 + pow(error_norm, 1.2)

			var absorbed_force = min(eff_force, mineral_health)
			var excess_force    = max(eff_force - mineral_health, 0.0)

			loss_factor *= start_min_qual * start_min_qual
			mineral_health -= absorbed_force

			if excess_force > 0.0:
				var excess_loss := clampf(excess_force / (base_mineral_health * 0.5), 0.0, 1.0)
				loss_factor    += pow(excess_loss * 1.35, 1.05)

			mineral_quality -= (float(mineral_fragility) + ql_bonus) * loss_factor / 10

	mineral_quality = snapped(clamp(mineral_quality, 0.0, 1.0), 0.01)
	_check_result()

func _check_result() -> void:
	if mineral_health <= 0.0 or mineral_quality <= 0.0:
		finish_mining()

func finish_mining() -> void:
	if not player:
		queue_free()
		return

	if mineral_quality > 0.0:
		player.collect_mineral(mineral_type, mineral_quality, weight, mineral_weight, mineral_fragility)
		player.exit_inspect()
	else:
		print("stone_mine: mineral destroyed — no yield for", mineral_type)
		player.exit_inspect()

	queue_free()
