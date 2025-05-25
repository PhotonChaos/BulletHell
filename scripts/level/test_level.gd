extends Level

func _play() -> void:
	#for i in range(5):
		#var posx = randf_range(100, 360)
		#var enemy_tick = func (age: float, _position: Vector2, _level: Level):
			#_level.bullet_ring(_position, BulletType.SMALL_BALL, 5, age * PI/15, 5, 40, 20)
		#
		#spawn_enemy(Vector2(posx, -60), Vector2(posx, randf_range(130, 200)), randf_range(0.1, 0.4), enemy_tick)
		#sleep(1)
	#
	sleep(2)
	var chain: DialogueChain = DialogueChain.new()
	
	chain.add_script_from_text("res://resources/dialogue_scripts/lucas_kalligan_text.txt")
	start_dialogue(chain)
	
	sleep(1000)
