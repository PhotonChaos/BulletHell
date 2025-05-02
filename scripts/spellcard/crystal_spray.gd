extends SpellCard

func nonspell():
	if lifetime % 10 == 0:
		var player_point_angle = (-(_boss.position - GameController.get_player_pos())).angle()
		_level.bullet_burst(_boss.global_position, Level.BulletType.KNIFE, 6, 12, player_point_angle, 4, 90, 0)

func spell():
	if lifetime % 10 == 0:
		_level.bullet_ring(_boss.global_position, Level.BulletType.KNIFE, 25, lifetime * TAU/7, 10, 20, 30)
		_level.bullet_ring(_boss.global_position, Level.BulletType.KNIFE, 10, lifetime * -TAU/7, 10, 20, 30)
