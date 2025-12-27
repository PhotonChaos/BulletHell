class_name OptionsMenu
extends Control

signal options_closed
signal sfx_test

@export_range(0, 1) var default_bgm_volume: float
@export_range(0, 1) var default_sfx_volume: float

@onready var music_slider: HSlider = $HBoxContainer/VBoxContainer/MusicVolume/MusicVolumeSlider
@onready var sfx_slider: HSlider = $HBoxContainer/VBoxContainer/SFXVolume/SFXVolumeSlider

## Index for the master bus that handles everything
const BUS_MASTER_INDEX = 0

## Index for the bus that handles sound effects
const BUS_SFX_INDEX = 1

## Index for the audio bus that handles background music
const BUS_BGM_INDEX = 2

## Static flag that is true if the user has adjusted the volume
static var sf_volume_cusomized: bool = false

func _ready() -> void:
	if not sf_volume_cusomized:
		AudioServer.set_bus_volume_linear(BUS_BGM_INDEX, default_bgm_volume)
		AudioServer.set_bus_volume_linear(BUS_SFX_INDEX, default_sfx_volume)
		
	music_slider.value = AudioServer.get_bus_volume_linear(BUS_BGM_INDEX)
	sfx_slider.value = AudioServer.get_bus_volume_linear(BUS_SFX_INDEX)


func _on_music_volume_slider_value_changed(value: float) -> void:
	sf_volume_cusomized = true
	AudioServer.set_bus_volume_linear(BUS_BGM_INDEX, value)


func _on_sfx_volume_slider_value_changed(value: float) -> void:
	sf_volume_cusomized = true
	AudioServer.set_bus_volume_linear(BUS_SFX_INDEX, value)


func _on_sfx_volume_slider_drag_ended(value_changed: bool) -> void:
	sfx_test.emit()


func _on_back_button_pressed() -> void:
	options_closed.emit()
