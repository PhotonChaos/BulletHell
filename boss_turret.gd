class_name BossTurret
extends Sprite2D

static func _easing(x: float) -> float:
	return 1 - (1 - x) * (1 - x)


var destination: Vector2
var duration: float

var _lifetime = 0


func new_destination(dest: Vector2, travel_time: float) -> void:
	destination = dest
	duration = travel_time
	_lifetime = 0

func _process(delta: float) -> void:
	if _lifetime >= duration:
		return
	
	_lifetime += delta
	
	global_position = global_position.lerp(destination, _easing(min(duration, _lifetime / duration)))
	
