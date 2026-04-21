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
	label.text = (
		"[b]" + str(type).capitalize() + "[/b]" + 
		"\n Estimated data:" +
		"\n[color=gray]Weight: [/color] " + weightToShow +
		"\n[color=gray]Base quality: [/color]" + str(snapped(quality,0.01)) +
		"\n[color=gray]Mineral percentage: [/color]" + str(snapped(mperc,0.1)) + "%"
		)

func _clear(mode, _rock = null, _zoom = -1.5) -> void:
	if mode != player.Mode.INSPECT:
		queue_free()
