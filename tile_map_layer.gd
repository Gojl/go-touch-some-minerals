extends TileMapLayer

@export var map_radius: int = 50

const GRASS_SOURCE_ID := 0
const GRASS_ATLAS_COORDS := Vector2i(0, 0)

func _ready() -> void:
	generate_map()

func generate_map() -> void:
	clear()

	for y in range(-map_radius, map_radius + 1):
		for x in range(-map_radius, map_radius + 1):
			set_cell(
				Vector2i(x, y),0, Vector2i(0,0))
