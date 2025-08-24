class_name Level
extends Node2D
## This is supposed to be an abstract class, so don't add nodes of this base type!
## Subclass from this! The [method Level._play()] function gets called 

signal level_loaded
signal level_finished

# For SFX
signal bullet_fired
signal laser_fired
signal boss_spawned
signal boss_started
signal boss_defeated
signal boss_phase_defeated
signal boss_phases_changed(old: int, new: int)
signal spell_started(name: String, boss_name: String)
signal spell_time_updated(new: float)
signal spell_hp_updated(max: int, old: int, new: int)
signal bgm_changed(bgm: BGMAudio)
signal dialogue_started(chain: DialogueChain)
signal dialogue_controls(paused: bool)

enum BulletType {
	BALL = 0,
	SMALL_BALL,
	KNIFE,
	KNIFE_GOLD,
	SHARD,
	STAR
}

@export var title: String
@export var subtitle: String
@export var level_id: String

## Map of bosses that the level might need. Can be empty.
@export var bosses: Dictionary[String, PackedScene]

# TODO: Implement object pooling
# ## Unused at the moment.
#@export var bullet_pools: Dictionary[Level.BulletType, int]

var _enemy_template: PackedScene = preload("res://scenes/enemy/enemy.tscn")
var _item_template: PackedScene = preload("res://scenes/pickup/item.tscn")
var _boss_death_wave_template: PackedScene = preload("res://scenes/player/death_wave.tscn")
var _boss_death_particles: PackedScene = preload("res://scenes/fx/fx_boss_explosion.tscn")

var _boss_ref: Boss = null

const DEFAULT_BULLET_TYPE = BulletType.BALL
const BOSS_OFFSCREEN_POSITION = Vector2(-40, 100)
const BOSS_DEFAULT_POSITION = Vector2(620, 300)
const PLAY_AREA_CENTER = Vector2(619.5, 540.5)

const DIALOGUE_CUE_BOSS_SPAWN = "enter"
const DIALOGUE_CUE_BOSS_START = "startfight"
const DIALOGUE_CUE_BOSS_BGM = "bgm"

const BULLET_CLEAR_TIME = 0.1

# Screw it, I'm just gonna hardcode this.
const bullet_library: Dictionary = {
	BulletType.BALL: preload('res://scenes/bullets/bullet.tscn'),
	BulletType.KNIFE: preload('res://scenes/bullets/bullet_knife.tscn'),
	BulletType.KNIFE_GOLD: preload('res://scenes/bullets/bullet_gold_knife.tscn'),
	BulletType.SMALL_BALL: preload('res://scenes/bullets/bullet_small.tscn'),
	BulletType.SHARD: preload("res://scenes/bullets/bullet_shard.tscn"),
	BulletType.STAR: preload("res://scenes/bullets/bullet_star.tscn")
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
	Logger.error("Do not instantiate Level directly, use a subclass!")


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


func start_dialogue(chain: DialogueChain):
	(func(): chain.event_cue.connect(on_dialogue_event)).call_deferred()
	call_deferred("emit_signal", "dialogue_started", chain)


## This [i]should[/i] get called on the main thread
func on_dialogue_event(event_name: String, params: Array):	
	if event_name == DIALOGUE_CUE_BOSS_SPAWN:
		spawn_boss(params[0], BOSS_DEFAULT_POSITION, BOSS_OFFSCREEN_POSITION)
	elif event_name == DIALOGUE_CUE_BOSS_START:
		_boss_ref.start()
	elif event_name == DIALOGUE_CUE_BOSS_BGM:
		bgm_changed.emit(_boss_ref.boss_theme)
	

func on_boss_defeat():
	pass

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
func spawn_boss(boss: String, pos: Vector2=BOSS_DEFAULT_POSITION, offscreen_pos: Vector2=BOSS_OFFSCREEN_POSITION) -> void:
	call_deferred("_spawn_boss", boss, pos, offscreen_pos)
	
## Called only on the main thread.
func _spawn_boss(boss: String, pos: Vector2, offscreen_pos: Vector2) -> void:
	var bossInstance: Boss = bosses[boss].instantiate() 
	bossInstance.global_position = offscreen_pos
	bossInstance._level = self
	
	boss_spawned.emit()
	bossInstance.boss_defeated.connect(func(): boss_death_particles(bossInstance.position))
	bossInstance.boss_defeated.connect(func(): clear_bullet_wave(bossInstance.position, 1, true, true))
	bossInstance.boss_defeated.connect(func(): boss_defeated.emit())
	
	
	bossInstance.boss_started.connect(boss_started.emit)
	bossInstance.spell_hp_changed.connect(func(max, old, new): spell_hp_updated.emit(max, old, new))
	bossInstance.spell_time_changed.connect(func(new): spell_time_updated.emit(new))
	bossInstance.spell_card_started.connect(func(spell_name): spell_started.emit(spell_name, bossInstance.name))
	bossInstance.phases_left_changed.connect(func(old, new): boss_phases_changed.emit(old, new))
	bossInstance.phase_defeated.connect(func(was_spellz): boss_phase_defeated.emit())
	
	var tw = get_tree().create_tween().set_ease(Tween.EASE_OUT)
	
	tw.set_trans(Tween.TRANS_QUAD).tween_property(bossInstance, "position:x", pos.x, 2)
	tw.parallel().set_trans(Tween.TRANS_EXPO).tween_property(bossInstance, "position:y", pos.y, 2)
	tw.tween_callback(func(): dialogue_controls.emit(false))
	
	_boss_ref = bossInstance
	dialogue_controls.emit(true)
	add_child(bossInstance)

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
		Logger.warning("Unknown bullet type '"+BulletType.keys()[name]+"'")
		name = DEFAULT_BULLET_TYPE
		
	return bullet_library[name]


## Spawns a bullet of [param type] at [param position] with properties [param args].[br]
## Returns a reference to the new bullet.
func spawn_bullet(_position: Vector2, type: BulletType, _rotation: float, v: Vector2, a: Vector2) -> Bullet:
	# TODO: Make this work with object pooling
	var bullet: Bullet = get_bullet_template(type).instantiate()
	
	bullet.position = _position
	bullet.scale = Vector2.ZERO
	bullet.type = type
	bullet.velocity = v
	bullet.acceleration = a
	bullet.rotation = _rotation
	
	# TODO: Figure out whether it's better to bulk-tween these in the burst methods instead of this.
	var tween = get_tree().create_tween()
	tween.tween_property(bullet, "scale", Vector2.ONE, 0.1)
	
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
	var angle_gap = spread / (count-1) if count > 1 else 0
	var start_angle = _rotation - spread / 2
	
	for i in range(count):
		var bullet_dir = start_angle + angle_gap * i
		var point_dir = Vector2.from_angle(bullet_dir)
		
		var bullet: Bullet = spawn_bullet(_position + point_dir * dist, type, bullet_dir, point_dir * v, point_dir * a)
		
		bullets.append(bullet)
	
	bullet_fired.emit()
	
	for bullet in bullets:
		add_child(bullet)
	
	return bullets


## Same as [method Level.spawn_burst] but spawns them in a circle.
func bullet_ring(_position: Vector2, type: BulletType, count: int, _rotation: float=0, dist: float=0, v: float=0, a: float=0) -> Array[Bullet]:	
	return bullet_burst(_position, type, count, TAU - TAU / count, _rotation, dist, v, a)

func bullet_star(_position: Vector2, type: BulletType, points: int, density: int, v_mult: float, _rotation: float, v: float, a: float=0) -> Array[Bullet]:
	var bullets: Array[Bullet] = []
	var total_bullets = points*density
	
	for i in range(total_bullets):
		var amp = (1-v_mult)*2*abs(i % density - density*0.5) / (2*density) + v_mult
		var dir = Vector2.from_angle(TAU / total_bullets * i + _rotation) * amp
		bullets.append(spawn_bullet(_position, type, dir.angle(), dir*v, dir.normalized()*a))
	
	for bullet in bullets:
		bullet.rotate_to_velocity = false
		add_child(bullet)
	
	return bullets

func laser_straight(_start: Vector2, _direction: Vector2, length: float, radius: float, startup_delay: float, duration: float, out_color: Color, in_color: Color = Color.WHITE) -> LaserStraight:
	var laser = LaserStraight.create(_start, _direction, length, radius, startup_delay, duration, out_color, in_color)
	
	laser.laser_expand.connect(laser_fired.emit)
	add_child(laser)
	
	return laser

func laser_straight_points(_start: Vector2, _end: Vector2, radius: float, startup_delay: float, duration: float, out_color: Color, in_color: Color = Color.WHITE) -> LaserStraight:
	var laser = LaserStraight.create_from_points(_start, _end, radius, startup_delay, duration, out_color, in_color)
	
	laser.laser_expand.connect(laser_fired.emit)
	add_child(laser)
	
	return laser
	


func clear_bullet(bullet: Bullet, spawn_point: bool) -> void:
	# Disable collision the first frame so the player isn't hurt
	bullet.harmless = true 
		
	var bullet_tween: Tween = get_tree().create_tween().set_parallel(true)
	bullet_tween.tween_property(bullet.get_sprite(), "scale", Vector2.ONE * 1.3, BULLET_CLEAR_TIME)
	bullet_tween.tween_property(bullet.get_sprite(), "modulate", Color.TRANSPARENT, BULLET_CLEAR_TIME)
	bullet_tween.tween_callback(bullet.queue_free).set_delay(BULLET_CLEAR_TIME)
	
	if spawn_point:
		call_deferred("spawn_item", bullet.global_position, Item.ItemType.SMALL_POINT, true)


func clear_laser(laser: LaserStraight) -> void:
	if laser._expand_tween:
		laser._expand_tween.kill()
	
	if laser._laser_started:
		laser.collapse_laser()
	else:
		laser.queue_free()

## Turns all bullets onscreen into points. [br]
## If [param hard_clear] is set to true, also clears strong bullets (ones which survive bombs) and lasers
func clear_all_bullets(hard_clear=false):
	var bullets: Array = get_tree().get_nodes_in_group("enemy_bullets")
	
	for bullet: Bullet in bullets:
		clear_bullet(bullet, true)
	
	if hard_clear:
		for laser: LaserStraight in get_tree().get_nodes_in_group("enemy_lasers"):
			clear_laser(laser)
			
func clear_all_lasers():
	for laser: LaserStraight in get_tree().get_nodes_in_group("enemy_lasers"):
		clear_laser(laser)

## Spawns a wave that clears the bullets onscreen.
func clear_bullet_wave(pos: Vector2, duration: float, points: bool, hard: bool) -> void:
	var wave = _boss_death_wave_template.instantiate() as DeathWave
	wave.position = pos
	wave.lifespan = duration 
	wave.hard_clear = hard
	wave.invisible = true
	wave._level_ref = self
	wave.finished.connect(clear_all_lasers)
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
