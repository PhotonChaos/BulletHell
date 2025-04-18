class_name Killable
extends Area2D
## Component of an enemy.
## Represents an entity with health and a hitbox that can die.[br]
## Requires one or more CollisionShape2D children.

signal dead

# TODO: Maybe add an on hit signal

@export_range(1, 100000) var starting_health: int = 20

var health: int

func _ready() -> void:
	health = starting_health


func _on_area_entered(area: Area2D) -> void:
	if area is PlayerShot:
		var shot = area as PlayerShot
		health -= shot.damage
		shot.queue_free()
		
		if health <= 0:
			dead.emit()
