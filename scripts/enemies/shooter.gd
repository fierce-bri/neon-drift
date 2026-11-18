extends Enemy
## Shooter: keeps its distance, strafes around the player and fires slow,
## dodgeable shots after a short charge-up glow.

const PREFERRED_RANGE := 340.0
const FIRE_INTERVAL := 2.1
const CHARGE_TIME := 0.45
const SHOT_SPEED := 290.0

const BulletScene := preload("res://scenes/bullet.tscn")

var _fire_timer := randf_range(1.0, FIRE_INTERVAL)
var _strafe_sign := 1.0 if randf() < 0.5 else -1.0


func _behave(delta: float, target: Player) -> void:
	if not target:
		_steer(Vector2.ZERO, 2.0, delta)
		return
	var to := target.global_position - global_position
	var dist := to.length()
	var dir := to / maxf(dist, 0.01)
	var desired := dir.orthogonal() * _strafe_sign * speed * 0.8
	if dist > PREFERRED_RANGE + 50.0:
		desired += dir * speed
	elif dist < PREFERRED_RANGE - 60.0:
		desired -= dir * speed
	_steer(desired, 2.5, delta)
	if fmod(_time, 3.5) < delta:
		_strafe_sign *= -1.0
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = FIRE_INTERVAL
		var muzzle := global_position + dir * (radius + 4.0)
		Events.spawn(BulletScene.instantiate().setup(muzzle, dir * SHOT_SPEED * GameState.difficulty(), false))
		Audio.play("enemy_shoot", -6.0)
		velocity -= dir * 90.0


func _draw_body(c: Color) -> void:
	var charge := clampf(1.0 - _fire_timer / CHARGE_TIME, 0.0, 1.0)
	c = c.lerp(Color(1.0, 0.4, 0.3), charge)
	Neon.shape(self, Neon.ngon(radius, 6, _time * 0.8), c, 2.4)
	Neon.shape(self, Neon.ngon(radius * 0.45, 3, -_time * 2.5), c, 1.6, 0.3)
	if charge > 0.0:
		draw_circle(Vector2.ZERO, 4.0 + charge * 6.0, Color(1.0, 0.5, 0.4, 0.4 + charge * 0.5))
