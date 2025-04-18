class_name PlayerShot extends Area2D

@export_range(0, 100) var damage: int

var velocity: int

func _physics_process(delta: float) -> void:
	position += Vector2.UP * velocity
	
