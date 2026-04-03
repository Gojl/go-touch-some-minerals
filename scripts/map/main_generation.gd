extends Node2D

@export var rock_scene: PackedScene
@export var map_width: int = 100
@export var map_height: int = 100
@export var region_name: String = "upper_silesia"

@export var tilemap: TileMapLayer

# Loaded data
var _mineral_atlas: Dictionary = {}     
var _vein_data: Dictionary = {}        
var _region_weights: Dictionary = {}
var _occupied_tiles: Dictionary = {}   # Vector2i -> true, prevents stacking

func _ready() -> void:
	if not _load_data():
		return
	spawn_veins()

func _load_data() -> bool:
	var atlas_raw = _read_json("res://data/atlas.json")
	var gen_raw   = _read_json("res://data/generacja.json")
	var reg_raw   = _read_json("res://data/regiony.json")

	if atlas_raw == null or gen_raw == null or reg_raw == null:
		return false

	for entry in atlas_raw["minerals"]:
		_mineral_atlas[entry["name"]] = entry

	_vein_data = gen_raw["veins"]

	var found_region := false
	for region in reg_raw["regions"]:
		if region["name"] == region_name:
			_region_weights = region["minerals"]
			found_region = true
			break

	if not found_region:
		push_error("main_generation: region '%s' not found in regiony.json" % region_name)
		return false

	return true

func _read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("main_generation: cannot open '%s'" % path)
		return null
	var text := file.get_as_text()
	file.close()
	var result = JSON.parse_string(text)
	if result == null:
		push_error("main_generation: JSON parse failed for '%s'" % path)
	return result


func spawn_veins() -> void:
	if rock_scene == null:
		push_error("main_generation: rock_scene is not set!")
		return
	if tilemap == null:
		push_error("main_generation: tilemap is not set!")
		return

	randomize()

	for mineral_name in _vein_data:
		if not _region_weights.has(mineral_name):
			continue
		if not _mineral_atlas.has(mineral_name):
			continue

		var region_w: int = _region_weights[mineral_name]
		if region_w == 0:
			continue

		var vein: Dictionary   = _vein_data[mineral_name]
		var atlas: Dictionary  = _mineral_atlas[mineral_name]

		var num_veins: int = max(1, roundi(float(vein["vein_rarity"]) * float(region_w) / 200.0))

		for _v in range(num_veins):
			_spawn_vein(mineral_name, vein, atlas)

func _spawn_vein(mineral_name: String, vein: Dictionary, atlas: Dictionary) -> void:
	var cx: int = randi_range(-map_width / 2, map_width / 2)
	var cy: int = randi_range(-map_height / 2, map_height / 2)

	var vein_size: int = randi_range(vein["vein_size"][0], vein["vein_size"][1])
	var cluster_chance: float = vein["cluster_chance"]

	var spread: int = max(1, int(sqrt(float(vein_size)) * 1.5))

	for _r in range(vein_size):
		if randf() > cluster_chance:
			continue

		var tx: int = cx + randi_range(-spread, spread)
		var ty: int = cy + randi_range(-spread, spread)

		if tx == 0 and ty == 0:
			tx = 1

		var tile := Vector2i(tx, ty)
		if _occupied_tiles.has(tile):
			continue
		_occupied_tiles[tile] = true

		var rock := rock_scene.instantiate()
		rock.global_position = tilemap.map_to_local(Vector2i(tx, ty))

		_configure_rock(rock, mineral_name, atlas)
		add_child(rock)

func _configure_rock(rock: Node, mineral_name: String, atlas: Dictionary) -> void:
	rock.mineral_type      = mineral_name
	rock.base_mineral_quality      = float(atlas["base_quality"])
	rock.quality_variation         = float(atlas["quality_variation"])
	rock.mineral_fragility         = int(atlas["fragility"])
	rock.mohs_hardness             = float(atlas["mohs_hardness"])
	rock.mineral_percentage        = float(atlas["mineral_percent"])



	var avg_total_g: float = float(atlas["avg_weight_kg"]) * 1000.0
	var total_weight_g: float
	if randf() < 0.05:
		total_weight_g = randf_range(avg_total_g * 1.5, avg_total_g * 3.0)
	else:
		total_weight_g = randf_range(avg_total_g * 0.65, avg_total_g * 1.35)

	var base_pct: float = float(atlas["mineral_percent"])
	var pct_variation: float = base_pct * 0.1
	var actual_pct: float = clamp(
		randf_range(base_pct - pct_variation, base_pct + pct_variation),
		0.0, 1.0
	)

	rock.weight         = total_weight_g
	rock.mineral_weight = total_weight_g * actual_pct
