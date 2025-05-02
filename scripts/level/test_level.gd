extends Level

@onready var bossy = preload("res://scenes/boss/crystal_boss.tscn")

func _play() -> void:
	#for i in range(5):
		#var posx = randf_range(100, 360)
		#var enemy_tick = func (age: float, _position: Vector2, _level: Level):
			#_level.bullet_ring(_position, BulletType.SMALL_BALL, 5, age * PI/15, 5, 40, 20)
		#
		#spawn_enemy(Vector2(posx, -60), Vector2(posx, randf_range(130, 200)), randf_range(0.1, 0.4), enemy_tick)
		#sleep(1)
		#
	#
	#sleep(3)
	
	spawn_boss(bossy, Vector2(200, 100))
	sleep(1000)
