extends Node2D

@export var rock_scene: PackedScene
@export var map_radius: int = 50
@export var rock_count: int = 80

@export var tilemap: TileMapLayer

func _ready() -> void:
	spawn_rocks()

func spawn_rocks() -> void:
	
	if rock_scene == null:
		push_error("RockSpawner: rock_scene NIE JEST ustawione!")
		return

	if tilemap == null:
		push_error("RockSpawner: tilemap NIE JEST ustawiona!")
		return
	
	randomize()

	for i in range(rock_count):
		var rock := rock_scene.instantiate()
		
		var tile_x := randi_range(-map_radius, map_radius)
		var tile_y := randi_range(-map_radius, map_radius)

		# NIE spawnuj na (0,0) – spawn gracza
		if tile_x == 0 and tile_y == 0:
			continue

		var world_pos := tilemap.map_to_local(Vector2i(tile_x, tile_y))
		rock.global_position = world_pos

		add_child(rock)

func _on_rock_clicked(rock):
	# Przykład: wchodzimy w tryb inspekcji
	print("Kliknięto kamień:", rock)
	#show_inspection_view(rock)
