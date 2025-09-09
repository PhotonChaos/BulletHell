extends Level

var boss_flag = false
var end_dialogue_flag = false

func _play() -> void:
	sleep(2)
	
	spawn_boss("crystal_boss", BOSS_DEFAULT_POSITION, BOSS_OFFSCREEN_POSITION)
	sleep(3)
	_boss_ref.call_deferred("start")
	
	sleep(10000)
