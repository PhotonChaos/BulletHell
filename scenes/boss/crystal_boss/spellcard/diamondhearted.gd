extends SpellCard

var last_player_pos: Vector2
var last_trajectory: float
var next_charge: int = 0

func spell_setup() -> void:
	_level.bullet_ring(global_position, Level.BulletType.SMALL_BALL, 50, 0, 10, 10, 140)
	next_charge = 60 + int(60*4*get_time_scaler())
	charge_at_player(1)

func spell() -> void:
	if lifetime < 60*2:
		return
		
	if lifetime == next_charge:
		next_charge = lifetime + 60 + int(60*4*get_time_scaler())
		charge_at_player(0)
		
	if lifetime % 6 == 0:
		_level.bullet_ring(global_position, Level.BulletType.SMALL_BALL, 2, last_trajectory, 3, 0, 40)

func get_time_scaler() -> float:
	return max(0, 1-(float(lifetime)/((spell_time_limit-10)*60)))

func charge_at_player(delay: float) -> void:
	last_player_pos = GameController.get_player_pos()
	last_trajectory = (global_position - last_player_pos).angle()
	
	var charge_tween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD)
	var tween_time =  1 + 0.75*get_time_scaler()
	print(tween_time)
	charge_tween.tween_interval(delay)
	charge_tween.tween_property(_boss, "position", last_player_pos, tween_time)
	charge_tween.tween_callback(bullet_burst)

func bullet_burst() -> void:
	for i in range(40):
		var r =  randf_range(0,TAU)
		var rv = Vector2.from_angle(r)
		var b = _level.spawn_bullet(global_position, Level.BulletType.SHARD, r, 20*rv, randf_range(70, 120)*rv)
		
		_level.call_deferred("add_child", b)


func get_drops() -> Dictionary:
	return Item.get_drop_dict(25, 0, 1) if on_spell else Item.get_drop_dict(0, 0, 0)
