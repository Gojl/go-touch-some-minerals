extends Node2D

@onready var tile_layer: TileMapLayer = $TileMapLayer
@onready var player: CharacterBody2D = $CharacterBody2D
@export var chunk_size: int = 4

func _ready() -> void:
	player.chunk_changed.connect(_on_chunk_changed)
	_on_chunk_changed(Vector2i.ZERO)
	
func _on_chunk_changed(chunk: Vector2i) -> void:
	for ch in get_neighbors(chunk):
		draw_chunk(ch)

func draw_chunk(chunk: Vector2i) -> void:
	var world_pos = chunk * chunk_size
	if tile_layer.get_cell_source_id(world_pos) != -1:
		return

	@warning_ignore("integer_division")
	for x in range(world_pos.x - chunk_size / 2, world_pos.x + chunk_size / 2):
		@warning_ignore("integer_division")
		for y in range(world_pos.y - chunk_size / 2, world_pos.y + chunk_size / 2):
			var tile = Vector2i(randi() % 3, randi() % 6)
			tile_layer.set_cell(Vector2i(x, y), 0, tile)


func get_neighbors(center: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in range(-1, 2):
		for y in range(-1, 2):
			result.append(center + Vector2i(x, y))
	return result
