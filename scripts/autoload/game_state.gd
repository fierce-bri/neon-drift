extends Node
## Run state (score, combo, wave), persistent settings (best score, mute)
## and the input map. Saved to user:// which maps to IndexedDB on the web.

signal score_changed(score: int)
signal combo_changed(multiplier: int)
signal wave_changed(wave: int)

const SAVE_PATH := "user://neon_drift_save.cfg"
const COMBO_WINDOW := 2.5
const KILLS_PER_MULTIPLIER := 4
const MAX_MULTIPLIER := 8

var score := 0
var best_score := 0
var kills := 0
var wave := 0
var combo_kills := 0
var combo_timer := 0.0
var muted := false

# Touch controls write here; the player reads it.
var touch_active := false
var touch_move := Vector2.ZERO
var touch_aim_world := Vector2.ZERO
var touch_firing := false


func _ready() -> void:
	_setup_input_map()
	load_save()


func _process(delta: float) -> void:
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			break_combo()


# ------------------------------------------------------------------ run state
func reset_run() -> void:
	score = 0
	kills = 0
	wave = 0
	combo_kills = 0
	combo_timer = 0.0
	score_changed.emit(score)
	combo_changed.emit(multiplier())
	wave_changed.emit(wave)


func multiplier() -> int:
	return mini(1 + floori(float(combo_kills) / KILLS_PER_MULTIPLIER), MAX_MULTIPLIER)


## Registers a kill and returns the points actually awarded.
func register_kill(base_points: int) -> int:
	var before := multiplier()
	combo_kills += 1
	combo_timer = COMBO_WINDOW
	kills += 1
	var awarded := base_points * multiplier()
	score += awarded
	score_changed.emit(score)
	if multiplier() != before:
		combo_changed.emit(multiplier())
	return awarded


func break_combo() -> void:
	combo_timer = 0.0
	if combo_kills != 0:
		combo_kills = 0
		combo_changed.emit(multiplier())


func combo_fraction() -> float:
	return clampf(combo_timer / COMBO_WINDOW, 0.0, 1.0)


func set_wave(n: int) -> void:
	wave = n
	wave_changed.emit(wave)


## Enemy speed scale for the current wave.
func difficulty() -> float:
	return 1.0 + minf(maxi(wave - 1, 0) * 0.05, 0.6)


## Ends the run; returns true when a new best score was set.
func finish_run() -> bool:
	if score > best_score:
		best_score = score
		save()
		return true
	return false


# ------------------------------------------------------------------ persistence
func load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_score = int(cfg.get_value("stats", "best_score", 0))
		muted = bool(cfg.get_value("settings", "muted", false))


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("stats", "best_score", best_score)
	cfg.set_value("settings", "muted", muted)
	cfg.save(SAVE_PATH)


# ------------------------------------------------------------------ input map
func _setup_input_map() -> void:
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("move_up", [KEY_W, KEY_UP])
	_add_keys("move_down", [KEY_S, KEY_DOWN])
	_add_keys("pause", [KEY_ESCAPE, KEY_P])
	_add_keys("mute", [KEY_M])
	_add_keys("restart", [KEY_R])
	_add_keys("start", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE])
	_add_keys("fire", [])
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("fire", click)


func _add_keys(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)
