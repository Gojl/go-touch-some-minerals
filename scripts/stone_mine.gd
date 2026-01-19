#kod na przykladowe pisanie (niedokonczony)
#extends Node2D
#
#@export var max_charge_time := 1.5
#@export var max_force := 100.0
#@onready var mineral_sprite := $MineralSprite  # Sprite kamienia
#
#var charging := false
#var charge_time := 0.0
#var mineral_health := 100.0
#var mineral_quality := 1.0  # 1.0 = idealna
#var damage_radius := 24.0
#
#func _input(event):
	#if Globals.mode != Globals.Mode.MINE:
		#return
#
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		#if event.pressed:
			#charging = true
			#charge_time = 0.0
		#else:
			#release_hit()
#
#func _process(delta):
	#if charging:
		#charge_time += delta
		#charge_time = min(charge_time, max_charge_time)
#
#func release_hit():
	#if not charging:
		#return
	#charging = false
#
	#var force := (charge_time / max_charge_time) * max_force
	#var mouse_pos := get_global_mouse_position()
	#apply_hit(force, mouse_pos)
#
#func apply_hit(force: float, hit_pos: Vector2):
	#var dist := hit_pos.distance_to(mineral_sprite.global_position)
	#if dist < damage_radius:
		#mineral_quality -= force * 0.005  # za blisko → uszkodzony
	#else:
		#mineral_health -= force  # idealne uderzenie
#
	#mineral_quality = clamp(mineral_quality, 0.0, 1.0)
	#check_result()
#
#func check_result():
	#if mineral_health <= 0:
		#finish_mining()
#
#func finish_mining():
	#print("MINERAŁ WYDOBYTY, jakość:", mineral_quality)
	#Globals.exit_inspect()
	#queue_free()  # usuń node kopania
