class_name Bullet
extends Area2D

var velocity: Vector2 = Vector2.ZERO
var acceleration: Vector2 = Vector2.ZERO

## If the magnitude of [member Bullet.velocity] would be brought below this, it is instead brought to exactly this.[br]
## This is intended to be used when acceleration is parallel (but possibly reversed from) velocity[br]
## NYI
var min_velocity: float

## If the magnitude of [member Bullet.velocity] would be brought above this, it is instead brought to exactly this.[br]
## This is intended to be used when acceleration is parallel (but possibly reversed from) velocity[br]
## NYI
var max_velocity: float

## Whether the bullet should auto-rotate in the direction of its velocity.
var rotate_to_velocity: bool = true

## Bullet sprite will be rotated by this much relative to the bullet object's rotation.[br]
## Defaults to PI/2 since 0 radians points on the x-axis in Godot.
var rotation_offset: float = PI / 2

## Whether the bullet survives bombs
var strong: bool = false

## If set to true, the bullet will not harm the player
var harmless: bool = false

var type: Level.BulletType

var paint_color: Color = Color.WHITE

func _ready():
	var collider = get_node_or_null("Hitbox") as CollisionShape2D
	
	if not collider:
		print("ERROR: Bullet has no collider!")
	elif not (collision_layer & 0b10):
		print("ERROR: Bullet is not in collision layer 2, so it won't be cleaned when it goes out of bounds!")
	
	rotation = velocity.angle() + rotation_offset

func get_sprite() -> Sprite2D:
	return $Sprite2D

## Implemented in some bullet types. Colours the sprite according to [param color][br]
## By default, does nothing but set [field Bullet.paint_color].
func paint_bullet(color: Color) -> void:
	paint_color = color

func _physics_process(delta: float) -> void:
	velocity += 0.5 * acceleration * delta
	position += velocity * delta
	velocity += 0.5 * acceleration * delta
	
	if rotate_to_velocity:
		rotation = velocity.angle() + rotation_offset
