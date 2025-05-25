class_name DialogueProfile
extends Resource

## The ID of the character this profile represents. This is used by dialogue scripts to reference the character, so it must be unique.
@export var character_id: String

## The name which gets displayed in the dialogue box.
@export var character_name: String

## The title shown alongside the character name when their name and titel are revealed during dialogue
@export var character_title: String

## The color of the character's title + text in dialogue
@export var character_color: Color

## A dictionary mapping emotion ids to portrait images. A portrait assigned to "neutral" is strongly reccommended!
@export var portraits: Dictionary[String, Texture2D]
