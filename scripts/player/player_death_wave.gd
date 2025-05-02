extends Area2D

const MAX_SCALE = 40
const LIFESPAN = Player.MAX_ITIME 

func _ready() -> void:
	scale = Vector2(0.1, 0.1)
	

var lifetime: float = 0

func _process(delta: float) -> void:
	lifetime += delta
	
	scale = Vector2(lifetime, lifetime)*1/(LIFESPAN)*MAX_SCALE
	
	if lifetime > LIFESPAN:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area is Bullet:
		area.queue_free()
