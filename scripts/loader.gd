extends TextureRect

var player: Node
@onready var label = $RichTextLabel

func _ready() -> void:
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("stone_mine: Could not find player node in group 'player'!")
	player.mode_changed.connect(_clear)

var target: Node = null
var time: float
var telapsed = 0
const barFull = 600
@onready var bar = $ColorRect

func _process(delta: float) -> void:
	if not (target and time and bar):
		return
	telapsed += delta
	var ratio = telapsed / time
	bar.size.x = barFull * clamp(0,1,ratio)
	if telapsed >= time:
		target.visible = true
		queue_free()
	
func _clear(mode, _node = null, _zoom = -1.5) -> void:
	if mode != player.Mode.INSPECT:
		queue_free()

func setData(starget, st) -> void:
	target = starget
	time = st
