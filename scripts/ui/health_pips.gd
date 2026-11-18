extends Control
## Draws the player's health as glowing pips.

var hp := 5
var max_hp := 5
var _flash := 0.0


func set_health(value: int, maximum: int) -> void:
	if value < hp:
		_flash = 1.0
	hp = value
	max_hp = maximum
	custom_minimum_size = Vector2(maximum * 30.0, 26.0)
	queue_redraw()


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(_flash - delta * 3.0, 0.0)
		queue_redraw()


func _draw() -> void:
	var low := hp <= 2
	for i in max_hp:
		var center := Vector2(12.0 + i * 30.0, 13.0)
		var pts := Neon.ngon(10.0, 4, PI / 4.0)
		for j in pts.size():
			pts[j] += center
		if i < hp:
			var c := Color(1.0, 0.3, 0.45) if low else Color(0.3, 1.0, 0.55)
			Neon.shape(self, pts, c.lerp(Color.WHITE, _flash * 0.6), 2.0, 0.5)
		else:
			var closed := pts.duplicate()
			closed.append(pts[0])
			draw_polyline(closed, Color(1, 1, 1, 0.18), 1.5, true)
