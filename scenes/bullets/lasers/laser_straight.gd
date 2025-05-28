class_name Laser
extends Area2D


var start: Vector2
var end: Vector2

var start_delay: float
var duration: float

var radius: float
var color: Color

const LASER_EXPAND_TIME = 0.2

var _radius: float
var _m: float
var _b: float

var _player_ref: Player

@onready var collider: CollisionShape2D = $Hitbox

func _ready() -> void:
	get_tree().create_timer(start_delay).timeout.connect(expand_laser)
	
	_m = (end.y - start.y)/(end.x - start.x)
	_b = start.y - _m*start.x
	_radius = 0
	
	_player_ref = GameController.get_player()

func rotate_laser(angle_rad: float):
	# TODO: Update _m and _b
	pass

func expand_laser():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "_radius", radius, LASER_EXPAND_TIME)
	

func _physics_process(delta: float) -> void:
	if _radius == 0:
		return
	elif in_hitbox(_player_ref.position):
		_player_ref.die()
	

func f(x: float) -> float:
	return _m*x + _b


func in_hitbox(point: Vector2) -> bool:
	return f(point.x) + _radius >= point.y and point.y >= f(point.x) - _radius
