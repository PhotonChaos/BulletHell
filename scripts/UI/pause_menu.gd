class_name PauseMenuUI
extends Control
## This class will always process, even when the game is paused.

@onready var options_button: Button = $ColorRect/VBoxContainer/VBoxContainer/OptionsButton
@onready var main_container: VBoxContainer = $ColorRect/VBoxContainer
@onready var ui_bg: ColorRect = $ColorRect
@onready var options_menu: OptionsMenu = $ColorRect/OptionsMenu
@onready var sfx_test_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	options_menu.hide()

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
	options_button.disabled = true
	main_container.hide()
	options_menu.show()

func _on_options_menu_options_closed() -> void:
	options_menu.hide()
	main_container.show()
	options_button.disabled = false

func _on_options_menu_sfx_test() -> void:
	sfx_test_player.play()
	

func _on_quit_button_pressed() -> void:
	pass # TODO: Quitting to menu
