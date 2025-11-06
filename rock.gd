extends StaticBody2D

@onready var interactable: Area2D = $interactable
@onready var sprite_2d: Sprite2D = $Kamień
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interactable.interact = _on_interact


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_interact():
	print("the tree cannot be cut down due to cultural issues")
		#sprite_2d.frame = 1
		#print("the rock has been checked")
