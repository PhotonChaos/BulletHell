class_name BulletClearPoint extends Area2D
# TODO: Fix memory leak if bullets are cleared before they hit this

static var template: PackedScene = preload("res://scenes/utils/bullet_clear_point.tscn")

var bullets: Array[Bullet] = []
var _level_ref: Level = null

static func create(level: Level) -> BulletClearPoint:
	var bcp = template.instantiate() as BulletClearPoint
	
	bcp._level_ref = level
	
	return bcp

func _on_area_entered(area: Area2D) -> void:
	if area is Bullet and (area as Bullet) in bullets:
		for bullet in bullets:
			if is_instance_valid(bullet):
				_level_ref.clear_bullet(bullet, false)
		
		queue_free()
