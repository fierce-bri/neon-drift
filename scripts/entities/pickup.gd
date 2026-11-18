class_name Pickup
extends Area2D
## Health or rapid-fire power-up dropped by enemies. Expires after a while.

enum Kind { HEALTH, RAPID_FIRE }

const LIFETIME := 9.0
const COLORS := { Kind.HEALTH: Color(0.3, 1.0, 0.45), Kind.RAPID_FIRE: Color(1.0, 0.85, 0.2) }

var kind: Kind = Kind.HEALTH
var _life := LIFETIME
var _time := 0.0
var _taken := false


func setup(pos: Vector2, pickup_kind: Kind) -> Pickup:
	position = Arena.clamp_point(pos, 30.0)
	kind = pickup_kind
	return self


func _ready() -> void:
	collision_layer = Arena.LAYER_PICKUP
	collision_mask = Arena.LAYER_PLAYER
	var shape := CircleShape2D.new()
	shape.radius = 22.0  # generous: pickups are easier to grab than they look
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	area_entered.connect(_on_area_entered)
	scale = Vector2.ZERO
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	_time += delta
	_life -= delta
	if _life <= 0.0:
		queue_free()
	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	if _taken or not area is Player or area.is_dead():
		return
	_taken = true
	var color: Color = COLORS[kind]
	match kind:
		Kind.HEALTH:
			area.heal(1)
			Events.popup(global_position, "+1 HP", color)
			Audio.play("pickup")
		Kind.RAPID_FIRE:
			area.give_rapid_fire()
			Events.popup(global_position, "RAPID FIRE", color)
			Audio.play("powerup")
	Events.explode(global_position, color, 0.7)
	queue_free()


func _draw() -> void:
	if _life < 2.5 and int(_life * 8.0) % 2 == 0:
		return  # blink before expiring
	var color: Color = COLORS[kind]
	var bob := Vector2(0, sin(_time * 4.0) * 3.0)
	draw_set_transform(bob, 0.0, Vector2.ONE)
	var pts := Neon.ngon(17.0, 4, _time * 1.5 + PI / 4.0)
	Neon.shape(self, pts, color, 2.2, 0.15)
	match kind:
		Kind.HEALTH:
			Neon.line(self, Vector2(-7, 0), Vector2(7, 0), color, 3.0)
			Neon.line(self, Vector2(0, -7), Vector2(0, 7), color, 3.0)
		Kind.RAPID_FIRE:
			var bolt := PackedVector2Array([Vector2(2, -9), Vector2(-5, 1), Vector2(0, 1), Vector2(-2, 9), Vector2(5, -1), Vector2(0, -1)])
			Neon.shape(self, bolt, color, 1.8, 0.6)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
