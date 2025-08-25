class_name LaserStraight
extends Area2D

## Emits when the laser begins to expand
signal laser_expand

var start: Vector2
var end: Vector2

var start_delay: float
var duration: float

var radius: float
var in_color: Color = Color.WHITE
var out_color: Color = Color.TRANSPARENT

const LASER_EXPAND_TIME: float = 0.2
const LASER_WARN_WIDTH: int = 2
const LASER_GRACE_THRESHOLD: int = 2
const LASER_ABSOLUTE_MIN_RADIUS: int = 1

var _laser_started: bool

var _expand_tween: Tween

var _laser_arrow: Vector2
var _grace: float

var _player_ref: Player

@onready var sprite: Sprite2D = $Sprite
@onready var collider: CollisionShape2D = $Hitbox


static func create(start: Vector2, direction: Vector2, length: float, radius: float, warn_time: float, duration: float, out_color: Color=Color.TRANSPARENT, in_color: Color=Color.WHITE) -> LaserStraight:
	var ret = load("res://scenes/bullets/lasers/laser_straight.tscn").instantiate() as LaserStraight
	
	ret.start = start
	ret.end = start + direction.normalized()*length
	ret.in_color = in_color
	ret.out_color = out_color
	ret.duration = duration
	ret.start_delay = warn_time
	ret.radius = radius
	
	return ret
	
static func create_from_points(start: Vector2, end: Vector2, radius: float, warn_time: float, duration: float, out_color: Color=Color.TRANSPARENT, in_color: Color=Color.WHITE) -> LaserStraight:
	var ret = load("res://scenes/bullets/lasers/laser_straight.tscn").instantiate() as LaserStraight
	
	ret.start = start
	ret.end = end
	ret.in_color = in_color
	ret.out_color = out_color
	ret.duration = duration
	ret.start_delay = warn_time
	ret.radius = radius
		
	return ret

func _ready() -> void:
	get_tree().create_timer(start_delay).timeout.connect(expand_laser)
		
	_player_ref = GameController.get_player()
	_laser_arrow = end - start
	_grace = max(5, radius - LASER_ABSOLUTE_MIN_RADIUS)
	_laser_started = false
	
	sprite.texture = GradientTexture1D.new()
	
	var gradient = Gradient.new()
	gradient.set_color(0, out_color)
	gradient.set_color(1, out_color)
	gradient.add_point(0.3, in_color)
	gradient.add_point(0.7, in_color)
	sprite.texture.width = LASER_WARN_WIDTH
	sprite.texture.gradient = gradient
	
	var collider_shape = RectangleShape2D.new()
	collider_shape.size = Vector2(radius, 1)
	collider.shape = collider_shape
	collider.set_deferred("disabled", true)
	
	draw_sprite()

## Rotates the laser to point at direction [param angle_rad].
func rotate_laser(angle_rad: float):
	var direction = Vector2.from_angle(angle_rad)
	var length = _laser_arrow.length()
	
	end = start + direction*length
		
	draw_sprite()
	

## Sets the sprite parameters so that the laser renders properly. 
## Call only when the positions of [member start] or [member end] change.
func draw_sprite():
	var arrow = end - start
	position = start + 0.5*arrow
	rotation = arrow.angle() - PI/2
	scale = Vector2(1, arrow.length())


func expand_laser():
	laser_expand.emit()
	
	_expand_tween = get_tree().create_tween()
	_expand_tween.tween_property(sprite.texture, "width", radius, LASER_EXPAND_TIME)
	# Be forgiving on the player, only enable the collider when at max width in the animation
	_expand_tween.tween_callback(func(): 
		collider.set_deferred("disabled", false)
		_laser_started = true
		)
	_expand_tween.tween_interval(duration)
	_expand_tween.tween_callback(collapse_laser)

func collapse_laser():
	collider.set_deferred("disabled", true)
	
	var tw = get_tree().create_tween()
	tw.tween_property(sprite.texture, "width", 1, LASER_EXPAND_TIME)
	tw.tween_callback(queue_free)
