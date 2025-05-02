extends SpellCard

func nonspell():
	if lifetime % 10 == 0:
		var player_point_angle = (-(_boss.position - GameController.get_player_pos())).angle()
		_level.bullet_burst(_boss.position, Level.BulletType.KNIFE, 6, 12, player_point_angle, 4, 90, 0)

var spell_rotation: float = 0

func spell():
	if lifetime % 1 == 0:
		spell_rotation += sin(deg_to_rad(lifetime))
		_level.bullet_ring(_boss.position, Level.BulletType.SMALL_BALL, 8, spell_rotation, 10, 20, 50)
