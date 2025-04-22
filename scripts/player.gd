class_name Player
extends RigidBody2D

signal lives_changed(old: int, new: int)
signal bombs_changed(old: int, new: int)
signal score_changed(old: int, new: int)

## Player Settings
@export var speed: float
@export var focus_speed: float
@export var lives: int
@export var bombs: int
#@export var deathbomb_timer: float
@export_group("Player Shot")
@export_range(1, 100) var fire_rate: float
@export_range(1, 7) var shot_count: int
## Shot spread in degrees
@export_range(1, 360) var shot_spread: float
@export_range(1, 360) var focus_spread: float

## Game Variables
@onready var hitbox_sprite: Sprite2D = $HitboxSprite
@onready var sfx_player_hit: AudioStreamPlayer2D = $PlayerHitSFX
@onready var sfx_player_graze: AudioStreamPlayer2D = $PlayerGrazeSFX

var shot_template: PackedScene = preload("res://scenes/player_shot.tscn")
var bomb_template: PackedScene = preload("res://scenes/bomb.tscn")

@onready var shot_threshold: float = 1/fire_rate
@onready var shot_cooldown: float = shot_threshold

const BOMB_COOLDOWN: float = 4
var _bomb_cooldown: float = BOMB_COOLDOWN

var _lives: int
var _bombs: int

const MAX_ITIME: float = 1  # Max itime when hit
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
		shot.velocity = Vector2.from_angle(angle_start + i*gap_size) * 20
		add_sibling(shot)

func use_bomb() -> void:
	var bomb = bomb_template.instantiate() as Bomb
	bomb.position = position
	add_sibling(bomb)

func add_lives(count: int) -> void:
	_lives += count
	lives_changed.emit(_lives - count, _lives)

func add_bombs(count: int) -> void:
	_bombs += count
	bombs_changed.emit(_bombs - count, _bombs)

func add_points(points: int) -> void:
	score += points
	# TODO: Check for extra life thresholds
	score_changed.emit(score-points, score)


## Causes the player to emit all of it's stat changed signals
## Order is lives, bombs, score
func emit_stats():
	lives_changed.emit(_lives, _lives)
	bombs_changed.emit(_bombs, _bombs)
	score_changed.emit(0, 0)

func _ready() -> void:
	state = PlayerState.NORMAL
	
	_lives = lives
	_bombs = bombs
	
	var _shot_spread_rad = deg_to_rad(shot_spread)
	var _focus_spread_rad = deg_to_rad(focus_spread)
	
	_shot_angle_start  = -(PI+_shot_spread_rad)/2
	_focus_angle_start = -(PI+_focus_spread_rad)/2
	
	if shot_count > 1:
		_shot_gap_size  = _shot_spread_rad / (shot_count-1)
		_focus_gap_size = _focus_spread_rad / (shot_count-1)
	else:
		_shot_gap_size = 0
		_focus_gap_size = 0


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
			itime += 6
			_bombs -= 1
			bombs_changed.emit(_bombs+1, _bombs)
			use_bomb()


func _on_player_hitbox_area_entered(area: Area2D) -> void:
	if itime > 0:
		return
	
	_lives -= 1
	
	area.queue_free()
	sfx_player_hit.play()
	lives_changed.emit(_lives+1, _lives)
	
	itime = MAX_ITIME


func _on_player_grazebox_area_entered(area: Area2D) -> void:
	add_points(100)
	sfx_player_graze.play()


func _on_item_hitbox_area_entered(area: Area2D) -> void:
	if area is Item:
		(area as Item).apply(self)
		area.queue_free()
