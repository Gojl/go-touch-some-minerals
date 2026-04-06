extends TileMapLayer

@export var chunk_size: int        = 16
@export var generation_radius: int = 3
@export var noise_frequency: float = 0.03

@export var river_count: int            = 10
@export var river_x_spread: int         = 1500
@export var river_wander_amplitude: int = 18
@export var river_wander_frequency: float = 0.008
@export var river_min_width: int        = 4
@export var river_max_width: int        = 8
@export var bridge_threshold: float     = 0.55

const TERRAIN_TILES := [
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(2, 0),
	Vector2i(3, 0),
	Vector2i(4, 0),
	Vector2i(5, 0),
	Vector2i(6, 0),
]
const TILE_RIVER  := Vector2i(0,  8)
const TILE_BRIDGE := Vector2i(16, 3)

var _terrain_noise := FastNoiseLite.new()
var _river_noise   := FastNoiseLite.new()
var _width_noise   := FastNoiseLite.new()


var _generated_chunks: Dictionary = {}
var _terrain_layers:   Array      = []
var _rivers:           Array      = []
var _last_player_chunk := Vector2i(-9999, -9999)
var _player: Node = null

func _ready() -> void:
	_load_terrain_layers()
	_setup_noise()
	_setup_rivers()
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")
	if not _player:
		push_error("TileMapLayer: player not found")
		return
	_check_player_chunk()

func _process(_delta: float) -> void:
	_check_player_chunk()

func _load_terrain_layers() -> void:
	var file := FileAccess.open("res://data/głebokosc.json", FileAccess.READ)
	if not file:
		push_error("TileMapLayer: cannot open głebokosc.json")
		return
	var result = JSON.parse_string(file.get_as_text())
	file.close()
	if result == null:
		push_error("TileMapLayer: failed to parse głebokosc.json")
		return
	_terrain_layers = result["layers"]

func _setup_noise() -> void:
	randomize()
	_terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_terrain_noise.seed       = randi()
	_terrain_noise.frequency  = noise_frequency

	_river_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_river_noise.seed       = randi()
	_river_noise.frequency  = river_wander_frequency

	_width_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_width_noise.seed       = randi()
	_width_noise.frequency  = 0.04

func _setup_rivers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _river_noise.seed
	var spacing = (river_x_spread * 2) / max(river_count, 1)
	for i in range(river_count):
		var base_x = -river_x_spread + i * spacing + rng.randi_range(0, spacing / 2)
		_rivers.append({
			"base_x":        base_x,
			"wander_offset": rng.randf_range(0.0, 1000.0),
			"width_offset":  rng.randf_range(0.0, 1000.0),
		})


func _check_player_chunk() -> void:
	if not _player:
		return
	var player_tile  := local_to_map(to_local(_player.global_position))
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
			var tile   := Vector2i(origin.x + lx, origin.y + ly)
			var height := _terrain_noise.get_noise_2d(float(tile.x), float(tile.y))
			set_cell(tile, 0, _atlas_coords(height))

	for lx in range(chunk_size):
		for ly in range(chunk_size):
			var tile := Vector2i(origin.x + lx, origin.y + ly)
			_apply_river(tile)

func _atlas_coords(height: float) -> Vector2i:
	for i in range(_terrain_layers.size()):
		var layer = _terrain_layers[i]
		var lo    = min(float(layer["from"]), float(layer["to"]))
		var hi    = max(float(layer["from"]), float(layer["to"]))
		if height >= lo and height <= hi:
			return TERRAIN_TILES[i] if i < TERRAIN_TILES.size() else TERRAIN_TILES[-1]
	return TERRAIN_TILES[-1]

func _apply_river(tile: Vector2i) -> void:
	for river in _rivers:
		if not _tile_in_river(tile, river):
			continue
		var bridge_val = abs(_river_noise.get_noise_1d(
			float(tile.y) * 3.7 + river["wander_offset"] + 500.0
		))
		if bridge_val > bridge_threshold:
			set_cell(tile, 0, TILE_BRIDGE)
		else:
			set_cell(tile, 0, TILE_RIVER)

func _tile_in_river(tile: Vector2i, river: Dictionary) -> bool:
	var wander   := _river_noise.get_noise_1d(float(tile.y) + river["wander_offset"])
	var center_x = river["base_x"] + int(wander * river_wander_amplitude)
	var w_noise  = abs(_width_noise.get_noise_1d(float(tile.y) + river["width_offset"]))
	var half_w   := (river_min_width + int(w_noise * (river_max_width - river_min_width))) / 2
	return abs(tile.x - center_x) <= half_w

func is_river_tile(tile: Vector2i) -> bool:
	for river in _rivers:
		if _tile_in_river(tile, river):
			var bridge_val = abs(_river_noise.get_noise_1d(
				float(tile.y) * 3.7 + river["wander_offset"] + 500.0
			))
			if bridge_val <= bridge_threshold:
				return true
	return false
