class_name GameplayUI
extends Control

var heart_icon = preload("res://textures/UI/heart_icon.png")
var bomb_icon  = preload("res://textures/UI/bomb_icon.png")
var phase_icon = preload("res://textures/UI/bossPhases.png")

@export var dialogueProfiles: Array[DialogueProfile]

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
@onready var dialoguePortraitLeft = $GameOverlay/DialogueUI/PortraitLeft as TextureRect
@onready var dialoguePortraitRight = $GameOverlay/DialogueUI/PortraitRight as TextureRect
@onready var dialogueText = $GameOverlay/DialogueUI/Text as Label

# Boss Tracker
@onready var bossPos = $BossPosIndicator as TextureRect

# Dialogue Variables
const DEFAULT_COLOR: Color = Color.WHITE
const DEFAULT_NAME: String = "???"
const DEFAULT_EMOTION: String = "neutral"

## Time that animations for activating a side of dialogue should take
const DIALOGUE_SIDE_SWITCH_TIME = 0.2

var dialogueRegistry: Dictionary[String, DialogueProfile]

var dialogueStartingWidth: float
var dialogueStartingHeight: float

var dialogueStartColor: Color
var nameplateStartColor: Color

var leftPlateStartPos: Vector2
var rightPlateStartPos: Vector2

var leftPortraitStartPos: Vector2
var rightPortraitStartPos: Vector2

var leftPlateShown: bool
var leftPlateActive: bool
var rightPlateShown: bool
var rightPlateActive: bool

var side: String = "N"


func _ready() -> void:
	musicBox.hide()
	musicY = musicBox.position.y
	
	dialogueStartingWidth = dialogueContainer.size.x
	dialogueStartingHeight = dialogueContainer.size.y
	dialogueStartColor = dialogueContainer.color
	nameplateStartColor = dialogueNameplateLeft.color
	
	leftPlateStartPos = dialogueNameplateLeft.position
	rightPlateStartPos = dialogueNameplateRight.position
	
	dialogueContainer.hide()
	
	leftPlateShown = false
	rightPlateShown = false
	
	leftPlateActive = false
	rightPlateActive = false
	
	leftPortraitStartPos = dialoguePortraitLeft.position
	rightPortraitStartPos = dialoguePortraitRight.position
	
	# Setup dialogue registry
	dialogueRegistry = {}
	
	for profile in dialogueProfiles:
		dialogueRegistry[profile.character_id] = profile
	


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
	leftPlateShown = false
	rightPlateShown = false
	
	leftPlateActive = false
	rightPlateActive = false
	
	dialogueContainer.size = Vector2(10, dialogueStartingHeight)
	dialogueContainer.color.a = 0
	dialogueText.text = ""
	
	dialogueNameplateLeftText.text = ""
	dialogueNameplateRightText.text = ""
	#dialogueNameplateLeftText.modulate = Color.WHITE
	#dialogueNameplateRightText.modulate = Color.WHITE
	
	tw.tween_property(dialogueContainer, "size:x", dialogueStartingWidth, 1)
	tw.parallel().tween_property(dialogueContainer, "color", dialogueStartColor, 1)
	
	return tw


func hide_dialogue() -> Tween:
	var tw = get_tree().create_tween()
	
	tw.tween_property(dialogueNameplateLeft, "modulate", Color.TRANSPARENT, DIALOGUE_SIDE_SWITCH_TIME)
	tw.parallel().tween_property(dialogueNameplateRight, "modulate", Color.TRANSPARENT, DIALOGUE_SIDE_SWITCH_TIME)
	
	tw.tween_property(dialogueContainer, "size:x", 0, 0.5)
	tw.parallel().tween_property(dialogueContainer, "color", Color.TRANSPARENT, 0.5)
	tw.tween_callback(func(): dialogueContainer.hide())
	
	leftPlateShown = false
	rightPlateShown = false
	
	leftPlateActive = false
	rightPlateActive = false
	
	dialoguePortraitLeft.hide()
	dialoguePortraitRight.hide()
	
	return tw

func set_nameplate(nameplate: ColorRect, active: bool) -> Tween:
	var tw = get_tree().create_tween()
	
	if active:
		nameplate.position += Vector2(0, 10)
		tw.tween_property(nameplate, "color:a", nameplateStartColor.a, DIALOGUE_SIDE_SWITCH_TIME)
		tw.parallel().tween_property(nameplate, "position:y", leftPlateStartPos.y, DIALOGUE_SIDE_SWITCH_TIME)
	else:
		nameplate.position.y = leftPlateStartPos.y
		tw.tween_property(nameplate, "color:a", 0.3, DIALOGUE_SIDE_SWITCH_TIME)
		tw.parallel().tween_property(nameplate, "position:y", leftPlateStartPos.y+10, DIALOGUE_SIDE_SWITCH_TIME)
	
	return tw
	
func set_portrait(left: bool, active: bool) -> Tween:
	var tw = get_tree().create_tween()
	
	const OFFSET = 15
	
	var original_pos = leftPortraitStartPos if left else rightPortraitStartPos
	var begin_pos = original_pos if not active else original_pos - OFFSET
	var end_x_offset = -OFFSET if left else OFFSET
	var portrait = dialoguePortraitLeft if left else dialoguePortraitRight
	var oldPos = portrait.position.x
	
	#portrait.position.x += begin_x_offset
	tw.tween_property(portrait, "position:x", oldPos, DIALOGUE_SIDE_SWITCH_TIME)
	
	return tw
	
	
func show_nameplate(nameplate: ColorRect, original_pos: Vector2) -> Tween:
	var tw = get_tree().create_tween()
	
	nameplate.position += Vector2(0, 20)
	nameplate.color.a = 0
	
	nameplate.show()
	
	tw.tween_property(nameplate, "modulate", Color.WHITE, DIALOGUE_SIDE_SWITCH_TIME)
	tw.parallel().tween_property(nameplate, "position", original_pos, DIALOGUE_SIDE_SWITCH_TIME)
	
	return tw

func show_portrait(left: bool) -> Tween:
	var tw = get_tree().create_tween()
	
	return tw
	


## Shows a line of dialogue. 
func dialogue_line(side: String, speaker_id: String, emotion_id: String, text: String):
	var _name = DEFAULT_NAME
	var _color = DEFAULT_COLOR
	var portrait: Texture2D
	
	if dialogueRegistry.has(speaker_id):
		_name = dialogueRegistry[speaker_id].character_name
		_color = dialogueRegistry[speaker_id].character_color
		
		if dialogueRegistry[speaker_id].portraits.has(emotion_id):
			portrait = dialogueRegistry[speaker_id].portraits[emotion_id]
		elif dialogueRegistry[speaker_id].portraits.has(DEFAULT_EMOTION):
			Logger.warning("Emotion " + emotion_id + " is missing portrait for speaker " + speaker_id)
			portrait = dialogueRegistry[speaker_id].portraits[DEFAULT_EMOTION]
		else:
			Logger.warning("Emotion " + emotion_id + " is missing portrait for speaker " + speaker_id)
			Logger.warning("Fallback emotion neutral also missing portrait for speaker " + speaker_id + ". Defaulting to empty image.")
			portrait = Texture2D.new()
	
	var activeNameplate: ColorRect
	var activeNameplateText: Label
	var activePortrait: TextureRect
	
	var inactiveNameplate: ColorRect
	var inactivePortrait: TextureRect
	
	if side == "L":
		activeNameplate = dialogueNameplateLeft
		activeNameplateText = dialogueNameplateLeftText
		activePortrait = dialoguePortraitLeft
		
		inactiveNameplate = dialogueNameplateRight
		inactivePortrait = dialoguePortraitRight
		
		if not leftPlateShown:
			show_nameplate(dialogueNameplateLeft, leftPlateStartPos)
			leftPlateShown = true
			
		if not leftPlateActive:
			set_nameplate(activeNameplate, true)
			leftPlateActive = true
			
			set_nameplate(inactiveNameplate, false)
			rightPlateActive = false
	else:
		activeNameplate = dialogueNameplateRight
		activeNameplateText = dialogueNameplateRightText
		activePortrait = dialoguePortraitRight
		
		inactiveNameplate = dialogueNameplateLeft
		inactivePortrait = dialoguePortraitLeft
		
		if not rightPlateShown:
			show_nameplate(dialogueNameplateRight, rightPlateStartPos)
			rightPlateShown = true
		
		if not rightPlateActive:
			set_nameplate(activeNameplate, true)
			rightPlateActive = true
			
			set_nameplate(inactiveNameplate, false)
			leftPlateActive = false
	
	inactivePortrait.hide()
	
	activePortrait.texture = portrait
	activePortrait.show()
	
	activeNameplateText.text = _name
	activeNameplateText.set("theme_override_colors/font_color", _color)
	
	dialogueText.text = text
	dialogueText.set("theme_override_colors/font_color", _color)


func introduce_speaker(speaker_id: String, on_left: bool):
	var tw = get_tree().create_tween().set_trans(Tween.TRANS_EXPO)
	
	if on_left:
		dialogueNameplateLeft.position -= Vector2(0, -10)
		tw.tween_property(dialogueNameplateLeft, "color", nameplateStartColor, DIALOGUE_SIDE_SWITCH_TIME)
		tw.parallel().tween_property(dialogueNameplateLeft, "position:y", dialogueNameplateLeft.position.y + 10, DIALOGUE_SIDE_SWITCH_TIME)

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
