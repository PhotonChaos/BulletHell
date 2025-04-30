class_name Boss
extends Area2D
## Base class for a Boss. Subclass this for special behaviour![br]
## Just load this up with spell cards if you don't need anything fancy

## Emits when the boss runs out of spell cards
signal boss_defeated

## Emits when the current spell card has been defeated
signal spell_card_defeated

## Emits when the spell card health changes
signal hp_changed(old: int, new: int)

## The name that displays in dialogue and under the bosses health bar 
@export var boss_name: String

## The title of the boss that displays during dialogue
@export var boss_title: String

## The attacks that the boss uses. Using int as a placeholder for the nodes
@export var spell_cards: Array[SpellCard]

var current_spell: SpellCard = null

func next_spell() -> void:
	pass

func _ready() -> void:
	area_entered.connect(_on_hitbox_entered)
	

func _on_hitbox_entered(area: Area2D) -> void:
	if area is PlayerShot:
		area.queue_free()
		
		if current_spell.
