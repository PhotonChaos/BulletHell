extends Control

@onready var main_container: VBoxContainer = $VBoxContainer
@onready var music_container: VBoxContainer = $MusicCredits
@onready var credits_container: VBoxContainer = $CreditsContainer
@onready var options_container: OptionsMenu = $OptionsMenu
@onready var options_back_button: Button = $OptionsMenu/HBoxContainer/VBoxContainer/BackButton
@onready var credits_back_button: Button = $CreditsContainer/BackButton

@onready var menu_bgm: AudioStreamPlayer = $BackgroundMusic

var game = preload("res://scenes/game.tscn")

var main_tween: Tween

var music_tween: Tween

const MENU_IO_TIME: float = 0.1
const CREDS_TRANS_Y = 20

func _ready() -> void:
	menu_bgm.finished.connect(func(): menu_bgm.play())
	
	options_container.position.y += 40
	options_container.modulate = Color.TRANSPARENT
	
	options_container.sfx_test.connect($SFXTest.play)
	
	for c in credits_container.get_children():
		c.modulate = Color.TRANSPARENT

	music_container.position.y -= 10
	music_container.modulate = Color.TRANSPARENT
	
	music_tween = get_tree().create_tween()
	music_tween.tween_interval(0.5)
	music_tween.tween_property(music_container, "position:y", music_container.position.y + 10, 0.8)
	music_tween.parallel().tween_property(music_container, "modulate", Color.WHITE, 0.8)
	music_tween.tween_interval(2)
	music_tween.tween_property(music_container, "position:y", music_container.position.y + 30, 0.8)
	music_tween.parallel().tween_property(music_container, "modulate", Color.TRANSPARENT, 0.8)
	



####################
## Utility Functions
func fade_out_menu(tw: Tween) -> Tween:
	var buttons = main_container.get_children()
	
	for button in buttons:
		(button as Button).disabled = true
		tw.tween_property(button, "modulate", Color.TRANSPARENT, MENU_IO_TIME)
		tw.parallel().tween_property(button, "position:y", button.position.y - 40, MENU_IO_TIME)
	
	return tw
	
func fade_in_menu(tw: Tween) -> Tween:
	var buttons = main_container.get_children()
	buttons.reverse()
	
	for button in buttons:
		tw.tween_property(button, "modulate", Color.WHITE, MENU_IO_TIME)
		tw.parallel().tween_property(button, "position:y", button.position.y + 40, MENU_IO_TIME)
	
	for button in buttons:
		tw.tween_callback(func(): (button as Button).disabled = false)

	return tw

####################
## Button Functions

func _on_play_button_pressed() -> void:
	GameController.desperado = false
	get_tree().change_scene_to_packed(game)

## Options
func _on_options_button_pressed() -> void:
	main_tween = get_tree().create_tween()
	options_container.show()
	fade_out_menu(main_tween)
	
	main_tween.tween_property(options_container, "position:y", options_container.position.y + 10, 0.3)
	main_tween.parallel().tween_property(options_container, "modulate", Color.WHITE, 0.3)
	
	main_tween.tween_callback(func(): 
		options_back_button.disabled = false
		options_container.mouse_filter = Control.MOUSE_FILTER_PASS
		)
	
	main_tween.play()
	

func _on_options_menu_options_closed() -> void:
	main_tween = get_tree().create_tween()
	
	options_back_button.disabled = true
	
	main_tween.tween_property(options_container, "position:y", options_container.position.y - 10, 0.2)
	main_tween.parallel().tween_property(options_container, "modulate", Color.WHITE, 0.2)
	
	main_tween.tween_callback(options_container.hide)
		
	fade_in_menu(main_tween)
	main_tween.play()


## Credits
func _on_credits_button_pressed() -> void:
	credits_container.show()
	($CreditsContainer/BackButton as Button).show()
	
	await get_tree().create_timer(0).timeout
	
	main_tween = get_tree().create_tween()
	fade_out_menu(main_tween)
		
	for component in credits_container.get_children():
		component.modulate = Color.TRANSPARENT
		main_tween.tween_property(component, "modulate", Color.WHITE, 0.3)
		main_tween.parallel().tween_property(component, "global_position:y", component.global_position.y + CREDS_TRANS_Y, 0.3)
	
	main_tween.tween_callback(func(): 
		($CreditsContainer/BackButton as Button).disabled = false
		($CreditsContainer/BackButton as Button).mouse_filter = Control.MOUSE_FILTER_PASS
		credits_container.mouse_filter = Control.MOUSE_FILTER_PASS
		)
	
	
func _on_back_button_pressed() -> void:
	main_tween = get_tree().create_tween()
	($CreditsContainer/BackButton as Button).disabled = false
	credits_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	await get_tree().create_timer(0).timeout
	
	for component in credits_container.get_children():
		main_tween.tween_property(component, "modulate", Color.TRANSPARENT, 0.05)
		main_tween.parallel().tween_property(component, "global_position:y", component.global_position.y - CREDS_TRANS_Y, 0.05)
	
	main_tween.tween_callback(credits_container.hide)
	main_tween.tween_callback(($CreditsContainer/BackButton as Button).hide)
	fade_in_menu(main_tween)

	main_tween.play()


## Quitting the game
func _on_quit_button_pressed() -> void:
	get_tree().quit()
	


func _on_play_desperado_pressed() -> void:
	GameController.desperado = true
	get_tree().change_scene_to_packed(game)
