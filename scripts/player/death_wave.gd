class_name DeathWave
extends Area2D

signal finished

const MAX_SCALE = 45*3

var lifespan = Player.HIT_ITIME 
var invisible: bool = false
var give_points: bool = true
var lifetime: float = 0

var hard_clear: bool = false

var _level_ref: Level = null

func _ready() -> void:
	scale = Vector2(0.1, 0.1)
	
	if invisible:
		$Sprite2D.hide()
	

func _process(delta: float) -> void:
	lifetime += delta
	
	scale = Vector2(lifetime, lifetime)*1/(lifespan)*MAX_SCALE
	
	if lifetime > lifespan:
		finished.emit()
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area is Bullet:
		_level_ref.clear_bullet(area, give_points)
	if area is LaserStraight and hard_clear:
		_level_ref.clear_laser(area)
