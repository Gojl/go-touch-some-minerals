extends TileMapLayer

@export var chunk_size: int = 16
@export var generation_radius: int = 3
@export var noise_frequency: float = 0.03

const TILE_DARK_EARTH := Vector2i(18, 9)
const TILE_GRASS      := Vector2i(2, 1)
const TILE_DRY_GRASS  := Vector2i(8, 8)

const HEIGHT_DARK_EARTH_MAX := -0.45
const HEIGHT_GRASS_MAX      :=  0.3

var _terrain_noise := FastNoiseLite.new()
var _generated_chunks: Dictionary = {}
var _last_player_chunk := Vector2i(-9999, -9999)
var _player: Node = null

func _ready() -> void:
	_setup_noise()
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")
	if not _player:
		push_error("TileMapLayer: player not found")
		return
	_check_player_chunk()

func _process(_delta: float) -> void:
	_check_player_chunk()

func _setup_noise() -> void:
	randomize()
	_terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_terrain_noise.seed       = randi()
	_terrain_noise.frequency  = noise_frequency

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

func _atlas_coords(height: float) -> Vector2i:
	if height < HEIGHT_DARK_EARTH_MAX:
		return TILE_DARK_EARTH
	elif height < HEIGHT_GRASS_MAX:
		return TILE_GRASS
	else:
		return TILE_DRY_GRASS
