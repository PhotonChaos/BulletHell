extends SpellCard

func nonspell_setup() -> void:
	var _turrets = []
	
	_turrets.push_back(spawn_turret(global_position + Vector2(-40,0), 1))
	_turrets.push_back(spawn_turret(global_position + Vector2(40, 0), 1))
	
	for i in _turrets:
		i.reparent(self)


func nonspell() -> void:
	if lifetime % 2 == 0:
		_level.bullet_ring(global_position + Vector2(-40, 0), Level.BulletType.SHARD, 2, deg_to_rad(lifetime*4), 10, 60)
		_level.bullet_ring(global_position + Vector2(40, 0), Level.BulletType.SHARD, 2, -deg_to_rad(lifetime*4), 10, 60)
	
	if lifetime % 60 == 0:
		var random_walk = randf_range(20,40) * randi_range(-1, 1)
		
		if global_position.x + random_walk < Boss.MOVEMENT_LEFT_BOUND + 30:
			random_walk += 90
		if global_position.x + random_walk > Boss.MOVEMENT_RIGHT_BOUND - 30:
			random_walk -= 90
		
		var tw = get_tree().create_tween().set_trans(Tween.TRANS_QUAD)
		tw.tween_property(_boss, "position:x", global_position.x + random_walk, 1)

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
	return Item.get_drop_dict(15, 1, 1) if on_spell else Item.get_drop_dict(13, 1, 0)
