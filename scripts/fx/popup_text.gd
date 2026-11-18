class_name PopupText
extends Label
## Floating text that rises and fades (score values, pickup names).


func setup(pos: Vector2, text_value: String, color: Color, font_size: int = 18) -> PopupText:
	text = text_value
	add_theme_font_size_override("font_size", font_size)
	add_theme_color_override("font_color", color.lerp(Color.WHITE, 0.35))
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	add_theme_constant_override("outline_size", 5)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	size = Vector2(220, 30)
	position = pos - Vector2(110, 22)
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20
	return self


func _ready() -> void:
	scale = Vector2(0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "position:y", position.y - 46.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.35).set_delay(0.45)
	tw.tween_callback(queue_free)
