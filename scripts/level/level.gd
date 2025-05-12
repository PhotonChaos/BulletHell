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
signal boss_phase_defeated
signal boss_phases_changed(old: int, new: int)
signal spell_started(name: String, boss_name: String)
signal spell_time_updated(new: float)
signal spell_hp_updated(max: int, old: int, new: int)
signal bgm_changed(bgm: BGMAudio)

enum BulletType {
	BALL = 0,
	SMALL_BALL,
	KNIFE,
	SHARD
}

@export var title: String
@export var subtitle: String
@export var level_id: String

# TODO: Implement object pooling
# ## Unused at the moment.
#@export var bullet_pools: Dictionary[Level.BulletType, int]

var _enemy_template: PackedScene = preload("res://scenes/enemy/enemy.tscn")
var _item_template: PackedScene = preload("res://scenes/pickup/item.tscn")
var _boss_death_wave_template: PackedScene = preload("res://scenes/player/death_wave.tscn")
var _boss_death_particles: PackedScene = preload("res://scenes/fx/fx_boss_explosion.tscn")

const DEFAULT_BULLET_TYPE = BulletType.BALL
const X_MIDPOINT = 181

# Screw it, I'm just gonna hardcode this.
const bullet_library: Dictionary = {
	BulletType.BALL: preload('res://scenes/bullets/bullet.tscn'),
	BulletType.KNIFE: preload('res://scenes/bullets/bullet_knife.tscn'),
	BulletType.SMALL_BALL: preload('res://scenes/bullets/bullet_small.tscn'),
	BulletType.SHARD: preload("res://scenes/bullets/bullet_shard.tscn")
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
	change_bgm(get_starting_bgm())
	
	_level_thread = Thread.new()
	
	_level_thread.start(_play)
	_level_thread.wait_to_finish()
	
	call_deferred("emit_signal", "level_finished")


## Internal version of the play method, executes in a new thread.
## This is what is overridden in subclasses, do not call this directly.[br]
## The level_end signal is sent out immediately after this method finishes executing.
func _play() -> void:
	print_rich("[color=red]ERROR: Do not instantiate Level directly, use a subclass![/color]")


## Produces the BGM asset that the level should use at the start.[br]
## Usually, you don't change BGM aside from the boss, but if you need to, call [method Level.change_bgm].
func get_starting_bgm() -> BGMAudio:
	return null


func change_bgm(music: BGMAudio) -> void:
	bgm_changed.emit.call_deferred(music)

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
	
## Called only on the main thread.
func _spawn_boss(boss: PackedScene, pos: Vector2) -> void:
	var bossInstance: Boss = boss.instantiate() 
	bossInstance.global_position = pos
	bossInstance._level = self
	
	boss_spawned.emit()
	bossInstance.boss_defeated.connect(func(): boss_death_particles(bossInstance.position))
	bossInstance.boss_defeated.connect(func(): clear_bullet_wave(bossInstance.position, 1, true, true))
	bossInstance.boss_defeated.connect(func(): boss_defeated.emit())
	
	bossInstance.spell_hp_changed.connect(func(max, old, new): spell_hp_updated.emit(max, old, new))
	bossInstance.spell_time_changed.connect(func(new): spell_time_updated.emit(new))
	bossInstance.spell_card_started.connect(func(spell_name): spell_started.emit(spell_name, bossInstance.name))
	bossInstance.phases_left_changed.connect(func(old, new): boss_phases_changed.emit(old, new))
	bossInstance.phase_defeated.connect(func(was_spellz): boss_phase_defeated.emit())
	
	call_deferred("change_bgm", bossInstance.boss_theme)
	call_deferred("add_child", bossInstance)

# Bullet mechanics

func boss_death_particles(pos: Vector2) -> void:
	var particles = _boss_death_particles.instantiate() as GPUParticles2D
	add_child(particles)
	particles.position = pos
	particles.finished.connect(func(): particles.queue_free())
	particles.emitting = true

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
## The arc is centred on a vector rotated by [param _rotation] radians, and the 
## bullets spawn [param distance] away from [param position] along the aim vector.[br]
## The bullets will have a velocity of [param v] in the direction they are facing, with acceleration [param a].[br]
## Also, the bullets will be added as children of the game controller.
## Returns an array containing the bullets, ordered from lowest angle aim vector to highest.
func bullet_burst(_position: Vector2, type: BulletType, count: int, spread: float, _rotation: float, dist: float, v: float, a: float) -> Array[Bullet]:	
	var bullets: Array[Bullet] = []
	var angle_gap = spread / (count-1) if count > 0 else 0
	var start_angle = _rotation - spread / 2
	
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
	# Disable collision the first frame so the player isn't hurt
	bullet.harmless = true 
		
	var bullet_tween: Tween = get_tree().create_tween().set_parallel(true)
	bullet_tween.tween_property(bullet.get_sprite(), "scale", Vector2.ONE * 1.3, 0.1)
	bullet_tween.tween_property(bullet.get_sprite(), "modulate", Color.TRANSPARENT, 0.1)
	bullet_tween.tween_callback(bullet.queue_free).set_delay(0.1)
	
	if spawn_point:
		call_deferred("spawn_item", bullet.global_position, Item.ItemType.SMALL_POINT, true)


## Turns all bullets onscreen into points. [br]
## If [param hard_clear] is set to true, also clears strong bullets (ones which survive bombs)
func clear_all_bullets(hard_clear=false):
	var bullets: Array = get_tree().get_nodes_in_group("enemy_bullets")
	
	for bullet: Bullet in bullets:
		clear_bullet(bullet, true)

## Spawns a wave that clears the bullets onscreen.
func clear_bullet_wave(pos: Vector2, duration: float, points: bool, hard: bool) -> void:
	var wave = _boss_death_wave_template.instantiate() as DeathWave
	wave.position = pos
	wave.lifespan = duration 
	wave.invisible = true
	wave._level_ref = self
	call_deferred("add_child", wave)

# Other spawning

## Spawns an item of [param type] at [param _position].[br]
## Returns a refernece to the item node.
func spawn_item(_position: Vector2, type: Item.ItemType, magnet: bool=false) -> Item:
	var item: Item = _item_template.instantiate()
	
	item.position = _position
	item.item_type = type
	item.magnet_player = magnet
	
	add_child(item)
	
	return item
