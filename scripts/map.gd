extends Node2D

var noise: FastNoiseLite
var map_size: Vector2i = Vector2i(100, 100)
var grass_cap: float = 0.7

func _ready():
	#randomize()
	noise = FastNoiseLite.new()
	#noise.seed = randi()
	noise.frequency = 0.02
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	noise.fractal_octaves = 4
	noise.fractal_gain = 0.09

	var grass_cells: Array[Vector2i] = []
	var water_cells: Array[Vector2i] = []
	
	for x in range(map_size.x):
		for y in range(map_size.y):
			var a = noise.get_noise_2d(float(x), float(y))
			if a < grass_cap:
				grass_cells.append(Vector2i(x, y))
				$TileMapLayer.set_cell(Vector2i(x, y), 0, Vector2i(1, 1))
	#$TileMapLayer.set_cells_terrain_connect(grass_cells, 0, 0)
	
	for x in range(map_size.x):
		for y in range(map_size.y):
			if $TileMapLayer.get_cell_source_id(Vector2i(x, y)) == -1:
				water_cells.append(Vector2i(x, y))
				$TileMapLayer.set_cell(Vector2i(x, y), 0, Vector2i(1, 5))
	#$TileMapLayer.set_cells_terrain_connect(water_cells, 0, 1)
	
