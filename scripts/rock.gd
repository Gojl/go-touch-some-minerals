extends Node2D

@export var rock_name: String
@export var health: int
@export var sprite_texture: Texture2D

func _ready() -> void:
	if sprite_texture:
		$StaticBody2D/Sprite2D.texture = sprite_texture
		
	$StaticBody2D/Label.text = str(health)
	$Area2D.connect("body_entered", Callable(self, "_on_body_entered"))
	$Area2D.connect("body_exited", Callable(self, "_on_body_exited"))

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and $StaticBody2D/Label.visible:
		health -= 1
		if health == 0:
			queue_free()
		else:
			$StaticBody2D/Label.text = str(health)
				
func _on_body_entered(body):
	if body.name == "Player":
		$StaticBody2D/Label.visible = true

func _on_body_exited(body):
	if body.name == "Player":
		$StaticBody2D/Label.visible = false
