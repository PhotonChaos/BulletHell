class_name GameplayUI
extends Control

var heart_icon = preload("res://textures/UI/heart_icon.png")
var bomb_icon  = preload("res://textures/UI/bomb_icon.png")
var phase_icon = preload("res://textures/UI/bossPhases.png")

# Right-side UI elements
@onready var livesContainer = $GeneralSection/VBoxContainer/HBoxContainer/PlayerStats/PlayerResources/LivesContainer/HPIcons as HBoxContainer
@onready var bombsContainer = $GeneralSection/VBoxContainer/HBoxContainer/PlayerStats/PlayerResources/BombsContainer/BombIcons as HBoxContainer
@onready var scoreLabel = $GeneralSection/VBoxContainer/HBoxContainer/PlayerStats/Scores/Score as Label
@onready var highScoreLabel = $GeneralSection/VBoxContainer/HBoxContainer/PlayerStats/Scores/HighScore as Label
@onready var flashBombMeter = $GeneralSection/VBoxContainer/HBoxContainer/FlashbombContainer/VBoxContainer/FlashbombMeter/TextureProgressBar as TextureProgressBar

# Boss UI elements
@onready var spellNameLabel = $BossStats/VBoxContainer/HBoxContainer/SpellName as Label
@onready var bossNameLabel = $BossStats/VBoxContainer/HBoxContainer/BossName as Label
@onready var timerLabel = $BossStats/TimeLeft as Label
@onready var hpBar = $BossStats/VBoxContainer/HealthBar as ProgressBar
@onready var bossStats = $BossStats as HBoxContainer
@onready var phaseContainer = $BossStats/VBoxContainer/PhasesLeft as HBoxContainer

# Music UI elements
@onready var musicLabel = $VBoxContainer/HBoxContainer/MusicCredit as Label
@onready var musicIcon = $VBoxContainer/HBoxContainer/MusicIcon as TextureRect
@onready var musicBox = $VBoxContainer as VBoxContainer

var musicY

# Boss Tracker
@onready var bossPos = $BossPosIndicator as TextureRect


func _ready() -> void:
	musicBox.hide()
	musicY = musicBox.position.y

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
	scoreLabel.text = "Score: " + str(score)


func set_high_score(score: int):
	highScoreLabel.text = "High Score: " + str(score)


func set_flash_charge(charge: float, max: float):
	flashBombMeter.value = charge
	flashBombMeter.max_value = max


func set_boss_pos(boss_x: float):
	bossPos.position.x = boss_x

# Boss Methods
func set_boss_stats(_visible: bool):
	if _visible:
		bossStats.show()
	else:
		bossStats.hide()

func set_spell_name(_name: String):
	spellNameLabel.text = _name
	
func set_boss_name(_name: String):
	bossNameLabel.text = _name
	
func set_time(time: float):
	timerLabel.text = "%000.2f" % time

func set_hp(hp: int, max: int):
	hpBar.max_value = max
	hpBar.value = hp

func set_phases(num_phases: int) -> void:
	for child in phaseContainer.get_children():
		child.queue_free()
	
	for i in range(num_phases):
		var icon = TextureRect.new()
		
		icon.texture = phase_icon
		icon.stretch_mode = TextureRect.STRETCH_KEEP
		icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		
		phaseContainer.add_child(icon)
		
func show_bgm_credit(artist: String, song_name: String) -> void:
	const CREDIT_Y_OFFSET = 30
	
	musicBox.show()
	musicBox.position.y = musicY - CREDIT_Y_OFFSET
	
	musicLabel.text = artist + " - " + song_name
	musicLabel.modulate = Color.TRANSPARENT
	musicIcon.modulate = Color.TRANSPARENT
	
	var tw = get_tree().create_tween()
	
	tw.tween_property(musicBox, "position:y", musicY, 1)
	tw.parallel().tween_property(musicLabel, "modulate", Color.WHITE, 1)
	tw.parallel().tween_property(musicIcon, "modulate", Color.WHITE, 1)
	tw.tween_interval(3)
	tw.tween_property(musicLabel, "modulate", Color.TRANSPARENT, 1)
	tw.parallel().tween_property(musicIcon, "modulate", Color.TRANSPARENT, 1)
	tw.parallel().tween_property(musicBox, "position:y", musicY + CREDIT_Y_OFFSET, 1)
