extends RigidBody2D

@export var type: String
@export var quality: float
@export var weight: float
@export var mweight: float
@export var fragility: float
var min_weight := 50.0
var max_weight := 55000.0
var min_mass = 0.05
var max_mass = 1.0

func _ready() -> void:
	var w = clamp(weight, min_weight, max_weight)
	var normalized = (log(w) - log(min_weight)) / (log(max_weight) - log(min_weight))
	mass = lerp(min_mass, max_mass, normalized)
