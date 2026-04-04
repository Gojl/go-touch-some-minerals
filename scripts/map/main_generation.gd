extends Node2D

@export var rock_scene: PackedScene
@export var chunk_size: int = 16
@export var generation_radius: int = 3
@export var region_name: String = "lower_silesia"
@export var tilemap: TileMapLayer

var _terrain_noise := FastNoiseLite.new()
var _detail_noise  := FastNoiseLite.new()

var _mineral_atlas:  Dictionary = {}
var _vein_data:      Dictionary = {}
var _region_weights: Dictionary = {}

var _generated_chunks: Dictionary = {}
var _occupied_tiles:   Dictionary = {}
var _player: Node = null
var _last_player_chunk := Vector2i(-9999, -9999)

const HEIGHT_DARK_EARTH_MAX := -0.45
const HEIGHT_GRASS_MAX      :=  0.3

const NO_MINERAL_ABOVE      :=  0.3

const ROCK_CHANCE_DARK_EARTH := 0.0005
const ROCK_CHANCE_GRASS      := 0.0007
const ROCK_CHANCE_DRY_GRASS  := 0.0003

func _ready() -> void:
	if not _load_data():
		return
	_setup_noise()
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")
	if not _player:
		push_error("main_generation: player not found")
		return
	_check_player_chunk()

func _process(_delta: float) -> void:
	_check_player_chunk()

func _setup_noise() -> void:
	randomize()
	_terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_terrain_noise.seed       = randi()
	_terrain_noise.frequency  = 0.03

	_detail_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	_detail_noise.seed       = randi()
	_detail_noise.frequency  = 0.08

func _check_player_chunk() -> void:
	if not _player or not tilemap:
		return
	var player_tile  := tilemap.local_to_map(tilemap.to_local(_player.global_position))
	var player_chunk := Vector2i(
		floori(float(player_tile.x) / float(chunk_size)),
		floori(float(player_tile.y) / float(chunk_size))
	)
	if player_chunk == _last_player_chunk:
		return
	_last_player_chunk = player_chunk
	_generate_chunks_around(player_chunk)

func _generate_chunks_around(center: Vector2i) -> void:
	for dx in range(-generation_radius, generation_radius + 1):
		for dy in range(-generation_radius, generation_radius + 1):
			var chunk := Vector2i(center.x + dx, center.y + dy)
			if not _generated_chunks.has(chunk):
				_generated_chunks[chunk] = true
				_generate_chunk(chunk)

func _generate_chunk(chunk: Vector2i) -> void:
	var origin := chunk * chunk_size
	for lx in range(chunk_size):
		for ly in range(chunk_size):
			var tile := Vector2i(origin.x + lx, origin.y + ly)

			if tile == Vector2i.ZERO:
				continue

			var height := _terrain_noise.get_noise_2d(float(tile.x), float(tile.y))

			if randf() > _rock_chance(height):
				continue

			if _occupied_tiles.has(tile):
				continue

			_try_spawn_rock(tile, height)

func _rock_chance(height: float) -> float:
	if height < HEIGHT_DARK_EARTH_MAX:
		return ROCK_CHANCE_DARK_EARTH
	elif height < HEIGHT_GRASS_MAX:
		return ROCK_CHANCE_GRASS
	else:
		return ROCK_CHANCE_DRY_GRASS

func _try_spawn_rock(tile: Vector2i, height: float) -> void:
	var mineral := _pick_mineral(height)
	if mineral == "":
		return

	_place_rock(tile, mineral)

	var vein: Dictionary = _vein_data[mineral]
	if randf() < float(vein["cluster_chance"]):
		var vein_size := randi_range(int(vein["vein_size"][0]), int(vein["vein_size"][1]))
		var spread    = max(1, int(sqrt(float(vein_size)) * 1.5))

		for _i in range(vein_size - 1):
			var offset   := Vector2i(randi_range(-spread, spread), randi_range(-spread, spread))
			var neighbor := tile + offset
			if neighbor == Vector2i.ZERO or _occupied_tiles.has(neighbor):
				continue
			_place_rock(neighbor, mineral)

func _pick_mineral(height: float) -> String:
	if height >= NO_MINERAL_ABOVE:
		return ""


	var candidates: Array = []
	var total_weight := 0

	for mineral_name in _vein_data:
		if not _region_weights.has(mineral_name) or not _mineral_atlas.has(mineral_name):
			continue
		var region_w: int = _region_weights[mineral_name]
		if region_w == 0:
			continue
		var vein: Dictionary = _vein_data[mineral_name]
		if height >= float(vein["height_min"]) and height < float(vein["height_max"]):
			candidates.append({ "name": mineral_name, "weight": region_w })
			total_weight += region_w

	if candidates.is_empty() or total_weight == 0:
		return ""

	var roll := randi_range(0, total_weight - 1)
	var cumulative := 0
	for c in candidates:
		cumulative += c["weight"]
		if roll < cumulative:
			return c["name"]

	return candidates[-1]["name"]

func _place_rock(tile: Vector2i, mineral_name: String) -> void:
	_occupied_tiles[tile] = true
	var rock := rock_scene.instantiate()
	rock.global_position = tilemap.to_global(tilemap.map_to_local(tile))
	_configure_rock(rock, mineral_name, _mineral_atlas[mineral_name])
	add_child(rock)

func _configure_rock(rock: Node, mineral_name: String, atlas: Dictionary) -> void:
	rock.mineral_type         = mineral_name
	rock.base_mineral_quality = float(atlas["base_quality"])
	rock.quality_variation    = float(atlas["quality_variation"])
	rock.mineral_fragility    = int(atlas["fragility"])
	rock.mohs_hardness        = float(atlas["mohs_hardness"])
	rock.mineral_percentage   = float(atlas["mineral_percent"])

	var avg_total_g: float = float(atlas["avg_weight_kg"]) * 1000.0
	var total_weight_g: float
	if randf() < 0.05:
		total_weight_g = randf_range(avg_total_g * 1.5, avg_total_g * 3.0)
	else:
		total_weight_g = randf_range(avg_total_g * 0.65, avg_total_g * 1.35)

	var base_pct: float      = float(atlas["mineral_percent"])
	var pct_variation: float = base_pct * 0.1
	var actual_pct: float    = clamp(
		randf_range(base_pct - pct_variation, base_pct + pct_variation),
		0.0, 1.0
	)

	rock.weight         = total_weight_g
	rock.mineral_weight = total_weight_g * actual_pct

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
	var text   := file.get_as_text()
	file.close()
	var result = JSON.parse_string(text)
	if result == null:
		push_error("main_generation: JSON parse failed for '%s'" % path)
	return result
