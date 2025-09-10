extends Level

var boss_flag = false
var end_dialogue_flag = false

func _build_level() -> void:
	sleep(2)
	spawn_enemy_wave(10, 1, Vector2(100,0), Vector2(100, 2000), 1, func(l: float, p: Vector2, lvl: Level): 
		lvl.bullet_burst(p, BulletType.KNIFE_GOLD, 8, PI/4, l*PI/32, 5, 100, 45))
	spawn_enemy_wave(10, 1, Vector2(100,0), Vector2(100, 2000), 1, func(l: float, p: Vector2, lvl: Level): 
		lvl.bullet_burst(p, BulletType.KNIFE_GOLD, 8, PI/4, l*PI/32, 5, 100, 45))
	spawn_enemy_wave(10, 1, Vector2(100,0), Vector2(100, 2000), 1, func(l: float, p: Vector2, lvl: Level): 
		lvl.bullet_burst(p, BulletType.KNIFE_GOLD, 8, PI/4, l*PI/32, 5, 100, 45))
	sleep(10)
	
	spawn_boss("crystal_boss", BOSS_DEFAULT_POSITION, BOSS_OFFSCREEN_POSITION)
	sleep(3)
	add_script_func(func(): _boss_ref.call_deferred("start"))
	lock_gate()
	sleep(10000)
