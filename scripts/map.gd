extends Node2D

@onready var tile_layer = $TileMapLayer
@onready var player = $CharacterBody2D
@export var size = 32

func _ready():
	generate_map()
#
#func _process(delta: float) -> void:
	#var position = world_to_tile(player.global_position)
	##print(position)

func world_to_tile(pos:Vector2)->Vector2i:
	return Vector2i(floor(pos.x/16), floor(pos.y/16))
	
func generate_map():
	var chunk = Vector2i(0, 0)
	var source_id = 2
	var atlas_coords = Vector2i(0, 0)
	while true:
		chunk = get_chunk(chunk)
		var pozycja = world_to_tile(-1*(player.global_position))
		for x in range(pozycja.x-size/2, pozycja.x+size/2):
			for y in range(pozycja.y-size/2, pozycja.y+size/2):
				tile_layer.set_cell(Vector2i(x,y), source_id, atlas_coords)
		await get_tree().create_timer(0.1).timeout		
		
func get_chunk(chunk: Vector2i)->Vector2i:
	chunk = world_to_tile(-1*(player.global_position))/size
	print(world_to_tile(player.global_position))
	print(chunk.x,chunk.y)
	return chunk
