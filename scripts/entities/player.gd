class_name Player
extends Area2D
## Twin-stick player ship: WASD/arrows to move, mouse (or touch) to aim and fire.

signal health_changed(hp: int, max_hp: int)
signal rapid_fire_changed(time_left: float)
signal died

const MAX_HP := 5
const RADIUS := 13.0
const MAX_SPEED := 370.0
const ACCEL := 3400.0          # reaches top speed in ~0.11 s
const DECEL := 2600.0          # stops in ~0.14 s
const FIRE_INTERVAL := 0.12
const RAPID_INTERVAL := 0.055
const RAPID_DURATION := 6.0
const BULLET_SPEED := 980.0
const INVULN_TIME := 1.2
const COLOR := Color(0.2, 0.95, 1.0)

const BulletScene := preload("res://scenes/bullet.tscn")

var hp := MAX_HP
var velocity := Vector2.ZERO
var aim_dir := Vector2.RIGHT
var rapid_timer := 0.0
var _fire_cooldown := 0.0
var _invuln := 0.0
var _flash := 0.0
var _dead := false

@onready var _trail: CPUParticles2D = $Trail


func _ready() -> void:
	add_to_group("player")
	collision_layer = Arena.LAYER_PLAYER
	collision_mask = Arena.LAYER_ENEMY
	scale = Vector2.ZERO
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	health_changed.emit.call_deferred(hp, MAX_HP)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_move(delta)
	_aim()
	_shoot(delta)
	_check_contact()
	_invuln = maxf(_invuln - delta, 0.0)
	_flash = maxf(_flash - delta * 5.0, 0.0)
	if rapid_timer > 0.0:
		rapid_timer = maxf(rapid_timer - delta, 0.0)
		rapid_fire_changed.emit(rapid_timer)
	_trail.emitting = velocity.length() > 60.0
	_trail.rotation = velocity.angle() - rotation + PI
	queue_redraw()


func _move(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input == Vector2.ZERO and GameState.touch_active:
		input = GameState.touch_move.limit_length(1.0)
	var rate := ACCEL if input != Vector2.ZERO else DECEL
	velocity = velocity.move_toward(input * MAX_SPEED, rate * delta)
	position = Arena.clamp_point(position + velocity * delta, RADIUS)


func _aim() -> void:
	var target := GameState.touch_aim_world if GameState.touch_active else get_global_mouse_position()
	var to := target - global_position
	if to.length() > 4.0:
		aim_dir = to.normalized()
	rotation = lerp_angle(rotation, aim_dir.angle(), 0.5)


func _shoot(delta: float) -> void:
	_fire_cooldown -= delta
	var firing := GameState.touch_firing if GameState.touch_active else Input.is_action_pressed("fire")
	if not firing or _fire_cooldown > 0.0:
		return
	var rapid := rapid_timer > 0.0
	_fire_cooldown = RAPID_INTERVAL if rapid else FIRE_INTERVAL
	var spread := 0.07 if rapid else 0.025
	var dir := aim_dir.rotated(randf_range(-spread, spread))
	var muzzle := global_position + aim_dir * (RADIUS + 6.0)
	Events.spawn(BulletScene.instantiate().setup(muzzle, dir * BULLET_SPEED, true))
	velocity -= aim_dir * 18.0  # tiny recoil
	Audio.play("shoot", -9.0 if rapid else -6.0, 0.1)


func _check_contact() -> void:
	if _invuln > 0.0:
		return
	for area in get_overlapping_areas():
		if area is Enemy and not area.is_dead():
			take_damage(area.contact_damage, area.global_position)
			return


func take_damage(amount: int, from: Vector2) -> void:
	if _dead or _invuln > 0.0:
		return
	hp = maxi(hp - amount, 0)
	_invuln = INVULN_TIME
	_flash = 1.0
	velocity += (global_position - from).normalized() * 520.0
	health_changed.emit(hp, MAX_HP)
	GameState.break_combo()
	Events.player_damaged.emit()
	Events.shake(0.55)
	Events.explode(global_position, COLOR, 0.6)
	Audio.play("player_hit")
	_hit_stop()
	if hp <= 0:
		_die()


func heal(amount: int) -> void:
	hp = mini(hp + amount, MAX_HP)
	health_changed.emit(hp, MAX_HP)


func give_rapid_fire() -> void:
	rapid_timer = RAPID_DURATION
	rapid_fire_changed.emit(rapid_timer)


func is_dead() -> bool:
	return _dead


func _hit_stop() -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.07, true, false, true).timeout
	Engine.time_scale = 1.0


func _die() -> void:
	_dead = true
	_trail.emitting = false
	Events.shake(1.0)
	Events.explode(global_position, COLOR, 2.5)
	Events.explode(global_position, Color(1, 0.3, 0.8), 1.6)
	Audio.play("death", 2.0, 0.0)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(2.2, 2.2), 0.25)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	died.emit()


func _draw() -> void:
	if _invuln > 0.0 and not _dead and int(_invuln * 14.0) % 2 == 0:
		return  # blink while invulnerable
	var c := COLOR.lerp(Color.WHITE, _flash)
	if rapid_timer > 0.0:
		c = c.lerp(Color(1.0, 0.9, 0.2), 0.45 + 0.2 * sin(Time.get_ticks_msec() * 0.02))
	var hull := PackedVector2Array([Vector2(18, 0), Vector2(-12, 12), Vector2(-6, 0), Vector2(-12, -12)])
	Neon.shape(self, hull, c, 2.6, 0.18)
	draw_circle(Vector2(2, 0), 3.0, c.lerp(Color.WHITE, 0.6))
