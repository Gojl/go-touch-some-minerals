extends Node

var player: Node2D = null
var chunk_size: int = 16

enum Mode {
	EXPLORE,
	INSPECT,
	MINE
}

var mode := Mode.EXPLORE
var inspected_rock: Node2D = null

func exit_inspect():
	mode = Mode.EXPLORE
	inspected_rock = null

func add_mineral_to_inv(mineral_type: String, mineral_quality: float):
	print("dodano minerał do ekwipunku, ", mineral_type, " o jakosci: ", mineral_quality)
