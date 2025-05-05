class_name PauseMenuUI
extends Control
## This class will always process, even when the game is paused.


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("escape") and GameController._game_instance.is_ingame():
		GameController._game_instance.set_pause(not GameController._game_instance.is_paused())
		
		if GameController._game_instance.is_paused():
			show()
		else:
			hide()


func _on_resume_button_pressed() -> void:
	GameController._game_instance.set_pause(false)
	hide()


func _on_options_button_pressed() -> void:
	pass # TODO: Options Menu


func _on_quit_button_pressed() -> void:
	pass # TODO: Quitting to menu
