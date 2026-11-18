extends SceneTree
## Headless smoke test: boots the main scene, plays ~20 simulated seconds with
## scripted input, checks waves/kills/score progress, pause, death and restart.
## Run:  godot --headless --script res://tests/smoke_test.gd

var _main: Node
var _frame := 0
var _failures: Array[String] = []
var _log: Array[String] = []


func _initialize() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)


func _check(name: String, ok: bool, detail: String = "") -> void:
	_log.append("%s %s %s" % ["PASS" if ok else "FAIL", name, detail])
	if not ok:
		_failures.append(name)


func _process(_delta: float) -> bool:
	_frame += 1
	var s: Dictionary = _main.debug_state()
	match _frame:
		5:
			_check("boot_title", s.state == "TITLE")
			_main.start_game()
		10:
			_check("start", s.state == "PLAYING" and s.hp == 5)
			Input.action_press("move_right")
		40:
			_check("move_right", s.player[0] > 660.0, str(s.player))
			Input.action_release("move_right")
			Input.action_press("fire")
		60:
			var p0: Array = s.player
			_main.set_meta("p0", p0)
		70:
			var p0: Array = _main.get_meta("p0")
			_check("stops_on_release", absf(s.player[0] - p0[0]) < 25.0, "%s -> %s" % [p0, s.player])
		200:
			_check("wave_started", s.wave >= 1, "wave=%d enemies=%d" % [s.wave, s.enemies])
	if _frame > 70 and _frame < 1300:
		_autoplay()
	if _frame == 1300:
		_check("scoring", s.score > 0, "score=%d wave=%d hp=%d" % [s.score, s.wave, s.hp])
		_main._toggle_pause()
	if _frame == 1310:
		_check("pause", s.state == "PAUSED" and paused)
		_main._toggle_pause()
	if _frame == 1320:
		_check("resume", s.state == "PLAYING" and not paused)
		var player = _main.player
		if player:
			for i in 6:
				player._invuln = 0.0
				player.take_damage(1, player.global_position + Vector2(10, 0))
	if _frame == 1500:
		_check("game_over", s.state == "GAME_OVER", s.state)
		_check("best_saved", _gs().best_score >= s.score and s.best > 0, "best=%d" % s.best)
		_main.start_game()
	if _frame == 1510:
		_check("restart", s.state == "PLAYING" and s.score == 0 and s.hp == 5 and s.enemies == 0)
		for line in _log:
			print(line)
		print("SMOKE TEST: %s" % ("ALL PASSED" if _failures.is_empty() else "FAILED " + str(_failures)))
		quit(0 if _failures.is_empty() else 1)
	return false


## Aim at the nearest enemy and strafe in a circle.
func _autoplay() -> void:
	var player = _main.player
	if player == null:
		return
	var nearest: Node2D = null
	var best := INF
	for e in get_nodes_in_group("enemies"):
		var d: float = e.global_position.distance_to(player.global_position)
		if d < best:
			best = d
			nearest = e
	if nearest:
		player.aim_dir = (nearest.global_position - player.global_position).normalized()
		_gs().touch_active = true  # route aim/fire through the touch path, which the test controls
		_gs().touch_aim_world = nearest.global_position
		_gs().touch_firing = true
		var away: Vector2 = (player.global_position - nearest.global_position).normalized()
		_gs().touch_move = away.orthogonal() * 0.8 + (away * 0.6 if best < 200.0 else Vector2.ZERO)
	player._invuln = 1.0  # god mode during the autoplay phase


func _gs() -> Node:
	return root.get_node("GameState")
