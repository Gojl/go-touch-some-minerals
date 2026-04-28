extends Node

var money: float     = 0
var inventory: Array = []

# ── Time ──────────────────────────────────────────────────────────────────────
var world_time: float = 0.0     
var city_mode: bool   = false  

# ── World ─────────────────────────────────────────────────────────────────────
var terrain_seed: int      = 0
var spawn_point: Vector2   = Vector2.ZERO
var spawn_assigned: bool   = false

var generated_chunks: Dictionary = {}

var mined_tiles: Dictionary = {}

func is_mined(tile: Vector2i) -> bool:
	return mined_tiles.has(_tk(tile))

func mine_tile(tile: Vector2i) -> void:
	mined_tiles[_tk(tile)] = true

const SAVE_PATH := "user://world.sav"
var MAGIC     := PackedByteArray([0x4D, 0x49, 0x4E, 0x45])
const VERSION   := 1

func _ready() -> void:
	load_data()

func _process(delta: float) -> void:
	if city_mode:
		world_time += delta * 0.1

func reset_time() -> void:
	world_time = 0.0

func get_entry_position() -> Vector2:
	var angle := randf() * TAU
	var dist  := randf_range(1400.0, 2000.0)
	return spawn_point + Vector2(cos(angle), sin(angle)) * dist

func relocate_spawn() -> void:
	var angle := randf() * TAU
	var dist  := randf_range(10000.0, 24000.0)
	spawn_point += Vector2(cos(angle), sin(angle)) * dist
	generated_chunks.clear()
	mined_tiles.clear()
	save_data()

func is_chunk_generated(chunk: Vector2i) -> bool:
	return generated_chunks.has(_ck(chunk))

func mark_chunk_generated(chunk: Vector2i) -> void:
	generated_chunks[_ck(chunk)] = true

func _ck(c: Vector2i) -> String:
	return "%d,%d" % [c.x, c.y]

func _tk(tile: Vector2i) -> String:
	return "%d,%d" % [tile.x, tile.y]

func save_data() -> void:
	var data := {
		"mo": money,         "in": inventory,
		"ts": terrain_seed,  "wt": world_time,
		"sx": spawn_point.x, "sy": spawn_point.y,
		"sa": spawn_assigned,
		"gc": generated_chunks,
		"mt": mined_tiles,
	}
	var raw        : PackedByteArray = var_to_bytes(data)
	var compressed : PackedByteArray = raw.compress(FileAccess.COMPRESSION_GZIP)

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("Game: cannot open save file for writing")
		return
	file.store_buffer(MAGIC)
	file.store_8(VERSION)
	file.store_32(raw.size())
	file.store_buffer(compressed)

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var magic := file.get_buffer(4)
	if magic != MAGIC:
		push_error("Game: invalid save file magic")
		return

	var version := file.get_8()
	if version != VERSION:
		push_warning("Game: save version mismatch (got %d, expected %d)" % [version, VERSION])

	var raw_size   : int             = file.get_32()
	var compressed : PackedByteArray = file.get_buffer(file.get_length() - file.get_position())
	var raw        : PackedByteArray = compressed.decompress(raw_size, FileAccess.COMPRESSION_GZIP)
	var data                         = bytes_to_var(raw)

	if typeof(data) != TYPE_DICTIONARY:
		push_error("Game: save data corrupt")
		return

	money            = float(data.get("mo", 0))
	inventory        = data.get("in", [])
	terrain_seed     = int(data.get("ts", 0))
	world_time       = float(data.get("wt", 0.0))
	spawn_point      = Vector2(float(data.get("sx", 0.0)), float(data.get("sy", 0.0)))
	spawn_assigned   = bool(data.get("sa", false))
	generated_chunks = data.get("gc", {})
	mined_tiles      = data.get("mt", {})
