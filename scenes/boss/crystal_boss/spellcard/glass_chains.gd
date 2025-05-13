extends SpellCard

func nonspell() -> void:
	pass
	

var turrets = []

func spell_setup() -> void:
	for i in range(6):
		turrets.push_back(spawn_turret(Vector2(Boss.MOVEMENT_LEFT_BOUND - 20, global_position.y - 200 + 80*i), 0.5))
		turrets.push_back(spawn_turret(Vector2(Boss.MOVEMENT_RIGHT_BOUND + 20, global_position.y - 200 + 80*i), 0.5))

func spell() -> void:
	# Circle spray to make following the diamonds more difficult	
	if lifetime % 30 == 0:
		_level.bullet_ring(global_position, Level.BulletType.SMALL_BALL, 10, TAU/20 * (lifetime/30 % 2), 13, 60, 0)
	
	if lifetime % 6 == 0:
		for turr in turrets:
			var xy = turr.global_position
			var angle = deg_to_rad(135 + sin(deg_to_rad(lifetime / 6)*2)*13)
			
			if xy.x > global_position.x:
				angle = deg_to_rad(-135 + sin(deg_to_rad(lifetime / 6)*2)*13)
			
			_level.bullet_burst(xy, Level.BulletType.SHARD, 1, PI, angle, 0, 70, 0)

func get_drops() -> Dictionary:
	return Item.get_drop_dict(15, 1, 1)
