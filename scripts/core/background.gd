extends Node2D
## Animated neon grid, arena border and drifting dust. Pulses on every kill.

const GRID := 64.0
const GRID_COLOR := Color(0.45, 0.2, 0.9)
const BORDER_COLOR := Color(0.1, 0.9, 1.0)
const BORDER_ALT := Color(1.0, 0.2, 0.7)

var _time := 0.0
var _pulse := 0.0
var _dust: Array[Vector3] = []  # x, y, speed


func _ready() -> void:
	for i in 70:
		_dust.append(Vector3(randf_range(-600, 1880), randf_range(-400, 1120), randf_range(4, 18)))
	Events.enemy_killed.connect(func(_e): _pulse = minf(_pulse + 0.35, 1.0))


func _process(delta: float) -> void:
	_time += delta
	_pulse = maxf(_pulse - delta * 1.5, 0.0)
	for i in _dust.size():
		var d := _dust[i]
		d.y -= d.z * delta
		if d.y < -400:
			d.y = 1120
		_dust[i] = d
	queue_redraw()


func _draw() -> void:
	var r := Arena.RECT
	# Outer void, slightly lighter so the arena edge reads as a wall.
	draw_rect(Rect2(-1400, -1000, 4080, 2720), Color(0.03, 0.012, 0.06))
	draw_rect(r, Color(0.012, 0.006, 0.03))
	for d in _dust:
		draw_circle(Vector2(d.x, d.y), 1.2, Color(0.6, 0.5, 1.0, 0.25))

	# Grid inside the arena, brighter lines every 4 cells, gentle breathing + kill pulse.
	var breathe := 0.5 + 0.5 * sin(_time * 1.3)
	var alpha := 0.11 + 0.04 * breathe + 0.14 * _pulse
	var x := r.position.x
	var i := 0
	while x <= r.end.x + 0.5:
		var a := alpha * (2.2 if i % 4 == 0 else 1.0)
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color(GRID_COLOR, a), 1.0)
		x += GRID
		i += 1
	var y := r.position.y
	i = 0
	while y <= r.end.y + 0.5:
		var a := alpha * (2.2 if i % 4 == 0 else 1.0)
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color(GRID_COLOR, a), 1.0)
		y += GRID
		i += 1

	# Arena wall: thick double neon border with colour cycling corners.
	var c := BORDER_COLOR.lerp(BORDER_ALT, 0.5 + 0.5 * sin(_time * 0.6))
	var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	Neon.shape(self, pts, c, 3.0, 0.0)
	var inner := PackedVector2Array()
	for p in pts:
		inner.append(p.lerp(r.get_center(), 0.012))
	var closed := inner.duplicate()
	closed.append(inner[0])
	draw_polyline(closed, Color(c, 0.25), 1.0, true)
	for p in pts:
		draw_circle(p, 6.0, Color(c, 0.35))
		draw_circle(p, 3.0, c.lerp(Color.WHITE, 0.6))
