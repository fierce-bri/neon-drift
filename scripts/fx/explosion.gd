class_name Explosion
extends Node2D
## One-shot particle burst plus an expanding shockwave ring.

var color := Color.WHITE
var size := 1.0
var _ring := 0.0

@onready var _particles: CPUParticles2D = $Particles
@onready var _sparks: CPUParticles2D = $Sparks


func setup(pos: Vector2, c: Color, s: float) -> Explosion:
	position = pos
	color = c
	size = s
	return self


func _ready() -> void:
	for p in [_particles, _sparks]:
		p.color = color
		p.amount = maxi(4, int(p.amount * clampf(size, 0.3, 2.5)))
		p.initial_velocity_max *= clampf(0.6 + size * 0.4, 0.6, 1.8)
		p.emitting = true
	var tw := create_tween()
	tw.tween_property(self, "_ring", 1.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_interval(0.5)
	tw.tween_callback(queue_free)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _ring >= 1.0:
		return
	var r := 8.0 + _ring * 60.0 * size
	var a := 1.0 - _ring
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(color, 0.25 * a), 10.0 * a + 1.0, true)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(color.lerp(Color.WHITE, 0.5), a), 2.5 * a + 0.5, true)
