class_name FlashBomb
extends Area2D

signal bomb_finished

var level_ref: Level
var lifetime: float = 2
const DAMAGE = 20

func _ready() -> void:	
	var tw: Tween = get_tree().create_tween()
	tw.tween_interval(lifetime)
	tw.tween_property(self, "modulate", Color.TRANSPARENT, 0.2)
	tw.tween_callback(bomb_finished.emit)
	tw.tween_callback(queue_free)


func _on_area_entered(area: Area2D) -> void:
	if not level_ref:
		return
	
	if area is Bullet and not (area as Bullet).strong:
		level_ref.clear_bullet(area, true)
	elif area is Killable:
		(area as Killable).damage(DAMAGE)
	elif area is Boss:
		(area as Boss).damage(DAMAGE)
