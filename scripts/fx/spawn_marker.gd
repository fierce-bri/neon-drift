class_name SpawnMarker
extends Node2D
## Telegraphs an incoming enemy with a collapsing ring, then spawns it.
## Gives the player time to react so spawns never feel cheap.

const DURATION := 0.85

var _scene: PackedScene
var _color := Color.WHITE
var _t := 0.0


func setup(pos: Vector2, scene: PackedScene, color: Color) -> SpawnMarker:
	position = pos
	_scene = scene
	_color = color
	return self


func _ready() -> void:
	add_to_group("spawn_markers")


func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= DURATION:
		var enemy := _scene.instantiate() as Node2D
		enemy.position = position
		Events.spawn(enemy)
		Events.explode(position, _color, 0.35)
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := _t / DURATION
	var r := lerpf(46.0, 6.0, k * k)
	draw_set_transform(Vector2.ZERO, k * 4.0, Vector2.ONE)
	Neon.shape(self, Neon.ngon(r, 4), Color(_color, 0.35 + 0.6 * k), 1.5, 0.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2.ZERO, 3.0 + 4.0 * k, Color(_color, 0.6 * k))
