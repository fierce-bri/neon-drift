extends Node
## Global signal bus. Gameplay objects emit here so they never need direct
## references to the main scene, the camera or the effects layer.

## Ask the main scene to add a node (bullet, enemy, effect) to the world.
signal spawn_requested(node: Node2D)
## Screen shake request, 0..1 trauma.
signal shake_requested(amount: float)
## Particle burst + shockwave at a position.
signal explosion_requested(position: Vector2, color: Color, size: float)
## Floating text in the world (score popups, pickup names).
signal popup_requested(position: Vector2, text: String, color: Color)
## An enemy died (emitted before it is freed).
signal enemy_killed(enemy: Node2D)
## The player took damage.
signal player_damaged


func spawn(node: Node2D) -> void:
	spawn_requested.emit(node)


func shake(amount: float) -> void:
	shake_requested.emit(amount)


func explode(position: Vector2, color: Color, size: float = 1.0) -> void:
	explosion_requested.emit(position, color, size)


func popup(position: Vector2, text: String, color: Color = Color.WHITE) -> void:
	popup_requested.emit(position, text, color)
