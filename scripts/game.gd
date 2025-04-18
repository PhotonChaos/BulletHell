class_name GameController
extends Node2D

# Collision Layers:
#  1. Player rigidbody
#  2. Bullets
#  3. Player shot, enemies


@onready var bullet_sfx = $BulletSoundPlayer as AudioStreamPlayer2D

var play_sfx: bool = false
var sfx_cooldown: float = 0

const DEFAULT_BULLET_TYPE = "ball"

# Screw it, I'm just gonna hardcode this.
static var bullet_library: Dictionary = {
	"ball": preload('res://scenes/bullets/bullet.tscn'),
	"knife": preload('res://scenes/bullets/bullet_knife.tscn'),
	"small_ball": preload('res://scenes/bullets/bullet_small.tscn')
}


## Static functions
static func get_bullet_template(name: String) -> PackedScene:
	if not (name in bullet_library):
		print_rich("[color=yellow]Warning:[/color] Unknown bullet name '"+name+"'")
		name = DEFAULT_BULLET_TYPE
		
	return bullet_library[name]


## Spawns a bullet of [param type] at [param position] with properties [param args].[br]
## Returns a reference to the new bullet.
static func spawn_bullet(position: Vector2, type: String, args: BulletStats=null) -> Bullet:
	# TODO: Make this work with object pooling
	var bullet: Bullet = get_bullet_template(type).instantiate()
	
	bullet.init(args)
	
	return bullet


## Spawns a shotgun-burst containing [param count] bullets of [param type], 
## spread evenly across an arc of [param spread]. [br]
## The arc is centred on a vector rotated by [param rotation], and the 
## bullets spawn [param distance] away from [param position] along the aim vector.[br]
## The bullets will have a velocity of [param v] in the direction they are facing, with acceleration [param a].
## Returns an array containing the bullets, ordered from lowest angle aim vector to highest.
static func spawn_burst(position: Vector2, type: String, count: int, spread: float, rotation: float, dist: float, v: float, a: float) -> Array[Bullet]:
	var bullets: Array[Bullet] = []
	var angle_gap = spread / count
	var start_angle = rotation - spread / 2
	
	for i in range(count):
		var bullet_dir = start_angle + angle_gap * i
		var point_dir = Vector2.from_angle(bullet_dir)
		
		var bullet: Bullet = spawn_bullet(position + point_dir * dist, type)
		
		bullet.rotation = bullet_dir
		bullet.velocity = point_dir * v
		bullet.acceleration = point_dir * a
		
		bullets.append(bullet)
		
	return bullets


static func spawn_ring(position: Vector2, type: String, count: int, rotation: float=0, dist: float=0, v: float=0, a: float=0) -> Array[Bullet]:
	return spawn_burst(position, type, count, TAU, rotation, rotation, v, a)


func _process(delta: float) -> void:
	if sfx_cooldown <= 0 and play_sfx:
		play_sfx = false
		sfx_cooldown = 0.1
		
		bullet_sfx.play()
	else:
		sfx_cooldown = max(0, sfx_cooldown - delta)


## Signals
func _on_bullet_bounds_area_entered(area: Area2D) -> void:
	# Triggers when a bullet is spawned
	if area is Bullet:
		play_sfx = true


func _on_bullet_bounds_area_exited(area: Area2D) -> void:
	# Triggers whenever a bullet exits the area
	area.queue_free()  # Only bullets should be on layer 2
