class_name Bullet
extends Area2D
## Projectile for both the player and enemies. Moves in a straight line.

const PLAYER_COLOR := Color(0.3, 0.95, 1.0)
const ENEMY_COLOR := Color(1.0, 0.35, 0.3)

var velocity := Vector2.ZERO
var damage := 1
var from_player := true
var radius := 4.0
var life := 1.6
var _spent := false


## Must be called before the bullet enters the tree.
func setup(pos: Vector2, vel: Vector2, is_player: bool) -> Bullet:
	position = pos
	velocity = vel
	from_player = is_player
	rotation = vel.angle()
	if not is_player:
		radius = 6.0
		life = 4.0
	return self


func _ready() -> void:
	collision_layer = Arena.LAYER_PLAYER_BULLET if from_player else Arena.LAYER_ENEMY_BULLET
	collision_mask = Arena.LAYER_ENEMY if from_player else Arena.LAYER_PLAYER
	var shape := CircleShape2D.new()
	shape.radius = radius + (2.0 if from_player else 0.0)
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if life <= 0.0 or not Arena.RECT.has_point(position):
		if not Arena.RECT.has_point(position):
			Events.explode(Arena.clamp_point(position, 1.0), _color(), 0.25)
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _spent:
		return
	if from_player and area is Enemy:
		_spent = true
		area.hit(damage, velocity.normalized())
		queue_free()
	elif not from_player and area is Player:
		_spent = true
		area.take_damage(1, global_position)
		queue_free()


func _color() -> Color:
	return PLAYER_COLOR if from_player else ENEMY_COLOR


func _draw() -> void:
	var c := _color()
	if from_player:
		Neon.line(self, Vector2(-14, 0), Vector2(4, 0), c, 3.0)
	else:
		var pulse := 1.0 + 0.2 * sin(life * 20.0)
		Neon.dot(self, Vector2.ZERO, radius * pulse, c)
