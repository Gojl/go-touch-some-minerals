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

		if tile_x == 0 and tile_y == 0:
			continue

		var world_pos := tilemap.map_to_local(Vector2i(tile_x, tile_y))
		rock.global_position = world_pos
		
		var mineral_rarity = randi_range(0,100)
		
		
		
		if mineral_rarity > 99:
			rock.mineral_type = "Diamond"
			rock.mineral_tier = 3
			rock.base_mineral_quality = 0.95
			rock.mineral_quality_randomness_up = 0.05
			rock.mineral_quality_randomness_down = 0
		elif mineral_rarity > 10:
			rock.mineral_type = "Gold"
			rock.mineral_tier = 2
		else:
			rock.mineral_type = "Coal"
			rock.mineral_tier = 1
			rock.base_mineral_quality = 0.35
			rock.mineral_quality_randomness_up = 0.35
			rock.mineral_quality_randomness_down = 0.15
		
		var rarity = randf()
		if rarity >= 0.99:
			match rock.mineral_type:
				"Diamond":
					rock.weight = randf_range(20,200)
				"Gold":
					rock.weight = randf_range(500,5000)
				"Coal":
					rock.weight = randf_range(10,50)
		elif rarity >= 0.95:
			match rock.mineral_type:
				"Diamond":
					rock.weight = randf_range(2,20)
				"Gold":
					rock.weight = randf_range(100,500)
				"Coal":
					rock.weight = randf_range(50,200)
		elif rarity >= 0.9 :
			match rock.mineral_type:
				"Diamond":
					rock.weight = randf_range(0.2, 1)
				"Gold":
					rock.weight = randf_range(20,100)
				"Coal":
					rock.weight = randf_range(200,1000)
		else:
			match rock.mineral_type:
				"Diamond":
					rock.weight = randf_range(0.02, 0.1)
				"Gold":
					rock.weight = randf_range(0.5, 2)
				"Coal":
					rock.weight = randf_range(1000,5000)
		add_child(rock)
