extends Control

@onready var background = $Background
@onready var previous = $Previous
@onready var next = $Next

var current_building = 0
const positions = [0, -980, -2270, -3350] # px offsets for houses

func _ready() -> void:
	await get_tree().process_frame
	if get_tree().get_meta("current_building"):
		current_building = get_tree().get_meta("current_building")
		background.position.x = positions[get_tree().get_meta("current_building")]

func _on_previous_pressed() -> void:
	if current_building <= 0:
		get_tree().change_scene_to_file("res://scenes/polska.tscn")
		return
	current_building -= 1
	get_tree().set_meta("current_building", current_building)
	move_to_x(positions[current_building])


func _on_next_pressed() -> void:
	if current_building >= len(positions) - 1:
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		return
	current_building += 1
	get_tree().set_meta("current_building", current_building)
	move_to_x(positions[current_building])

func move_to_x(pos: float):
	var tween = create_tween()
	tween.tween_property(background, "position", Vector2(pos, background.position.y), 0.3)

func _unhandled_input(event):
	if event.is_action_pressed("left"):
		_on_previous_pressed()
	elif event.is_action_pressed("right"):
		_on_next_pressed()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("up"):
		_enter_house()

func _enter_house():
	if current_building == 0:
		get_tree().change_scene_to_file("res://scenes/budynki/wystawa.tscn")
	elif current_building == 1:
		get_tree().change_scene_to_file("res://scenes/budynki/skup.tscn")
	elif current_building == 2:
		get_tree().change_scene_to_file("res://scenes/budynki/dom.tscn")
	elif current_building == 3:
		get_tree().change_scene_to_file("res://scenes/budynki/sklep.tscn")
