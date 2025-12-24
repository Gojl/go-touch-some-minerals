extends Node2D
@onready var inv = $"."
var kamien1 = 0
var open = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	inv.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void: 
	if event.is_action_pressed("inventory"):
		if open == 0:
			print("opened")
			inv.show()
			open = 1
		elif open == 1:
			print("closed")
			inv.hide()
			open = 0
		
