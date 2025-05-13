class_name GameOverMenu 
extends Control

signal restart

func _on_restart_button_pressed() -> void:
	restart.emit()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
