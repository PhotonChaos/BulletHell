extends Level

var boss_flag = false
var end_dialogue_flag = false

func _play() -> void:
	sleep(1)
	
	for j in range(20):
		for i in range(40):
			var laser = LaserStraight.create(Vector2(randf_range(100, 1100), -100), Vector2.from_angle(randf_range(0,PI)), 2400, 30, 1, 3, Color.GREEN, Color.BLACK)
			call_deferred("add_child", laser)
		sleep(3)
	
	sleep(10000)
