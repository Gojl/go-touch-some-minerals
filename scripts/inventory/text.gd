extends RichTextLabel

func _ready() -> void:
	get_parent().add_theme_font_size_override("normal_font_size", 16)

func _process(delta: float) -> void:
	pass
