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
@onready var spellNameLabel = $GameOverlay/BossStats/VBoxContainer/HBoxContainer/SpellName as Label
@onready var bossNameLabel = $GameOverlay/BossStats/VBoxContainer/HBoxContainer/BossName as Label
@onready var timerLabel = $GameOverlay/BossStats/TimeLeft as Label
@onready var hpBar = $GameOverlay/BossStats/VBoxContainer/HealthBar as ProgressBar
@onready var phaseContainer = $GameOverlay/BossStats/VBoxContainer/PhasesLeft as HBoxContainer
@onready var bossStats = $GameOverlay/BossStats as HBoxContainer

# Music UI elements
@onready var musicLabel = $GameOverlay/MusicCredits/HBoxContainer/MusicCredit as Label
@onready var musicIcon = $GameOverlay/MusicCredits/HBoxContainer/MusicIcon as TextureRect
@onready var musicBox = $GameOverlay/MusicCredits as VBoxContainer

var musicY

# Dialogue UI Elements
@onready var dialogueContainer = $GameOverlay/DialogueUI as ColorRect
@onready var dialogueNameplateLeft = $GameOverlay/DialogueUI/NameplateLeft as ColorRect
@onready var dialogueNameplateRight = $GameOverlay/DialogueUI/NameplateRight as ColorRect
@onready var dialogueNameplateLeftText = $GameOverlay/DialogueUI/NameplateLeft/Label as Label
@onready var dialogueNameplateRightText = $GameOverlay/DialogueUI/NameplateRight/Label as Label
@onready var dialogueText = $GameOverlay/DialogueUI/Text as Label

# Boss Tracker
@onready var bossPos = $BossPosIndicator as TextureRect

# Dialogue Variables
var dialogueStartingWidth: float
var dialogueStartingHeight: float
var nameplateStartColor: Color

var leftPlateShown: bool
var rightPlateShown: bool
var leftPlateActive: bool
var rightPlateActive: bool


func _ready() -> void:
	musicBox.hide()
	musicY = musicBox.position.y
	
	dialogueStartingWidth = dialogueContainer.size.x
	dialogueStartingHeight = dialogueContainer.size.y
	nameplateStartColor = dialogueNameplateLeft.color
	dialogueContainer.hide()
	
	leftPlateShown = false
	rightPlateShown = false
	leftPlateActive = false
	rightPlateActive = false


func _set_icons(container: HBoxContainer, count: int, texture: Resource):
	for child in container.get_children():
		child.queue_free()
		
	for i in range(count):
		var icon = TextureRect.new()
		
		icon.texture = texture
		icon.position = Vector2(0, 4)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		
		container.add_child(icon)


func set_lives(lives: int):
	_set_icons(livesContainer, lives, heart_icon)


func set_bombs(bombs: int):
	_set_icons(bombsContainer, bombs, bomb_icon)


func set_score(score: int):
	scoreLabel.text = "Score: " + str(score)


func set_high_score(score: int):
	highScoreLabel.text = "High Score: " + str(score)


func set_flash_charge(charge: float, max: float):
	flashBombMeter.value = charge
	flashBombMeter.max_value = max

# Dialogue Methods
## Plays the animation for popping up the dialogue window
func show_dialogue() -> Tween:
	dialogueContainer.show()
	var tw = get_tree().create_tween().set_trans(Tween.TRANS_QUAD)
	
	dialogueNameplateLeft.hide()
	dialogueNameplateRight.hide()
	
	var oldColor = dialogueContainer.color
	
	dialogueContainer.size = Vector2(10, dialogueStartingHeight)
	dialogueContainer.color = Color.TRANSPARENT
	dialogueText.text = ""
	
	dialogueNameplateLeftText.text = ""
	dialogueNameplateRightText.text = ""
	dialogueNameplateLeftText.modulate = Color.WHITE
	dialogueNameplateRightText.modulate = Color.WHITE
	
	tw.tween_property(dialogueContainer, "size:x", dialogueStartingWidth, 1)
	tw.parallel().tween_property(dialogueContainer, "color", oldColor, 1)
	
	return tw


func hide_dialogue() -> Tween:
	var tw = get_tree().create_tween()
	
	tw.tween_property(dialogueNameplateLeft, "color", Color.TRANSPARENT, 0.3)
	tw.parallel().tween_property(dialogueNameplateRight, "color", Color.TRANSPARENT, 0.3)
	tw.parallel().tween_property(dialogueNameplateLeftText, "modulate", Color.TRANSPARENT, 0.3)
	tw.parallel().tween_property(dialogueNameplateRightText, "modulate", Color.TRANSPARENT, 0.3)
	
	tw.tween_property(dialogueContainer, "size:x", 0, 0.5)
	tw.parallel().tween_property(dialogueContainer, "color", Color.TRANSPARENT, 0.5)
	tw.tween_callback(func(): dialogueContainer.hide())
	
	return tw

## Shows a line of dialogue. 
func dialogue_line(side: String, speaker_id: String, emotion_id: String, text: String):
	dialogueText.text = text


func introduce_speaker(speaker_id: String, on_left: bool):
	var tw = get_tree().create_tween().set_trans(Tween.TRANS_EXPO)
	
	if on_left:
		dialogueNameplateLeft.position -= Vector2(0, -10)
		tw.tween_property(dialogueNameplateLeft, "color", nameplateStartColor, 0.3)
		tw.parallel().tween_property(dialogueNameplateLeft, "position:y", dialogueNameplateLeft.position.y + 10, 0.3)

# Boss Methods
func set_boss_pos(boss_x: float, boss_width: float):
	bossPos.position.x = boss_x
	bossPos.size.x = boss_width

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
	const CREDIT_Y_OFFSET = 10
	
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
