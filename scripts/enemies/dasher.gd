extends Enemy
## Dasher: closes in, locks on with a visible telegraph, then dashes in a straight line.

enum Phase { APPROACH, WINDUP, DASH, RECOVER }

const TRIGGER_RANGE := 320.0
const WINDUP_TIME := 0.7
const DASH_TIME := 0.38
const DASH_SPEED := 760.0
const RECOVER_TIME := 0.7

var _phase := Phase.APPROACH
var _phase_time := 0.0
var _dash_dir := Vector2.RIGHT


func _behave(delta: float, target: Player) -> void:
	_phase_time += delta
	match _phase:
		Phase.APPROACH:
			if target:
				var to := target.global_position - global_position
				_dash_dir = to.normalized()
				_steer(_dash_dir * speed, 3.0, delta)
				if to.length() < TRIGGER_RANGE and _phase_time > 0.6:
					_set_phase(Phase.WINDUP)
			else:
				_steer(Vector2.ZERO, 2.0, delta)
		Phase.WINDUP:
			if target:  # keep tracking until the last moment so the dash is fair but aimed
				_dash_dir = _dash_dir.slerp((target.global_position - global_position).normalized(), 0.08)
			_steer(-_dash_dir * 40.0, 8.0, delta)
			if _phase_time >= WINDUP_TIME:
				_set_phase(Phase.DASH)
				Audio.play("dash", -4.0)
		Phase.DASH:
			velocity = _dash_dir * DASH_SPEED * GameState.difficulty()
			if _phase_time >= DASH_TIME:
				_set_phase(Phase.RECOVER)
		Phase.RECOVER:
			_steer(Vector2.ZERO, 5.0, delta)
			if _phase_time >= RECOVER_TIME:
				_set_phase(Phase.APPROACH)


func _set_phase(p: Phase) -> void:
	_phase = p
	_phase_time = 0.0


func _draw_body(c: Color) -> void:
	if _phase == Phase.WINDUP:
		# Telegraph: a flickering aim line and a brightening body.
		var k := _phase_time / WINDUP_TIME
		var a := 0.15 + 0.5 * k * (0.6 + 0.4 * sin(_phase_time * 40.0))
		draw_line(Vector2.ZERO, _dash_dir * 260.0, Color(c, a), 2.0 + 4.0 * k, true)
		c = c.lerp(Color.WHITE, k * 0.5)
	var jitter := Vector2(randf_range(-2, 2), randf_range(-2, 2)) if _phase == Phase.WINDUP else Vector2.ZERO
	draw_set_transform(jitter, _dash_dir.angle(), Vector2.ONE)
	var pts := PackedVector2Array([
		Vector2(radius * 1.3, 0), Vector2(-radius * 0.8, radius * 0.9), Vector2(-radius * 0.3, 0), Vector2(-radius * 0.8, -radius * 0.9)])
	Neon.shape(self, pts, c, 2.4)
	if _phase == Phase.DASH:
		for i in 3:
			var off := -radius * (1.4 + i * 0.9)
			draw_line(Vector2(off, -6), Vector2(off, 6), Color(c, 0.5 - i * 0.15), 3.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
