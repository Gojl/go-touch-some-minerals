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

# TERRAIN_TILES kept as reference for when you re-add rivers/bridges.
# The terrain system no longer uses these directly — tile selection is
# handled by Godot based on the peering bits you set in the TileSet editor.
const TERRAIN_TILES := [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0),
]
const TILE_RIVER  := Vector2i(0,  8)
const TILE_BRIDGE := Vector2i(16, 3)

# Four TileMapLayer nodes per non-base terrain, one per cardinal direction group.
# For terrain with ID t, base index = (elevation_rank_of_t - 1) * 4
# (rank 0 = terrain 1 is highest, rank 2 = terrain 0 = base grass = skipped)
# [t_N, t_S, t_E, t_W,  t2_N, t2_S, t2_E, t2_W, ...]
# Assign in inspector in that exact order, one set per non-base terrain.
@export var transition_layers: Array[TileMapLayer]

const DIR_TO_LAYER_SLOT := {
	"n": 0, "ne": 0, "nw": 0,
	"s": 1, "se": 1, "sw": 1,
	"e": 2,
	"w": 3,
}

func _get_transition_layer(terrain_id: int, dir: String) -> TileMapLayer:
	# Map terrain_id → a 0-based index excluding base grass
	var rank     : int = _elevation_rank.get(terrain_id, -1)
	if rank < 0:
		return null
	# Shift rank to exclude base grass slot (rank 2 in [1,2,0,4,3])
	var base_grass_rank : int = _elevation_rank.get(BASE_GRASS_ID, 2)
	var array_rank : int = rank if rank < base_grass_rank else rank - 1
	var slot       : int = DIR_TO_LAYER_SLOT.get(dir, -1)
	if slot < 0:
		return null
	var idx : int = array_rank * 4 + slot
	if idx < 0 or idx >= transition_layers.size():
		return null
	return transition_layers[idx]

# Key: "from_terrain_id:direction"
# Direction = where the source terrain IS relative to MY cell.
# The tile painted is always the OPPOSITE face of the source terrain —
# e.g. source is to my North → paint its South fringe onto my cell.
#
# Terrain 1 center: (3,1)   Terrain 2 center: (6,1)
# Terrain 3 center: (9-10, 1-2) 2x2   Terrain 4 center: (13,1)
# Terrain 0 (base grass) has no fringe tiles of its own.
const TRANSITION_TILES := {
	# ── Terrain 1 (dry grass) ─────────────────────────────────────────────────
	"1:n":  Vector2i( 3, 2),  # south face  — terrain1 is north,  bleeds south
	"1:s":  Vector2i( 3, 0),  # north face  — terrain1 is south,  bleeds north
	"1:e":  Vector2i( 2, 1),  # west face   — terrain1 is east,   bleeds west
	"1:w":  Vector2i( 4, 1),  # east face   — terrain1 is west,   bleeds east
	"1:ne": Vector2i( 2, 2),  # SW corner
	"1:nw": Vector2i( 4, 2),  # SE corner
	"1:se": Vector2i( 2, 0),  # NW corner
	"1:sw": Vector2i( 4, 0),  # NE corner

	# ── Terrain 2 (tall grass) ────────────────────────────────────────────────
	"2:n":  Vector2i( 6, 2),
	"2:s":  Vector2i( 6, 0),
	"2:e":  Vector2i( 5, 1),
	"2:w":  Vector2i( 7, 1),
	"2:ne": Vector2i( 5, 2),
	"2:nw": Vector2i( 7, 2),
	"2:se": Vector2i( 5, 0),
	"2:sw": Vector2i( 7, 0),

	# ── Terrain 3 (dark dirt, 2x2) ────────────────────────────────────────────
	# Two N and S tiles exist — (9,x) and (10,x). Using (9,x) here;
	# see _paint_transitions for x-parity variant picking.
	"3:n":  Vector2i( 9, 3),  # S face (left variant)
	"3:s":  Vector2i( 9, 0),  # N face (left variant)
	"3:e":  Vector2i( 8, 1),  # W face (top variant)
	"3:w":  Vector2i(11, 1),  # E face (top variant)
	"3:ne": Vector2i( 8, 3),  # SW corner
	"3:nw": Vector2i(11, 3),  # SE corner
	"3:se": Vector2i( 8, 0),  # NW corner
	"3:sw": Vector2i(11, 0),  # NE corner

	# ── Terrain 4 (deep dirt with grass) ─────────────────────────────────────
	"4:n":  Vector2i(13, 2),
	"4:s":  Vector2i(13, 0),
	"4:e":  Vector2i(12, 1),
	"4:w":  Vector2i(14, 1),
	"4:ne": Vector2i(12, 2),
	"4:nw": Vector2i(14, 2),
	"4:se": Vector2i(12, 0),
	"4:sw": Vector2i(14, 0),
}

const NEIGHBOURS := {
	"n":  Vector2i( 0, -1),
	"s":  Vector2i( 0,  1),
	"e":  Vector2i( 1,  0),
	"w":  Vector2i(-1,  0),
	"ne": Vector2i( 1, -1),
	"nw": Vector2i(-1, -1),
	"se": Vector2i( 1,  1),
	"sw": Vector2i(-1,  1),
}


var _generated_chunks: Dictionary = {}
var _terrain_layers:   Array      = []
var _rivers:           Array      = []
var _last_player_chunk := Vector2i(-9999, -9999)
var _player: Node = null

var _terrain_noise := FastNoiseLite.new()
var _river_noise   := FastNoiseLite.new()
var _width_noise   := FastNoiseLite.new()

func _ready() -> void:
	for i in range(TERRAIN_IDS.size()):
		_elevation_rank[TERRAIN_IDS[i]] = i
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
	# Lower frequency = larger terrain blobs, more natural landmass shapes
	_terrain_noise.noise_type  = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_terrain_noise.seed        = randi()
	_terrain_noise.frequency   = 0.015
	_terrain_noise.fractal_type       = FastNoiseLite.FRACTAL_FBM
	_terrain_noise.fractal_octaves    = 3
	_terrain_noise.fractal_lacunarity = 2.0
	_terrain_noise.fractal_gain       = 0.4   # low gain = detail octaves are subtle

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
		if base_x in range(-100,100):
			if base_x < 0:
				base_x -= 50
			else:
				base_x += 50
			base_x *= 2
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


# Terrain IDs — must match the order you added terrains in the TileSet editor.
# Index 0 = first terrain you added, 1 = second, etc.
# Keep this in the same order as głebokosc.json layers and TERRAIN_TILES.
const TERRAIN_IDS := [1, 2, 0, 4, 3]   # highest → lowest elevation
const TERRAIN_SET := 0
const BASE_GRASS_ID := 0   # has no transition tiles — always receives bleeds

# Precomputed elevation rank: lower number = higher elevation
# Built from TERRAIN_IDS at startup so bleed checks are O(1)
var _elevation_rank: Dictionary = {}   # terrain_id -> rank int

var _tile_terrain: Dictionary = {}

# Cardinals first so they always overwrite diagonals on the same cell.
const DIRECTIONS_SORTED := ["n", "s", "e", "w", "ne", "nw", "se", "sw"]

func _generate_chunk(chunk: Vector2i) -> void:
	var origin := chunk * chunk_size
	var buckets: Dictionary = {}

	for lx in range(chunk_size):
		for ly in range(chunk_size):
			var tile   := Vector2i(origin.x + lx, origin.y + ly)
			var raw    := _terrain_noise.get_noise_2d(float(tile.x), float(tile.y))
			# Squash extremes toward 0 so mid-range (base grass) dominates.
			# pow exponent > 1 pulls values away from ±1 toward 0.
			# Tweak the exponent: higher = more base grass, lower = more variety.
			var height = sign(raw) * pow(abs(raw), 1.6)
			var tid    := _terrain_id(height)
			_tile_terrain[tile] = tid
			if not buckets.has(tid):
				buckets[tid] = []
			buckets[tid].append(tile)

	var sorted_ids := buckets.keys()
	sorted_ids.sort()
	for tid in sorted_ids:
		set_cells_terrain_connect(buckets[tid], TERRAIN_SET, tid, false)

	_paint_transitions(origin)

	# Re-run transition pass on the 1-tile border of each already-generated
	# neighbour chunk — their edge tiles had -1 for our tiles when they ran.
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var neighbour_chunk := Vector2i(chunk.x + dx, chunk.y + dy)
			if not _generated_chunks.has(neighbour_chunk):
				continue
			_repaint_chunk_border(neighbour_chunk, chunk)

func _repaint_chunk_border(chunk: Vector2i, towards: Vector2i) -> void:
	# Only re-paint the 1-tile strip of `chunk` that faces `towards`.
	var origin  := chunk  * chunk_size
	var o2      := towards * chunk_size
	var tiles: Array[Vector2i] = []

	for lx in range(chunk_size):
		for ly in range(chunk_size):
			var tile := Vector2i(origin.x + lx, origin.y + ly)
			# Include the tile if any of its 8 neighbours are in the newly generated chunk
			for dir in NEIGHBOURS:
				var n = tile + NEIGHBOURS[dir]
				if n.x >= o2.x and n.x < o2.x + chunk_size \
				and n.y >= o2.y and n.y < o2.y + chunk_size:
					tiles.append(tile)
					break

	_paint_transition_tiles(tiles)

func _paint_transitions(origin: Vector2i) -> void:
	var tiles: Array[Vector2i] = []
	for lx in range(chunk_size):
		for ly in range(chunk_size):
			tiles.append(Vector2i(origin.x + lx, origin.y + ly))
	_paint_transition_tiles(tiles)

func _paint_transition_tiles(tiles: Array[Vector2i]) -> void:
	for tile in tiles:
		var my_tid: int = _tile_terrain.get(tile, -1)

		# Clear this cell on all transition layers
		for layer in transition_layers:
			if layer:
				layer.erase_cell(tile)

		# Cardinals first, then diagonals
		for dir in DIRECTIONS_SORTED:
			var neighbour     = tile + NEIGHBOURS[dir]
			var neighbour_tid : int = _tile_terrain.get(neighbour, -1)

			# Bleed rules:
			# - Base grass (id 0) has no transitions of its own, so any
			#   non-identical neighbour always bleeds into it.
			# - All other terrains: only higher-elevation neighbours bleed in
			#   (lower elevation rank = higher up).
			if neighbour_tid == -1 or neighbour_tid == my_tid:
				continue
			if my_tid != BASE_GRASS_ID:
				var my_rank  : int = _elevation_rank.get(my_tid, 999)
				var nb_rank  : int = _elevation_rank.get(neighbour_tid, 999)
				if nb_rank >= my_rank:
					continue   # neighbour is same or lower elevation, skip

			var key := "%d:%s" % [neighbour_tid, dir]
			if not TRANSITION_TILES.has(key):
				continue

			var is_diagonal = dir in ["ne", "nw", "se", "sw"]
			var layer       := _get_transition_layer(neighbour_tid, dir)
			if not layer:
				continue

			# For diagonals: skip if the cardinal that shares this layer
			# is already painted from the same source terrain.
			# (ne/nw share the N-layer with n; se/sw share the S-layer with s)
			# This prevents diagonals from overwriting a clean edge line.
			if is_diagonal:
				var same_layer_cardinal := "n" if dir in ["ne", "nw"] else "s"
				var card_layer := _get_transition_layer(neighbour_tid, same_layer_cardinal)
				if card_layer and card_layer.get_cell_source_id(tile) != -1:
					continue

			var atlas_coord: Vector2i = TRANSITION_TILES[key]

			if neighbour_tid == 3:
				if dir == "n" or dir == "s":
					if tile.x % 2 != 0:
						atlas_coord.x = 10
				elif dir == "e" or dir == "w":
					if tile.y % 2 != 0:
						atlas_coord.y = 2

			layer.set_cell(tile, 0, atlas_coord)

func _terrain_id(height: float) -> int:
	for i in range(_terrain_layers.size()):
		var layer = _terrain_layers[i]
		var lo    = min(float(layer["from"]), float(layer["to"]))
		var hi    = max(float(layer["from"]), float(layer["to"]))
		if height >= lo and height <= hi:
			return TERRAIN_IDS[i] if i < TERRAIN_IDS.size() else TERRAIN_IDS[-1]
	return TERRAIN_IDS[-1]

# Kept for main_generation compatibility (returns terrain index, not atlas coords)
func get_terrain_at(tile: Vector2i) -> int:
	return _tile_terrain.get(tile, -1)

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
	var half_w   = (river_min_width + (w_noise * (river_max_width - river_min_width))) / 2
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
