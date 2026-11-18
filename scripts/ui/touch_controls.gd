extends Control
## Touch fallback: drag on the left half to move (virtual stick), hold on the
## right half to aim at that point and fire. Activates on the first touch and
## turns off again as soon as a real mouse moves.

const STICK_RADIUS := 70.0

var _move_index := -1
var _aim_index := -1
var _stick_origin := Vector2.ZERO
var _stick_pos := Vector2.ZERO


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		if GameState.touch_active:
			GameState.touch_active = false
			_reset()
		return
	if event is InputEventScreenTouch:
		GameState.touch_active = true
		if event.pressed:
			if event.position.x < size.x * 0.5 and _move_index == -1:
				_move_index = event.index
				_stick_origin = event.position
				_stick_pos = event.position
			elif event.position.x >= size.x * 0.5 and _aim_index == -1 and not _in_pause_corner(event.position):
				_aim_index = event.index
				_set_aim(event.position)
		else:
			if event.index == _move_index:
				_move_index = -1
				GameState.touch_move = Vector2.ZERO
			elif event.index == _aim_index:
				_aim_index = -1
				GameState.touch_firing = false
		queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == _move_index:
			_stick_pos = _stick_origin + (event.position - _stick_origin).limit_length(STICK_RADIUS)
			GameState.touch_move = (_stick_pos - _stick_origin) / STICK_RADIUS
		elif event.index == _aim_index:
			_set_aim(event.position)
		queue_redraw()


func _set_aim(screen_pos: Vector2) -> void:
	GameState.touch_aim_world = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	GameState.touch_firing = true


func _in_pause_corner(p: Vector2) -> bool:
	return p.x > size.x - 110.0 and p.y < 110.0


func _reset() -> void:
	_move_index = -1
	_aim_index = -1
	GameState.touch_move = Vector2.ZERO
	GameState.touch_firing = false
	queue_redraw()


func _draw() -> void:
	if not GameState.touch_active or _move_index == -1:
		return
	var c := Color(0.3, 0.9, 1.0)
	draw_arc(_stick_origin, STICK_RADIUS, 0.0, TAU, 48, Color(c, 0.35), 3.0, true)
	draw_circle(_stick_pos, 28.0, Color(c, 0.25))
	draw_arc(_stick_pos, 28.0, 0.0, TAU, 32, Color(c, 0.8), 2.0, true)
