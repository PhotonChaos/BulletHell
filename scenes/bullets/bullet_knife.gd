extends Bullet

func paint_bullet(color: Color) -> void:
	super.paint_bullet(color)
	($Sprite2D as Sprite2D).self_modulate = color
