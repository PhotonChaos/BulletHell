class_name GameController
extends Node2D

# Collision Layers:
#  1. Player rigidbody
#  2. Bullets, enemies
#  3. Player shots
#  4. Powerups

# Sprite Layers (lower is further back):
#  -3. Bomb Sprite
#  -2. Player Shots
#  -1. Player Sprite
#   0. Default
#   5. Enemy Bullets
#  10. Player Hitbox

# TODO list
#  - Add a level system
#    - Make bullets a child of the Level node
#    - Level node is abstract, levels are subclasses of the base Level node
#    - Level base class has all the bullet spawn/clear methods
#    - Level base class has enemy spawning methods + dialogue starting methods

@onready var bullet_sfx = $BulletSoundPlayer as AudioStreamPlayer2D
@onready var enemy_death_sfx = $EnemyDeathSoundPlayer as AudioStreamPlayer2D
@onready var main_ui = $UILayer/GameplayUI as GameplayUI

@onready var enemy_template: PackedScene = preload("res://scenes/enemy/enemy.tscn")
@onready var item_template: PackedScene = preload("res://scenes/pickup/item.tscn")

static var _game_instance: GameController = null
static var _player_reference: Player = null

var play_sfx: bool = false
var sfx_cooldown: float = 0

var enemy_cooldown: float = 0

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
static func spawn_bullet(_position: Vector2, type: String, args: BulletStats=null) -> Bullet:
	# TODO: Make this work with object pooling
	var bullet: Bullet = get_bullet_template(type).instantiate()
	
	bullet.position = _position
	bullet.init(args)
	
	return bullet


## Spawns a shotgun-burst containing [param count] bullets of [param type], 
## spread evenly across an arc of [param spread]. [br]
## The arc is centred on a vector rotated by [param rotation], and the 
## bullets spawn [param distance] away from [param position] along the aim vector.[br]
## The bullets will have a velocity of [param v] in the direction they are facing, with acceleration [param a].[br]
## Also, the bullets will be added as children of the game controller.
## Returns an array containing the bullets, ordered from lowest angle aim vector to highest.
static func spawn_burst(_position: Vector2, type: String, count: int, spread: float, rotation: float, dist: float, v: float, a: float) -> Array[Bullet]:
	var bullets: Array[Bullet] = []
	var angle_gap = spread / count
	var start_angle = rotation - spread / 2
	
	for i in range(count):
		var bullet_dir = start_angle + angle_gap * i
		var point_dir = Vector2.from_angle(bullet_dir)
		
		var bullet: Bullet = spawn_bullet(_position + point_dir * dist, type)
		
		bullet.rotation = bullet_dir
		bullet.velocity = point_dir * v
		bullet.acceleration = point_dir * a
		
		bullets.append(bullet)
	
	_game_instance.play_sfx = true
	
	for bullet in bullets:
		_game_instance.add_child(bullet)
	
	return bullets


static func spawn_ring(_position: Vector2, type: String, count: int, _rotation: float=0, dist: float=0, v: float=0, a: float=0) -> Array[Bullet]:
	return spawn_burst(_position, type, count, TAU, _rotation, dist, v, a)


static func spawn_item(_position: Vector2, type: Item.ItemType) -> Item:
	var item: Item = _game_instance.item_template.instantiate()
	
	item.position = _position
	item.item_type = type
	_game_instance.add_child(item)
	
	return item

## Returns the position of the player.[br]
## If there is more than one player object in the group, returns the first one.
static func get_player_pos() -> Vector2:
	if not _game_instance:
		return Vector2.ZERO
		
	if _player_reference == null:
		_player_reference = _game_instance.get_tree().get_first_node_in_group('player')
	
	return _player_reference.position


## SFX Methods
static func play_enemy_death_sfx():
	_game_instance.enemy_death_sfx.stop()
	_game_instance.enemy_death_sfx.play()


static func clear_bullet(bullet: Bullet, spawn_point: bool) -> void:
	if spawn_point:
		spawn_item(bullet.global_position, Item.ItemType.SMALL_POINT).magnet_player = true
	
	bullet.queue_free()

## Turns all bullets onscreen into points. [br]
## If [param hard_clear] is set to true, also clears strong bullets (ones which survive bombs)
static func clear_all_bullets(hard_clear=false):
	var bullets: Array = _game_instance.get_tree().get_nodes_in_group("enemy_bullets")
	
	for bullet: Bullet in bullets:
		clear_bullet(bullet, true)
	
	
func spawn_enemies():
	var enemy = enemy_template.instantiate()
	var posx = randf_range(100, 360)
	
	enemy.position = Vector2(posx, -60)
	enemy.destination = Vector2(posx, randf_range(130, 200))
	enemy.target_dest = true
	enemy.tick_duration = randf_range(0.1, 0.4)
	
	var enemy_shots = randi_range(3, 6)
	
	enemy.tick_func = func (age: float, _position: Vector2):
		GameController.spawn_ring(_position, "small_ball", enemy_shots, age * PI/15, 5, 40, 20)
	
	add_child(enemy)



func _ready() -> void:
	_game_instance = self
	var player: Player = get_tree().get_first_node_in_group('player')
	player.emit_stats()

func _process(delta: float) -> void:
	sfx_cooldown = max(0, sfx_cooldown - delta)
	enemy_cooldown = max(0, enemy_cooldown - delta)
	
	if sfx_cooldown <= 0 and play_sfx:
		play_sfx = false
		sfx_cooldown = 0.1
		
		bullet_sfx.play()
		
	if enemy_cooldown <= 0:
		enemy_cooldown = 0.4
		spawn_enemies()


func _on_bullet_bounds_area_exited(area: Area2D) -> void:
	# Triggers whenever a bullet exits the area
	area.queue_free()  # Only bullets and enemies should be on layer 2


func _on_player_bombs_changed(old: int, new: int) -> void:
	main_ui.set_bombs(new)
	# TODO: Sound Effect


func _on_player_lives_changed(old: int, new: int) -> void:
	main_ui.set_lives(new)
	# TODO: Sound Effect 
