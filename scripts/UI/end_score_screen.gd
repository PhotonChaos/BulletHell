class_name EndScoreScreen
extends Control

signal restart

@onready var livesBox: HBoxContainer = $ColorRect/VBoxContainer/ScoreStats/LivesBonus
@onready var bombsBox: HBoxContainer = $ColorRect/VBoxContainer/ScoreStats/BombsBonus
@onready var perfectBox: HBoxContainer = $ColorRect/VBoxContainer/ScoreStats/PerfectBonus
@onready var totalBonusBox: HBoxContainer = $ColorRect/VBoxContainer/ScoreStats/TotalBonus
@onready var totalScoreBox: HBoxContainer = $ColorRect/VBoxContainer/ScoreStats/ScoreTotal
@onready var dividerBar: ColorRect = $ColorRect/VBoxContainer/ScoreStats/ColorRect
@onready var bgRect: ColorRect = $ColorRect

@onready var title: Label = $ColorRect/VBoxContainer/WinTitle

const BONUS_PER_LIFE: int = 10000
const BONUS_PER_BOMB: int = 2000
const BONUS_PER_PERFECT: int = 50000

const GAME_END_BG_COLOUR = Color("56bf00", 0.521)
const LEVEL_END_BG_COLOUR = Color("797a78", 0.321)

func _ready() -> void:
	if GameController.desperado:
		title.text = "PERFECT!!"
	else:
		title.text = "YOU WIN!!"

func calculate_bonus(lives: int, bombs: int, perfects: int) -> int:
	return lives * BONUS_PER_LIFE + bombs * BONUS_PER_BOMB + perfects * BONUS_PER_PERFECT

## Invokes the game end screen
func end_transition(lives: int, bombs: int, perfects: int, score: int):
	var tween = get_tree().create_tween()

	livesBox.get_child(0).text += str(lives)
	bombsBox.get_child(0).text += str(bombs)
	#perfectBox.get_child(0).text += "N/A" #str(perfects)
	totalBonusBox.get_child(1).text = str(calculate_bonus(lives, bombs, perfects))
	totalScoreBox.get_child(1).text = str(score + calculate_bonus(lives, bombs, perfects))
	
	livesBox.get_child(1).text = "x" + str(BONUS_PER_LIFE)
	bombsBox.get_child(1).text = "x" + str(BONUS_PER_BOMB)
	#perfectBox.get_child(1).text = "x" + str(BONUS_PER_PERFECT)
	
	bgRect.color = GAME_END_BG_COLOUR
	modulate = Color.TRANSPARENT
	
	tween.tween_interval(0.5)
	tween.tween_property(self, "modulate", Color.WHITE, 0.75)
	
	for box: HBoxContainer in [livesBox, bombsBox, totalBonusBox, totalScoreBox]:
		var label: Label = box.get_child(0)
		var bonus: Label = box.get_child(1)
		
		label.modulate = Color.TRANSPARENT
		bonus.modulate = Color.TRANSPARENT
		
		if box == totalScoreBox:
			var oldPosBar = dividerBar.position
			
			dividerBar.color = Color.TRANSPARENT
			tween.tween_property(dividerBar, "color", Color.WHITE, 0.5)
		
		tween.tween_property(label, "modulate", Color.WHITE, 0.5)
		tween.parallel().tween_property(bonus, "modulate", Color.WHITE, 0.5)
		
## Invokes the level end screen
func level_end_transition():
	bgRect.color = GAME_END_BG_COLOUR
	# TODO: Finish this

func _on_restart_button_pressed() -> void:
	GameController.skip_dialogue = false
	restart.emit()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
