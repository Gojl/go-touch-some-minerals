extends TextureButton

@onready var inv = get_parent().get_parent().get_parent().get_parent()
@onready var slot = get_parent()

func _pressed() -> void:
	inv.drop_mineral(slot.id)
