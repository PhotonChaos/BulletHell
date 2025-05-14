class_name EndScoreScreen
extends Control

signal restart

@onready var livesBox: HBoxContainer = $ColorRect/VBoxContainer/ScoreStats/LivesBonus
@onready var bombsBox: HBoxContainer = $ColorRect/VBoxContainer/ScoreStats/BombsBonus
@onready var perfectBox: HBoxContainer = $ColorRect/VBoxContainer/ScoreStats/PerfectBonus
@onready var totalBonusBox: HBoxContainer = $ColorRect/VBoxContainer/ScoreStats/TotalBonus
@onready var totalScoreBox: HBoxContainer = $ColorRect/VBoxContainer/ScoreStats/ScoreTotal
@onready var dividerBar: ColorRect = $ColorRect/VBoxContainer/ScoreStats/ColorRect

func end_transition():
	var tween = get_tree().create_tween()
	tween.tween_interval(1)
	
	for box: HBoxContainer in [livesBox, bombsBox, perfectBox, totalBonusBox, totalScoreBox]:
		var label: Label = box.get_child(0)
		var score: Label = box.get_child(1)
		#var oldPos = box.position
		
		#box.set_position(box.position + Vector2(0, -20))
		#label.offset_bottom = 20
		#score.offset_bottom = 20
		label.modulate = Color.TRANSPARENT
		score.modulate = Color.TRANSPARENT
		
		if box == totalScoreBox:
			var oldPosBar = dividerBar.position
			#dividerBar.set_position(dividerBar.position + Vector2(0, -20))
			#dividerBar.offset_bottom = 20
			dividerBar.color = Color.TRANSPARENT
			#tween.tween_property(dividerBar, "position", oldPosBar, 0.5)
			#tween.tween_property(dividerBar, "offset_bottom", 0, 0.5)
			tween.tween_property(dividerBar, "color", Color.WHITE, 0.5)
		
		#tween.tween_property(box, "position", oldPos, 0.5)
		#tween.tween_property(label, "offset_bottom", 0, 0.5)
		#tween.tween_property(score, "offset_bottom", 0, 0.5)
		tween.tween_property(label, "modulate", Color.WHITE, 0.5)
		tween.parallel().tween_property(score, "modulate", Color.WHITE, 0.5)
		



func _on_restart_button_pressed() -> void:
	restart.emit()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
