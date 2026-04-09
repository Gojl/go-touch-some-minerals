extends ColorRect

@export var default_alpha: float = 0.7
@export var default_duration: float = 0.3

var _tween: Tween = null

func _ready() -> void:
	modulate.a = 0.0

func fade_in(alpha: float = -1.0, duration: float = -1.0, _z_index: int = 1) -> void:
	if duration < 0:
		duration = default_duration
	if alpha < 0:
		alpha = default_alpha
	
	_kill_tween()
	modulate.a = 0.0
	z_index = _z_index
	visible = true
	
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", alpha, duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)

func fade_out(duration: float = -1.0) -> void:
	if duration < 0:
		duration = default_duration
	
	_kill_tween()
	
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(func() -> void:
		visible = false
	)

func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
