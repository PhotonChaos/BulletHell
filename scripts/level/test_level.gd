extends Level

func _play() -> void:
	var enemy = enemy_template.instantiate()
	var posx = randf_range(100, 360)
	
	enemy.position = Vector2(posx, -60)
	enemy.destination = Vector2(posx, randf_range(130, 200))
	enemy.target_dest = true
	enemy.tick_duration = randf_range(0.1, 0.4)
	
	var enemy_shots = randi_range(3, 6)
	
	enemy.tick_func = func (age: float, _position: Vector2):
		GameController.spawn_ring(_position, "small_ball", enemy_shots, age * PI/15, 5, 40, 20)
	
	add_child(enemy)
