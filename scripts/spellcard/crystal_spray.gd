extends SpellCard

func nonspell():
	if lifetime % 10 == 0:
		_level.bullet_ring(_boss.global_position, Level.BulletType.KNIFE, 25, lifetime * TAU/7, 10, 20, 30)

func spell():
	if lifetime % 10 == 0:
		_level.bullet_ring(_boss.global_position, Level.BulletType.KNIFE, 20, lifetime * TAU/7, 10, 20, 30)
		_level.bullet_ring(_boss.global_position, Level.BulletType.BALL, 20, lifetime * -TAU/7, 10, 20, 30)
