class_name Bullet
extends Area2D

var velocity: Vector2 = Vector2.ZERO
var acceleration: Vector2 = Vector2.ZERO

## Whether the bullet should auto-rotate in the direction of its velocity.
var rotate_to_velocity: bool = true

## Bullet sprite will be rotated by this much relative to the bullet object's rotation.[br]
## Defaults to PI/2 since 0 radians points on the x-axis in Godot.
var rotation_offset: float = PI / 2

func _ready():
	var collider = get_node_or_null("Hitbox") as CollisionShape2D
	
	if not collider:
		print("ERROR: Bullet has no collider!")
	elif not (collision_layer & 0b10):
		print("ERROR: Bullet is not in collision layer 2, so it won't be cleaned when it goes out of bounds!")
	
	rotation = velocity.angle() + rotation_offset

## Initializes the bullet with the given template. 
## Null fields of the template are ignored.
func init(template: BulletStats = null) -> void:
	if template:
		velocity = template.velocity
		acceleration = template.acceleration

func _physics_process(delta: float) -> void:
	velocity += 0.5 * acceleration * delta
	position += velocity * delta
	velocity += 0.5 * acceleration * delta
	
	if rotate_to_velocity:
		rotation = velocity.angle() + rotation_offset
