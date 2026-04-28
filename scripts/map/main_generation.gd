extends Node2D

@export var rock_scene: PackedScene
@export var return_zone_scene: PackedScene
@export var tree_scenes: Array[PackedScene]
@export var bush_scene: PackedScene
@export var chunk_size: int = 16
@export var generation_radius: int = 3
@export var region_name: String = "lower_silesia"
@export var tilemap: TileMapLayer

var _current_return_zone: Node = null
var _veg_noise := FastNoiseLite.new()

var _terrain_noise := FastNoiseLite.new()
var _detail_noise  := FastNoiseLite.new()

var _mineral_atlas:  Dictionary = {}
var _vein_data:      Dictionary = {}
var _region_weights: Dictionary = {}
var _terrain_layers: Array      = []

var _generated_chunks: Dictionary = {}
var _occupied_tiles:   Dictionary = {}
var _player: Node = null
var _last_player_chunk := Vector2i(-9999, -9999)
var _chunk_rng := RandomNumberGenerator.new()

const NO_MINERAL_ABOVE := 0.7

func _chunk_seed(chunk: Vector2i) -> int:
	var h : int = Game.terrain_seed
	h ^= chunk.x * 0x9E3779B9
	h ^= chunk.y * 0x6C62272E
	h ^= (h >> 16)
	h *= 0x45D9F3B
	h ^= (h >> 16)
	return absi(h) % 2147483647 + 1

func _ready() -> void:
	var loading = get_node_or_null("LoadingScreen")
	if loading:
		loading.show()
	if not _load_data():
		return
	_setup_noise()
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")
	if not _player:
		push_error("main_generation: player not found")
		return
	_setup_spawn()
	await get_tree().process_frame
	_check_player_chunk()
	if loading:
		loading.hide()

func _setup_spawn() -> void:
	var entry_pos := Game.get_entry_position()
	_player.global_position = entry_pos
	_place_return_zone(entry_pos)

func _place_return_zone(pos: Vector2) -> void:
	if _current_return_zone:
		_current_return_zone.queue_free()
		_current_return_zone = null
	if not return_zone_scene:
		push_warning("main_generation: return_zone_scene not assigned")
		return
	_current_return_zone = return_zone_scene.instantiate()
	_current_return_zone.global_position = pos
	get_parent().add_child(_current_return_zone)

func relocate_spawn() -> void:
	Game.relocate_spawn()
	Game.save_data()
	_place_return_zone(Game.spawn_point)

func _process(_delta: float) -> void:
	_check_player_chunk()

func _setup_noise() -> void:
	if Game.terrain_seed == 0:
		Game.terrain_seed = randi_range(1, 2147483647)
	_terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_terrain_noise.seed       = Game.terrain_seed
	_terrain_noise.frequency  = 0.03

	_detail_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	_detail_noise.seed       = Game.terrain_seed + 3
	_detail_noise.frequency  = 0.08

	_veg_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_veg_noise.seed       = Game.terrain_seed + 7
	_veg_noise.frequency  = 0.15

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
				Game.mark_chunk_generated(chunk)
				_generate_chunk(chunk)

func _generate_chunk(chunk: Vector2i) -> void:
	_chunk_rng.seed = _chunk_seed(chunk)

	var origin := chunk * chunk_size
	for lx in range(chunk_size):
		for ly in range(chunk_size):
			var tile := Vector2i(origin.x + lx, origin.y + ly)

			if tile == Vector2i.ZERO:
				continue

			var height := _terrain_noise.get_noise_2d(float(tile.x), float(tile.y))

			if _chunk_rng.randf() > _rock_chance(height):
				continue

			if _occupied_tiles.has(tile):
				continue

			if tilemap.is_river_tile(tile):
				continue

			if Game.is_mined(tile):
				continue

			_try_spawn_rock(tile, height)

	_generate_vegetation(origin)

func _generate_vegetation(origin: Vector2i) -> void:
	if tree_scenes.is_empty() and not bush_scene:
		return

	for lx in range(chunk_size):
		for ly in range(chunk_size):
			var tile   := Vector2i(origin.x + lx, origin.y + ly)
			if _occupied_tiles.has(tile):
				continue

			var height := _terrain_noise.get_noise_2d(float(tile.x), float(tile.y))
			var veg    := _veg_noise.get_noise_2d(float(tile.x), float(tile.y))

			if height < -0.45 or height > 0.3:
				continue

			if veg < 0.0:
				continue

			var world_pos := tilemap.to_global(tilemap.map_to_local(tile))

			if veg > 0.6 and height < 0.1 and not tree_scenes.is_empty():
				var scene := tree_scenes[_chunk_rng.randi() % tree_scenes.size()]
				var tree  := scene.instantiate()
				tree.global_position = world_pos + Vector2(_chunk_rng.randf_range(-12, 12), _chunk_rng.randf_range(-12, 12))
				add_child(tree)
				_occupied_tiles[tile] = true
				continue

			if veg > 0.35 and veg <= 0.6 and bush_scene:
				var bush := bush_scene.instantiate()
				bush.global_position = world_pos + Vector2(_chunk_rng.randf_range(-8, 8), _chunk_rng.randf_range(-8, 8))
				add_child(bush)
				_occupied_tiles[tile] = true

func _rock_chance(height: float) -> float:
	for layer in _terrain_layers:
		var lo = min(float(layer["from"]), float(layer["to"]))
		var hi = max(float(layer["from"]), float(layer["to"]))
		if height >= lo and height <= hi:
			return float(layer["rock_spawn_chance"])
	return 0.0

const VEIN_ROCK_CHANCE := 0.35

func _try_spawn_rock(tile: Vector2i, height: float) -> void:
	var mineral := _pick_mineral(height)
	if mineral == "":
		return

	_place_rock(tile, mineral)

	var vein: Dictionary = _vein_data[mineral]
	if _chunk_rng.randf() < float(vein["cluster_chance"]):
		var vein_size := _chunk_rng.randi_range(int(vein["vein_size"][0]), int(vein["vein_size"][1]))
		var spread     = max(1, int(sqrt(float(vein_size)) * 1.5))

		for _i in range(vein_size - 1):
			var offset   := Vector2i(_chunk_rng.randi_range(-spread, spread), _chunk_rng.randi_range(-spread, spread))
			var neighbor := tile + offset
			if neighbor == Vector2i.ZERO or _occupied_tiles.has(neighbor):
				continue
			if tilemap.is_river_tile(neighbor):
				continue
			if Game.is_mined(neighbor):
				continue
			var spawn_type := "rock" if _chunk_rng.randf() < VEIN_ROCK_CHANCE else mineral
			_place_rock(neighbor, spawn_type)

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
		var _vein: Dictionary = _vein_data[mineral_name]
		var spawn_range := _parse_spawn_layer(str(_mineral_atlas[mineral_name]["spawn_layer"]))
		if height >= spawn_range.x and height < spawn_range.y:
			candidates.append({ "name": mineral_name, "weight": region_w })
			total_weight += region_w

	if candidates.is_empty() or total_weight == 0:
		return ""

	var roll := _chunk_rng.randi_range(0, total_weight - 1)
	var cumulative := 0
	for c in candidates:
		cumulative += c["weight"]
		if roll < cumulative:
			return c["name"]

	return candidates[-1]["name"]

func _place_rock(tile: Vector2i, mineral_name: String) -> void:
	_occupied_tiles[tile] = true
	var rock  := rock_scene.instantiate()
	rock.global_position = tilemap.to_global(tilemap.map_to_local(tile))
	var atlas  = _mineral_atlas.get(mineral_name, {})
	_configure_rock(rock, mineral_name, atlas)
	rock.tile_coord = tile
	add_child(rock)

func _configure_rock(rock: Node, mineral_name: String, atlas: Dictionary) -> void:
	rock.mineral_type = mineral_name

	if mineral_name == "rock":
		rock.generation_type      = "mineral_in_rock"
		rock.base_mineral_quality = 1.0
		rock.quality_variation    = 0.0
		rock.mineral_fragility    = 1
		rock.mohs_hardness        = float(atlas.get("mohs_hardness", 5.0))
		rock.mineral_percentage   = 0.0
		var avg_g := float(atlas.get("avg_weight_kg", 3.0)) * 1000.0
		rock.weight         = _chunk_rng.randf_range(avg_g * 0.65, avg_g * 1.35)
		rock.mineral_weight = 0.0
		return

	rock.generation_type      = str(atlas["generation_type"])
	rock.base_mineral_quality = float(atlas["base_quality"])
	rock.quality_variation    = float(atlas["quality_variation"])
	rock.mineral_fragility    = int(atlas["fragility"])
	rock.mohs_hardness        = float(atlas["mohs_hardness"])
	rock.mineral_percentage   = float(atlas["mineral_percent"])

	var avg_total_g: float = float(atlas["avg_weight_kg"]) * 1000.0
	var total_weight_g: float
	if _chunk_rng.randf() < 0.05:
		total_weight_g = _chunk_rng.randf_range(avg_total_g * 1.5, avg_total_g * 3.0)
	else:
		total_weight_g = _chunk_rng.randf_range(avg_total_g * 0.65, avg_total_g * 1.35)

	var base_pct: float      = float(atlas["mineral_percent"])
	var pct_variation: float = base_pct * 0.1
	var actual_pct: float    = clamp(
		_chunk_rng.randf_range(base_pct - pct_variation, base_pct + pct_variation),
		0.0, 1.0
	)

	rock.weight         = total_weight_g
	rock.mineral_weight = total_weight_g * actual_pct

func _load_data() -> bool:
	var atlas_raw  = _read_json("res://data/atlas.json")
	var gen_raw    = _read_json("res://data/generacja.json")
	var reg_raw    = _read_json("res://data/regiony.json")
	var depth_raw  = _read_json("res://data/głebokosc.json")

	if atlas_raw == null or gen_raw == null or reg_raw == null or depth_raw == null:
		return false

	for entry in atlas_raw["minerals"]:
		_mineral_atlas[entry["name"]] = entry

	_vein_data = gen_raw["veins"]

	_terrain_layers = depth_raw["layers"]

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

func _parse_spawn_layer(spawn_layer: String) -> Vector2:
	var parts := spawn_layer.split(" → ")
	if parts.size() != 2:
		push_warning("main_generation: bad spawn_layer format '%s'" % spawn_layer)
		return Vector2(-1.0, 1.0)
	var a := float(parts[0])
	var b := float(parts[1])
	return Vector2(min(a, b), max(a, b))

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
