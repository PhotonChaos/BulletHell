class_name GameplayUI
extends Control

var heart_icon = preload("res://textures/heart_icon.png")
var bomb_icon  = preload("res://textures/bomb_icon.png")

@onready var livesContainer = $ColorRect/PlayerResources/LivesContainer/HPIcons as HBoxContainer
@onready var bombsContainer = $ColorRect/PlayerResources/BombsContainer/BombIcons as HBoxContainer


func set_lives(lives: int):
	for child in livesContainer.get_children():
		child.queue_free()
		
	for i in range(lives):
		var icon = TextureRect.new()
		
		icon.texture = heart_icon
		icon.position = Vector2(0, 4)
		icon.stretch_mode = TextureRect.STRETCH_KEEP
		icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		
		livesContainer.add_child(icon)


func set_bombs(bombs: int):	
	if bombs < 0:
		bombs = 0
	
	for child in bombsContainer.get_children():
		child.queue_free()
		
	for i in range(bombs):
		var icon = TextureRect.new()
		
		icon.texture = bomb_icon
		icon.position = Vector2(0, 4)
		icon.stretch_mode = TextureRect.STRETCH_KEEP
		icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		
		bombsContainer.add_child(icon)


func set_score(score: int):
	pass
