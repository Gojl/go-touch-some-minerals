extends Node2D

var mineral_type:       String = "iron"
var generation_type:    String = "mineral_in_rock"

var base_mineral_quality: float = 0.55
var quality_variation:    float = 0.2
var mineral_fragility:    int   = 2
var mohs_hardness:        float = 4.0
var mineral_percentage:   float = 0.45
var weight:               float = 5000.0
var mineral_weight:       float = 2250.0

var first_hit:            bool  = true

var _cores: Array = []

const MINERAL_CORES := {
	"iron":    [{ "offset": Vector2( 0.0,  0.0), "a": 4.5, "b": 4.5, "angle": 0.0,  "ideal_ratio": 1.7 }],
	"calcite": [{ "offset": Vector2( 0.0,  0.0), "a": 5.5, "b": 5.0, "angle": 0.0,  "ideal_ratio": 1.6 }],
	"topaz":   [{ "offset": Vector2( 0.0,  0.0), "a": 3.5, "b": 3.5, "angle": 0.0,  "ideal_ratio": 1.5 }],
	"agate":   [{ "offset": Vector2( 0.0,  0.0), "a": 4.5, "b": 4.0, "angle": 0.0,  "ideal_ratio": 1.7 }],

	"amethyst": [
		{ "offset": Vector2(-3.0, -2.0), "a": 2.5, "b": 2.0, "angle": -0.3, "ideal_ratio": 1.8 },
		{ "offset": Vector2( 2.0,  2.0), "a": 1.8, "b": 1.8, "angle":  0.0, "ideal_ratio": 1.8 }
	],

	"malachite": [
		{ "offset": Vector2(-2.0, -4.0), "a": 3.0, "b": 2.0, "angle":  0.3, "ideal_ratio": 1.8 },
		{ "offset": Vector2(-5.0, -1.0), "a": 2.0, "b": 2.5, "angle": -0.2, "ideal_ratio": 1.8 },
		{ "offset": Vector2(-3.0,  2.0), "a": 2.0, "b": 2.0, "angle":  0.0, "ideal_ratio": 1.8 }
	],

	"pyrite": [
		{ "offset": Vector2( 0.0, -3.0), "a": 2.0, "b": 1.5, "angle":  0.0, "ideal_ratio": 1.8 },
		{ "offset": Vector2(-4.0,  0.0), "a": 2.0, "b": 2.0, "angle":  0.5, "ideal_ratio": 1.8 },
		{ "offset": Vector2( 1.0,  1.0), "a": 2.5, "b": 2.0, "angle": -0.3, "ideal_ratio": 1.8 }
	],

	"quartz": [
		{ "offset": Vector2(-2.0, -4.0), "a": 3.5, "b": 2.0, "angle": -0.4, "ideal_ratio": 1.7 },
		{ "offset": Vector2(-4.0,  1.0), "a": 3.0, "b": 2.0, "angle":  0.3, "ideal_ratio": 1.7 }
	],
}

const CORE_TEMPLATES := {
	"loose": {
		"count_min": 1, "count_max": 1,
		"a_min": 10.0, "a_max": 14.0, "b_ratio": 0.9, "angle_jitter": 0.3,
		"ideal_ratio": 2.0, "spread": 0.0, "arrangement": "random"
	},
	"mineral_in_rock": {
		"count_min": 1, "count_max": 2,
		"a_min": 4.0, "a_max": 6.0, "b_ratio": 0.75, "angle_jitter": 0.6,
		"ideal_ratio": 1.8, "spread": 4.0, "arrangement": "random"
	},
	"metal_in_rock": {
		"count_min": 1, "count_max": 2,
		"a_min": 2.5, "a_max": 4.0, "b_ratio": 0.65, "angle_jitter": 0.8,
		"ideal_ratio": 1.6, "spread": 6.0, "arrangement": "random"
	},
	"crystal_in_rock": {
		"count_min": 2, "count_max": 4,
		"a_min": 2.0, "a_max": 3.5, "b_ratio": 0.55, "angle_jitter": 1.2,
		"ideal_ratio": 1.5, "spread": 8.0, "arrangement": "radial"
	}
}


var base_mineral_health: float:
	get:
		return 25.0 + mohs_hardness * 4.0

var max_charge_time := 1.5
var max_force       := 100.0

@onready var mine_area:   Area2D          = $MineArea
@onready var mine_shape:  CollisionShape2D = $MineArea/CollisionShape2D
@onready var sprite: Sprite2D = $collider/Sprite2D

var charging      := false
var charge_time   := 0.0
var mineral_health: float
var mineral_quality: float
var start_min_qual: float
var player: Node = null

var default_texture = preload("res://assets/rock_1.png")

var mineral_textures = {
	#"gold": preload("res://assets/gold.png"),
	"iron": preload("res://assets/Ferrum.png"),
	#"galena": preload("res://assets/galena.png"),
	#"silver": preload("res://assets/silver.png"),
	#"copper": preload("res://assets/copper.png"),
	"pyrite": preload("res://assets/pyrite.png"),
	#"fluorite": preload("res://assets/fluorite.png"),
	"calcite": preload("res://assets/calcite.png"),
	"malachite": preload("res://assets/malachite.png"),
	"topaz": preload("res://assets/topaz.png"),
	"amethyst": preload("res://assets/amethyst.png"),
	"quartz": preload("res://assets/quartz.png"),
	#"opal": preload("res://assets/opal.png"),
	#"amber": preload("res://assets/amber.png"),
	"agate": preload("res://assets/agate.png")
}

func update_texture():
	if mineral_type in mineral_textures:
		sprite.texture = mineral_textures[mineral_type]
	else:
		sprite.texture = default_texture

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
	update_texture()
	_generate_cores()

func _generate_cores() -> void:
	_cores.clear()
	if MINERAL_CORES.has(mineral_type):
		for entry in MINERAL_CORES[mineral_type]:
			_cores.append(entry.duplicate())
		return
	var tmpl: Dictionary = CORE_TEMPLATES.get(generation_type, CORE_TEMPLATES["mineral_in_rock"])
	var count  := randi_range(int(tmpl["count_min"]), int(tmpl["count_max"]))
	var spread : float = tmpl["spread"]
	for i in range(count):
		var a      := randf_range(float(tmpl["a_min"]), float(tmpl["a_max"]))
		var b      := a * randf_range(float(tmpl["b_ratio"]), 1.0)
		var angle  := randf_range(-float(tmpl["angle_jitter"]), float(tmpl["angle_jitter"]))
		var offset := Vector2.ZERO
		if spread > 0.0:
			if tmpl["arrangement"] == "radial":
				var dir := (TAU / count) * i + randf_range(-0.3, 0.3)
				offset = Vector2(cos(dir), sin(dir)) * randf_range(spread * 0.5, spread)
			else:
				var dir := randf_range(0.0, TAU)
				offset = Vector2(cos(dir), sin(dir)) * randf_range(0.0, spread)
		_cores.append({ "offset": offset, "a": a, "b": b, "angle": angle, "ideal_ratio": float(tmpl["ideal_ratio"]) })

func _ellipse_norm_dist(hit_pos: Vector2, core_world_pos: Vector2, core: Dictionary) -> float:
	var local := hit_pos - core_world_pos
	var ang   : float = core.get("angle", 0.0)
	if ang != 0.0:
		local = local.rotated(-ang)
	var a : float = core["a"]
	var b : float = core["b"]
	return sqrt((local.x / a) * (local.x / a) + (local.y / b) * (local.y / b))

func _shape_center() -> Vector2:
	return mine_area.global_position + mine_shape.position

func _closest_core(hit_pos: Vector2) -> Dictionary:
	var center  := _shape_center()
	var best    := {}
	var best_nd := INF
	for core in _cores:
		var nd := _ellipse_norm_dist(hit_pos, center + core["offset"], core)
		if nd < best_nd:
			best_nd = nd
			best = { "core": core, "norm_dist": nd }
	return best

func get_core_world_positions() -> Array:
	var center := _shape_center()
	var result := []
	for core in _cores:
		result.append({
			"pos":         center + core["offset"],
			"a":           core["a"],
			"b":           core["b"],
			"angle":       core.get("angle", 0.0),
			"ideal_ratio": core["ideal_ratio"]
		})
	return result

func _on_mine_input(_viewport, event, _shape_idx) -> void:
	if not player:
		return
	if player.get_current_mode() != player.Mode.MINE:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if first_hit:
			first_hit = false
			return
		if event.pressed:
			charging   = true
			charge_time = 0.0
		else:
			release_hit()


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


func get_core_global_position() -> Vector2:
	return mine_area.global_position + mine_shape.position

func apply_hit(force: float, hit_pos: Vector2) -> void:
	var tool          = player.get_tool() if player else {}
	var efficiency    := 1.0
	var ql_bonus      := 0.0
	if not tool.is_empty() and tool.has("efficiency"):
		efficiency = float(tool["efficiency"].get(generation_type, 1.0))
		ql_bonus   = float(tool["quality_loss"].get(generation_type, 0.0))
	var eff_force := force * efficiency
	if efficiency < 1:
		eff_force = force * pow(efficiency,1.0/1.9)
	if _cores.is_empty():
		return
	var nearest      := _closest_core(hit_pos)
	var norm_dist    : float      = nearest["norm_dist"]
	var core         : Dictionary = nearest["core"]
	var ideal_ratio  : float      = core["ideal_ratio"]

	var core_force_scale := 20.0

	if norm_dist <= 1.0:
		Notifications.notify("You damaged the core")
		var dist_factor := 2.0 - norm_dist
		var loss := (float(mineral_fragility) / 5.0 + ql_bonus) * (1.0 + force / core_force_scale) * dist_factor / 10.0
		mineral_quality -= loss
	elif norm_dist <= ideal_ratio:
			var ideal_force     := base_mineral_health * 0.97
			var max_force_error := base_mineral_health * 0.9
			var force_ratio     := force / ideal_force
			var force_error      = abs(force - ideal_force)
			var error_norm       = clamp(force_error / max_force_error, 0.0, 1.0)
			var loss_factor: float = pow(error_norm, 3.5)

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
			if first_hit:
				loss_factor *= 7.0/23.0
			mineral_quality -= (float(mineral_fragility) + (4.5/7.0*ql_bonus)) * loss_factor / 9.3
			Notifications.notify("Good hit")
	else:
		Notifications.notify("You hit too far")

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
		var notif_weight: String
		if weight < 1000:
			notif_weight = str(snapped(weight,0.01)) + "G"
		else:
			notif_weight = str(snapped(weight/1000,0.01)) + "KG"
		Notifications.notify("Collected: " + mineral_type + " quality: " + str(mineral_quality) + " weight: " + notif_weight)
		player.collect_mineral(mineral_type, mineral_quality, weight, mineral_weight, mineral_fragility)
		player.exit_inspect()
	else:
		Notifications.notify("You destroyed the mineral")
		player.exit_inspect()

	await get_tree().process_frame
	player.cancel_blocked = false

	queue_free()
