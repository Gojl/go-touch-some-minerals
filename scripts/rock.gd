#extends Node2D
#
#@export var rock_name: String
#@export var health: int
#@export var sprite_texture: Texture2D
#func _ready() -> void:
	#if sprite_texture:
		#$StaticBody2D/Sprite2D.texture = sprite_texture
		#
	#$StaticBody2D/Label.text = str(health)
	#$Area2D.connect("body_entered", Callable(self, "_on_body_entered"))
	#$Area2D.connect("body_exited", Callable(self, "_on_body_exited"))
#
#func _input(event):
				#if event.is_action_pressed("interact") and $StaticBody2D/Label.visible:
					#health -= 1
					#if health == 0:
						#queue_free()
					#else:
						#$StaticBody2D/Label.text = str(health)
							#
#func _on_body_entered(body):
	#if body.name == "Player":
		#$StaticBody2D/Label.visible = true
#
#func _on_body_exited(body):
	#if body.name == "Player":
		#$StaticBody2D/Label.visible = false
		
extends Node2D

@export var rock_name: String
@export var health: int = 3
@export var sprite_texture: Texture2D

var player: Node = null

func _ready():
	add_to_group("rock")
	if sprite_texture:
		$StaticBody2D/Sprite2D.texture = sprite_texture
	$StaticBody2D/Label.text = str(health)
	$Area2D.connect("body_entered", Callable(self, "_on_body_entered"))
	$Area2D.connect("body_exited", Callable(self, "_on_body_exited"))

func _input(event):
	if event.is_action_pressed("interact") and player:
		# znajdź wszystkie obiekty Rock w scenie
		var rocks = get_tree().get_nodes_in_group("rock")
		var nearest = self
		var nearest_dist = player.global_position.distance_to(global_position)
		for rock in rocks:
			var dist = player.global_position.distance_to(rock.global_position)
			if dist < nearest_dist:
				nearest = rock
				nearest_dist = dist
		if nearest == self:
			# interakcja tylko jeśli to najbliższy
			health -= 1
			if health <= 0:
				queue_free()
			else:
				$StaticBody2D/Label.text = str(health)

func _on_body_entered(body):
	if body.name == "Player":
		player = body
		$StaticBody2D/Label.visible = true

func _on_body_exited(body):
	if body.name == "Player":
		player = null
		$StaticBody2D/Label.visible = false
