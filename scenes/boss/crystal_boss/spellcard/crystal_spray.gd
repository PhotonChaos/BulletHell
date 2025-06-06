extends SpellCard

const BURST_PLAYER_OFFSETS = [Vector2(70, -50)*3, Vector2(150, -10)*3]

var next_move_frames: int = 60*5


func nonspell_setup():
	for offset in BURST_PLAYER_OFFSETS:
		var offsetb = Vector2(-offset.x, offset.y)
		
		spawn_turret(global_position + offset, 1)
		spawn_turret(global_position + offsetb, 1)

var player_pos: Vector2 = Vector2.ZERO

func nonspell():
	if lifetime % 2 == 0 and floor(lifetime / 20) % 2 == 0:
		if lifetime % 20 == 0:
			player_pos = GameController.get_player_pos()  # Only check once every burst. Helps make this more consistently clearable
		
		for offset in BURST_PLAYER_OFFSETS:
			var offsetb = Vector2(-offset.x, offset.y)
			var player_point_angle_a = (-(_boss.position + offset - player_pos)).angle()
			var player_point_angle_b = (-(_boss.position + offsetb - player_pos)).angle()
			_level.bullet_burst(_boss.position + offset,  Level.BulletType.SHARD, 3, deg_to_rad(55), player_point_angle_a + randf_range(0, PI/32), 4, 90*3, 0)
			_level.bullet_burst(_boss.position + offsetb, Level.BulletType.SHARD, 3, deg_to_rad(55), player_point_angle_b + randf_range(0, PI/32), 4, 90*3, 0)


var spell_rotation: float = 0


func spell():
	if lifetime % 60 == 0:
		_boss.move_to(Vector2(GameController.get_player_pos().x + randi_range(-5, 5), Level.BOSS_DEFAULT_POSITION.y), 0.8, 0, 0)
	
	if lifetime % 2 == 0:
		spell_rotation += sin(deg_to_rad(lifetime) * 0.5)
		_level.bullet_ring(_boss.position, Level.BulletType.SMALL_BALL, 8, spell_rotation, 10*3, 20*3, 50*3)


func get_drops() -> Dictionary:
	return Item.get_drop_dict(30, 0, 0)
