extends Node2D
## Root of the game: owns the state machine (title -> playing <-> paused ->
## game over), wires gameplay signals to the HUD and spawns world effects.

enum State { TITLE, PLAYING, PAUSED, GAME_OVER }

const PlayerScene := preload("res://scenes/player.tscn")
const ExplosionScene := preload("res://scenes/fx/explosion.tscn")
const PickupScene := preload("res://scenes/pickup.tscn")

const DROP_CHANCE := 0.09
const GAME_OVER_INPUT_DELAY := 1.0

var state := State.TITLE
var player: Player
var _state_time := 0.0

@onready var _entities: Node2D = $World/Entities
@onready var _effects: Node2D = $World/Effects
@onready var _director: WaveDirector = $World/WaveDirector
@onready var _post: ShaderMaterial = $PostFX/Screen.material
@onready var _ui: GameUI = $UI


func _ready() -> void:
	randomize()
	Events.spawn_requested.connect(_on_spawn_requested)
	Events.explosion_requested.connect(_on_explosion_requested)
	Events.popup_requested.connect(_on_popup_requested)
	Events.enemy_killed.connect(_on_enemy_killed)
	Events.player_damaged.connect(_on_player_damaged)
	_director.wave_started.connect(_on_wave_started)
	_director.wave_cleared.connect(_on_wave_cleared)
	_ui.pause_pressed.connect(_toggle_pause)
	_ui.show_title()


func _process(delta: float) -> void:
	_state_time += delta


func _unhandled_input(event: InputEvent) -> void:
	match state:
		State.TITLE:
			if _is_confirm(event):
				start_game()
		State.PLAYING:
			if event.is_action_pressed("pause"):
				_toggle_pause()
		State.PAUSED:
			if event.is_action_pressed("pause") or _is_confirm(event):
				_toggle_pause()
			elif event.is_action_pressed("restart"):
				start_game()
		State.GAME_OVER:
			if _state_time < GAME_OVER_INPUT_DELAY:
				return
			if _is_confirm(event) or event.is_action_pressed("restart"):
				start_game()
			elif event.is_action_pressed("pause"):
				_go_to_title()


func _notification(what: int) -> void:
	# Auto-pause when the tab/window loses focus.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if state == State.PLAYING:
			_toggle_pause()


# ------------------------------------------------------------------ flow
func start_game() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	_clear_world()
	GameState.reset_run()
	player = PlayerScene.instantiate()
	player.position = Arena.RECT.get_center()
	player.health_changed.connect(_ui.set_health)
	player.rapid_fire_changed.connect(_ui.set_rapid_fire)
	player.died.connect(_on_player_died)
	_entities.add_child(player)
	_director.start()
	_set_state(State.PLAYING)
	_ui.show_hud()
	Audio.play("ui")
	Audio.start_music()


func _toggle_pause() -> void:
	if state == State.PLAYING:
		get_tree().paused = true
		_set_state(State.PAUSED)
		_ui.show_pause()
	elif state == State.PAUSED:
		get_tree().paused = false
		_set_state(State.PLAYING)
		_ui.hide_pause()
	Audio.play("ui", -6.0)


func _go_to_title() -> void:
	_director.stop()
	_clear_world()
	_set_state(State.TITLE)
	_ui.show_title()


func _on_player_died() -> void:
	_director.stop()
	var new_best := GameState.finish_run()
	_set_state(State.GAME_OVER)
	# Brief slow motion for drama, then the results screen.
	Engine.time_scale = 0.35
	await get_tree().create_timer(0.9, true, false, true).timeout
	Engine.time_scale = 1.0
	if state == State.GAME_OVER:
		_ui.show_game_over(GameState.score, GameState.best_score, GameState.wave, new_best)


func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0


func _clear_world() -> void:
	for container in [_entities, _effects]:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
	player = null


func _is_confirm(event: InputEvent) -> bool:
	if event.is_action_pressed("start"):
		return true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		return true
	return event is InputEventScreenTouch and event.pressed


# ------------------------------------------------------------------ gameplay events
func _on_spawn_requested(node: Node2D) -> void:
	# Deferred: spawns often happen inside physics callbacks.
	_entities.add_child.call_deferred(node)


func _on_explosion_requested(pos: Vector2, color: Color, size: float) -> void:
	_effects.add_child(ExplosionScene.instantiate().setup(pos, color, size))


func _on_popup_requested(pos: Vector2, text: String, color: Color) -> void:
	_effects.add_child(PopupText.new().setup(pos, text, color, 18))


func _on_enemy_killed(enemy: Node2D) -> void:
	if state != State.PLAYING:
		return
	var e := enemy as Enemy
	var awarded := GameState.register_kill(e.points)
	var size := 16 + mini(GameState.multiplier() * 2, 14)
	_effects.add_child(PopupText.new().setup(e.global_position, str(awarded), e.color, size))
	_maybe_drop_pickup(e.global_position)


func _maybe_drop_pickup(pos: Vector2) -> void:
	if player == null:
		return
	var chance := DROP_CHANCE + (0.06 if player.hp <= 2 else 0.0)
	if randf() > chance:
		return
	var kind := Pickup.Kind.RAPID_FIRE
	if player.hp < Player.MAX_HP and randf() < (0.75 if player.hp <= 2 else 0.45):
		kind = Pickup.Kind.HEALTH
	_on_spawn_requested(PickupScene.instantiate().setup(pos, kind))


func _on_player_damaged() -> void:
	_post.set_shader_parameter("flash", 1.0)
	create_tween().tween_method(func(v): _post.set_shader_parameter("flash", v), 1.0, 0.0, 0.45)


func _on_wave_started(wave: int, intro: String) -> void:
	_ui.banner("WAVE %d" % wave, intro)
	Audio.play("wave")


func _on_wave_cleared(_wave: int) -> void:
	_ui.banner("WAVE CLEAR", "+%d BONUS" % (_wave * 250))
	GameState.score += _wave * 250
	GameState.score_changed.emit(GameState.score)


## Snapshot for the web playtest bridge.
func debug_state() -> Dictionary:
	return {
		"state": State.keys()[state],
		"score": GameState.score,
		"best": GameState.best_score,
		"wave": GameState.wave,
		"multiplier": GameState.multiplier(),
		"hp": player.hp if player else 0,
		"player": [player.position.x, player.position.y] if player else [],
		"enemies": get_tree().get_nodes_in_group("enemies").size(),
		"paused": get_tree().paused,
		"muted": GameState.muted,
		"fps": Engine.get_frames_per_second(),
	}
