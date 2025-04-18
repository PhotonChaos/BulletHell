class_name Player
extends RigidBody2D

signal player_damage

## Player Settings
@export var speed: float
@export var focus_speed: float
@export var deathbomb_timer: float
@export_range(1, 100) var fire_rate: float

## Game Variables
@onready var hitbox_sprite: Sprite2D = $HitboxSprite
@onready var sfx_player: AudioStreamPlayer2D = $PlayerSFX
@onready var shot_template: PackedScene = preload("res://scenes/player_shot.tscn")

@onready var shot_threshold: float = 1/fire_rate
@onready var shot_cooldown: float = shot_threshold

const MAX_ITIME: float = 1  # Max itime when hit
var itime: float = 0

var focused: bool = true
var points: int = 0

func get_move_speed() -> float:
	return focus_speed if focused else speed

func shoot() -> void:
	var shot = shot_template.instantiate()
	shot.position = position + Vector2(0, -10)
	shot.velocity = 20
	add_sibling(shot)


func _process(delta: float) -> void:	
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
	
	# Shooting
	shot_cooldown += delta

	if shot_cooldown >= shot_threshold:
		shot_cooldown = shot_threshold

		if Input.is_action_pressed("primary"):
			shot_cooldown = 0
			shoot()
	
	# ITime
	itime = max(0, itime - delta)
	

func _on_player_hitbox_area_entered(area: Area2D) -> void:
	if itime > 0:
		return
	
	area.queue_free()
	sfx_player.play()
	player_damage.emit()
	
	itime = MAX_ITIME


func _on_player_grazebox_area_entered(area: Area2D) -> void:
	points += 1
