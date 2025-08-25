extends SpellCard

var laser: LaserStraight = null
var laser2: LaserStraight = null
var start_angle = 0
var widen = 0

func spell() -> void:
	if lifetime % 60*5 == 0:
		widen = 0
		start_angle = GameController.get_player_pos().angle() + randf_range(-PI/6, PI/6)
		laser = _level.laser_straight(Vector2.ZERO, Vector2.from_angle(start_angle), 2000, 40, 1, 4, Color.ORANGE, Color.YELLOW)
		laser2 = _level.laser_straight(Vector2.ZERO, Vector2.from_angle(start_angle), 2000, 40, 1, 4, Color.ORANGE, Color.YELLOW)
	
	if lifetime % 3 == 0 and laser != null and is_instance_valid(laser):
		widen += deg_to_rad(1)
		laser.rotate_laser(start_angle + widen)
		laser2.rotate_laser(start_angle - widen)


func get_drops() -> Dictionary:
	if on_spell:
		return Item.get_drop_dict(30, 1, 0)
		
	return Item.get_drop_dict(0, 0, 0)
