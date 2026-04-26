extends Control

var player: Node
@onready var label = $RichTextLabel

func _ready() -> void:
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("stone_mine: Could not find player node in group 'player'!")
	player.mode_changed.connect(_clear)

func setInfo(type,weight,quality, mperc) -> void:
	var weightToShow: String
	if weight < 1000:
		weightToShow = str(snapped(weight,0.01)) + "G"
	else:
		weightToShow = str(snapped(weight/1000,0.01)) + "KG"
	if type != "rock":
		label.text = (
			"[b]" + str(type).capitalize() + "[/b]" +
			"\n[font_size=40]Estimated data:[/font_size]" +
			"\n[color=gray]Weight:\n[/color] " + weightToShow +
			"\n[color=gray]Base quality:\n[/color]" + str(snapped(quality,0.01)) +
			"\n[color=gray]Percentage:\n[/color]" + str(snapped(mperc,0.1)) + "%"
		)
	else:
		label.text = (
			"[b]" + str(type).capitalize() + "[/b]" +
			"\n[font_size=40]Generic rock[/font_size]")

func _clear(mode, _rock = null, _zoom = -1.5) -> void:
	if mode != player.Mode.INSPECT:
		queue_free()
