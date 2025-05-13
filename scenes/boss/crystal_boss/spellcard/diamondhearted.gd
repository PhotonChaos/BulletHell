extends SpellCard



func get_drops() -> Dictionary:
	return Item.get_drop_dict(25, 0, 0)
