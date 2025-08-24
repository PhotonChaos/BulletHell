extends Bullet

func paint_bullet(color: Color):
	super.paint_bullet(color)
	($Sprite2D/Border as Sprite2D).self_modulate = color
