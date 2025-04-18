extends Node2D

@export var bullet: String
@export var speed: float
@export var acceleration: float
@export_range(0.001, 50) var fire_rate: float
@export_range(-1, 1) var rotate_inc: float

@onready var time_threshold = 1.0 / fire_rate

var time: float
var count: int = 0
var to_fire = true
var offset = randf_range(0,TAU)

func bullet_ring(points: int, _rotation: float = 0):
	for i in range(points):
		var bullet: Bullet = GameController.spawn_bullet(position, bullet)
		
		bullet.velocity = Vector2.UP.rotated((i + count*rotate_inc) * TAU / points + _rotation) * speed
		#bullet.acceleration = Vector2.UP.rotated(randf_range(0, TAU) + offset) * acceleration 
		#bullet.acceleration = Vector2.UP.rotated((i + count*rotate_inc) * TAU / points  + _rotation) * acceleration 
		
		bullet.rotate_to_velocity = true
		bullet.rotation_offset = PI / 2
		
		add_child(bullet)

var c = 0
const buls = 8

func _ready() -> void:
	time = 0
	
func _process(delta: float) -> void:
	time += delta
	
	if time >= time_threshold:
		time -= time_threshold
		
		bullet_ring(buls, c * TAU/buls/6)
		bullet_ring(buls, -(c * TAU/buls/6))
		
		c += 1
		
