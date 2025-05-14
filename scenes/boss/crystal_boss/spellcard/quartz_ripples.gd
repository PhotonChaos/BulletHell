extends SpellCard


func nonspell() -> void:
	if lifetime % 4 == 0:
		_level.bullet_ring(global_position, Level.BulletType.KNIFE, 5, deg_to_rad(lifetime/4)*7, 9, 10, 70)
		_level.bullet_ring(global_position, Level.BulletType.KNIFE, 5, -deg_to_rad(lifetime/4)*7, 9, 30, 70)



func spell() -> void:
	if (lifetime-1) % 60*2 == 0:
		var bulletList = get_tree().get_nodes_in_group("enemy_bullets") as Array[Bullet]
		var playerPos = GameController.get_player_pos()
		
		for bullet in bulletList:
			var b = bullet as Bullet
			if b.type == Level.BulletType.BALL:
				var pos = b.global_position
				_level.clear_bullet(b, false)
				_level.bullet_ring(pos, Level.BulletType.SMALL_BALL, 4, randf_range(0,PI/16), 1, 60)
			elif b.type == Level.BulletType.SMALL_BALL:
				var pos = b.global_position
				_level.clear_bullet(b, false)
				_level.bullet_burst(pos, Level.BulletType.SHARD, 3, deg_to_rad(90), (playerPos - pos).angle(), 0, 90, 0)
			
		_level.bullet_ring(global_position, Level.BulletType.BALL, 8, 0, 9, 80, 0)
	
func get_drops() -> Dictionary:
	return Item.get_drop_dict(15, 1, 0) if on_spell else Item.get_drop_dict(15, 0, 0)
