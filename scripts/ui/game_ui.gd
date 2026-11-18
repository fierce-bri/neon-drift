class_name GameUI
extends CanvasLayer
## All menus and the HUD. Screens are built in code from small helpers so the
## styling (font sizes, glow colours, outlines) stays consistent in one place.

signal pause_pressed

const CYAN := Color(0.25, 0.95, 1.0)
const PINK := Color(1.0, 0.3, 0.75)
const YELLOW := Color(1.0, 0.85, 0.25)
const DIM := Color(0.75, 0.75, 0.9)
const TITLE_FONT := preload("res://assets/fonts/Orbitron.ttf")
const HealthPips := preload("res://scripts/ui/health_pips.gd")
const TouchControls := preload("res://scripts/ui/touch_controls.gd")

var _hud: Control
var _title: Control
var _pause: Control
var _game_over: Control
var _score_label: Label
var _mult_label: Label
var _combo_bar: ColorRect
var _wave_label: Label
var _best_label: Label
var _rapid_label: Label
var _mute_label: Label
var _banner: Label
var _banner_sub: Label
var _health: Control
var _pause_button: Button
var _title_best: Label
var _start_hint: Label
var _go_score: Label
var _go_best: Label
var _go_new_best: Label
var _go_wave: Label
var _bold: FontVariation


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bold = FontVariation.new()
	_bold.base_font = TITLE_FONT
	_bold.variation_embolden = 0.9
	_build_hud()
	_build_title()
	_build_pause()
	_build_game_over()
	add_child(TouchControls.new())
	GameState.score_changed.connect(_on_score_changed)
	GameState.combo_changed.connect(_on_combo_changed)
	GameState.wave_changed.connect(func(w): _wave_label.text = "WAVE %d" % w)
	Audio.mute_changed.connect(_on_mute_changed)
	_on_mute_changed(GameState.muted)


func _process(_delta: float) -> void:
	if _hud.visible:
		_combo_bar.scale.x = GameState.combo_fraction()
		_pause_button.visible = GameState.touch_active


# ------------------------------------------------------------------ public API
func show_title() -> void:
	_show_only(_title)
	_title_best.text = "BEST  %s" % _fmt(GameState.best_score)
	_title_best.visible = GameState.best_score > 0


func show_hud() -> void:
	_show_only(_hud)
	_best_label.text = "BEST %s" % _fmt(GameState.best_score)
	_rapid_label.visible = false


func show_pause() -> void:
	_pause.visible = true
	_pop_in(_pause)


func hide_pause() -> void:
	_pause.visible = false


func show_game_over(score: int, best: int, wave: int, new_best: bool) -> void:
	_game_over.visible = true
	_go_score.text = _fmt(score)
	_go_best.text = "BEST  %s" % _fmt(best)
	_go_wave.text = "REACHED WAVE %d  ·  %d KILLS" % [wave, GameState.kills]
	_go_new_best.visible = new_best
	_pop_in(_game_over)
	if new_best:
		var tw := create_tween().set_loops(6)
		tw.tween_property(_go_new_best, "modulate", Color(1, 1, 1, 0.4), 0.25)
		tw.tween_property(_go_new_best, "modulate", Color.WHITE, 0.25)


func banner(text: String, sub: String = "") -> void:
	_banner.text = text
	_banner_sub.text = sub
	for l in [_banner, _banner_sub]:
		l.modulate = Color(1, 1, 1, 0)
		l.scale = Vector2(1.6, 1.6)
		var tw := create_tween()
		tw.tween_property(l, "modulate:a", 1.0, 0.2)
		tw.parallel().tween_property(l, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(1.4)
		tw.tween_property(l, "modulate:a", 0.0, 0.4)


func set_health(hp: int, max_hp: int) -> void:
	_health.set_health(hp, max_hp)


func set_rapid_fire(time_left: float) -> void:
	_rapid_label.visible = time_left > 0.0
	_rapid_label.text = "RAPID FIRE  %.1fs" % time_left


# ------------------------------------------------------------------ screens
func _build_hud() -> void:
	_hud = _screen()
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 28
	top.offset_right = -28
	top.offset_top = 16
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(top)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 2)
	top.add_child(left)
	_score_label = _label("0", 34, Color.WHITE, true)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	left.add_child(_score_label)
	var mult_row := HBoxContainer.new()
	mult_row.add_theme_constant_override("separation", 10)
	left.add_child(mult_row)
	_mult_label = _label("x1", 20, YELLOW, true)
	mult_row.add_child(_mult_label)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(1, 1, 1, 0.12)
	bar_bg.custom_minimum_size = Vector2(120, 6)
	bar_bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mult_row.add_child(bar_bg)
	_combo_bar = ColorRect.new()
	_combo_bar.color = YELLOW
	_combo_bar.size = Vector2(120, 6)
	bar_bg.add_child(_combo_bar)

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.alignment = BoxContainer.ALIGNMENT_BEGIN
	top.add_child(center)
	_wave_label = _label("WAVE 1", 22, CYAN, true)
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_wave_label)
	_health = HealthPips.new()
	_health.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(_health)
	_rapid_label = _label("", 15, YELLOW)
	_rapid_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_rapid_label)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(right)
	_best_label = _label("BEST 0", 16, DIM)
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(_best_label)

	_banner = _label("", 64, CYAN, true)
	_banner_sub = _label("", 20, Color.WHITE)
	for l in [_banner, _banner_sub]:
		l.set_anchors_preset(Control.PRESET_CENTER)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size = Vector2(1000, 90)
		l.position = Vector2(-500, -150 if l == _banner else -70)
		l.pivot_offset = Vector2(500, 45)
		l.modulate.a = 0.0
		_hud.add_child(l)

	_pause_button = Button.new()
	_pause_button.text = "II"
	_pause_button.flat = false
	_pause_button.add_theme_font_size_override("font_size", 26)
	_pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_pause_button.position = Vector2(-90, 70)
	_pause_button.size = Vector2(64, 56)
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.pressed.connect(func(): pause_pressed.emit())
	_hud.add_child(_pause_button)

	_mute_label = _label("SOUND OFF  [M]", 14, DIM)
	_mute_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_mute_label.position = Vector2(-200, -36)
	add_child(_mute_label)


func _build_title() -> void:
	_title = _screen(0.35)
	var box := _center_box(_title)
	var title := _label("NEON DRIFT", 92, CYAN, true)
	title.add_theme_color_override("font_shadow_color", Color(PINK, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)
	box.add_child(title)
	title.pivot_offset = Vector2(400, 50)
	var tw := create_tween().set_loops()
	tw.tween_property(title, "modulate", Color(1.15, 1.15, 1.15), 1.1).set_trans(Tween.TRANS_SINE)
	tw.tween_property(title, "modulate", Color(0.85, 0.85, 0.95), 1.1).set_trans(Tween.TRANS_SINE)
	box.add_child(_label("ARENA SURVIVAL SHOOTER", 20, PINK))
	box.add_child(_spacer(26))
	box.add_child(_label("MOVE   WASD / ARROWS", 17, Color.WHITE))
	box.add_child(_label("AIM + SHOOT   MOUSE (HOLD CLICK)", 17, Color.WHITE))
	box.add_child(_label("PAUSE  ESC / P     MUTE  M", 17, Color.WHITE))
	box.add_child(_label("TOUCH: LEFT THUMB MOVES, RIGHT THUMB AIMS + FIRES", 13, DIM))
	box.add_child(_spacer(16))
	box.add_child(_label("Chain kills to raise your multiplier. Getting hit resets it.", 14, DIM))
	box.add_child(_spacer(26))
	_start_hint = _label("CLICK OR PRESS ENTER TO START", 24, YELLOW, true)
	box.add_child(_start_hint)
	var blink := create_tween().set_loops()
	blink.tween_property(_start_hint, "modulate:a", 0.35, 0.6)
	blink.tween_property(_start_hint, "modulate:a", 1.0, 0.6)
	box.add_child(_spacer(10))
	_title_best = _label("", 18, DIM)
	box.add_child(_title_best)

	var credit := _label("Made by Aphiwe Mzulwini", 16, Color(1, 1, 1, 0.85))
	credit.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credit.size = Vector2(600, 30)
	credit.position = Vector2(-300, -64)
	_title.add_child(credit)


func _build_pause() -> void:
	_pause = _screen(0.6)
	var box := _center_box(_pause)
	box.add_child(_label("PAUSED", 72, CYAN, true))
	box.add_child(_spacer(18))
	box.add_child(_label("ESC / P  OR CLICK TO RESUME", 20, Color.WHITE))
	box.add_child(_label("R  TO RESTART     M  TO MUTE", 18, DIM))


func _build_game_over() -> void:
	_game_over = _screen(0.55)
	var box := _center_box(_game_over)
	box.add_child(_label("GAME OVER", 76, PINK, true))
	box.add_child(_spacer(8))
	_go_score = _label("0", 56, Color.WHITE, true)
	box.add_child(_go_score)
	_go_new_best = _label("NEW BEST!", 26, YELLOW, true)
	box.add_child(_go_new_best)
	_go_best = _label("", 20, DIM)
	box.add_child(_go_best)
	_go_wave = _label("", 18, CYAN)
	box.add_child(_go_wave)
	box.add_child(_spacer(24))
	box.add_child(_label("CLICK OR PRESS ENTER TO PLAY AGAIN", 22, YELLOW, true))
	box.add_child(_label("ESC FOR TITLE", 16, DIM))


# ------------------------------------------------------------------ helpers
func _screen(dim: float = 0.0) -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if dim > 0.0:
		var bg := ColorRect.new()
		bg.color = Color(0.02, 0.0, 0.06, dim)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(bg)
	c.visible = false
	add_child(c)
	return c


func _center_box(parent: Control) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(box)
	return box


func _label(text: String, font_size: int, color: Color, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.0, 0.08, 0.85))
	l.add_theme_constant_override("outline_size", maxi(4, font_size / 7))
	if bold:
		l.add_theme_font_override("font", _bold)
	return l


func _spacer(h: float) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


func _show_only(screen: Control) -> void:
	for s in [_hud, _title, _pause, _game_over]:
		s.visible = s == screen
	_pop_in(screen)


func _pop_in(screen: Control) -> void:
	screen.modulate.a = 0.0
	create_tween().tween_property(screen, "modulate:a", 1.0, 0.25)


func _fmt(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out


func _on_score_changed(score: int) -> void:
	_score_label.text = _fmt(score)
	_score_label.pivot_offset = Vector2(0, _score_label.size.y / 2.0)
	_score_label.scale = Vector2(1.15, 1.15)
	create_tween().tween_property(_score_label, "scale", Vector2.ONE, 0.15)


func _on_combo_changed(mult: int) -> void:
	_mult_label.text = "x%d" % mult
	_mult_label.pivot_offset = _mult_label.size / 2.0
	_mult_label.scale = Vector2(1.6, 1.6)
	create_tween().tween_property(_mult_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_mult_label.add_theme_color_override("font_color", YELLOW.lerp(PINK, (mult - 1) / 7.0))


func _on_mute_changed(muted: bool) -> void:
	_mute_label.visible = muted
