class_name WaveDirector
extends Node
## Builds each wave from a point budget, introduces one new enemy type at a
## time, and spawns enemies through telegraphed markers away from the player.

signal wave_started(wave: int, intro: String)
signal wave_cleared(wave: int)

enum Phase { IDLE, BREAK, SPAWNING, FIGHTING }

const SpawnMarkerScene := preload("res://scenes/fx/spawn_marker.tscn")

## type -> [scene, cost, first wave, spawn weight, colour, intro text]
const ENEMY_TYPES := {
	"chaser": [preload("res://scenes/enemies/chaser.tscn"), 1, 1, 6.0, Color(1.0, 0.25, 0.65), ""],
	"dasher": [preload("res://scenes/enemies/dasher.tscn"), 2, 2, 3.0, Color(1.0, 0.85, 0.2), "DASHERS: watch for the aim line"],
	"shooter": [preload("res://scenes/enemies/shooter.tscn"), 3, 3, 2.0, Color(0.3, 1.0, 0.5), "SHOOTERS: dodge the red shots"],
	"splitter": [preload("res://scenes/enemies/splitter.tscn"), 3, 4, 2.0, Color(1.0, 0.5, 0.15), "SPLITTERS: they burst into minis"],
}
const BREAK_TIME := 2.6
const MIN_SPAWN_DIST := 280.0

var wave := 0
var _phase := Phase.IDLE
var _timer := 0.0
var _queue: Array[String] = []
var _interval := 1.0


func start() -> void:
	wave = 0
	_queue.clear()
	_phase = Phase.BREAK
	_timer = 1.2


func stop() -> void:
	_phase = Phase.IDLE
	_queue.clear()


func _physics_process(delta: float) -> void:
	match _phase:
		Phase.BREAK:
			_timer -= delta
			if _timer <= 0.0:
				_begin_wave(wave + 1)
		Phase.SPAWNING:
			_timer -= delta
			if _timer <= 0.0:
				_spawn_group()
				_timer = _interval
			if _queue.is_empty():
				_phase = Phase.FIGHTING
		Phase.FIGHTING:
			if get_tree().get_nodes_in_group("enemies").is_empty() \
					and get_tree().get_nodes_in_group("spawn_markers").is_empty():
				wave_cleared.emit(wave)
				_phase = Phase.BREAK
				_timer = BREAK_TIME


func _begin_wave(n: int) -> void:
	wave = n
	GameState.set_wave(n)
	_queue = _build_wave(n)
	_interval = maxf(0.28, 1.1 - n * 0.07)
	_timer = 0.3
	_phase = Phase.SPAWNING
	var intro := ""
	for type in ENEMY_TYPES:
		if ENEMY_TYPES[type][2] == n:
			intro = ENEMY_TYPES[type][5]
	wave_started.emit(n, intro)


## Returns a shuffled list of enemy type names whose cost fits the wave budget.
func _build_wave(n: int) -> Array[String]:
	var budget := 5 + int(n * 3.2)
	var result: Array[String] = []
	# A freshly introduced type always appears a few times so the player learns it.
	for type in ENEMY_TYPES:
		if ENEMY_TYPES[type][2] == n and n > 1:
			for i in 2:
				result.append(type)
				budget -= ENEMY_TYPES[type][1]
	var unlocked: Array = ENEMY_TYPES.keys().filter(func(t): return ENEMY_TYPES[t][2] <= n)
	while budget > 0:
		var type := _weighted_pick(unlocked)
		result.append(type)
		budget -= ENEMY_TYPES[type][1]
	result.shuffle()
	return result


func _weighted_pick(types: Array) -> String:
	var total := 0.0
	for t in types:
		total += ENEMY_TYPES[t][3]
	var roll := randf() * total
	for t in types:
		roll -= ENEMY_TYPES[t][3]
		if roll <= 0.0:
			return t
	return types[0]


func _spawn_group() -> void:
	var count := mini(_queue.size(), 1 + randi() % (2 + wave / 3))
	var anchor := _spawn_point()
	for i in count:
		var type: String = _queue.pop_back()
		var data: Array = ENEMY_TYPES[type]
		var pos := Arena.clamp_point(anchor + Vector2(randf_range(-60, 60), randf_range(-60, 60)), 40.0)
		Events.spawn(SpawnMarkerScene.instantiate().setup(pos, data[0], data[4]))
	Audio.play("spawn", -10.0)


func _spawn_point() -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var best := Arena.random_point(60.0)
	for attempt in 12:
		var p := Arena.random_point(60.0)
		if player == null or p.distance_to(player.global_position) >= MIN_SPAWN_DIST:
			return p
		best = p
	return best
