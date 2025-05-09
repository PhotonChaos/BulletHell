class_name Level
extends Node2D
## This is supposed to be an abstract class, so don't add nodes of this base type!
## Subclass from this! The [method Level._play()] function gets called 

signal level_loaded
signal level_finished

# For SFX
# TODO: Figure out where to handle this
signal bullet_fired

signal boss_spawned
signal boss_defeated
signal spell_started(name: String, boss_name: String)
signal spell_time_updated(new: float)
signal spell_hp_updated(max: int, old: int, new: int)


enum BulletType {
	BALL = 0,
	SMALL_BALL,
	KNIFE
}

@export var title: String
@export var subtitle: String
@export var level_id: String

# TODO: Implement object pooling
# ## Unused at the moment.
#@export var bullet_pools: Dictionary[Level.BulletType, int]

var _enemy_template: PackedScene = preload("res://scenes/enemy/enemy.tscn")
var _item_template: PackedScene = preload("res://scenes/pickup/item.tscn")

const DEFAULT_BULLET_TYPE = BulletType.BALL
const X_MIDPOINT = 181

# Screw it, I'm just gonna hardcode this.
const bullet_library: Dictionary = {
	BulletType.BALL: preload('res://scenes/bullets/bullet.tscn'),
	BulletType.KNIFE: preload('res://scenes/bullets/bullet_knife.tscn'),
	BulletType.SMALL_BALL: preload('res://scenes/bullets/bullet_small.tscn')
}

var _player_ref: Player = null

var _level_thread: Thread = null

var _bomb_active: bool = false

# ############
# Core Functions

## Called to set up object pools. Not implemented yet.
func setup(player_ref: Player) -> void:
	_player_ref = player_ref


## Begin the level script in a new thread.[br]
## Make sure to call [method Level.setup()] first!
func play() -> void:
	_level_thread = Thread.new()
	
	_level_thread.start(_play)
	_level_thread.wait_to_finish()
	
	call_deferred("emit_signal", "level_finished")


## Internal version of the play method, executes in a new thread.
## This is what is overridden in subclasses, do not call this directly.[br]
## The level_end signal is sent out immediately after this method finishes executing.
func _play() -> void:
	print_rich("[color=red]ERROR: Do not instantiate Level directly, use a subclass![/color]")


# ############
# Utility Functions

# Meant to help the subclasses do their thing.

## Holds up the current thread for [param time] seconds (rounded down to the nearest millisecond).
func sleep(time: float) -> void:
	OS.delay_msec(floor(time * 1000))


# Enemy spawning

## Spawns a standard enemy. Death functions must be added manually.[br]
## Enemy will spawn at [param pos] and fly to [param dest].
func spawn_enemy(pos: Vector2, dest: Vector2, tick_length: float, shot_func: Callable) -> Enemy:
	var enemy: Enemy = _enemy_template.instantiate()
	
	enemy.position = pos
	enemy.destination = dest
	enemy.tick_duration = tick_length
	enemy.tick_func = shot_func
	enemy._level_ref = self

	# Can't add children from outside the main thread, so we use call_deferred
	call_deferred("add_child", enemy)
	
	return enemy


## Spawns a wave of [param count] enemies, at time intervals of [param spacing] seconds.[br]
func spawn_enemy_wave(count: int, spacing: float, pos: Vector2, dest: Vector2, tick_length: float, shot_func: Callable) -> Array[Enemy]:
	var enemies = []
	
	for i in range(count):
		var enemy = spawn_enemy(pos, dest, tick_length, shot_func)
		enemies.append(enemy)
		
		if i != count-1:
			OS.delay_msec(floor(spacing*1000))
	
	return enemies

## Spawns [param boss] at position [param pos]
func spawn_boss(boss: PackedScene, pos: Vector2) -> void:
	call_deferred("_spawn_boss", boss, pos)
	
	
func _spawn_boss(boss: PackedScene, pos: Vector2) -> void:
	var bossInstance: Boss = boss.instantiate() 
	bossInstance.global_position = pos
	bossInstance._level = self
	
	boss_spawned.emit()
	bossInstance.boss_defeated.connect(func(): 
		boss_defeated.emit()
		call_deferred("clear_all_bullets", true))
	bossInstance.spell_hp_changed.connect(func(max, old, new): spell_hp_updated.emit(max, old, new))
	bossInstance.spell_time_changed.connect(func(new): spell_time_updated.emit(new))
	bossInstance.spell_card_started.connect(func(spell_name): spell_started.emit(spell_name, bossInstance.name))
	
	call_deferred("add_child", bossInstance)

# Bullet mechanics

## Produces the template for the bullet with id [param name]
func get_bullet_template(name: BulletType) -> PackedScene:
	if not (name in bullet_library):
		print_rich("[color=yellow]Warning:[/color] Unknown bullet type '"+BulletType.keys()[name]+"'")
		name = DEFAULT_BULLET_TYPE
		
	return bullet_library[name]


## Spawns a bullet of [param type] at [param position] with properties [param args].[br]
## Returns a reference to the new bullet.
func spawn_bullet(_position: Vector2, type: BulletType, args: BulletStats=null) -> Bullet:
	# TODO: Make this work with object pooling
	var bullet: Bullet = get_bullet_template(type).instantiate()
	
	bullet.position = _position
	bullet.init(args)
	
	return bullet


## Spawns a shotgun-burst containing [param count] bullets of [param type], 
## spread evenly across an arc of [param spread]. [br]
## The arc is centred on a vector rotated by [param rotation] degrees, and the 
## bullets spawn [param distance] away from [param position] along the aim vector.[br]
## The bullets will have a velocity of [param v] in the direction they are facing, with acceleration [param a].[br]
## Also, the bullets will be added as children of the game controller.
## Returns an array containing the bullets, ordered from lowest angle aim vector to highest.
func bullet_burst(_position: Vector2, type: BulletType, count: int, spread: float, rotation: float, dist: float, v: float, a: float) -> Array[Bullet]:
	var bullets: Array[Bullet] = []
	var angle_gap = spread / (count-1) if count > 0 else 0
	var start_angle = rotation - spread / 2
	
	for i in range(count):
		var bullet_dir = start_angle + angle_gap * i
		var point_dir = Vector2.from_angle(bullet_dir)
		
		var bullet: Bullet = spawn_bullet(_position + point_dir * dist, type)
		
		bullet.rotation = bullet_dir
		bullet.velocity = point_dir * v
		bullet.acceleration = point_dir * a
		
		bullets.append(bullet)
	
	bullet_fired.emit()
	
	for bullet in bullets:
		add_child(bullet)
	
	return bullets


## Same as [method Level.spawn_burst] but spawns them in a circle.
func bullet_ring(_position: Vector2, type: BulletType, count: int, _rotation: float=0, dist: float=0, v: float=0, a: float=0) -> Array[Bullet]:	
	return bullet_burst(_position, type, count, TAU - TAU / count, _rotation, dist, v, a)


func clear_bullet(bullet: Bullet, spawn_point: bool) -> void:
	if spawn_point:
		spawn_item(bullet.global_position, Item.ItemType.SMALL_POINT).magnet_player = true
	
	bullet.queue_free()


## Turns all bullets onscreen into points. [br]
## If [param hard_clear] is set to true, also clears strong bullets (ones which survive bombs)
func clear_all_bullets(hard_clear=false):
	var bullets: Array = get_tree().get_nodes_in_group("enemy_bullets")
	
	for bullet: Bullet in bullets:
		clear_bullet(bullet, true)


# Other spawning

## Spawns an item of [param type] at [param _position].[br]
## Returns a refernece to the item node.
func spawn_item(_position: Vector2, type: Item.ItemType) -> Item:
	var item: Item = _item_template.instantiate()
	
	item.position = _position
	item.item_type = type
	
	call_deferred("add_child", item)
	
	return item
