class_name BBG extends Node

var _bullets: Array[Bullet] = []

## A funtction of the form func(bullet: Bullet, delta: Float) -> void. [br]
## It should act as one physics step on the bullet.
var physics_func: Callable

func _physics_process(delta: float) -> void:
	var pruned = []

	for i in len(_bullets):
		if is_instance_valid(_bullets[i]):
			physics_func.call(_bullets[i], delta)
		else:
			pruned.append(i)
	
	if len(pruned) > 0:
		pruned.reverse()
		for i in pruned:
			_bullets.remove_at(i)

func add_bullet(bullet: Bullet) -> void:
	_bullets.append(bullet)

func add_bullets(bullets: Array) -> void:
	_bullets.append_array(bullets)

## Clears the refernece list. Does not alter any other objects
func clear() -> void:
	_bullets.clear()
	
# Some useful defaults

## A callable you can use for [member physics_func] for the normal bullet movement.
static func normal_movement(bullet: Bullet, delta: float) -> void:
	bullet.velocity += 0.5 * bullet.acceleration * delta
	bullet.position += bullet.velocity * delta
	bullet.velocity += 0.5 * bullet.acceleration * delta
	
	if bullet.rotate_to_velocity:
		bullet.rotation = bullet.velocity.angle() + bullet.rotation_offset
