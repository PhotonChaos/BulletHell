extends Area2D

var total_time = 0
var layer_set = true

func _physics_process(delta: float) -> void:
	total_time += delta
	
	if total_time >= 1:
		var tw = get_tree().create_tween()
		tw.tween_interval(1)
		tw.tween_callback(func(): ($CollisionShape2D as CollisionShape2D).set_deferred("disabled", layer_set))
		layer_set = !layer_set
		total_time = 0
