class_name GameplayUI
extends Control

var heart_icon = preload("res://textures/UI/heart_icon.png")
var bomb_icon  = preload("res://textures/UI/bomb_icon.png")

@onready var livesContainer = $ColorRect/PlayerStats/VBoxContainer/PlayerResources/LivesContainer/HPIcons as HBoxContainer
@onready var bombsContainer = $ColorRect/PlayerStats/VBoxContainer/PlayerResources/BombsContainer/BombIcons as HBoxContainer

@onready var scoreLabel = $ColorRect/PlayerStats/VBoxContainer/Scores/Score as Label
@onready var highScoreLabel = $ColorRect/PlayerStats/VBoxContainer/Scores/HighScore as Label

var highScore: int = -1


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
	if score > highScore:
		highScore = score
		highScoreLabel.text = "High Score: " + str(highScore)
	
	scoreLabel.text = "Score: " + str(score)
