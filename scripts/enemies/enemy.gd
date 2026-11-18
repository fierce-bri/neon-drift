class_name Enemy
extends Area2D
## Base class for all enemies: health, hit flash, knockback, separation
## steering and death. Subclasses implement _behave() and _draw_body().

@export var max_hp := 1
@export var speed := 150.0
@export var radius := 14.0
@export var points := 100
@export var color := Color(1.0, 0.25, 0.65)
@export var contact_damage := 1
@export var knockback := 260.0
@export var enemy_name := "enemy"

var hp := 1
var velocity := Vector2.ZERO
var _flash := 0.0
var _time := 0.0
var _dead := false


func _ready() -> void:
	hp = max_hp
	speed *= GameState.difficulty()
	add_to_group("enemies")
	collision_layer = Arena.LAYER_ENEMY
	collision_mask = 0
	var shape := CircleShape2D.new()
	shape.radius = radius * 0.85  # slightly forgiving contact hitbox
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	scale = Vector2(0.1, 0.1)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	_time += delta
	_flash = maxf(_flash - delta * 7.0, 0.0)
	_behave(delta, _target())
	velocity += _separation() * delta
	position = Arena.clamp_point(position + velocity * delta, radius)
	queue_redraw()


## Override: steer `velocity` toward/around `target` (may be null when the player is dead).
func _behave(_delta: float, _target_node: Player) -> void:
	pass


## Override: draw the enemy body using Neon helpers. `c` already includes hit flash.
func _draw_body(_c: Color) -> void:
	pass


## Override: extra effects on death (e.g. splitting).
func _on_death() -> void:
	pass


func hit(damage: int, dir: Vector2) -> void:
	if _dead:
		return
	hp -= damage
	_flash = 1.0
	velocity += dir * knockback
	if hp <= 0:
		die()
	else:
		Audio.play("hit", -8.0, 0.15)


func die() -> void:
	if _dead:
		return
	_dead = true
	Events.enemy_killed.emit(self)
	Events.explode(global_position, color, radius / 14.0)
	Events.shake(0.12 + radius * 0.006)
	Audio.play("explode", -4.0, 0.12)
	_on_death()
	queue_free()


func is_dead() -> bool:
	return _dead


func _target() -> Player:
	var p := get_tree().get_first_node_in_group("player") as Player
	if p == null or p.is_dead():
		return null
	return p


## Steer toward a desired velocity with exponential smoothing.
func _steer(desired: Vector2, responsiveness: float, delta: float) -> void:
	velocity = velocity.lerp(desired, 1.0 - exp(-responsiveness * delta))


## Push away from overlapping neighbours so groups don't stack into one blob.
func _separation() -> Vector2:
	var push := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self:
			continue
		var d: Vector2 = position - other.position
		var min_dist: float = radius + other.radius + 4.0
		var dist := d.length()
		if dist < min_dist and dist > 0.01:
			push += d / dist * (min_dist - dist) * 30.0
	return push


func _draw() -> void:
	_draw_body(color.lerp(Color.WHITE, _flash))
