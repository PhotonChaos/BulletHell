extends SpellCard

func nonspell():
	if lifetime % 10 == 0:
		var player_point_angle = (-(_boss.position - GameController.get_player_pos())).angle()
		_level.bullet_burst(_boss.position, Level.BulletType.KNIFE, 7, deg_to_rad(30), player_point_angle + randf_range(0, PI/12), 4, 90, 0)

var spell_rotation: float = 0

func spell():
	if lifetime % 2 == 0:
		spell_rotation += sin(deg_to_rad(lifetime))
		_level.bullet_ring(_boss.position, Level.BulletType.SMALL_BALL, 8, spell_rotation, 10, 20, 50)
