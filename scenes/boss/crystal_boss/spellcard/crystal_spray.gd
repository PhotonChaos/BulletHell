extends SpellCard

const BURST_PLAYER_OFFSETS = [Vector2(70, -50), Vector2(150, -10)]

var next_move_frames: int = 60*5

func nonspell_setup():
	for offset in BURST_PLAYER_OFFSETS:
		var offsetb = Vector2(-offset.x, offset.y)
		
		spawn_turret(global_position + offset, 1)
		spawn_turret(global_position + offsetb, 1)

func nonspell():
	if lifetime > 60 and lifetime % 2 == 0 and floor(lifetime / 20) % 2 == 1:
		for offset in BURST_PLAYER_OFFSETS:
			var offsetb = Vector2(-offset.x, offset.y)
			var player_point_angle_a = (-(_boss.position + offset - GameController.get_player_pos())).angle()
			var player_point_angle_b = (-(_boss.position + offsetb - GameController.get_player_pos())).angle()
			_level.bullet_burst(_boss.position + offset,  Level.BulletType.SHARD, 3, deg_to_rad(55), player_point_angle_a + randf_range(0, PI/32), 4, 90, 0)
			_level.bullet_burst(_boss.position + offsetb, Level.BulletType.SHARD, 3, deg_to_rad(55), player_point_angle_b + randf_range(0, PI/32), 4, 90, 0)


var spell_rotation: float = 0

func spell():
	if lifetime % 60 == 0:
		_boss.move_to(Vector2(GameController.get_player_pos().x + randi_range(-5, 5), 100), 0.8, 0, 0)
	
	if lifetime % 2 == 0:
		spell_rotation += sin(deg_to_rad(lifetime) * 0.5)
		_level.bullet_ring(_boss.position, Level.BulletType.SMALL_BALL, 8, spell_rotation, 10, 20, 50)

func get_drops() -> Dictionary:
	return Item.get_drop_dict(10, 10, 10)
