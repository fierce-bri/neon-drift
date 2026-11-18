extends Enemy
## Splitter: slow, tanky block that bursts into fast mini chasers when destroyed.

const MiniScene := preload("res://scenes/enemies/mini_chaser.tscn")
const CHILDREN := 3


func _behave(delta: float, target: Player) -> void:
	var desired := Vector2.ZERO
	if target:
		desired = (target.global_position - global_position).normalized() * speed
	_steer(desired, 1.5, delta)


func _on_death() -> void:
	var base := randf() * TAU
	for i in CHILDREN:
		var dir := Vector2.RIGHT.rotated(base + TAU * i / CHILDREN)
		var mini := MiniScene.instantiate() as Enemy
		mini.position = Arena.clamp_point(global_position + dir * radius * 0.8, 12.0)
		mini.velocity = dir * 320.0
		Events.spawn(mini)


func _draw_body(c: Color) -> void:
	var hurt := 1.0 - float(hp) / max_hp
	Neon.shape(self, Neon.ngon(radius, 4, _time * 0.6 + PI / 4.0), c, 2.8)
	Neon.shape(self, Neon.ngon(radius * (0.55 + 0.1 * sin(_time * 4.0)), 4, -_time * 1.2), c, 1.8, 0.2)
	# Cracks appear as it takes damage.
	if hurt > 0.0:
		for i in int(hurt * 4.0) + 1:
			var a := i * 1.7 + 0.4
			draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * radius * 0.9, Color(1, 1, 1, 0.5), 1.5, true)
