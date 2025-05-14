class_name Player
extends RigidBody2D

signal lives_changed(old: int, new: int)
signal bombs_changed(old: int, new: int)
signal score_changed(old: int, new: int)
signal flash_changed(value: int, max: int)

## Player Settings
@export var speed: float
@export var focus_speed: float
@export var lives: int
@export var bombs: int
## Charge needed to use flash bomb
@export var max_flash_charge: int
## The time in seconds the player has to bomb after getting hit to save themselves
@export_range(0, 2) var deathbomb_window: float
@export_group("Player Shot")
@export_range(1, 100) var fire_rate: float
@export_range(1, 7) var shot_count: int
## Shot spread in degrees
@export_range(1, 360) var shot_spread: float
@export_range(1, 360) var focus_spread: float
@export var shot_velocity: float

@export_group("Cheats")
@export var invincible: bool = false

## Game Variables
@onready var hitbox_sprite: Sprite2D = $HitboxSprite

@onready var sfx_player_hit: AudioStreamPlayer2D = $HitSFX
@onready var sfx_player_graze: AudioStreamPlayer2D = $GrazeSFX
#@onready var sfx_player_item: AudioStreamPlayer2D = $ItemSFX
@onready var sfx_player_bullet_item: AudioStreamPlayer2D = $BulletItemSFX
@onready var sfx_player_flashbomb_charge: AudioStreamPlayer2D = $FlashChargeSFX
@onready var sfx_player_use_bomb: AudioStreamPlayer2D = $BombSFX
@onready var sfx_player_use_flashbomb: AudioStreamPlayer2D = $FlashBombSFX
@onready var sfx_player_shoot: AudioStreamPlayer2D = $ShotSFX

var shot_template: PackedScene = preload("res://scenes/player/player_shot.tscn")
var bomb_template: PackedScene = preload("res://scenes/player/bomb.tscn")
var flashbomb_template: PackedScene = preload("res://scenes/player/flash_bomb.tscn")
var deathwave_template: PackedScene = preload("res://scenes/player/death_wave.tscn")

var item_pickup_sfx: AudioStreamWAV = preload("res://audio/SFX/click(5).wav")
var bomb_pickup_sfx: AudioStreamWAV = preload("res://audio/SFX/BombGain.wav")
var life_pickup_sfx: AudioStreamWAV = preload("res://audio/SFX/LifeGain.wav")

@onready var shot_threshold: float = 1/fire_rate
@onready var shot_cooldown: float = shot_threshold

var _game_ref: GameController = null

const BOMB_COOLDOWN: float = 4
var _bomb_cooldown: float = BOMB_COOLDOWN

const MAX_LIVES: int = 6
const MAX_BOMBS: int = 6

var _lives: int
var _bombs: int


var _flash_charge: int = 0

const HIT_ITIME: float = 2  
const BOMB_ITIME: float = 6
const FLASH_ITIME: float = 1

var itime: float = 0

var focused: bool = true

var score: int = 0

var _shot_gap_size: float
var _shot_angle_start: float
var _focus_gap_size: float
var _focus_angle_start: float

enum PlayerState {
	NORMAL,
	DIALOGUE,
	PAUSE
}

var state: PlayerState

func get_move_speed() -> float:
	return focus_speed if focused else speed

func shoot() -> void:
	var gap_size = _focus_gap_size if focused else _shot_gap_size
	var angle_start = _focus_angle_start if focused else _shot_angle_start
	
	for i in range(shot_count):
		var shot: PlayerShot = shot_template.instantiate()
		shot.position = position + Vector2(0, -10)
		shot.rotation = angle_start + i*gap_size + PI/2
		shot.velocity = Vector2.from_angle(angle_start + i*gap_size) * shot_velocity
		add_sibling(shot)
	
	#sfx_player_shoot.pitch_scale = randf_range(0.95, 1.05)
	sfx_player_shoot.play()

func use_bomb() -> void:
	if get_parent() is Level:
		(get_parent() as Level)._bomb_active = true
	else:
		return  # The bomb won't work if we're not on the level anyways
	
	var bomb = bomb_template.instantiate() as Bomb
	bomb.position = position
	bomb.level_ref = get_parent() as Level
	add_sibling(bomb)
	sfx_player_use_bomb.play()

func use_flash_bomb() -> void:
	if not get_parent() is Level:
		return
		
	var flash = flashbomb_template.instantiate() as FlashBomb
	flash.position = position
	flash.level_ref = get_parent() as Level
	add_sibling(flash)
	sfx_player_use_flashbomb.play()
	

## Grants the player [param time] seconds of invincibility time. [br]
## If [param force_set] is false, this function will not reduce the player's 
## invincibility window if [param time] is smaller than the current amount of invincibility time the player has left.[br]
## This should be used when itime is granted, or set to a specific value. 
func set_itime(time: float, force_set: bool = false) -> void:
	if force_set:
		itime = time
	else:
		itime = max(itime, time)


func add_lives(count: int) -> void:
	var old = _lives
	_lives = min(_lives+count, MAX_LIVES)
	lives_changed.emit(old, _lives)


func add_bombs(count: int) -> void:
	var old = _bombs
	_bombs = min(_bombs+count, MAX_BOMBS)
	bombs_changed.emit(old, _bombs)
	


func add_points(points: int) -> void:
	score += points
	# TODO: Check for extra life thresholds
	score_changed.emit(score-points, score)


func die() -> void:
	if (get_parent() as Level)._bomb_active:
		# This is to allow for the deathbomb window. 
		# Besides, you should be invincible when your bomb is onscreen no matter what.
		print("DEATHBOMBED")
		return
	
	var wave = deathwave_template.instantiate() as DeathWave
	call_deferred("add_sibling", wave)
	wave.lifespan = HIT_ITIME
	wave.position = position
	wave._level_ref = get_parent() as Level
	wave.give_points = false
	_lives -= 1
	set_itime(HIT_ITIME)
	
	lives_changed.emit(_lives+1, _lives)
	

## Causes the player to emit all of it's stat changed signals
## Order is lives, bombs, score, flash charge
func emit_stats():
	lives_changed.emit(_lives, _lives)
	bombs_changed.emit(_bombs, _bombs)
	score_changed.emit(0, 0)
	flash_changed.emit(_flash_charge, max_flash_charge)


func _ready() -> void:
	state = PlayerState.NORMAL
	
	_lives = lives
	_bombs = bombs
	
	_flash_charge = 0
	
	var _shot_spread_rad: float = deg_to_rad(shot_spread)
	var _focus_spread_rad: float = deg_to_rad(focus_spread)
	
	_shot_angle_start  = -(PI+_shot_spread_rad)/2
	_focus_angle_start = -(PI+_focus_spread_rad)/2
	
	if shot_count > 1:
		_shot_gap_size  = _shot_spread_rad / (shot_count-1)
		_focus_gap_size = _focus_spread_rad / (shot_count-1)
	else:
		_shot_gap_size = 0
		_focus_gap_size = 0

## Used for debug
#func _draw():
	#draw_line(Vector2.ZERO, Vector2(0, -1000), Color.RED)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# TODO: Handle player movement here maybe
	pass

func _physics_process(delta: float) -> void:
	# Moving
	if not focused and Input.is_action_pressed("focus"):
		focused = true
		hitbox_sprite.visible = true
	elif focused and not Input.is_action_pressed("focus"):
		focused = false
		hitbox_sprite.visible = false
	
	var frame_move = Vector2.ZERO
	
	if Input.is_action_pressed("move_left"):
		frame_move += Vector2.LEFT
	elif Input.is_action_pressed("move_right"):
		frame_move += Vector2.RIGHT
	
	if Input.is_action_pressed("move_up"):
		frame_move += Vector2.UP
	elif Input.is_action_pressed("move_down"):
		frame_move += Vector2.DOWN
	
	linear_velocity = frame_move.normalized() * get_move_speed()
	
	itime = max(0, itime - delta)
	
	
	## From this point onwards, nothing runs in cutscene or during pause
	if state != PlayerState.NORMAL:
		return

	shot_cooldown += delta
	_bomb_cooldown += delta

	if shot_cooldown >= shot_threshold:
		shot_cooldown = shot_threshold

		if Input.is_action_pressed("primary"):
			shot_cooldown = 0
			shoot()
	
	if _bomb_cooldown >= BOMB_COOLDOWN:
		_bomb_cooldown = BOMB_COOLDOWN
		
		if Input.is_action_pressed("secondary") and _bombs > 0:
			_bomb_cooldown = 0
			set_itime(BOMB_ITIME)
			_bombs -= 1
			bombs_changed.emit(_bombs+1, _bombs)
			use_bomb()
			
	if Input.is_action_pressed("flash") and _flash_charge >= max_flash_charge:
		set_itime(FLASH_ITIME)
		_flash_charge = 0
		flash_changed.emit(_flash_charge, max_flash_charge)
		use_flash_bomb()


func _on_player_hitbox_area_entered(area: Area2D) -> void:
	if itime > 0 or invincible:
		return
	
	if area is Bullet:
		if (area as Bullet).harmless:
			return  # Harmless bullets should pass through the player
		
		area.queue_free()
		
	sfx_player_hit.play()
	
	set_itime(deathbomb_window)
	await get_tree().create_timer(deathbomb_window).timeout.connect(die)


func _on_player_grazebox_area_entered(area: Area2D) -> void:
	add_points(100)
	
	var old_flash = _flash_charge
	
	_flash_charge = min(_flash_charge + 1, max_flash_charge)
	flash_changed.emit(_flash_charge, max_flash_charge)
	
	if old_flash < _flash_charge and _flash_charge == max_flash_charge:
		sfx_player_flashbomb_charge.play()

	sfx_player_graze.pitch_scale = randf_range(0.98, 1.02)
	sfx_player_graze.play()


func _on_item_hitbox_area_entered(area: Area2D) -> void:
	if area is Item:
		var item = area as Item
		
		if item.item_type == Item.ItemType.SMALL_POINT:
			sfx_player_bullet_item.pitch_scale = randf_range(0.99, 1.01)
			sfx_player_bullet_item.play()
		
		item.apply(self)
		item.queue_free()

 
func _on_item_magnet_box_area_entered(area: Area2D) -> void:
	if area is Item:
		(area as Item).magnet_player = true
