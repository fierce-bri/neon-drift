class_name Arena
## Play-area bounds and physics layer constants shared by every entity.

const RECT := Rect2(32, 32, 1216, 656)

# Physics layers (bit values).
const LAYER_PLAYER := 1
const LAYER_ENEMY := 2
const LAYER_PLAYER_BULLET := 4
const LAYER_ENEMY_BULLET := 8
const LAYER_PICKUP := 16


## Clamps a circle of `radius` inside the arena.
static func clamp_point(p: Vector2, radius: float) -> Vector2:
	return Vector2(
		clampf(p.x, RECT.position.x + radius, RECT.end.x - radius),
		clampf(p.y, RECT.position.y + radius, RECT.end.y - radius))


static func random_point(margin: float) -> Vector2:
	return Vector2(
		randf_range(RECT.position.x + margin, RECT.end.x - margin),
		randf_range(RECT.position.y + margin, RECT.end.y - margin))
