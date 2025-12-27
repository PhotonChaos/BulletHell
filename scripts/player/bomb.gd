class_name Bomb
extends AnimatedSprite2D

@export var damage: float
@export_range(0.1, 30) var duration: float

@onready var area = $Hitbox as Area2D

const DAMAGE_GAP = 0.1
const MAX_SCALE = Vector2(60, 60)
const MIN_SCALE = Vector2(0.1, 0.1)

var level_ref: Level

var _age: float
var _damage_cooldown: float
var _lerp_end: float

func _ready() -> void:
	scale = Vector2(0.1, 0.1)
	
	_age = 0
	_damage_cooldown = 0
	_lerp_end = duration - 1/(sprite_frames.get_animation_speed("default") * sprite_frames.get_frame_count("default"))
	pause()


func _process(delta: float) -> void:
	_age += delta
	_damage_cooldown = max(0, _damage_cooldown - delta)
	
	if _damage_cooldown <= 0:
		_damage_cooldown = DAMAGE_GAP
		
		for target in area.get_overlapping_areas():
			if target is Killable:
				var t = target as Killable
				t.damage(damage / 5)
			elif target is Boss and not (target as Boss).is_bomb_immune():
				(target as Boss).damage(damage / 5)
	
	if _age > _lerp_end and not is_playing():
		play("default")
	else:
		scale = MIN_SCALE.lerp(MAX_SCALE, _age / _lerp_end)


func _on_animation_finished() -> void:
	if get_parent() is Level:
		(get_parent() as Level)._bomb_active = false
	queue_free()


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is Bullet and not (area as Bullet).strong:
		level_ref.clear_bullet(area as Bullet, true)
