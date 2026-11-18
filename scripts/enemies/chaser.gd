extends Enemy
## Chaser: relentlessly homes in on the player with a slight wobble.

var _wobble_seed := randf() * TAU


func _behave(delta: float, target: Player) -> void:
	var desired := Vector2.ZERO
	if target:
		var to := (target.global_position - global_position).normalized()
		desired = to.rotated(sin(_time * 3.0 + _wobble_seed) * 0.35) * speed
	else:
		desired = Vector2.RIGHT.rotated(_wobble_seed + _time * 0.5) * speed * 0.3
	_steer(desired, 3.5, delta)


func _draw_body(c: Color) -> void:
	var stretch := 1.0 + 0.12 * sin(_time * 10.0)
	var pts := PackedVector2Array([
		Vector2(radius * stretch, 0), Vector2(0, radius * 0.75), Vector2(-radius * stretch, 0), Vector2(0, -radius * 0.75)])
	draw_set_transform(Vector2.ZERO, velocity.angle(), Vector2.ONE)
	Neon.shape(self, pts, c, 2.4)
	draw_circle(Vector2(radius * 0.25, 0), 2.5, c.lerp(Color.WHITE, 0.7))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
