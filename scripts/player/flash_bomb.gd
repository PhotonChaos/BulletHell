class_name FlashBomb
extends Area2D

var level_ref: Level
var lifetime: float
const DAMAGE = 20

func _ready() -> void:
	lifetime = 2
	
	var tw: Tween = get_tree().create_tween()
	tw.tween_interval(lifetime)
	tw.tween_property($Sprite2D, "modulate", Color.TRANSPARENT, 0.2)
	tw.tween_callback(queue_free)


func _on_area_entered(area: Area2D) -> void:
	if not level_ref:
		return
	
	if area is Bullet:
		level_ref.clear_bullet(area, true)
	elif area is Killable:
		(area as Killable).damage(DAMAGE)
	elif area is Boss:
		(area as Boss).damage(DAMAGE)
