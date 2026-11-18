class_name Neon
## Drawing helpers for the vector-neon look: every shape is a bright core line
## wrapped in wide, faint strokes that the bloom shader then spreads further.

const GLOW_LAYERS := [[12.0, 0.07], [7.0, 0.14], [4.0, 0.3]]


## Regular polygon points (radius r, n sides, rotation in radians).
static func ngon(r: float, sides: int, rotation: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in sides:
		var a := rotation + TAU * i / sides
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


## Closed glowing outline with a faint fill.
static func shape(ci: CanvasItem, pts: PackedVector2Array, color: Color, width: float = 2.5, fill_alpha: float = 0.12) -> void:
	if fill_alpha > 0.0:
		ci.draw_colored_polygon(pts, Color(color, fill_alpha))
	var closed := pts.duplicate()
	closed.append(pts[0])
	for layer in GLOW_LAYERS:
		ci.draw_polyline(closed, Color(color, layer[1]), width + layer[0], true)
	ci.draw_polyline(closed, color, width, true)
	ci.draw_polyline(closed, color.lerp(Color.WHITE, 0.7), maxf(width * 0.4, 1.0), true)


## Glowing line segment.
static func line(ci: CanvasItem, a: Vector2, b: Vector2, color: Color, width: float = 2.5) -> void:
	for layer in GLOW_LAYERS:
		ci.draw_line(a, b, Color(color, layer[1]), width + layer[0], true)
	ci.draw_line(a, b, color, width, true)
	ci.draw_line(a, b, color.lerp(Color.WHITE, 0.7), maxf(width * 0.4, 1.0), true)


## Glowing ring.
static func ring(ci: CanvasItem, r: float, color: Color, width: float = 2.0) -> void:
	for layer in GLOW_LAYERS:
		ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(color, layer[1]), width + layer[0], true)
	ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, color, width, true)


## Soft glowing dot (bullets).
static func dot(ci: CanvasItem, pos: Vector2, r: float, color: Color) -> void:
	ci.draw_circle(pos, r * 3.0, Color(color, 0.08))
	ci.draw_circle(pos, r * 1.8, Color(color, 0.2))
	ci.draw_circle(pos, r, color)
	ci.draw_circle(pos, r * 0.5, color.lerp(Color.WHITE, 0.8))
