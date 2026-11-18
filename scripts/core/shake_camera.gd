class_name ShakeCamera
extends Camera2D
## Trauma-based screen shake (offset + slight roll driven by smooth noise).

@export var max_offset := Vector2(22, 16)
@export var max_roll := 0.025
@export var decay := 1.8

var trauma := 0.0
var _noise := FastNoiseLite.new()
var _t := 0.0


func _ready() -> void:
	_noise.frequency = 0.08
	ignore_rotation = false
	Events.shake_requested.connect(add_trauma)


func add_trauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)


func _process(delta: float) -> void:
	_t += delta * 60.0
	trauma = maxf(trauma - decay * delta, 0.0)
	var s := trauma * trauma
	offset = Vector2(
		max_offset.x * s * _noise.get_noise_2d(11.0, _t) * 2.0,
		max_offset.y * s * _noise.get_noise_2d(37.0, _t) * 2.0)
	rotation = max_roll * s * _noise.get_noise_2d(73.0, _t) * 2.0
